"""
    DimGroupByArray <: AbstractDimArray

`DimGroupByArray` is essentially a `DimArray` but holding
the results of a `groupby` operation.

Its dimensions are the sorted results of the grouping functions
used in `groupby`.

This wrapper allows for specialisations on later broadcast or
reducing operations, e.g. for chunk reading with DiskArrays.jl,
because we know the data originates from a single array.
"""
struct DimGroupByArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na,Me} <: AbstractDimArray{T,N,D,A}
    data::A
    dims::D
    refdims::R
    name::Na
    metadata::Me
    function DimGroupByArray(
        data::A, dims::D, refdims::R, name::Na, metadata::Me
    ) where {D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na,Me} where {T,N}
        checkdims(data, dims)
        new{T,N,D,R,A,Na,Me}(data, dims, refdims, name, metadata)
    end
end
function DimGroupByArray(data::AbstractArray, dims::Union{Tuple,NamedTuple};
    refdims=(), name=NoName(), metadata=NoMetadata()
)
    DimGroupByArray(data, format(dims, data), refdims, name, metadata)
end
@inline function rebuild(
    A::DimGroupByArray, data::AbstractArray, dims::Tuple, refdims::Tuple, name, metadata
)
    # Rebuild as a regular DimArray
    dimconstructor(dims)(data, dims, refdims, name, metadata)
end
@inline function rebuild(A::DimGroupByArray;
    data=parent(A), dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A)
)
    rebuild(A, data, dims, refdims, name, metadata) # Rebuild as a regular DimArray
end

function Base.summary(io::IO, A::DimGroupByArray{T,N}) where {T<:AbstractArray{T1,N1},N} where {T1,N1}
    print_ndims(io, size(A))
    print(io, string(nameof(typeof(A)), "{$(nameof(T)){$T1,$N1},$N}"))
end

function show_after(io::IO, mime, A::DimGroupByArray)
    displayheight, displaywidth = displaysize(io)
    blockwidth = get(io, :blockwidth, 0)
    if length(A) > 0 && isdefined(parent(A), 1)
        x = A[1]
        sorteddims = (dims(A)..., otherdims(x, dims(A))...)
        colordims = dims(map(rebuild, sorteddims, ntuple(dimcolors, Val(length(sorteddims)))), dims(x))
        colors = collect(map(val, colordims))
        lines, new_blockwidth, _ = print_dims_block(io, mime, basedims(x);
            displaywidth, blockwidth, label="group dims", colors
        )
        A1 = map(x -> DimSummariser(x, colors), A)
        ctx = IOContext(io,
            :blockwidth => blockwidth,
            :displaysize => (displayheight - lines, displaywidth)
        )
        show_after(ctx, mime, A1)
    else
        A1 = map(eachindex(A)) do i
            isdefined(parent(A), i) ? DimSummariser(A[i], colors) : Base.undef_ref_str 
        end
        ctx = IOContext(io, :blockwidth => blockwidth)
        show_after(ctx, mime, parent(A))
    end
    return nothing
end

mutable struct DimSummariser{T}
    obj::T
    colors::Vector{Int}
end
function Base.show(io::IO, s::DimSummariser)
    print_ndims(io, size(s.obj); colors=s.colors)
    print(io, string(nameof(typeof(s.obj))))
end
Base.alignment(io::IO, s::DimSummariser) = (textwidth(sprint(show, s)), 0)

# An array that doesn't know what it holds, to simplify dispatch
# It can also hold something that is not an AbstractArray itself.
struct OpaqueArray{T,N,P} <: AbstractArray{T,N}
    parent::P
end
OpaqueArray(A::P) where P<:AbstractArray{T,N} where {T,N} = OpaqueArray{T,N,P}(A)
OpaqueArray(st::P) where P<:AbstractDimStack{<:Any,T,N} where {T,N} = OpaqueArray{T,N,P}(st)

Base.size(A::OpaqueArray) = size(A.parent)
Base.getindex(A::OpaqueArray, args...) = Base.getindex(A.parent, args...)
Base.setindex!(A::OpaqueArray, args...) = Base.setindex!(A.parent, args...)


abstract type AbstractBins <: Function end

(bins::AbstractBins)(x) = bins.f(x)

