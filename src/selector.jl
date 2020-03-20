"""
Selectors indicate that index values are not indices, but points to
be selected from the dimension values, such as DateTime objects on a Time dimension.
"""
abstract type Selector{T} end

const SelectorOrStandard = Union{Selector, StandardIndices}

val(m::Selector) = m.val
rebuild(sel::Selector, val) = basetypeof(sel)(val)

# Selector indexing without dim wrappers. Must be in the right order!
Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{SelectorOrStandard}) =
    getindex(a, sel2indices(a, I)...)
Base.@propagate_inbounds Base.setindex!(a::AbDimArray, x, I::Vararg{SelectorOrStandard}) =
    setindex!(a, x, sel2indices(a, I)...)
Base.view(a::AbDimArray, I::Vararg{SelectorOrStandard}) =
    view(a, sel2indices(a, I)...)

"""
    At(x)

Selector that exactly matches the value on the passed-in dimensions, or throws an error.
For ranges and arrays, every value must match an existing value - not just the end points.
"""
struct At{T,A,R} <: Selector{T}
    val::T
    atol::A
    rtol::R
end
At(val::Union{Number,AbstractArray{<:Number},Tuple{<:Number,Vararg}};
   atol=zero(eltype(val)),
   rtol=(atol > zero(eltype(val)) ? zero(rtol) : Base.rtoldefault(eltype(val)))
  ) = At{typeof.((val, atol, rtol))...}(val, atol, rtol)
At(val; atol=nothing, rtol=nothing) =
    At{typeof.((val, atol, rtol))...}(val, atol, rtol)

atol(sel::At) = sel.atol
rtol(sel::At) = sel.rtol

"""
    Near(x)

Selector that selects the nearest index to its contained value(s).
Can only be used for [`PointSampling`](@ref)
"""
struct Near{T} <: Selector{T}
    val::T
end

"""
    Contains(x)

Selector that selects the interval the value is contained by.
Can only be used for [`IntervalSampling`](@ref) or [`CategoricalGrid`](@ref).
"""
struct Contains{T} <: Selector{T}
    val::T
end

"""
    Between(a, b)

Selector that retreive all indices located between 2 values.
"""
struct Between{T<:Union{Tuple{Any,Any},Nothing}} <: Selector{T}
    val::T
end
Between(args...) = Between{typeof(args)}(args)
Between(x::Tuple) = Between{typeof(x)}(x)

# Get the dims in the same order as the grid
# This would be called after RegularGrid and/or CategoricalGrid
# dimensions are removed
dims2indices(grid::TransformedGrid, dims::Tuple, lookups::Tuple, emptyval) =
    sel2indices(grid, dims, map(val, permutedims(dimz, dims(grid))))

sel2indices(A::AbstractArray, lookup) = sel2indices(dims(A), lookup)
sel2indices(dims::Tuple, lookup) = sel2indices(dims, (lookup,))
sel2indices(dims::Tuple, lookup::Tuple) = sel2indices(map(grid, dims), dims, lookup)
sel2indices(grids::Tuple, dims::Tuple, lookup::Tuple) =
    (sel2indices(grids[1], dims[1], lookup[1]),
     sel2indices(tail(grids), tail(dims), tail(lookup))...)
sel2indices(grids::Tuple{}, dims::Tuple{}, lookup::Tuple{}) = ()

sel2indices(grid::CategoricalGrid, dim::Dimension, sel::Contains) =
    sel2indices(grid, dim, At(val(sel)))
sel2indices(grid::CategoricalGrid, dim::Dimension, sel::At) =
    sel2indices(PointSampling(), grid, dim, At(val(sel)))
sel2indices(grid::CategoricalGrid, dim::Dimension, sel::Between) =
    sel2indices(PointSampling(), grid, dim, sel)
sel2indices(grid::CategoricalGrid, dim::Dimension, sel::Near) =
    throw(ArgumentError("`Near` has no meaning with `CategoricalGrid`. Use `At`"))

