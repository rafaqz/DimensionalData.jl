
"""
    set(A::AbstractDimArray, data::AbstractArray) => AbstractDimArray
    set(A::AbstractDimArray, name::String) => AbstractDimArray

    set(A, xs::Pairs...) => x with updated field/s
    set(A, xs...; kwargs...) => x with updated field/s
    set(A, xs::Tuple) => x with updated field/s
    set(A, xs::NamedTuple) => x with updated field/s

Set the field matching the supertypes of values in xs and return a new object.

As DimensionalData is so strongly typed you do not need to specify what field
to `set` - there is no ambiguity.

You do need to specify which dimension to to set which values on, and
this can be done using `Dimension => val` pairs, `Dimension` wrapped arguments,
keyword arguments or a `NamedTuple`.

If no dimensions are specified the length of the tuple must match the length of
the dimensions, and be in the right order.


## Examples

```julia
da = DimArray(rand(3, 4), (Dim{:custom}(10.0:010.0:30.0), Z(-20:010.0:10.0)))

# Set the array values
set(da, zeros(3, 4))

# Set the array name
set(da, "newname")

# Swap dimension type

# Using Pairs
set(da, :Z => Ti, :custom => Z)
set(da, :custom => X, Z => Y)

# Using keyword arguments
set(da, custom = X, Z = :a)

# Using Dimension wrappers
set(da, Dim{:custom}(X), Z(Dim{:a}))

# Set the dimension index

# To an `AbstractArray` set(da, Z => [:a, :b, :c, :d], :custom => Val((4, 5, 6)))

# To a `Val` tuple index (compile time indexing)
set(da, Z(Val((:a, :b, :c, :d))), custom = 4:6)

# Set dim modes
set(da, Z=NoIndex(), custom=Sampled())
set(da, :custom => Irregular(10, 12), Z => Regular(9.9))
set(da, (Z=NoIndex(), custom=Sampled()))
set(da, custom=Ordered(array=Reverse()), Z=Unordered())
```
"""
function set end



# Array

set(A::AbstractDimArray, args...; kwargs...) =
    rebuild(A, data(A), set(dims(A), args...; kwargs...))
set(A::AbstractDimArray, data::AbstractArray) = begin
    axes(A) == axes(data) ||
        throw(ArgumentError("axes of passed in array $(axes(data)) do not match the currect array $(axes(A))"))
    rebuild(A; data=data)
end
set(A::AbstractDimArray, name::AbstractString) = rebuild(A; name=name)



# Dataset

set(ds::AbstractDimDataset, args...; kwargs...) =
    rebuild(ds, layers(ds), set(dims(ds), args...; kwargs...))


# Dimension

# Convert args/kwargs to dims and set
set(dims_::DimTuple, args::Dimension...; kwargs...) =
    _set(dims_, (args..., _kwargdims(kwargs)...))
set(dims_::DimTuple, nt::NamedTuple) = _set(dims_, _kwargdims(nt))
# Convert pairs to wrapped dims and set
set(dims_::DimTuple, p::Pair, ps::Vararg{<:Pair}) = set(dims_, (p, ps...))
set(dims_::DimTuple, ps::Tuple{Vararg{<:Pair}}) = _set(dims_, _pairdims(ps...))
# Wrap naked vals with dims and set
set(dims::Tuple{Vararg{<:Dimension,N}}, xs::Tuple{Vararg{<:Any,N}}) where N = begin
    wrappers = map((d, v) -> basetypeof(d)(v), dims, xs)
    _set(dims, wrappers)
end
set(dims::DimTuple, wrappers::DimTuple) = _set(dims, wrappers)

# Set dims with (possibly unsorted) wrapper vals
_set(dims::DimTuple, wrappers::DimTuple) = begin
    newdims = map(set, dims, sortdims(wrappers, dims))
    swapdims(dims, newdims)
end

# Set the index
set(dim::Dimension, index::AbstractArray) = rebuild(dim; val=index)
set(dim::Dimension, index::Val) = rebuild(dim; val=index)

# Set the dim, checking the mode
set(dim::Dimension, newdim::Dimension) =
    rebuild(newdim; mode=set(mode(dim), mode(newdim)))
# Set things wrapped in dims
set(dim::Dimension, wrapper::Dimension{<:Union{Type,UnionAll,Dimension,IndexMode,ModeComponent,Symbol,Nothing}}) = 
    set(dim::Dimension, val(wrapper))

# Construct types
set(dim::Dimension, ::Type{T}) where T = set(dim, T())

set(dim::Dimension, ::Nothing) = dim
set(dim::Dimension, key::Symbol) = set(dim, key2dim(key))
set(dim::Dimension, dt::DimType) = basetypeof(dt)(val(dim), mode(dim), metadata(dim))

# Set the mode
set(dim::Dimension, newmode::IndexMode) = rebuild(dim; mode=set(mode(dim), newmode))

# Otherwise pass this on to set fields on the mode
set(dim::Dimension, x::ModeComponent) = rebuild(dim; mode=set(mode(dim), x))


# IndexMode

# AutoMode
set(mode::IndexMode, newmode::AutoMode) = mode
# Categorical
set(mode::IndexMode, newmode::Categorical) =
    rebuild(newmode; order=set(order(mode), order(newmode)))
# Sampled
set(mode::IndexMode, newmode::Sampled) = begin
    o = set(order(mode), order(newmode))
    sp = set(span(mode), span(newmode))
    sa = set(sampling(mode), sampling(newmode))
    rebuild(mode; order=o, span=sp, sampling=sa)
end
# NoIndex
set(mode::IndexMode, newmode::NoIndex) = newmode
# Transformed
set(tr::Transformed, f::Function) = rebuild(tr; f=f)
# set for `dim` is in dimension.jl, for dispatch


# Order
set(mode::IndexMode, neworder::Order) =
    rebuild(mode; order=set(order(mode), neworder))
set(order::Order, neworder::Order) = neworder
set(order::Order, neworder::AutoOrder) = order

# SubOrder
set(order::Ordered, suborder::IndexOrder) =
    rebuild(order; index=set(indexorder(order), suborder))
set(order::Ordered, suborder::ArrayOrder) =
    rebuild(order; array=set(arrayorder(order), suborder))
set(order::Ordered, suborder::RelationOrder) =
    rebuild(order; relation=set(relationorder(order), suborder))

set(order::SubOrder, neworder::AutoSubOrder) = order
set(order::SubOrder, neworder::SubOrder) = neworder


# Span
set(mode::AbstractSampled, span::Span) = rebuild(mode; span=span)
set(mode::AbstractSampled, span::AutoSpan) = mode
set(span::Span, newspan::Span) = newspan
set(span::Span, newspan::AutoSpan) = span


# Sampling
set(mode::AbstractSampled, newsampling::Sampling) =
    rebuild(mode; sampling=set(sampling(mode), newsampling))
set(mode::AbstractSampled, sampling::AutoSampling) = mode
set(sampling::Sampling, newsampling::Sampling) = newsampling
set(sampling::Sampling, newsampling::AutoSampling) = sampling


# Locus
set(mode::AbstractSampled, locus::Locus) =
    rebuild(mode; sampling=set(sampling(mode), locus))
set(sampling::Points, locus::Union{AutoLocus,Center}) = Points()
set(sampling::Points, locus::Locus) =
    error("Cannot set a locus for `Points` sampling other than `Center` - the index values are the exact points")
set(sampling::Intervals, locus::Locus) = Intervals(locus)
set(sampling::Intervals, locus::AutoLocus) = sampling
