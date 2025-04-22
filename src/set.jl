const DimArrayOrStack = Union{AbstractDimArray,AbstractDimStack}

"""
    set(x, val)
    set(x, dims::Pairs...)
    set(x, dims::Tuple{Vararg{Dimension}})
    set(x; kw...)

Set the properties of an object, its internal data or the traits 
of its dimensions and lookup index, returning a new, rebuild object.

Related properties will be updated to match the change, for example,
changing the order of a lookup from ForwardOrdered to ReverseOrdered will reverse the
data as well. See [`unsafe_set`](@ref) for a version that makes the specified change.

`x` can be a `AbstractDimArray`, `AbstractDimStack`, `Dimension`, `Lookup` or
`LookupTrait`.

As DimensionalData is so strongly typed you do not need to specify what field
of a [`Lookup`](@ref) to `set` - there is usually no ambiguity.

## Updating object dimensions

To set swap or alter the `Lookup` of an objects dimensions, you need to specify the dimension. 
This can be done using `set(obj, X => val)` pairs or `set(obj,, X(val))` wrapped arguments.

You can also updata all dimensions by passing a lookup trait 
e.g. `set(obj, ForwardOrdered)`. This will be set for all dimensions.

When a `Dimension` or `Lookup` is passed to `set` to replace the
existing ones, fields that were not set will keep their original values.

## Updating object data

Passing an `AbstractArray` to `set` will update the data of the object.

## Updating object fields

Keywords can be passed to `set` to update the fields of an object,
working like keyword `rebuild` but updating related fields where needed.

Fields are always the same as keywords for the objects constructor.

## Examples

Update the data in a `DimArray`:

```jldoctest set
julia> using DimensionalData; const DD = DimensionalData;

julia> da = DimArray(zeros(3, 4), (custom=10.0:010.0:30.0, Z=-20:010.0:10.0));

julia> set(da, ones(3, 4))
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────────── dims ┐
  ↓ custom Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Regular Points,
  → Z      Sampled{Float64} -20.0:10.0:10.0 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────────────────┘
  ↓ →  -20.0  -10.0  0.0  10.0
 10.0    1.0    1.0  1.0   1.0
 20.0    1.0    1.0  1.0   1.0
 30.0    1.0    1.0  1.0   1.0
```

Change the `Dimension` wrapper type:

```jldoctest set
julia> set(da, :Z => Ti, :custom => Z)
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────── dims ┐
  ↓ Z  Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Regular Points,
  → Ti Sampled{Float64} -20.0:10.0:10.0 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────────────┘
  ↓ →  -20.0  -10.0  0.0  10.0
 10.0    0.0    0.0  0.0   0.0
 20.0    0.0    0.0  0.0   0.0
 30.0    0.0    0.0  0.0   0.0
```

Change the dimension lookup values:

```jldoctest set
julia> set(da, Z => [:a, :b, :c, :d], :custom => [6, 5, 4])
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────────── dims ┐
  ↓ custom Sampled{Int64} [6, 5, 4] ReverseOrdered Regular Points,
  → Z      Sampled{Symbol} [:a, :b, :c, :d] ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────────────────┘
 ↓ →   :a   :b   :c   :d
 4    0.0  0.0  0.0  0.0
 5    0.0  0.0  0.0  0.0
 6    0.0  0.0  0.0  0.0
```

Change the `Lookup` type:

```jldoctest set
julia> set(da; Z => DD.NoLookup(), :custom => DD.Sampled())
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────────── dims ┐
  ↓ custom Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Regular Points,
  → Z
└─────────────────────────────────────────────────────────────────────────┘
 10.0  0.0  0.0  0.0  0.0
 20.0  0.0  0.0  0.0  0.0
 30.0  0.0  0.0  0.0  0.0
```

Change the `Sampling` trait:

```jldoctest set
julia> set(da, :custom => DD.Irregular(10, 12), Z => DD.Regular(9.9))
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴────────────────────────────────────────── dims ┐
  ↓ custom Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Irregular Points,
  → Z      Sampled{Float64} -20.0:10.0:10.0 ForwardOrdered Regular Points
└───────────────────────────────────────────────────────────────────────────┘
  ↓ →  -20.0  -10.0  0.0  10.0
 10.0    0.0    0.0  0.0   0.0
 20.0    0.0    0.0  0.0   0.0
 30.0    0.0    0.0  0.0   0.0
```

Set the name of a `DimArray`:

```jldoctest set
julia> set(da; name=:newname)
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴────────────────────────────────────────── dims ┐
  ↓ custom Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Regular Points,
  → Z      Sampled{Float64} -20.0:10.0:10.0 ForwardOrdered Regular Points
└───────────────────────────────────────────────────────────────────────────┘
  ↓ →  -20.0  -10.0  0.0  10.0
 10.0    0.0    0.0  0.0   0.0
 20.0    0.0    0.0  0.0   0.0
 30.0    0.0    0.0  0.0   0.0
```
"""
set(x::DimArrayOrStack, args...; kw...) = 
    _set(Safe(), _set(Safe(), x, args...); kw...)
set(x::DimArrayOrStack, ::Type{T}) where T = set(x, T())