"""
    Bins(f, bins; labels, pad)
    Bins(bins; labels, pad)

Specify bins to reduce groups after applying function `f`.

- `f`: a grouping function of the lookup values, by default `identity`.
- `bins`:
   * an `Integer` will divide the group values into equally spaced sections.
   * an `AbstractArray` of values will be treated as exact
       matches for the return value of `f`. For example, `1:3` will create 3 bins - 1, 2, 3.
   * an `AbstractArray` of `IntervalSets.Interval` can be used to
       explicitly define the intervals. Overlapping intervals have undefined behaviour.

## Keywords

- `pad`: fraction of the total interval to pad at each end when `Bins` contains an
   `Integer`. This avoids losing the edge values. Note this is a messy solution -
   it will often be prefereble to manually specify a `Vector` of chosen `Interval`s
   rather than relying on passing an `Integer` and `pad`.
- `labels`: a list of descriptive labels for the bins. The labels need to have the same length as `bins`.

When the return value of `f` is a tuple, binning is applied to the _last_ value of the tuples.
"""
struct Bins{F<:Callable,B<:Union{Integer,AbstractVector,Tuple},L,P} <: AbstractBins
    f::F
    bins::B
    labels::L
    pad::P
end
Bins(bins; labels=nothing, pad=0.001) = Bins(identity, bins, labels, pad)
Bins(f, bins; labels=nothing, pad=0.001) = Bins(f, bins, labels, pad)

Base.show(io::IO, bins::Bins) =
    println(io, nameof(typeof(bins)), "(", bins.f, ", ", bins.bins, ")")

abstract type AbstractCyclicBins end

"""
    CyclicBins(f; cycle, start, step, labels)

Cyclic bins to reduce groups after applying function `f`. Groups can wrap around
the cycle. This is used for grouping in [`seasons`](@ref), [`months`](@ref)
and [`hours`](@ref) but can also be used for custom cycles.

- `f`: a grouping function of the lookup values, by default `identity`.

## Keywords

- `cycle`: the length of the cycle, in return values of `f`.
- `start`: the start of the cycle: a return value of `f`.
- `step` the number of sequential values to group.
- `labels`: either a vector of labels matching the number of groups, 
    or a function that generates labels from `Vector{Int}` of the selected bins.

When the return value of `f` is a tuple, binning is applied to the _last_ value of the tuples.
"""
struct CyclicBins{F,C,Sta,Ste,L} <: AbstractBins
    f::F
    cycle::C
    start::Sta
    step::Ste
    labels::L
end
CyclicBins(f; cycle, step, start=1, labels=nothing) = CyclicBins(f, cycle, start, step, labels)

Base.show(io::IO, bins::CyclicBins) =
    println(io, nameof(typeof(bins)), "(", bins.f, "; ", join(map(k -> "$k=$(getproperty(bins, k))", (:cycle, :step, :start)), ", "), ")")

yearhour(x) = year(x), hour(x)

"""
    seasons(; [start=Dates.December, labels])

Generates `CyclicBins` for three month periods.

## Keywords

- `start`: By default seasons start in December, but any integer `1:12` can be used.
- `labels`: either a vector of four labels, or a function that generates labels from `Vector{Int}` of the selected quarters.
"""
seasons(; start=December, kw...) = months(3; start, kw...)

"""
    months(step; [start=Dates.January, labels])

Generates `CyclicBins` for grouping to arbitrary month periods. 
These can wrap around the end of a year.

- `step` the number of months to group.

## Keywords

- `start`: By default months start in January, but any integer `1:12` can be used.
- `labels`: either a vector of labels matching the number of groups, 
    or a function that generates labels from `Vector{Int}` of the selected months.
"""
months(step; start=January, labels=Dict(1:12 .=> monthabbr.(1:12))) = CyclicBins(month; cycle=12, step, start, labels)

"""
    hours(step; [start=0, labels])

Generates `CyclicBins` for grouping to arbitrary hour periods. 
These can wrap around the end of the day.

- `steps` the number of hours to group.

## Keywords

- `start`: By default seasons start at `0`, but any integer `1:24` can be used.
- `labels`: either a vector of four labels, or a function that generates labels
    from `Vector{Int}` of the selected hours of the day.
"""
hours(step; start=0, labels=nothing) = CyclicBins(hour; cycle=24, step, start, labels)

