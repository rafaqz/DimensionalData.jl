"""
    AbstractDimArrayGenerator <: AbstractBasicDimArray

Abstract supertype for all AbstractBasicDimArrays that
generate their `data` on demand during `getindex`.
"""
abstract type AbstractDimArrayGenerator{T,N,D} <: AbstractBasicDimArray{T,N,D} end

dims(dg::AbstractDimArrayGenerator) = dg.dims

# Dims that contribute to the element type.
# May be larger than `dims` after slicing
eldims(di::AbstractDimArrayGenerator) = dims((dims(di)..., refdims(di)...), orderdims(di))
eldims(di::AbstractDimArrayGenerator, d) = dims(eldims(di), d)

Base.size(dg::AbstractDimArrayGenerator) = map(length, dims(dg))
Base.axes(dg::AbstractDimArrayGenerator) = map(d -> axes(d, 1), dims(dg))

@inline Base.permutedims(A::AbstractDimArrayGenerator{<:Any,2}) =
    rebuild(A; dims=reverse(dims(A)))
@inline Base.permutedims(A::AbstractDimArrayGenerator{<:Any,1}) =
    rebuild(A; dims=(AnonDim(Base.OneTo(1)), dims(A)...))
@inline function Base.permutedims(A::AbstractDimArrayGenerator, perm)
    length(perm) == length(dims(A) || throw(ArgumentError("permutation must be same length as dims")))
    rebuild(A; dim=sortdims(dims(A), Tuple(perm)))
end

@inline function Base.PermutedDimsArray(A::AbstractDimArrayGenerator{T,N}, perm) where {T,N}
    perm_inds = dimnum(A, Tuple(perm))
    rebuild(A; dims=dims(dims(A), Tuple(perm)))
end

"""
    AbstractRebuildableDimArrayGenerator <: AbstractDimArrayGenerator

Abstract supertype for all AbstractDimArrayGenerator that
can be rebuilt when subsetted with `view` or `getindex`.

These arrays must have `dims` and `refdims` fields that defined the data
They do not need to define `rebuildsliced` methods as this is defined
as simply doing `slicedims` on `dims` and `refdims` and rebuilding.
"""
abstract type AbstractRebuildableDimArrayGenerator{T,N,D,R<:MaybeDimTuple} <: AbstractDimArrayGenerator{T,N,D} end

refdims(A::AbstractRebuildableDimArrayGenerator) = A.refdims

_refdims_firsts(A::AbstractRebuildableDimArrayGenerator) = map(d -> rebuild(d, first(d)), refdims(A))

# Custom rebuildsliced where data is ignored, and just dims and refdims are slices
# This makes sense for AbstractRebuildableDimArrayGenerator because Arrays are
# generated in getindex from the dims/refdims combination.
# `f` is ignored, and views are always used
@propagate_inbounds function rebuildsliced(f::Function, A::AbstractRebuildableDimArrayGenerator, I)
    dims, refdims = slicedims(view, A, I)
    return rebuild(A; dims, refdims)
end

abstract type AbstractDimIndices{T,N,D,R,O<:MaybeDimTuple} <: AbstractRebuildableDimArrayGenerator{T,N,D,R} end

orderdims(di::AbstractDimIndices) = di.orderdims

