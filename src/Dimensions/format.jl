
# When an object like DimArray or DimStack is constructed,
# `format` is called on its dimensions

"""
    format(dims, x) => Tuple{Vararg{Dimension,N}}

Format the passed-in dimension(s) `dims` to match the object `x`.

Errors are thrown if dims don't match the array dims or size, 
and any fields holding `Auto-` objects are filled with guessed objects.

If a [`Lookup`](@ref) hasn't been specified, a lookup is chosen
based on the type and element type of the index.
"""
format(dims, A::AbstractArray) = format((dims,), A)
function format(dims::NamedTuple, A::AbstractArray)
    dims = map(keys(dims), values(dims)) do k, v
        rebuild(key2dim(k), v)
    end
    return format(dims, A)
end
function format(dims::Tuple{<:Pair,Vararg{Pair}}, A::AbstractArray)
    dims = map(dims) do (k, v)
        rebuild(basedims(k), v)
    end
    return format(dims, A)
end
format(dims::Tuple{Vararg{Any,N}}, A::AbstractArray{<:Any,N}) where N = format(dims, axes(A))
@noinline format(dims::Tuple{Vararg{Any,M}}, A::AbstractArray{<:Any,N}) where {N,M} =
    throw(DimensionMismatch("Array A has $N axes, while the number of dims is $M: $(map(basetypeof, dims))"))
format(dims::Tuple{Vararg{Any,N}}, axes::Tuple{Vararg{Any,N}}) where N = map(_format, dims, axes)
format(d::Dimension{<:AbstractArray}) = _format(d, axes(val(d), 1))
format(d::Dimension, axis::AbstractRange) = _format(d, axis)

_format(dimname::Symbol, axis::AbstractRange) = Dim{dimname}(NoLookup(axes(axis, 1)))
_format(::Type{D}, axis::AbstractRange) where D<:Dimension = D(NoLookup(axes(axis, 1)))
_format(dim::Dimension{Colon}, axis::AbstractRange) = rebuild(dim, NoLookup(axes(axis, 1)))
function _format(dim::Dimension, axis::AbstractRange)
    newlookup = format(val(dim), basetypeof(dim), axes(axis, 1))
    checkaxis(newlookup, axis)
    return rebuild(dim, newlookup)
end

format(val::AbstractArray, D::Type, axis::AbstractRange) = format(AutoLookup(), D, val, axis)
format(m::Lookup, D::Type, axis::AbstractRange) = format(m, D, parent(m), axis)
format(v::AutoVal, D::Type, axis::AbstractRange) = _valformaterror(val(v), D)
format(v, D::Type, axis::AbstractRange) = _valformaterror(v, D) 

# Format Lookups
# No more identification required for NoLookup
format(m::NoLookup, D::Type, index, axis::AbstractRange) = m
format(m::NoLookup, D::Type, index::AutoIndex, axis::AbstractRange) = NoLookup(axis)
# # AutoLookup
function format(m::AutoLookup, D::Type, index::AbstractArray{T}, axis::AbstractRange) where T
    # A mixed type index is Categorical
    m = if isconcretetype(T) 
        Sampled(; order=order(m), span=span(m), sampling=sampling(m), metadata=metadata(m))
    else
        o = order(m) isa AutoOrder ? Unordered() : order(m)
        Categorical(; order=o, metadata=metadata(m))
    end
    format(m, D, index, axis)
end
function format(m::AutoLookup, D::Type, index::AbstractArray{<:CategoricalEltypes}, axis::AbstractRange)
    o = _format(order(m), D, index)
    return Categorical(index; order=o, metadata=metadata(m))
end
function format(m::Categorical, D::Type, index, axis::AbstractRange)
    i = _format(index, axis)
    o = _format(order(m), D, index)
    return rebuild(m; data=i, order=o)
end
# # Sampled
function format(m::AbstractSampled, D::Type, index, axis::AbstractRange)
    i = _format(index, axis)
    o = _format(order(m), D, index)
    sp = _format(span(m), D, index)
    sa = _format(sampling(m), sp, D, index)
    x = rebuild(m; data=i, order=o, span=sp, sampling=sa)
    return x
end
# # Transformed
format(m::Transformed, D::Type, index::AutoIndex, axis::AbstractRange) =
    rebuild(m; dim=D(), data=axis)
format(m::Transformed, D::Type, index, axis::AbstractRange) = rebuild(m; dim=D())

# Index
_format(index::AbstractArray, axis::AbstractRange) = index
_format(index::AutoLookup, axis::AbstractRange) = axis
# Order
_format(order::Order, D::Type, index) = order
_format(order::AutoOrder, D::Type, index) = Lookups.orderof(index)
# Span
_format(span::AutoSpan, D::Type, index::Union{AbstractArray,Val}) =
    _format(Irregular(), D, index)
_format(span::AutoSpan, D::Type, index::AbstractRange) = Regular(step(index))
_format(span::Regular{AutoStep}, D::Type, index::Union{AbstractArray,Val}) = _arraynosteperror()
_format(span::Regular{AutoStep}, D::Type, index::LinRange) = Regular(step(index))
_format(span::Regular{AutoStep}, D::Type, index::AbstractRange) = Regular(step(index))
_format(span::Regular, D::Type, index::Union{AbstractArray,Val}) = span
function _format(span::Regular, D::Type, index::AbstractRange)
    step(span) isa Number && !(step(span) ≈ step(index)) && _steperror(index, span)
    return span
end
function _format(span::Regular, D::Type, index::LinRange{T}) where T
    step(span) isa Number && step(index) > zero(T) && !(step(span) ≈ step(index)) && _steperror(index, span)
    return span
end
_format(span::Irregular{AutoBounds}, D, index) = Irregular(nothing, nothing)
_format(span::Irregular{<:Tuple}, D, index) = span
_format(span::Explicit, D, index) = span
# Sampling
_format(sampling::AutoSampling, span::Span, D::Type, index) = Points()
_format(::AutoSampling, ::Span, D::Type, ::AbstractArray{<:IntervalSets.Interval}) =
    Intervals(Start())
_format(sampling::AutoSampling, span::Explicit, D::Type, index) =
    Intervals(_format(locus(sampling), D, index))
# For ambiguity, not likely to happen in practice
_format(::AutoSampling, ::Explicit, D::Type, ::AbstractArray{<:IntervalSets.Interval}) =
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

_order(index) = first(index) <= last(index) ? ForwardOrdered() : ReverseOrdered()

checkaxis(lookup::Transformed, axis) = nothing
checkaxis(lookup, axis) = first(axes(lookup)) == axis || _checkaxiserror(lookup, axis)

@noinline _explicitpoints_error() =
    throw(ArgumentError("Cannot use Explicit span with Points sampling"))
@noinline _steperror(index, span) =
    throw(ArgumentError("lookup step $(step(span)) does not match index step $(step(index))"))
@noinline _arraynosteperror() =
    throw(ArgumentError("`Regular` must specify `step` size with an index other than `AbstractRange`"))
@noinline _checkaxiserror(lookup, axis) =
    throw(DimensionMismatch(
        "axes of $(basetypeof(lookup)) of $(first(axes(lookup))) do not match array axis of $axis"
    ))
@noinline _valformaterror(v, D::Type) =
    throw(ArgumentError(
        "Lookup value of `$v` for dimension $D cannot be converted to a `Lookup`. Did you mean to pass a range or array?"
    ))
