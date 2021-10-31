const DimArrayOrStack = Union{AbstractDimArray,AbstractDimStack}

"""
    set(x, val)
    set(x, args::Pairs...) => x with updated field/s
    set(x, args...; kw...) => x with updated field/s
    set(x, args::Tuple{Vararg{<:Dimension}}; kw...) => x with updated field/s

    set(dim::Dimension, index::AbstractArray) => Dimension
    set(dim::Dimension, lookup::LookupArray) => Dimension
    set(dim::Dimension, lookupcomponent::LookupArrayTrait) => Dimension
    set(dim::Dimension, metadata::AbstractMetadata) => Dimension

Set the properties of an object, its internal data or the traits of its dimensions
and lookup index.

As DimensionalData is so strongly typed you do not need to specify what field
of a [`LookupArray`](@ref) to `set` - there is no ambiguity.

To set fields of a `LookupArray` you need to specify the dimension. This can be done
using `X => val` pairs, `X = val` keyword arguments, or `X(val)` wrapped arguments.

When a `Dimension` or `LookupArray` is passed to `set` to replace the
existing ones, fields that are not set will keep their original values.

## Notes:

Changing a lookup index range/vector will also update the step size and order where applicable.

Setting the [`Order`](@ref) like `ForwardOrdered` will *not* reverse the array or
dimension to match. Use `reverse` and [`reorder`](@ref) to do this.

## Examples

```jldoctest set
julia> using DimensionalData; const DD = DimensionalData
DimensionalData

julia> da = DimArray(zeros(3, 4), (custom=10.0:010.0:30.0, Z=-20:010.0:10.0));

julia> set(da, ones(3, 4))
3×4 DimArray{Float64,2} with dimensions:
  Dim{:custom} Sampled 10.0:10.0:30.0 ForwardOrdered Regular Points,
  Z Sampled -20.0:10.0:10.0 ForwardOrdered Regular Points
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0 
```

Change the `Dimension` wrapper type:

```jldoctest set
julia> set(da, :Z => Ti, :custom => Z)
3×4 DimArray{Float64,2} with dimensions:
  Z Sampled 10.0:10.0:30.0 ForwardOrdered Regular Points,
  Ti Sampled -20.0:10.0:10.0 ForwardOrdered Regular Points
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0 
```

Change the lookup `Vector`:

```jldoctest set
julia> set(da, Z => [:a, :b, :c, :d], :custom => [4, 5, 6])
3×4 DimArray{Float64,2} with dimensions:
  Dim{:custom} Sampled Int64[4, 5, 6] ForwardOrdered Regular Points,
  Z Sampled Symbol[a, b, c, d] ForwardOrdered Regular Points
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
```

Change the `LookupArray` type:

```jldoctest set
julia> set(da, Z=DD.NoLookup(), custom=DD.Sampled())
3×4 DimArray{Float64,2} with dimensions:
  Dim{:custom} Sampled 10.0:10.0:30.0 ForwardOrdered Regular Points,
  Z
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
```

Change the `Sampling` trait:

```jldoctest set
julia> set(da, :custom => DD.Irregular(10, 12), Z => DD.Regular(9.9))
3×4 DimArray{Float64,2} with dimensions:
  Dim{:custom} Sampled 10.0:10.0:30.0 ForwardOrdered Irregular Points,
  Z Sampled -20.0:10.0:10.0 ForwardOrdered Regular Points
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0
```
"""
function set end
set(A::DimArrayOrStack, x::T) where {T<:Union{LookupArray,LookupArrayTrait}} = _onlydimerror(x)
set(x::DimArrayOrStack, ::Type{T}) where T = set(x, T())

set(A::AbstractDimStack, x::LookupArray) = LookupArrays._cantseterror(A, x)
set(A::AbstractDimArray, x::LookupArray) = LookupArrays._cantseterror(A, x)
set(A, x) = LookupArrays._cantseterror(A, x)
set(A::DimArrayOrStack, args::Union{Dimension,DimTuple,Pair}...; kw...) =
    rebuild(A, data(A), _set(dims(A), args...; kw...))
set(A::AbstractDimArray, newdata::AbstractArray) = begin
    axes(A) == axes(newdata) || _axiserr(A, newdata)
    rebuild(A; data=newdata)
end
set(s::AbstractDimStack, newdata::NamedTuple) = begin
    dat = data(s)
    keys(dat) === keys(newdata) || _keyerr(keys(dat), keys(newdata))
    map(dat, newdata) do d, nd
        axes(d) == axes(nd) || _axiserr(d, nd)
    end
    rebuild(s; data=newdata)
end

@noinline _onlydimerror(x) = throw(ArgumentError("Can only set $(typeof(x)) for a dimension. Specify which dimension you mean with `X => property`"))
@noinline _axiserr(a, b) = throw(ArgumentError("passed in axes $(axes(b)) do not match the currect axes $(axes(a))"))
@noinline _keyerr(ka, kb) = throw(ArgumentError("keys $ka and $kb do not match"))