"""
    DimIndices <: AbstractArray

    DimIndices(x)
    DimIndices(dims::Tuple)
    DimIndices(dims::Dimension)

Like `CartesianIndices`, but for `Dimension`s. Behaves as an `Array` of `Tuple`
of `Dimension(i)` for all combinations of the axis indices of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and
is especially useful when combined with `otherdims`, to iterate over the
indices of unknown dimension.

`DimIndices` can be used directly in `getindex` like `CartesianIndices`,
and freely mixed with individual `Dimension`s or tuples of `Dimension`.

## Example

Index a `DimArray` with `DimIndices`.

Notice that unlike CartesianIndices, it doesn't matter if the dimensions
are not in the same order. Or even if they are not all contained in each.

```jldoctest; setup = :(using DimensionalData, Random; Random.seed!(123))
julia> A = rand(Y(0.0:0.3:1.0), X('a':'f'))
┌ 4×6 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.3:0.9 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':1:'f' ForwardOrdered
└─────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'b'       'c'        'd'        'e'       'f'
 0.0  0.9063    0.253849  0.0991336  0.0320967  0.774092  0.893537
 0.3  0.443494  0.334152  0.125287   0.350546   0.183555  0.354868
 0.6  0.745673  0.427328  0.692209   0.930332   0.297023  0.131798
 0.9  0.512083  0.867547  0.136551   0.959434   0.150155  0.941133

julia> di = DimIndices((X(1:2:4), Y(1:2:4)))
┌ 2×2 DimIndices{Tuple{X{Int64}, Y{Int64}}, 2} ┐
├──────────────────────────────────────── dims ┤
  ↓ X 1:2:3,
  → Y 1:2:3
└──────────────────────────────────────────────┘
 ↓ →  1                3
 1     (↓ X 1, → Y 1)   (↓ X 1, → Y 3)
 3     (↓ X 3, → Y 1)   (↓ X 3, → Y 3)

julia> A[di] # Index A with these indices
┌ 2×2 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.6:0.6 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':2:'c' ForwardOrdered
└─────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'c'
 0.0  0.9063    0.0991336
 0.6  0.745673  0.692209
```
"""
struct DimIndices{T,N,D,R,O} <: AbstractDimIndices{T,N,D,R,O}
    dims::D
    refdims::R
    orderdims::O
    # Manual inner constructor for ambiguity only
    function DimIndices(dims::D, refdims::R, orderdims::O) where {D<:MaybeDimTuple,R<:MaybeDimTuple,O<:MaybeDimTuple}
        eldims = DD.dims((dims..., refdims...), orderdims)
        T = typeof(map(d -> rebuild(d, 1), eldims))
        N = length(dims)
        new{T,N,D,R,O}(dims, refdims, orderdims)
    end
end
function DimIndices(dims::MaybeDimTuple)
    dims = length(dims) > 0 ? _dimindices_format(dims) : dims
    return DimIndices(dims, (), basedims(dims))
end
DimIndices(x) = DimIndices(dims(x))
DimIndices(dim::Dimension) = DimIndices((dim,))
DimIndices(::Nothing) = throw(ArgumentError("Object has no `dims` method"))

