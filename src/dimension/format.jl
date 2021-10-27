
# When an object like DimArray or DimStack is constructed,
# `format` is called on its dimensions check that the axes match,
# and fill in any `Auto-` fields.


"""
    format(dims, x) => Tuple{Vararg{<:Dimension,N}}

Format the passed-in dimension(s) `dims` to match the object `x`.

This means converting indexes of `Tuple` to `LinRange`, and running
`format`. Errors are also thrown if dims don't match the array dims or size.

If a [`LookupArray`](@ref) hasn't been specified, an lookup is chosen
based on the type and element type of the index:
"""
format(dims, A::AbstractArray) = format((dims,), A)
function format(dims::NamedTuple, A::AbstractArray)
    dims = map((k, v) -> Dim{k}(v), keys(dims), values(dims))
    return format(dims, axes(A))
end
format(dims::Tuple{Vararg{<:Any,N}}, A::AbstractArray{<:Any,N}) where N =
    format(dims, axes(A))
@noinline format(dims::Tuple{Vararg{<:Any,M}}, A::AbstractArray{<:Any,N}) where {N,M} =
    throw(DimensionMismatch("Array A has $N axes, while the number of dims is $M: $(map(basetypeof, dims))"))
format(dims::Tuple, axes::Tuple) = map(_format, dims, axes)

_format(dimname::Symbol, axis::AbstractRange) = Dim{dimname}(NoLookup(axes(axis, 1)))
_format(::Type{D}, axis::AbstractRange) where D<:Dimension = D(NoLookup(axes(axis, 1)))
_format(dim::Dimension{Colon}, axis::AbstractRange) = rebuild(dim, NoLookup(axes(axis, 1)))
function _format(dim::Dimension, axis::AbstractRange)
    newlookup = format(val(dim), basetypeof(dim), axes(axis, 1))
    checkaxis(newlookup, axis)
    return rebuild(dim, newlookup)
end

format(val::AbstractArray, D::Type, axis::AbstractRange) = format(AutoLookup(), D, val, axis)
format(m::LookupArray, D::Type, axis::AbstractRange) = format(m, D, parent(m), axis)

# Format LookupArrays
# No more identification required for NoLookup
format(m::NoLookup, D::Type, index, axis::AbstractRange) = m
format(m::NoLookup, D::Type, index::AutoIndex, axis::AbstractRange) = NoLookup(axis)
# AutoLookup
function format(m::AutoLookup, D::Type, index::AbstractArray{T}, axis::AbstractRange) where T
    # A mixed type index is Categorical
    m = if isconcretetype(T) 
        Sampled(; order=order(m), span=span(m), sampling=sampling(m), metadata=metadata(m))
    else
        Categorical(; order=order(m), metadata=metadata(m))
    end
    format(m, D, index, axis)
end
function format(m::AutoLookup, D::Type, index::AbstractArray{<:CategoricalEltypes}, axis::AbstractRange)
    o = _format(order(m), D, index)
    return Categorical(index; order=o, metadata=metadata(m))
end
function format(m::AutoLookup, D::Type, index::Val, axis::AbstractRange)
    o = _format(order(m), D, index)
    return Categorical(index; order=o, metadata=metadata(m))
end
function format(m::Categorical, D::Type, index, axis::AbstractRange)
    i = _format(index, axis)
    o = _format(order(m), D, index)
    return rebuild(m; data=i, order=o)
end
# Sampled
function format(m::AbstractSampled, D::Type, index, axis::AbstractRange)
    i = _format(index, axis)
    o = _format(order(m), D, index)
    sp = _format(span(m), D, index)
    sa = _format(sampling(m), sp, D, index)
    x = rebuild(m; data=i, order=o, span=sp, sampling=sa)
    return x
end
# Transformed
format(m::Transformed, D::Type, index::AutoIndex, axis::AbstractRange) = rebuild(m; data=axis)
format(m::Transformed, D::Type, index, axis::AbstractRange) = m

# Index
_format(index::AbstractArray, axis::AbstractRange) = index
_format(index::AutoLookup, axis::AbstractRange) = axis
# Order
_format(order::Order, D::Type, index) = order
_format(order::AutoOrder, D::Type, index) = _orderof(index)
# Span
_format(span::AutoSpan, D::Type, index::Union{AbstractArray,Val}) =
    _format(Irregular(), D, index)
_format(span::AutoSpan, D::Type, index::AbstractRange) = Regular(step(index))
_format(span::Regular{AutoStep}, D::Type, index::Union{AbstractArray,Val}) = _arraynosteperror()
_format(span::Regular{AutoStep}, D::Type, index::AbstractRange) = Regular(step(index))
_format(span::Regular, D::Type, index::Union{AbstractArray,Val}) = span
function _format(span::Regular, D::Type, index::AbstractRange)
    step(span) isa Number && !(step(span) ≈ step(index)) && _steperror(index, span)
    return span
end
_format(span::Irregular{AutoBounds}, D, index) = Irregular(nothing, nothing)
_format(span::Irregular{<:Tuple}, D, index) = span
_format(span::Explicit, D, index) = span
# Sampling
_format(sampling::AutoSampling, span::Span, D::Type, index) = Points()
_format(sampling::AutoSampling, span::Explicit, D::Type, index) =
    Intervals(_format(locus(sampling), D, index))
_format(sampling::Points, span::Span, D::Type, index) = sampling
_format(sampling::Points, span::Explicit, D::Type, index) = _explicitpoints_error() 
_format(sampling::Intervals, span::Span, D::Type, index) =
    rebuild(sampling, _format(locus(sampling), D, index))
# Locus
_format(locus::AutoLocus, D::Type, index) = Center()
# Time dimensions need to default to the Start() locus, as that is
# nearly always the _format and Center intervals are difficult to
# calculate with DateTime step values.
_format(locus::AutoLocus, D::Type{<:TimeDim}, index) = Start()
_format(locus::Locus, D::Type, index) = locus

_orderof(index::AbstractUnitRange) = ForwardOrdered()
_orderof(index::AbstractRange) = _order(index)
_orderof(index::AbstractArray) = _detectorder(index)

function _detectorder(index)
    local sorted, indord
    # This is awful. But we don't know if we can
    # call `issorted` on the contents of `index`.
    # This may be resolved by: https://github.com/JuliaLang/julia/pull/37239
    try
        indord = _order(index)
        sorted = issorted(index; rev=isrev(indord))
    catch
        sorted = false
    end
    return sorted ? indord : Unordered()
end

_order(index) = first(index) <= last(index) ? ForwardOrdered() : ReverseOrdered()

@noinline _explicitpoints_error() =
    throw(ArgumentError("Cannot use Explicit span with Points sampling"))
@noinline _steperror(index, span) =
    throw(ArgumentError("lookup step $(step(span)) does not match index step $(step(index))"))
@noinline _arraynosteperror() =
    throw(ArgumentError("`Regular` must specify `step` size with an index other than `AbstractRange`"))

checkaxis(lookup::Transformed, axis) = nothing
function checkaxis(lookup, axis)
    if !(first(axes(lookup)) == axis)
        throw(DimensionMismatch(
            "axes of $(basetypeof(lookup)) of $(first(axes(lookup))) do not match array axis of $axis"
        ))
    end
end