sel2indices(grid::AbstractSampledGrid, dim::Dimension, sel) =
    sel2indices(sampling(grid), grid, dim, sel)

#= Specific selectors
We always run sel2indices again until the last possible call
This means vectors are unwrapped and passed to sel2indices,
so that grid based dispatch in external packages can operate
on single values only. `near`, `at` `contains` etc should only be
from one method.
=#

# At selector
sel2indices(sampling::Sampling, grid::Grid, dim::Dimension, sel::At{<:AbstractVector}) =
    map(v -> sel2indices(grid, dim, rebuild(sel, v)), val(sel))
sel2indices(gmpling::Sampling, rid::Grid, dim::Dimension, sel::At) = at(dim, sel)

# Handling base cases:
sel2indices(::Sampling, ::Grid, ::Dimension, sel::StandardIndices) = sel
# Near selector
sel2indices(::IntervalSampling, grid, dim::Dimension, sel::Near) =
    throw(ArgumentError("`Near` has no meaning with `IntervalSampling`. Use `Contains`"))
sel2indices(::PointSampling, grid, dim::Dimension, sel::Near{<:AbstractVector}) =
    map(v -> sel2indices(grid, dim, Near(v)), val(sel))
sel2indices(::PointSampling, grid, dim::Dimension, sel::Near) =
    near(dim, Near(val(sel)))

# Contains selector
sel2indices(sampling::PointSampling, grid::T, dim::Dimension, sel::Contains) where T =
    throw(ArgumentError("`Contains` has no meaning with `PointSampling`. Use `Near`"))
sel2indices(::IntervalSampling, grid, dim::Dimension, sel::Contains{<:AbstractVector}) =
    map(v -> sel2indices(grid, dim, Contains(v)), val(sel))
sel2indices(::IntervalSampling, grid, dim::Dimension, sel::Contains) =
    contains(dim, sel)

# Between selector
sel2indices(sampling::Sampling, grid::Grid, dim::Dimension, sel::Between{<:Tuple}) =
    between(sampling, dim, sel)


# Transformed grid

# We use the transformation from the first TransformedGrid dim.
# In practice the others could be empty.
sel2indices(grids::Tuple{Vararg{<:TransformedGrid}}, dims::DimTuple,
            sel::Tuple{Vararg{<:Selector}}) =
    map(to_int, sel, val(dims[1])([map(val, sel)...]))

to_int(::At, x) = convert(Int, x)
to_int(::Near, x) = round(Int, x)

# Do the input values need some kind of scalar conversion?
# what is the scale of these lookup matrices?
# sel2indices(grid::LookupGrid, sel::Tuple{Vararg{At}}) =
    # lookup(grid)[map(val, sel)...]


at(dim::Dimension, sel::At) =
    relate(dim, at(dim, val(sel), atol(sel), rtol(sel)))