"""
    groupby(A::Union{AbstractDimArray,AbstractDimStack}, dims::Pair...)
    groupby(A::Union{AbstractDimArray,AbstractDimStack}, dims::Dimension{<:Callable}...)

Group `A` by grouping functions or [`Bins`](@ref) over multiple dimensions.

## Arguments

- `A`: any `AbstractDimArray` or `AbstractDimStack`.
- `dims`: `Pair`s such as `groups = groupby(A, :dimname => groupingfunction)` or wrapped
  [`Dimension`](@ref)s like `groups = groupby(A, DimType(groupingfunction))`. Instead of
  a grouping function [`Bins`](@ref) can be used to specify group bins.

## Return value

A [`DimGroupByArray`](@ref) is returned, which is basically a regular `AbstractDimArray`
but holding the grouped `AbstractDimArray` or `AbstractDimStack`. Its `dims`
hold the sorted values returned by the grouping function/s.

Base julia and package methods work on `DimGroupByArray` as for any other
`AbstractArray` of `AbstractArray`.

It is common to broadcast or `map` a reducing function over groups,
such as `mean` or `sum`, like `mean.(groups)` or `map(mean, groups)`.
This will return a regular `DimArray`, or `DimGroupByArray` if `dims`
keyword is used in the reducing function or it otherwise returns an
`AbstractDimArray` or `AbstractDimStack`.

# Example

Group some data along the time dimension:

```jldoctest groupby; setup = :(using Random; Random.seed!(123))
julia> using DimensionalData, Dates

julia> A = rand(X(1:0.1:20), Y(1:20), Ti(DateTime(2000):Day(3):DateTime(2003)));

julia> groups = groupby(A, Ti => month) # Group by month
╭───────────────────────────────────────────────────╮
│ 12-element DimGroupByArray{DimArray{Float64,2},1} │
├───────────────────────────────────────────────────┴───────────── dims ┐
  ↓ Ti Sampled{Int64} [1, 2, …, 11, 12] ForwardOrdered Irregular Points
├───────────────────────────────────────────────────────────── metadata ┤
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>month
├─────────────────────────────────────────────────────────── group dims ┤
  ↓ X, → Y, ↗ Ti
└───────────────────────────────────────────────────────────────────────┘
  1  191×20×32 DimArray
  2  191×20×28 DimArray
  3  191×20×31 DimArray
  ⋮
 11  191×20×30 DimArray
 12  191×20×31 DimArray
```

And take the mean:

```jldoctest groupby; setup = :(using Statistics)
julia> groupmeans = mean.(groups) # Take the monthly mean
╭─────────────────────────────────╮
│ 12-element DimArray{Float64, 1} │
├─────────────────────────────────┴─────────────────────────────── dims ┐
  ↓ Ti Sampled{Int64} [1, 2, …, 11, 12] ForwardOrdered Irregular Points
├───────────────────────────────────────────────────────────── metadata ┤
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>month
└───────────────────────────────────────────────────────────────────────┘
  1  0.500064
  2  0.499762
  3  0.500083
  4  0.499985
  ⋮
 10  0.500874
 11  0.498704
 12  0.50047
```

Calculate daily anomalies from the monthly mean. Notice we map a broadcast
`.-` rather than `-`. This is because the size of the arrays to not
match after application of `mean`.

```jldoctest groupby
julia> map(.-, groupby(A, Ti=>month), mean.(groupby(A, Ti=>month), dims=Ti));
```

Or do something else with Y:

```jldoctest groupby
julia> groupmeans = mean.(groupby(A, Ti=>month, Y=>isodd))
╭───────────────────────────╮
│ 12×2 DimArray{Float64, 2} │
├───────────────────────────┴────────────────────────────────────── dims ┐
  ↓ Ti Sampled{Int64} [1, 2, …, 11, 12] ForwardOrdered Irregular Points,
  → Y  Sampled{Bool} [false, true] ForwardOrdered Irregular Points
├────────────────────────────────────────────────────────────── metadata ┤
  Dict{Symbol, Any} with 1 entry:
  :groupby => (:Ti=>month, :Y=>isodd)
└────────────────────────────────────────────────────────────────────────┘
  ↓ →  false         true
  1        0.499594     0.500533
  2        0.498145     0.501379
  ⋮
 10        0.501105     0.500644
 11        0.498606     0.498801
 12        0.501643     0.499298
```
"""
function DataAPI.groupby(A::DimArrayOrStack, x::AbstractDimArray)
    groupby(A, x)
end
DataAPI.groupby(A::DimArrayOrStack, dimfuncs::Dimension...) = groupby(A, dimfuncs)
function DataAPI.groupby(
    A::DimArrayOrStack, p1::Pair{<:Any,<:Base.Callable}, ps::Pair{<:Any,<:Base.Callable}...;
)
    dims = map((p1, ps...)) do (d, v)
        rebuild(basedims(d), v)
    end
    return groupby(A, dims)
