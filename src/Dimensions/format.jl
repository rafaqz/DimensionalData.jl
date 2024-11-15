
# When an object like DimArray or DimStack is constructed,
# `format` is called on its dimensions

"""
    format(dims, x) => Tuple{Vararg{Dimension,N}}

Format the passed-in dimension(s) `dims` to match the object `x`.

Errors are thrown if dims don't match the array dims or size, 
and any fields holding `Auto-` objects are filled with guessed objects.

If a [`Lookup`](@ref) hasn't been specified, a lookup is chosen
based on the type and element type of the values.
"""
format(dims, A::AbstractArray) = format((dims,), A)
function format(dims::NamedTuple, A::AbstractArray)
    dims = map(keys(dims), values(dims)) do k, v
        rebuild(name2dim(k), v)
    end
    return format(dims, A)
end
function format(dims::Tuple{<:Pair,Vararg{Pair}}, A::AbstractArray)
    dims = map(dims) do (k, v)
        rebuild(basedims(k), v)
    end
    return format(dims, A)
end
# Make a dummy array that assumes the dims are the correct length and don't hold `Colon`s
function format(dims::DimTuple) 
    ax = map(parent ∘ first ∘ axes, dims)
    A = CartesianIndices(ax)
    return format(dims, A)
end
format(dims::Tuple{Vararg{Any,N}}, A::AbstractArray{<:Any,N}) where N = format(dims, axes(A))
@noinline format(dims::Tuple{Vararg{Any,M}}, A::AbstractArray{<:Any,N}) where {N,M} =
    throw(DimensionMismatch("Array A has $N axes, while the number of dims is $M: $(map(basetypeof, dims))"))
format(dims::Tuple{Vararg{Any,N}}, axes::Tuple{Vararg{Any,N}}) where N = map(_format, dims, axes)
format(d::Dimension{<:AbstractArray}) = _format(d, axes(val(d), 1))
format(d::Dimension, axis::AbstractRange) = _format(d, axis)
format(l::Lookup) = parent(format(AnonDim(l)))

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
format(m::Lookups.Length1NoLookup, D::Type, values, axis::AbstractRange) = m
format(m::NoLookup, D::Type, values, axis::AbstractRange) = m
format(m::NoLookup, D::Type, values::AutoValues, axis::AbstractRange) = NoLookup(axis)
# # AutoLookup
function format(m::AutoLookup, D::Type, values::AbstractArray{T}, axis::AbstractRange) where T
    # A mixed type lookup is Categorical
    m = if isconcretetype(T) 
        Sampled(; order=order(m), span=span(m), sampling=sampling(m), metadata=metadata(m))
    else
        o = order(m) isa AutoOrder ? Unordered() : order(m)
        Categorical(; order=o, metadata=metadata(m))
    end
    format(m, D, values, axis)
end
function format(m::AutoLookup, D::Type, values::AbstractArray{<:CategoricalEltypes}, axis::AbstractRange)
    o = _format(order(m), D, values)
    return Categorical(values; order=o, metadata=metadata(m))
end
function format(m::Categorical, D::Type, values, axis::AbstractRange)
    i = _format(values, axis)
    o = _format(order(m), D, values)
    return rebuild(m; data=i, order=o)
end
# Sampled
function format(m::AbstractSampled, D::Type, values, axis::AbstractRange)
    i = _format(values, axis)
    o = _format(order(m), D, values)
    sp = _format(span(m), D, values)
    sa = _format(sampling(m), sp, D, values)
    x = rebuild(m; data=i, order=o, span=sp, sampling=sa)
    return x
end
# Transformed
format(m::Transformed, D::Type, values::AutoValues, axis::AbstractRange) =
    rebuild(m; dim=D(), data=axis)
format(m::Transformed, D::Type, values, axis::AbstractRange) = rebuild(m; dim=D())

# Values
_format(values::AbstractArray, axis::AbstractRange) = values
_format(values::AutoLookup, axis::AbstractRange) = axis
# Order
_format(order::Order, D::Type, values) = order
_format(order::AutoOrder, D::Type, values) = Lookups.orderof(values)
# Span
_format(span::AutoSpan, D::Type, values::Union{AbstractArray,Val}) =
    _format(Irregular(), D, values)
_format(span::AutoSpan, D::Type, values::AbstractRange) = Regular(step(values))
_format(span::Regular{AutoStep}, D::Type, values::Union{AbstractArray,Val}) = _arraynosteperror()
_format(span::Regular{AutoStep}, D::Type, values::LinRange) = Regular(step(values))
_format(span::Regular{AutoStep}, D::Type, values::AbstractRange) = Regular(step(values))
_format(span::Regular, D::Type, values::Union{AbstractArray,Val}) = span
function _format(span::Regular, D::Type, values::AbstractRange)
    step(span) isa Number && !(step(span) ≈ step(values)) && _steperror(values, span)
    return span
end
function _format(span::Regular, D::Type, values::LinRange{T}) where T
    step(span) isa Number && step(values) > zero(T) && !(step(span) ≈ step(values)) && _steperror(values, span)
    return span
end
_format(span::Irregular{AutoBounds}, D, values) = Irregular(nothing, nothing)
_format(span::Irregular{<:Tuple}, D, values) = span
_format(span::Explicit, D, values) = span
# Sampling
_format(sampling::AutoSampling, span::Span, D::Type, values) = Points()
_format(::AutoSampling, ::Span, D::Type, ::AbstractArray{<:IntervalSets.Interval}) =
    Intervals(Start())
_format(sampling::AutoSampling, span::Explicit, D::Type, values) =
    Intervals(_format(locus(sampling), D, values))
# For ambiguity, not likely to happen in practice
_format(::AutoSampling, ::Explicit, D::Type, ::AbstractArray{<:IntervalSets.Interval}) =
    Intervals(_format(locus(sampling), D, values))
_format(sampling::Points, span::Span, D::Type, values) = sampling
_format(sampling::Points, span::Explicit, D::Type, values) = _explicitpoints_error() 
_format(sampling::Intervals, span::Span, D::Type, values) =
    rebuild(sampling, _format(locus(sampling), D, values))
# Locus
_format(locus::AutoLocus, D::Type, values) = Center()
# Time dimensions need to default to the Start() locus, as that is
# nearly always the _format and Center intervals are difficult to
# calculate with DateTime step values.
_format(locus::AutoLocus, D::Type{<:TimeDim}, values) = Start()
_format(locus::Locus, D::Type, values) = locus

_order(values) = first(values) <= last(values) ? ForwardOrdered() : ReverseOrdered()

checkaxis(lookup::Transformed, axis) = nothing
checkaxis(lookup, axis) = first(axes(lookup)) == axis || _checkaxiserror(lookup, axis)

@noinline _explicitpoints_error() =
    throw(ArgumentError("Cannot use Explicit span with Points sampling"))
@noinline _steperror(values, span) =
    throw(ArgumentError("lookup step $(step(span)) does not match lookup step $(step(values))"))
@noinline _arraynosteperror() =
    throw(ArgumentError("`Regular` must specify `step` size with values other than `AbstractRange`"))
@noinline _checkaxiserror(lookup, axis) =
    throw(DimensionMismatch(
        "axes of $(basetypeof(lookup)) of $(first(axes(lookup))) do not match array axis of $axis"
    ))
@noinline _valformaterror(v, D::Type) =
    throw(ArgumentError(
        "Lookup value of `$v` for dimension $D cannot be converted to a `Lookup`. Did you mean to pass a range or array?"
    ))
