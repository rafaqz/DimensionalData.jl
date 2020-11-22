"""

Set the field matching the supertypes of values in xs and return a new object.

As DimensionalData is so strongly typed you do not need to specify what field
to `set` - there is no ambiguity.

To set fields of dimensions you need to specify the dimension. This can be done using
`Dimension => x` pairs, `X = x` keyword arguments, `Dimension` wrapped arguments,
or a `NamedTuple`.

When dimensions or IndexModes are passed to `set` to replace the existing ones,
fields that are not set will keep their original values.

## Notes:

Changing the dimension index range will set the `Sampled` mode
component `Regular` with a new step size, and set the dimension order.

Setting [`Order`](@ref) will *not* reverse the array or dimension to match. Use
[`reverse`](@ref) and [`reorder`](@ref) to do this.


## Examples

```julia
da = DimArray(rand(3, 4), (Dim{:custom}(10.0:010.0:30.0), Z(-20:010.0:10.0)))

# Set the array values
set(da, zeros(3, 4))

# Set the array name
set(da, "newname") # Swap dimension type # Using Pairs set(da, :Z => Ti, :custom => Z) set(da, :custom => X, Z => Y)
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

const DimArrayOrDataset = Union{AbstractDimArray,AbstractDimStack}

set(A::DimArrayOrDataset, name::T) where {T<:Union{Mode,ModeComponent}} = _onlydimerror(T)
set(A, x) = _cantseterror(A, x)
_set(A, x) = _cantseterror(A, x)

"""
    set(x, args::Pairs...) => x with updated field/s
    set(x, args...; kw...) => x with updated field/s
    set(x, args::Tuple{Vararg{<:Dimension}}; kw...) => x with updated field/s

Set the dimensions or any properties of the dimensions for `AbstractDimArray`
or `AbstractDimStack`.

Set can be passed Keyword arguments or arguments of Pairs using dimension names,
tuples of values wrapped in the intended dimensions. Or fully or partially
constructed dimensions with val, mode or metadata fields set to intended
values. Dimension fields not assigned a value will be ignored, and the orginals kept.
"""
set(A::DimArrayOrDataset, args::Union{Dimension,DimTuple,Pair}...; kw...) =
    rebuild(A, data(A), _set(dims(A), args...; kw...))

_set(dim::DimArrayOrDataset, ::Type{T}) where T = _set(dim, T())

# Array

"""
    set(A::AbstractDimArray, data::AbstractArray) => AbstractDimArray

`AbstractArray` is always data, and update the `data` field of the array.
This is what is returned by `parent(A)`. It must be the same size as the
original value to match the `Dimension`s in the dims field.
"""
set(A::AbstractDimArray, newdata::AbstractArray) = begin
    axes(A) == axes(newdata) || _axiserr(A, newdata)
    rebuild(A; data=newdata)
end
"""
    set(A::AbstractDimArray, metadata::ArrayMetadata) => AbstractDimArray

Update the `metadata` field of the array.
"""
set(A::AbstractDimArray, metadata::Union{ArrayMetadata,NoMetadata}) = 
    rebuild(A; metadata=metadata)
"""
    set(A::AbstractDimArray, metadata::DimMetadata) => AbstractDimArray

Symbols are always names, and update the `name` field of the array.
"""
set(A::AbstractDimArray, name::Union{Symbol,AbstractName}) = rebuild(A; name=name)

# Dataset

"""
    set(s::AbstractDimStack, data::NamedTuple) => AbstractDimStack