# Forces multiple indices not linear
function Base.getindex(A::DimIndices, i1::Integer, i2::Integer, I::Integer...)
    dis = map(dims(A), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
    dims((dis..., _refdims_firsts(A)...), orderdims(A))
end
# Dispatch to avoid linear indexing in multidimensional DimIndices
function Base.getindex(A::DimIndices{<:Any,1}, i::Integer)
    d = dims(A, 1)
    di = rebuild(d, d[i])
    return dims((di, _refdims_firsts(A)...), orderdims(A))
end
Base.getindex(A::DimIndices{<:Any,0}) = dims(_refdims_firsts(A), orderdims(A))

_dimindices_format(dims::Tuple{}) = ()
_dimindices_format(dims::Tuple) = map(rebuild, dims, map(_dimindices_axis, dims))

_dimindices_axis(x::Integer) = Base.OneTo(x)
_dimindices_axis(x::AbstractRange{<:Integer}) = x
_dimindices_axis(x::Dimension) = _dimindices_axis(val(x))
_dimindices_axis(x::Lookup) = axes(x, 1)
_dimindices_axis(x) =
    throw(ArgumentError("`$x` is not a valid input for `DimIndices`. Use `Dimension`s wrapping `Integer`, `AbstractArange{<:Integer}`, or a `Lookup` (the `axes` will be used)"))

abstract type AbstractDimVals{T,N,D,R,O} <: AbstractDimIndices{T,N,D,R,O} end

(::Type{T})(::Nothing; kw...) where T<:AbstractDimVals = throw(ArgumentError("Object has no `dims` method"))
(::Type{T})(x; kw...) where T<:AbstractDimVals = T(dims(x); kw...)
(::Type{T})(dim::Dimension; kw...) where T<:AbstractDimVals = T((dim,); kw...)

"""
    DimPoints <: AbstractArray

    DimPoints(x; order)
    DimPoints(dims::Tuple; order)
    DimPoints(dims::Dimension; order)

Like `CartesianIndices`, but for the point values of the dimension index.
Behaves as an `Array` of `Tuple` lookup values (whatever they are) for all
combinations of the lookup values of `dims`.

Either a `Dimension`, a `Tuple` of `Dimension` or an object `x`
that defines a `dims` method can be passed in.

# Keywords

- `order`: determines the order of the points, the same as the order of `dims` by default.
"""
struct DimPoints{T,N,D,R,O} <: AbstractDimVals{T,N,D,R,O}
    dims::D
    refdims::R
    orderdims::O
    function DimPoints(dims::D, refdims::R, orderdims::O) where {D<:MaybeDimTuple,R<:MaybeDimTuple,O<:MaybeDimTuple}
        eldims = DD.dims((dims..., refdims...), orderdims)
        T = Tuple{map(eltype, eldims)...}
        N = length(dims)
        new{T,N,D,R,O}(dims, refdims, orderdims)
    end
end
DimPoints(dims::Tuple; order=dims) = DimPoints(dims, order)
function DimPoints(dims::Tuple, order::Tuple)
    dims = length(dims) > 0 ? format(dims) : dims
    DimPoints(dims, (), basedims(order))
end

function Base.getindex(A::DimPoints, i1::Integer, i2::Integer, I::Integer...)
    # Get dim-wrapped point values at i1, I...
    pointdims = map(dims(A), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
    # Return the unwrapped point sorted by `order
    return map(val, DD.dims((pointdims..., _refdims_firsts(A)...), orderdims(A)))
end
function Base.getindex(A::DimPoints{<:Any,1}, i::Integer) 
    # Get dim-wrapped point values at i1, I...
    d1 = dims(A, 1)
    pointdim = rebuild(d1, d1[i])
    # Return the unwrapped point sorted by `order
    D = dims((pointdim, _refdims_firsts(A)...), orderdims(A))
    return map(val, D)
end
Base.getindex(A::DimPoints{<:Any,0}) = map(val, dims(_refdims_firsts(A), orderdims(A)))

"""
    DimSelectors <: AbstractArray

    DimSelectors(x; selectors, atol...)
    DimSelectors(dims::Tuple; selectors, atol...)
    DimSelectors(dims::Dimension; selectors, atol...)

Like [`DimIndices`](@ref), but returns `Dimensions` holding
the chosen [`Selector`](@ref)s.

Indexing into another `AbstractDimArray` with `DimSelectors`
is similar to doing an interpolation.

## Keywords

- `selectors`: `Near`, `At` or `Contains`, or a mixed tuple of these.
  `At` is the default, meaning only exact or within `atol` values are used.
- `atol`: used for `At` selectors only, as the `atol` value. Ignored where 
    `atol` is set inside individual `At` selectors.

## Example

Here we can interpolate a `DimArray` to the lookups of another `DimArray`
using `DimSelectors` with `Near`. This is essentially equivalent to
nearest neighbour interpolation.

```jldoctest; setup = :(using DimensionalData, Random; Random.seed!(123))
julia> A = rand(X(1.0:3.0:30.0), Y(1.0:5.0:30.0), Ti(1:2));

julia> target = rand(X(1.0:10.0:30.0), Y(1.0:10.0:30.0));

julia> A[DimSelectors(target; selectors=Near), Ti=2]
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────────── dims ┐
  ↓ X Sampled{Float64} [1.0, 10.0, 22.0] ForwardOrdered Irregular Points,
  → Y Sampled{Float64} [1.0, 11.0, 21.0] ForwardOrdered Irregular Points
└─────────────────────────────────────────────────────────────────────────┘
  ↓ →  1.0        11.0       21.0
  1.0  0.691162    0.218579   0.539076
 10.0  0.0303789   0.420756   0.485687
 22.0  0.0967863   0.864856   0.870485
```

Using `At` would make sure we only use exact interpolation,
while `Contains` with sampling of `Intervals` would make sure that
each values is taken only from an Interval that is present in the lookups.
"""
struct DimSelectors{T,N,D,R,O,S<:Tuple} <: AbstractDimVals{T,N,D,R,O}
    dims::D
    refdims::R
    orderdims::O
    selectors::S
    function DimSelectors(dims::D, refdims::R, orderdims::O, selectors::S) where {D<:Tuple,R<:Tuple,O<:Tuple,S<:Tuple}
        eldims = DD.dims((dims..., refdims...), orderdims)
        T = _selector_eltype(eldims, selectors)
        N = length(dims)
        new{T,N,D,R,O,S}(dims, refdims, orderdims, selectors)
    end
end
function DimSelectors(dims::MaybeDimTuple; atol=nothing, selectors=At())
    s = _format_selectors(dims, selectors, atol)
    DimSelectors(dims, s)
end
function DimSelectors(dims::MaybeDimTuple, selectors::Tuple)
    dims = length(dims) > 0 ? format(dims) : dims
    orderdims = basedims(dims)
    refdims = ()
    length(dims) == length(selectors) || throw(ArgumentError("`length(dims) must match  `length(selectors)`, got $(length(dims)) and $(length(selectors))"))
    DimSelectors(dims, refdims, orderdims, selectors)
end

@propagate_inbounds function Base.getindex(A::DimSelectors, i1::Integer, i2::Integer, I::Integer...)
    D = map(dims(A), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
    return _rebuild_selectors(A, D)
end
@propagate_inbounds function Base.getindex(A::DimSelectors{<:Any,1}, i::Integer)
    d1 = dims(A, 1)
    d = rebuild(d1, d1[i])
    return _rebuild_selectors(A, (d,))
end
@propagate_inbounds Base.getindex(A::DimSelectors{<:Any,0}) =
    _rebuild_selectors(A, ())

function _rebuild_selectors(A, D)
    sorteddims = dims((D..., _refdims_firsts(A)...), orderdims(A))
    map(sorteddims, A.selectors) do d, s
        rebuild(d, rebuild(s; val=val(d)))
    end
end

_selector_eltype(dims::Tuple, selectors::Tuple) =
    Tuple{map(_selector_eltype, dims, selectors)...}
_selector_eltype(d::D, ::S) where {D,S} =
    basetypeof(D){basetypeof(S){eltype(d)}}
_selector_eltype(d::D, ::At{<:Any,A,R}) where {D,A,R} =
    basetypeof(D){At{eltype(d),A,R}}

function show_after(io::IO, mime, A::DimSelectors)
    _, displaywidth = displaysize(io)
    blockwidth = get(io, :blockwidth, 0)
    selector_lines = split(sprint(show, mime, A.selectors), "\n")
    new_blockwidth = min(displaywidth-2, max(blockwidth, maximum(length, selector_lines) + 4))
    new_blockwidth = print_block_separator(io, "selectors", blockwidth, new_blockwidth)
    print(io, "  ")
    show(io, mime, A.selectors)
    println(io)
    print_block_close(io, new_blockwidth)
    ndims(A) > 0 && println(io)
    print_array(io, mime, A)
end

@inline _format_selectors(dims::Tuple, selector, atol) =
    _format_selectors(dims, map(_ -> selector, dims), atol)
@inline _format_selectors(dims::Tuple, selectors::Tuple, atol) =
    _format_selectors(dims, selectors, map(_ -> atol, dims))
@inline _format_selectors(dims::Tuple, selectors::Tuple, atol::Tuple) =
    map(_format_selectors, dims, selectors, atol)
@inline _format_selectors(d::Dimension, T::Type, atol) = _format_selectors(d, T(), atol)
@inline _format_selectors(d::Dimension, ::Near, atol) = Near(nothing)
@inline _format_selectors(d::Dimension, ::Contains, atol) = Contains(nothing)
@inline function _format_selectors(d::Dimension, at::At, atol)
    atolx = _atol(eltype(d), Lookups.atol(at), atol)
    At(nothing, atolx, nothing)
end

_atol(::Type, atol1, atol2) = atol1
_atol(T::Type{<:AbstractFloat}, atol, ::Nothing) = atol
_atol(T::Type{<:AbstractFloat}, ::Nothing, atol) = atol
_atol(T::Type{<:AbstractFloat}, ::Nothing, ::Nothing) = eps(T)

# Deprecated
const DimKeys = DimSelectors

const SliceDim = Dimension{<:Union{<:AbstractVector{Int},<:AbstractVector{<:AbstractVector{Int}}}}

"""
    DimSlices <: AbstractRebuildableDimArrayGenerator

    DimSlices(x, dims; drop=true)

A `Base.Slices` like object for returning view slices from a DimArray.

This is used for `eachslice` on stacks.

`dims` must be a `Tuple` of `Dimension` holding `AbstractVector{Int}`
or `AbstractVector{<:AbstractVector{Int}}`.

# Keywords

- `drop`: whether to drop dimensions from the outer array or keep the 
    same dimensions as the inner view, but with length 1.
"""
struct DimSlices{T,N,D,R,P,U} <: AbstractRebuildableDimArrayGenerator{T,N,D,R}
    _data::P
    dims::D
    refdims::R
    reduced::U
end
DimSlices(x; dims, drop=true) = DimSlices(x, dims; drop)
DimSlices(x, dim; kw...) = DimSlices(x, (dim,); kw...)
function DimSlices(x, dims::Tuple; drop::Union{Bool,Nothing}=nothing)
    dims = DD.dims(x, dims)
    refdims = ()
    inds = if length(dims) == 0
        map(d -> rebuild(d, :), DD.dims(x))
    else
        map(d -> rebuild(d, firstindex(d)), dims)
    end
    slicedims, reduced = if isnothing(drop) || drop
        # We have to handle filling in colons for no dims because passing 
        # no dims at all is owned by base to mean A[] not A[D1(:), D2(:), D3(:)]
        dims, ()
    else
        # Get other dimensions as length 1
        reduced = map(otherdims(x, dims)) do o
            reducedims(o)
        end
        # Re-sort to x dim order
        slicedims = DD.dims((reduced..., dims...), DD.dims(x))
        sliceddims, basedims(reduced)
    end
    T = typeof(view(x, inds...))
    N = length(slicedims)
    D = typeof(slicedims)
    R = typeof(refdims)
    A = typeof(x)
    U = typeof(reduced)
    return DimSlices{T,N,D,R,A,U}(x, slicedims, refdims, reduced)
end

function rebuild(ds::DimSlices{T,N}; 
    dims::D, refdims::R, reduced::U=ds.reduced
) where {T,N,D,R,U}
    A = typeof(ds._data)
    DimSlices{T,N,D,R,A,U}(ds._data, dims, refdims, reduced)
end
@propagate_inbounds function rebuildsliced(::Function, A::DimSlices, I)
    @boundscheck checkbounds(A, I...)
    # We use `unafe_view` to force always wrapping as a view, even for ranges
    # Then in `_refdims_firsts` we can use `first(parentindices(d))` to get the offset
    dims, refdims = slicedims(Base.unsafe_view, A, I)
    return rebuild(A; dims, refdims)
end

# We need to get the vist index from the view, so define this custom for DimSlices
_refdims_firsts(A::DimSlices) = map(d -> rebuild(d, first(parentindices(d))), refdims(A))

function Base.summary(io::IO, A::DimSlices{T,N}) where {T,N}
    print_ndims(io, size(A))
    print(io, string(nameof(typeof(A)), "{$(nameof(T)),$N}"))
end

@propagate_inbounds function Base.getindex(A::DimSlices, i1::Integer, i2::Integer, Is::Integer...)
    I = (i1, i2, Is...)
    D = map(dims(A), I) do d, i
        i1 = if hasdim(A.reduced, d) 
            @boundscheck checkbounds(d, i)
            Colon()
        else
            eachindex(d)[i]
        end
        return rebuild(d, i1)
    end
    R = _refdims_firsts(A)
    return view(A._data, D..., R...)
end
# Dispatch to avoid linear indexing in multidimensional DimIndices
@propagate_inbounds function Base.getindex(A::DimSlices{<:Any,1}, i::Integer)
    d1 = dims(A, 1)
    d = if hasdim(A.reduced, d1)
        @boundscheck checkbounds(d1, i)
        rebuild(d1, :)
    else
        rebuild(d1, eachindex(d1)[i])
    end
    return view(A._data, d, _refdims_firsts(A)...)
end
@propagate_inbounds function Base.getindex(A::DimSlices{<:Any,0})
    R = _refdims_firsts(A)
    # Need to manually force the Colons in case there are no dims at all
    D = map(otherdims(A._data, R)) do d
        rebuild(d, :)
    end
    view(A._data, D..., R...)
end

# Extends the dimensions of any `AbstractBasicDimArray`
# as if the array assigned into a larger array across all dimensions,
# but without the copying. Theres is a cost for linear indexing these objects
# as we need to convert to Cartesian.
struct DimExtensionArray{T,N,D<:MaybeDimTuple,R<:MaybeDimTuple,A<:AbstractBasicDimArray{T}} <: AbstractDimArrayGenerator{T,N,D}
    _data::A
    dims::D
    refdims::R
    function DimExtensionArray(A::AbstractBasicDimArray{T}, dims::Tuple, refdims::Tuple) where T
        all(hasdim(dims, DD.dims(A))) || throw(ArgumentError("all dim in array must also be in `dims`"))
        comparedims(A, DD.dims(dims, DD.dims(A)))
        fdims = format(dims, CartesianIndices(map(length, dims)))
        N = length(dims)
        new{T,N,typeof(fdims),typeof(refdims),typeof(A)}(A, fdims, refdims)
    end
end
DimExtensionArray(A::AbstractBasicDimArray, dims::Tuple; refdims=refdims(A)) =
    DimExtensionArray(A, dims, refdims)

name(A::DimExtensionArray) = name(A._data)
metadata(A::DimExtensionArray) = metadata(A._data)

@propagate_inbounds function rebuildsliced(f::Function, de::DimExtensionArray, I)
    newdims, newrefdims = slicedims(dims(de), refdims(de), I)
    D = map(rebuild, dims(de), I)
    A = de._data
    realdims = dims(D, dims(A))
    if all(map(d -> val(d) isa Colon, realdims))
        rebuild(de; dims=newdims, refdims=newrefdims)
    else
        newrealparent = begin
            x = f(parent(A), dims2indices(A, realdims)...)
            x isa AbstractArray ? x : fill(x)
        end
        newrealdims = dims(newdims, realdims)
        newdata = rebuild(A; data=newrealparent, dims=newrealdims)
        rebuild(de; _data=newdata, dims=newdims, refdims=newrefdims)
    end
end
@propagate_inbounds function rebuildsliced(
    f::Function, de::DimExtensionArray{<:Any,1}, I::Tuple{<:Union{Colon,AbstractRange}}
)
    newdims, _ = slicedims(dims(de), I)
    A = de._data
    D = rebuild(only(dims(de)), only(I))
    rebuild(de; dims=newdims, _data=A[D...])
end

# Integer indexing
function Base.getindex(de::DimExtensionArray, i1::Integer, i2::Integer, Is::Integer...)
    D = map(rebuild, dims(de), (i1, i2, Is...))
    A = de._data
    return getindex(A, dims(D, dims(A))...)
end
Base.getindex(de::DimExtensionArray{<:Any,1}, i::Integer) = getindex(de._data, rebuild(dims(de, 1), i))
Base.getindex(de::DimExtensionArray{<:Any,0}) = de._data[]

function mergedims(A::DimExtensionArray, dim_pairs::Pair...)
    all_dims = dims(A)
    dims_new = mergedims(all_dims, dim_pairs...)
    dimsmatch(all_dims, dims_new) && return A
    dims_perm = _unmergedims(dims_new, map(last, dim_pairs))
    Aperm = PermutedDimsArray(A, dims_perm)
    data_merged = reshape(parent(Aperm), map(length, dims_new))
    return DimArray(data_merged, dims_new)
end