at(dim, selval, atol::Nothing, rtol::Nothing) = begin
    i = findfirst(x -> x == selval, val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end
at(dim, selval, atol, rtol) = begin
    # This is not particularly efficient. It should be separated
    # out for unordered dims and otherwise treated as an ordered list.
    i = findfirst(x -> isapprox(x, selval; atol=atol, rtol=rtol), val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end


near(dim::Dimension, sel) =
    _fix(near(indexorder(dim), grid(dim), dim, sel), dim)
near(::Unordered, grid, dim, sel) =
    throw(ArgumentError("`Near` has no meaning in an `Unordered` grid"))
near(ord::Order, grid, dim, sel) = begin
    selval = val(sel)
    i = _bounded(searchsortedfirst(val(dim), selval; rev=isrev(ord)), dim)
    if isrev(ord)
        if i >= lastindex(dim)
            lastindex(dim)
        else
            abs(dim[i] - selval) <= abs(dim[i + 1] - selval) ? i : i + 1
        end
    else
        if i <= firstindex(dim)
            firstindex(dim)
        else
            abs(dim[i] - selval) <= abs(dim[i - 1] - selval) ? i : i - 1
        end
    end
end


contains(dim::Dimension, sel::Selector) =
    relate(dim, contains(grid(dim), dim, sel))

contains(grid::AbstractSampledGrid, dim, sel) =
    contains(locus(grid), sampling(grid), indexorder(grid), grid, dim, sel)

contains(::Any, ::PointSampling, ord, grid, dim, sel) =
    throw(ArgumentError("Point sampled grids cannot 'Contains', us 'Near' instead."))
contains(::Start, ::IntervalSampling, ord::Order, grid, dim, sel) = begin
    i = searchsortedlast(val(dim), val(sel); rev=isrev(ord))
    checkbounds(val(dim), i)
    i
end
contains(::End, ::IntervalSampling, ord::Order, grid, dim, sel) = begin
    i = searchsortedfirst(val(dim), val(sel); rev=isrev(ord))
    checkbounds(val(dim), i)
    i
end
contains(::Center, ::IntervalSampling, ord::Order, grid, dim, sel) = begin
    selval = val(sel)
    i = searchsortedlast(val(dim), selval; rev=isrev(ord))
    checkbounds(val(dim), i)
    if isrev(ord)
        if i == firstindex(dim)
            firstindex(dim)
        else
            (dim[i] + dim[i - 1]) / 2 <= selval ? i - 1 : i
        end
    else
        if i == lastindex(dim)
            lastindex(dim)
        else
            (dim[i] + dim[i + 1]) / 2 <= selval ? i + 1 : i
        end
    end
end


between(dim::Dimension, sel) =
    between(sampling(dim), dim::Dimension, sel)
between(sampling::Sampling, dim::Dimension, sel) =
    between(indexorder(dim), sampling, dim, val(sel))
between(::Unordered, sampling::Sampling, dim::Dimension, sel) =
    throw(ArgumentError("Cannot use `Between` on an unordered grid"))

between(indexord::Forward, ::PointSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel)
    a = _bounded(searchsortedfirst(val(dim), low), dim)
    b = _bounded(searchsortedlast(val(dim), high), dim)
    relate(dim, a:b)
end
between(indexord::Reverse, ::PointSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel)
    a = _bounded(searchsortedlast(val(dim), high; rev=true), dim)
    b = _bounded(searchsortedfirst(val(dim), low; rev=true), dim)
    relate(dim, a:b)
end

between(indexord, s::IntervalSampling, dim::Dimension, sel) =
    between(span(grid(dim)), indexord, s, dim, sel)
between(span::RegularSpan, indexord::Forward, ::IntervalSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel) .+ _locus_adjustment(grid(dim), span)
    a = _bounded(searchsortedfirst(val(dim), low), dim)
    b = _bounded(searchsortedlast(val(dim), high), dim)
    relate(dim, a:b)
end
between(span::RegularSpan, indexord::Reverse, ::IntervalSampling, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel) .+ _locus_adjustment(grid(dim), span)
    a = _bounded(searchsortedlast(val(dim), high; rev=true), dim)
    b = _bounded(searchsortedfirst(val(dim), low; rev=true), dim)
    relate(dim, a:b)
end

_locus_adjustment(grid::AbstractSampledGrid, span::RegularSpan) =
    _locus_adjustment(locus(grid), abs(step(span)))
_locus_adjustment(locus::Start, step) = zero(step), -step
_locus_adjustment(locus::Center, step) = step * 0.5, step * -0.5
_locus_adjustment(locus::End, step) = step, zero(step)


_fix(i::Int, dim::Dimension) = relate(dim, _bounded(i, dim))

# Return an inbounds index
_bounded(i::Int, dim::Dimension) =
    if i > lastindex(dim)
        lastindex(dim)
    elseif i <= firstindex(dim)
        firstindex(dim)
    else
        i
    end

_sorttuple((a, b)) = a < b ? (a, b) : (b, a)