end
function DataAPI.groupby(A::DimArrayOrStack, dimfuncs::DimTuple)
    length(otherdims(dimfuncs, dims(A))) > 0 &&
        Dimensions._extradimserror(otherdims(dimfuncs, dims(A)))

    # Get groups for each dimension
    dim_groups_indices = map(dimfuncs) do d
        _group_indices(dims(A, d), DD.val(d))
    end
    # Separate lookups dims from indices
    group_dims = map(first, dim_groups_indices)
    # Get indices for each group wrapped with dims for indexing
    indices = map(rebuild, group_dims, map(last, dim_groups_indices))

    # Hide that the parent is a DimSlices
    views = OpaqueArray(DimSlices(A, indices))
    # Put the groupby query in metadata
    meta = map(d -> name(d) => val(d), dimfuncs)
    metadata = Dict{Symbol,Any}(:groupby => length(meta) == 1 ? only(meta) : meta)
    # Return a DimGroupByArray
    return DimGroupByArray(views, format(group_dims, views), (), :groupby, metadata)
end

# Define the groups and find all the indices for values that fall in them
function _group_indices(dim::Dimension, f::Base.Callable; labels=nothing)
    orig_lookup = lookup(dim)
    k1 = f(first(orig_lookup))
    indices_dict = Dict{typeof(k1),Vector{Int}}()
    for (i, x) in enumerate(orig_lookup)
         k = f(x)
         inds = get!(() -> Int[], indices_dict, k)
         push!(inds, i)
    end
    ps = sort!(collect(pairs(indices_dict)))
    group_dim = format(rebuild(dim, _maybe_label(labels, first.(ps))))
    indices = last.(ps)
    return group_dim, indices
end
function _group_indices(dim::Dimension, group_lookup::Lookup; labels=nothing)
    orig_lookup = lookup(dim)
    indices = map(_ -> Int[], 1:length(group_lookup))
    for (i, v) in enumerate(orig_lookup)
        n = selectindices(group_lookup, Contains(v); err=Lookups._False())
        isnothing(n) || push!(indices[n], i)
    end
    group_dim = if isnothing(labels)
        rebuild(dim, group_lookup)
    else
        label_lookup = _maybe_label(labels, group_lookup)
        rebuild(dim, label_lookup)
    end
    return group_dim, indices
end
function _group_indices(dim::Dimension, bins::AbstractBins; labels=bins.labels)
    l = lookup(dim)
    # Apply the function first unless its `identity`
    transformed = bins.f == identity ? parent(l) : map(bins.f, parent(l))
    # Calculate the bin groups
    groups = if eltype(transformed) <: Tuple
        # Get all values of the tuples but the last one and take the union
        outer_groups = union!(map(t -> t[1:end-1], transformed))
        inner_groups = _groups_from(transformed, bins)
        # Combine the groups
        mapreduce(vcat, outer_groups) do og
            map(ig -> (og..., ig), inner_groups)
        end
    else
        _groups_from(transformed, bins)
    end
    group_lookup = lookup(format(rebuild(dim, groups)))
    transformed_lookup = rebuild(dim, transformed)

    # Call the Lookup version to do the work using selectors
    return _group_indices(transformed_lookup, group_lookup; labels)
end

# Get a vector of intervals for the bins
_groups_from(_, bins::Bins{<:Any,<:AbstractArray}) = bins.bins
function _groups_from(transformed, bins::Bins{<:Any,<:Integer})
    # With an Integer, we calculate evenly-spaced bins from the extreme values
    a, b = extrema(last, transformed)
    # pad a tiny bit so the top open interval includes the top value (xarray also does this)
    b_p = b + (b - a) * bins.pad
    # Create a range
    rng = range(IntervalSets.Interval{:closed,:open}(a, b_p), bins.bins)
    # Return a Vector of Interval{:closed,:open} for the range
    return IntervalSets.Interval{:closed,:open}.(rng, rng .+ step(rng))
end
function _groups_from(_, bins::CyclicBins)
    map(bins.start:bins.step:bins.start+bins.cycle-1) do g
        map(0:bins.step-1) do n
            rem(n + g - 1, bins.cycle) + 1
        end
    end
end

_maybe_label(vals) = vals
_maybe_label(f::Function, vals) = f.(vals)
_maybe_label(::Nothing, vals) = vals
function _maybe_label(labels::AbstractArray, vals)
    @assert length(labels) == length(vals)
    return labels
end
function _maybe_label(labels::Dict, vals)
    map(vals) do val
        if haskey(labels, val)
            labels[val]
        else
            Symbol(join(map(v -> string(labels[v]), val), '_'))
        end
    end
end

"""
    intervals(A::AbstractRange)

Generate a `Vector` of `UnitRange` with length `step(A)`
"""
intervals(rng::AbstractRange) = IntervalSets.Interval{:closed,:open}.(rng, rng .+ step(rng))

"""
    ranges(A::AbstractRange{<:Integer})

Generate a `Vector` of `UnitRange` with length `step(A)`
"""
ranges(rng::AbstractRange{<:Integer}) = map(x -> x:x+step(rng)-1, rng)