`NamedTuple`s are always data, and update the `data` field of the dataset.
The values must be `AbstractArray of the same size as the original data, to
match the `Dimension`s in the dims field.
"""
set(s::AbstractDimStack, newdata::NamedTuple) = begin
    map(data(s)) do l
        axes(l) == axes(first(data(s))) || _axiserr(first(data(s)), l)
    end
    rebuild(s; data=newdata)
end
"""
    set(s::AbstractDimStack, metadata::Union{StackMetadata,NoMetadata}) => AbstractDimStack

StackMetadata update the `metadata` field of the dataset.
"""
set(s::AbstractDimStack, metadata::Union{StackMetadata,NoMetadata}) = 
    rebuild(s; metadata=metadata)


const InDims = Union{DimMetadata,Type,UnionAll,Dimension,IndexMode,ModeComponent,Symbol,Nothing}

"""
    set(dim::Dimension, index::Unioon{AbstractArray,Val}) => Dimension
    set(dim::Dimension, mode::Mode) => Dimension
    set(dim::Dimension, modecomponent::ModeComponent) => Dimension
    set(dim::Dimension, metadata::DimMetadata) => Dimension

Set fields of the dimension
"""
set(dim::Dimension, x::InDims) = _set(dim, x)


# Convert args/kwargs to dims and set
_set(dims_::DimTuple, args::Dimension...; kw...) = _set(dims_, (args..., _kwargdims(kw)...))
# Convert pairs to wrapped dims and set
_set(dims_::DimTuple, p::Pair, ps::Vararg{<:Pair}) = _set(dims_, (p, ps...))
_set(dims_::DimTuple, ps::Tuple{Vararg{<:Pair}}) = _set(dims_, _pairdims(ps...))

# Set dims with (possibly unsorted) wrapper vals
_set(dims::DimTuple, wrappers::DimTuple) = begin
    # Check the dimension types match
    map(wrappers) do w
        hasdim(dims, w) || _wrongdimserr(dims, w)
    end
    # Missing dims return `nothing` from sortdims
    newdims = map(_set, dims, sortdims(wrappers, dims))
    # Swaps existing dims with non-nothing new dims
    swapdims(dims, newdims)
end


# Set things wrapped in dims
_set(dim::Dimension, wrapper::Dimension{<:InDims}) = _set(dim::Dimension, val(wrapper))

# Set the index
_set(dim::Dimension, index::Val) = rebuild(dim; val=index)
_set(dim::Dimension, index::AbstractArray) = rebuild(dim; val=index)
_set(dim::Dimension, index::AbstractRange) = begin
    dim = _set(dim, _orderof(index))
    # We might need to update the index mode
    _set(mode(dim), dim, index)
end
_set(dim::Dimension, index::Colon) = dim

_set(mode::IndexMode, dim::Dimension, index::AbstractRange) = rebuild(dim; val=index)
# Update the Sampling mode of Sampled dims - it must match the range.
_set(mode::AbstractSampled, dim::Dimension, index::AbstractRange) =
    rebuild(dim; val=index, mode=_set(mode, Regular(step(index))))

# Set the dim, checking the mode
_set(dim::Dimension, newdim::Dimension) = begin
    # Get new metadata and val
    dim = _set(dim, val(newdim))
    dim = _set(dim, metadata(newdim))
    dim = _set(dim, mode(newdim))
    # then wrap the updated dim in the new type
    basetypeof(newdim)(val(dim), mode(dim), metadata(dim))
end

# Construct types
_set(dim::Dimension, ::Type{T}) where T = _set(dim, T())

_set(dim::Dimension, key::Symbol) = _set(dim, key2dim(key))
_set(dim::Dimension, dt::DimType) = basetypeof(dt)(val(dim), mode(dim), metadata(dim))

# Set the mode
_set(dim::Dimension, newmode::IndexMode) = rebuild(dim; mode=_set(mode(dim), newmode))

# Otherwise pass this on to set fields on the mode
_set(dim::Dimension, x::ModeComponent) = rebuild(dim; mode=_set(mode(dim), x))


# IndexMode

# AutoMode
_set(mode::IndexMode, newmode::AutoMode) = mode
# Categorical
_set(mode::IndexMode, newmode::Categorical) =
    rebuild(newmode; order=_set(order(mode), order(newmode)))
# Sampled
_set(mode::IndexMode, newmode::AbstractSampled) = begin
    # Update each field separately. The old mode may not have these fields, or may have
    # a subset with the rest being traits. The new mode may have some auto fields.
    o = _set(order(mode), order(newmode))
    sp = _set(span(mode), span(newmode))
    sa = _set(sampling(mode), sampling(newmode))
    # Rebuild the new mode with the merged fields
    rebuild(newmode; order=o, span=sp, sampling=sa)
end
# NoIndex
_set(mode::IndexMode, newmode::NoIndex) = newmode


# Order
_set(mode::IndexMode, neworder::Order) = rebuild(mode; order=_set(order(mode), neworder))
_set(mode::NoIndex, neworder::Order) = mode

_set(order::Union{Ordered,Unordered}, neworder::Ordered) = begin
    index = _set(indexorder(order), indexorder(neworder))
    array = _set(arrayorder(order), arrayorder(neworder))
    rel = _set(relation(order), relation(neworder))
    Ordered(index, array, rel)
end
_set(order::Union{Ordered,Unordered}, neworder::Unordered) =
    Unordered(_set(relation(order), relation(neworder)))


# AutoOrder
_set(order::Order, neworder::AutoOrder) = order
_set(order::AutoOrder, neworder::Order) = order
_set(order::AutoOrder, neworder::AutoOrder) = AutoOrder()

# SubOrder
_set(order::Unordered, suborder::Relation) =
    rebuild(order; relation=_set(relation(order), suborder))

_set(order::Ordered, suborder::IndexOrder) =
    rebuild(order; index=_set(indexorder(order), suborder))
_set(order::Ordered, suborder::ArrayOrder) =
    rebuild(order; array=_set(arrayorder(order), suborder))
_set(order::Ordered, suborder::Relation) =
    rebuild(order; relation=_set(relation(order), suborder))

_set(suborder::ArrayOrder, newsuborder::ArrayOrder) = newsuborder
_set(suborder::IndexOrder, newsuborder::IndexOrder) = newsuborder
_set(suborder::Relation, newsuborder::Relation) = newsuborder


# Span
_set(mode::AbstractSampled, span::Span) = rebuild(mode; span=span)
_set(mode::AbstractSampled, span::AutoSpan) = mode
_set(span::Span, newspan::Span) = newspan
_set(span::Span, newspan::AutoSpan) = span


# Sampling
_set(mode::AbstractSampled, newsampling::Sampling) =
    rebuild(mode; sampling=_set(sampling(mode), newsampling))
_set(mode::AbstractSampled, sampling::AutoSampling) = mode
_set(sampling::Sampling, newsampling::Sampling) = newsampling
_set(sampling::Sampling, newsampling::AutoSampling) = sampling


# Locus
_set(mode::AbstractSampled, locus::Locus) =
    rebuild(mode; sampling=_set(sampling(mode), locus))
_set(sampling::Points, locus::Union{AutoLocus,Center}) = Points()
_set(sampling::Points, locus::Locus) = _locuserror()
_set(sampling::Intervals, locus::Locus) = Intervals(locus)
_set(sampling::Intervals, locus::AutoLocus) = sampling


_set(dim::Dimension, newmetadata::Union{DimMetadata,NoMetadata}) =
    rebuild(dim, val(dim), mode(dim), newmetadata)

_set(x, ::Nothing) = x
_set(::Nothing, x) = x
_set(::Nothing, ::Nothing) = nothing


@noinline _locuserror() = throw(ArgumentError("Can't set a locus for `Points` sampling other than `Center` - the index values are the exact points"))
@noinline _cantseterror(a, b) = throw(ArgumentError("Can not set any fields of $a to $b"))
@noinline _onlydimerror(T) = throw(ArgumentError("Can only set $(typeof(T)) for a dimension. Specify which dimension you want to set it for"))
@noinline _axiserr(a, b) = throw(ArgumentError("passed in axes $(axes(b)) do not match the currect axes $(axes(a))"))
@noinline _wrongdimserr(dims, w) = throw(ArgumentError("dim $(basetypeof(w))) not in $(map(basetypeof, dims))"))
