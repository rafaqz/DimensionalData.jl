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

@inline select(a::AbDimArray, seldim::AbDim, args...) = 
    select(a, (seldim,), args...)
@inline select(a::AbDimArray, seldims::Tuple, mode=Contained()) = begin
    indices = sel2indices(dims(a), permutedims(seldims, dims(a)), mode)
    a[indices...]
end

@inline selectview(a::AbDimArray, seldim::AbDim, args...) = 
    selectview(a, (seldim,), args...) 
@inline selectview(a::AbDimArray, seldims::Tuple, mode) = 
    view(a, sel2indices(dims(a), permutedims(seldims, dims(a)), mode))


@inline sel2indices(dims::AbDimTuple, seldims::Tuple, mode) =
    (sel2indices(dims, seldims[1], mode), sel2indices(dims, tail(seldims), mode)...)
@inline sel2indices(dims::AbDimTuple, seldim::Tuple{}, mode) = ()

@inline sel2indices(dims::AbDimTuple, seldim::Nothing, mode) = Colon()
@inline sel2indices(dims::AbDimTuple, seldim::AbDim{<:Colon}, mode) = Colon()
@inline sel2indices(dims::AbDimTuple, seldim::AbDim, mode) =
    sel2indices(dims[dimnum(dims, seldim)], val(seldim), mode)

# Contained
@inline sel2indices(dim::AbDim, selval, mode::Contained) = 
    searchsortedfirst(val(dim), selval)
@inline sel2indices(dim::AbDim, selvals::Tuple, mode::Contained) =
    searchsortedfirst(val(dim), first(selvals)):searchsortedlast(val(dim), last(selvals))
# Vectors can't use Contained(). Use Exact().
@inline sel2indices(dim::AbDim, selvals::AbstractVector, mode::Contained) =
    sel2indices(dim, selvals, Exact())

# Exact
@inline sel2indices(dim::AbDim, selval, ::Exact) = findorerror(selval, val(dim))
@inline sel2indices(dim::AbDim, selvals::Tuple, ::Exact) =
    findorerror(first(selvals), val(dim)):findorerror(last(selvals), val(dim))
@inline sel2indices(dim::AbDim, selvals::AbstractVector, mode::Exact) =
    findorerror.(selvals, Ref(val(dim)))

@inline findorerror(selval, dim) = begin
    ind = findfirst(x -> x == selval, val(dim))
    isnothing(ind) ? error("$selval not found in $dim") : ind
end
