const DimArrayOrStack = Union{AbstractDimArray,AbstractDimStack}

"""
    set(x, val)
    set(x, args::Pairs...) => x with updated field/s
    set(x, args...; kw...) => x with updated field/s
    set(x, args::Tuple{Vararg{Dimension}}; kw...) => x with updated field/s

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
3×4 DimArray{Float64,2}[90m with dimensions: [39m
  [31mDim{[39m[33m:custom[39m[31m}[39m Sampled{Float64} [36m10.0:10.0:30.0[39m ForwardOrdered Regular Points,
  [31mZ[39m Sampled{Float64} [36m-20.0:10.0:10.0[39m ForwardOrdered Regular Points
       [90m-20.0[39m  [90m-10.0[39m  [90m0.0[39m  [90m10.0[39m
 [39m[90m10.0[39m    [39m[39m1.0    [39m[39m1.0  [39m[39m1.0   [39m[39m1.0
 [39m[90m20.0[39m    [39m[39m1.0    [39m[39m1.0  [39m[39m1.0   [39m[39m1.0
 [39m[90m30.0[39m    [39m[39m1.0    [39m[39m1.0  [39m[39m1.0   [39m[39m1.0 
```

Change the `Dimension` wrapper type:

```jldoctest set
julia> set(da, :Z => Ti, :custom => Z)
3×4 DimArray{Float64,2}[90m with dimensions: [39m
  [31mZ[39m Sampled{Float64} [36m10.0:10.0:30.0[39m ForwardOrdered Regular Points,
  [31mTi[39m Sampled{Float64} [36m-20.0:10.0:10.0[39m ForwardOrdered Regular Points
       [90m-20.0[39m  [90m-10.0[39m  [90m0.0[39m  [90m10.0[39m
 [39m[90m10.0[39m    [39m[39m0.0    [39m[39m0.0  [39m[39m0.0   [39m[39m0.0
 [39m[90m20.0[39m    [39m[39m0.0    [39m[39m0.0  [39m[39m0.0   [39m[39m0.0
 [39m[90m30.0[39m    [39m[39m0.0    [39m[39m0.0  [39m[39m0.0   [39m[39m0.0 
```

Change the lookup `Vector`:

```jldoctest set
julia> set(da, Z => [:a, :b, :c, :d], :custom => [4, 5, 6])
3×4 DimArray{Float64,2}[90m with dimensions: [39m
  [31mDim{[39m[33m:custom[39m[31m}[39m Sampled{Int64} [36mInt64[4, 5, 6][39m ForwardOrdered Regular Points,
  [31mZ[39m Sampled{Symbol} [36mSymbol[:a, :b, :c, :d][39m ForwardOrdered Regular Points
     [90m:a[39m   [90m:b[39m   [90m:c[39m   [90m:d[39m
 [39m[90m4[39m  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0
 [39m[90m5[39m  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0
 [39m[90m6[39m  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0
```

Change the `LookupArray` type:

```jldoctest set
julia> set(da, Z=DD.NoLookup(), custom=DD.Sampled())
3×4 DimArray{Float64,2}[90m with dimensions: [39m
  [31mDim{[39m[33m:custom[39m[31m}[39m Sampled{Float64} [36m10.0:10.0:30.0[39m ForwardOrdered Regular Points,
  [31mZ[39m
 [39m[90m10.0[39m  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0
 [39m[90m20.0[39m  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0
 [39m[90m30.0[39m  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0  [39m[39m0.0
```

Change the `Sampling` trait:

```jldoctest set
julia> set(da, :custom => DD.Irregular(10, 12), Z => DD.Regular(9.9))
3×4 DimArray{Float64,2}[90m with dimensions: [39m
  [31mDim{[39m[33m:custom[39m[31m}[39m Sampled{Float64} [36m10.0:10.0:30.0[39m ForwardOrdered Irregular Points,
  [31mZ[39m Sampled{Float64} [36m-20.0:10.0:10.0[39m ForwardOrdered Regular Points
       [90m-20.0[39m  [90m-10.0[39m  [90m0.0[39m  [90m10.0[39m
 [39m[90m10.0[39m    [39m[39m0.0    [39m[39m0.0  [39m[39m0.0   [39m[39m0.0
 [39m[90m20.0[39m    [39m[39m0.0    [39m[39m0.0  [39m[39m0.0   [39m[39m0.0
 [39m[90m30.0[39m    [39m[39m0.0    [39m[39m0.0  [39m[39m0.0   [39m[39m0.0
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
