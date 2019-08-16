"""
Selection modes define how indexed data will be selected 
when given coordinates, times or other dimension criteria 
that may not match the values at any specific indices.
"""
abstract type SelectionMode end

"""
Selection mode for `select()`, retreiving values inside the range, 
(sorted) array or tuple passed in with a dimension.

What Contained means for numbers need more thought.

For now it's just using the first one larger than the number 
passed in, but maybe it should find the nearest number?
"""
struct Contained <: SelectionMode end

"""
Selection mode for `select()` that exactly matches the value on the 
passed in dimensions, or throws an error.
"""
struct Exact <: SelectionMode end

@inline select(a::AbstractDimensionalArray, seldim::AbstractDimension, args...) = 
    select(a, (seldim,), args...)
@inline select(a::AbstractDimensionalArray, seldims::Tuple, mode=Contained()) = begin
    indices = sel2indices(a, sortdims(a, seldims), mode)
    a[indices...]
end
@inline selectview(a::AbstractDimensionalArray, seldim::AbstractDimension, args...) = 
    selectview(a, (seldim,), args...) 
@inline selectview(a::AbstractDimensionalArray, seldims::Tuple, mode) = 
    view(a, sel2indices(a, sortdims(a, seldims), mode))

@inline sel2indices(a, seldims::Tuple, mode) =
    (sel2indices(a, seldims[1], mode), sel2indices(a, tail(seldims), mode)...)
@inline sel2indices(a, seldim::Tuple{}, mode) = ()

@inline sel2indices(a, seldim::Nothing, mode) = Colon()
@inline sel2indices(a, seldim::AbstractDimension{<:Colon}, mode) = Colon()
@inline sel2indices(a, seldim::AbstractDimension, mode) =
    sel2indices(val(dims(a)[dimnum(a, seldim)]), val(seldim), mode)

# Contained
@inline sel2indices(dim::AbstractDimension, selval, mode::Contained) = 
    searchsortedfirst(dim, selval)
@inline sel2indices(dim::AbstractDimension, selvals::Union{AbstractVector,Tuple}, mode::Contained) =
    searchsortedfirst(dim::AbstractDimension, first(selvals)):searchsortedlast(dim, last(selvals))

# Exact
@inline sel2indices(dim::AbstractDimension, selval, ::Exact) = findorerror(selval, dim)
@inline sel2indices(dim::AbstractDimension, selvals::Union{AbstractVector,Tuple}, ::Exact) =
    findorerror(first(selvals), dim):findorerror(last(selvals), dim)

@inline findorerror(selval, dim) = begin
    ind = findfirst(x -> x == selval, dim)
    isnothing(ind) ? error("$selval not found in $dim") : ind
end