"""
    unsafe_set(x, val)
    unsafe_set(x, dims::Pairs...)
    unsafe_set(x, dims::Tuple{Vararg{Dimension}})
    unsafe_set(x; kw...)

Set the properties of an object, its internal data or the traits
of its dimensions and lookup index, returning a new, rebuild object.

Works the same as [`set`](@ref) but does not update other 
properties to match any changes.

It is usually type stable and can be faster than `set`,
but can produce broken objects if used incorrectly.

`unsafe_set` with keywords is identical to `rebuild`.
"""
unsafe_set(x::DimArrayOrStack, args...; kw...) = 
    _set(Unsafe(), _set(Unsafe(), x, args...); kw...)
unsafe_set(x::DimArrayOrStack, ::Type{T}) where T = unsafe_set(x, T())

# Keywords are passed to rebuild, but with checks
function _set(s::Safety, A::AbstractDimArray;
    data=nothing, dims=nothing, kw...
)
    A1 = isnothing(data) ? A : _set_dimarray_data(s, A, data)
    A2 = isnothing(dims) ? A1 : _set(s, A1, dims)
    # Just `rebuild` everything else, it's assumed to have no interactions.
    # Package developers note: if other fields do interact, implement this 
    # method for your own `AbstractDimArray` type.
    return rebuild(A1; kw...)
end
function _set(s::Safety, st::AbstractDimStack;
    data=nothing, dims=nothing, kw...
)
    st1 = isnothing(data) ? st : _set_dimstack_data(s, st, data)
    st2 = isnothing(dims) ? st1 : _set(s, st, dims)
    # Just `rebuild` everything else, it's assumed to have no interactions.
    # Package developers note: if other fields do interact, implement this 
    # method for your own `AbstractDimStack` type.
    return rebuild(st2; kw...)
end

# Dimensions and pairs are set for dimensions 
# Short circuit here to avoid multiple allocations
function _set(
    s::Safety, A::AbstractDimArray, args::Union{Dimension,DimTuple,Pair}...
)
    newdims = _set(s, dims(A), args...)
    return rebuild(_rebuild_maybe_reorder(s, A, newdims); dims=newdims)
end
function _set(
    s::Safety, st::AbstractDimStack, args::Union{Dimension,DimTuple,Pair}...
)
    newdims = _set(s, dims(st), args...)
    st = if dimsmatch(newdims, dims(st))
        _rebuild_maybe_reorder(s, st, newdims)
    else
        dim_updates = map(rebuild, basedims(st), basedims(newdims))
        lds = map(layerdims(st)) do lds
            # Swap out the dims with the updated dims
            # that match the dims of this layer
            map(val, dims(dim_updates, lds))
        end
        rebuild(_rebuild_maybe_reorder(s, st, newdims); layerdims=lds)
    end
end
# Single traits are set for all dimensions
_set(s::Safety, A::DimArrayOrStack, x::LookupTrait) = 
    _set(s, A, map(d -> basedims(d) => x, dims(A))...)
# Single lookups are set for all dimensions.
_set(s::Safety, A::AbstractDimArray, x::Lookup) = 
    _set(s, A, map(d -> rebuild(d, x), dims(A))...)
_set(s::Safety, A::AbstractDimStack, x::Lookup) = 
    _set(s, A, map(d -> rebuild(d, x), dims(A))...)
# Arrays are set as data for AbstractDimArray
_set(s::Safety, A::AbstractDimArray, newdata::AbstractArray) =
    _set_dimarray_data(s, A, newdata)
_set(s::Safety, A::AbstractDimStack, newdata::NamedTuple) =
    _set_dimstack_data(s, A, newdata)

# Check dimensions for Safe
function _set_dimarray_data(::Safe, A, data)
    checkaxes(dims(A), axes(data))
    rebuild(A; data)
end
# Just rebuild for Unsafe
_set_dimarray_data(::Unsafe, A, data) = rebuild(A; data)

# NamedTuples are set as data for AbstractDimStack
function _set_dimstack_data(::Safe, st, newdata)
    # Allow updating subsets of data for NamedTuple
    newdata1 = if parent(st) isa NamedTuple && newdata isa NamedTuple
        ConstructionBase.setproperties(parent(st), newdata)
    else
        keys(st) === keys(newdata) || _keyerr(keys(dat), keys(newdata))
        newdata
    end
    # Make sure the data matches the dimensions
    map(layerdims(st), newdata1) do lds, nd
        # TODO a message with the layer name could help here
        checkaxes(dims(st, lds), axes(nd))
    end
    return rebuild(st; data=newdata1)
end
# Just rebuild for Unsafe
_set_dimstack_data(::Unsafe, st, data) = rebuild(st; data)

@noinline _axiserr(a, b) = _axiserr(axes(a), axes(b))
@noinline _axiserr(a::Tuple, b::Tuple) = 
    throw(ArgumentError("passed in axes $b do not match the currect axes $a"))
@noinline _keyerr(ka, kb) = throw(ArgumentError("keys $ka and $kb do not match"))

_rebuild_maybe_reorder(::Unsafe, A, newdims) = A
 # Handle any changes to order
function _rebuild_maybe_reorder(::Safe, A, newdims)
    if map(order, dims(A)) == map(order, newdims)
        rebuild(A; dims=newdims)
    else
        A1 = reorder(A, map(rebuild, dims(A), order(newdims)))
        rebuild(A; data=parent(A1), dims=newdims)
    end
end