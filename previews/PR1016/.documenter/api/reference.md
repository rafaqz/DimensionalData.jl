
# API Reference {#API-Reference}

## Arrays {#Arrays}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.AbstractBasicDimArray' href='#DimensionalData.AbstractBasicDimArray'><span class="jlbinding">DimensionalData.AbstractBasicDimArray</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractBasicDimArray <: AbstractArray
```


The abstract supertype for all arrays with a `dims` method that  returns a `Tuple` of `Dimension`

Only keyword `rebuild` is guaranteed to work with `AbstractBasicDimArray`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L3-L10" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.AbstractDimArray' href='#DimensionalData.AbstractDimArray'><span class="jlbinding">DimensionalData.AbstractDimArray</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractDimArray <: AbstractBasicArray
```


Abstract supertype for all &quot;dim&quot; arrays.

These arrays return a `Tuple` of [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension) from a [`dims`](/extending_dd#dims) method, and can be rebuilt using [`rebuild`](/api/reference#DimensionalData.Dimensions.Lookups.rebuild).

`parent` must return the source array.

They should have [`metadata`](/api/reference#DimensionalData.Dimensions.Lookups.metadata), [`name`](/api/reference#DimensionalData.Dimensions.name) and [`refdims`](/api/reference#DimensionalData.Dimensions.refdims) methods, although these are optional.

A [`rebuild`](/api/reference#DimensionalData.Dimensions.Lookups.rebuild) method for `AbstractDimArray` must accept `data`, `dims`, `refdims`, `name`, `metadata` arguments.

Indexing `AbstractDimArray` with non-range `AbstractArray` has undefined effects on the `Dimension` index. Use forward-ordered arrays only&quot;


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L41-L59" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimArray' href='#DimensionalData.DimArray'><span class="jlbinding">DimensionalData.DimArray</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimArray <: AbstractDimArray

DimArray(data, dims, refdims, name, metadata)
DimArray(data, dims::Tuple; refdims=(), name=NoName(), metadata=NoMetadata())
DimArray(gen; kw...)
```


The main concrete subtype of [`AbstractDimArray`](/api/reference#DimensionalData.AbstractDimArray).

`DimArray` maintains and updates its `Dimension`s through transformations and moves dimensions to reference dimension `refdims` after reducing operations (like e.g. `mean`).

**Arguments**
- `data`: An `AbstractArray`.
  
- `gen`: A generator expression. Where source iterators are `Dimension`s the dim args or kw is not needed.
  
- `dims`: A `Tuple` of `Dimension`
  
- `name`: A string name for the array. Shows in plots and tables.
  
- `refdims`: refence dimensions. Usually set programmatically to track past   slices and reductions of dimension for labelling and reconstruction.
  
- `metadata`: `Dict` or `Metadata` object, or `NoMetadata()`
  

Indexing can be done with all regular indices, or with [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension)s and/or [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s. 

Indexing `AbstractDimArray` with non-range `AbstractArray` has undefined effects on the `Dimension` index. Use forward-ordered arrays only&quot;

Note that the generator expression syntax requires usage of the semi-colon `;` to distinguish generator dimensions from keywords.

Example:

```julia
julia> using Dates, DimensionalData

julia> ti = Ti(DateTime(2001):Month(1):DateTime(2001,12));

julia> x = X(10:10:100);

julia> A = DimArray(rand(12,10), (ti, x), name="example");

julia> A[X(Near([12, 35])), Ti(At(DateTime(2001,5)))]
┌ 2-element DimArray{Float64, 1} example ┐
├────────────────────────────────────────┴──────────────── dims ┐
  ↓ X Sampled{Int64} [10, 40] ForwardOrdered Irregular Points
└───────────────────────────────────────────────────────────────┘
 10  0.253849
 40  0.637077

julia> A[Near(DateTime(2001, 5, 4)), Between(20, 50)]
┌ 4-element DimArray{Float64, 1} example ┐
├────────────────────────────────────────┴────────────── dims ┐
  ↓ X Sampled{Int64} 20:10:50 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────┘
 20  0.774092
 30  0.823656
 40  0.637077
 50  0.692235
```


Generator expression:

```julia
julia> DimArray((x, y) for x in X(1:3), y in Y(1:2); name = :Value)
┌ 3×2 DimArray{Tuple{Int64, Int64}, 2} Value ┐
├────────────────────────────────────────────┴───── dims ┐
  ↓ X Sampled{Int64} 1:3 ForwardOrdered Regular Points,
  → Y Sampled{Int64} 1:2 ForwardOrdered Regular Points
└────────────────────────────────────────────────────────┘
 ↓ →  1        2
 1     (1, 1)   (1, 2)
 2     (2, 1)   (2, 2)
 3     (3, 1)   (3, 2)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L360-L436" target="_blank" rel="noreferrer">source</a></Badge>

</details>


Shorthand `AbstractDimArray` constructors:
<details class='jldocstring custom-block' open>
<summary><a id='Base.fill' href='#Base.fill'><span class="jlbinding">Base.fill</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
Base.fill(x, dims::Dimension...; kw...) => DimArray
Base.fill(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray
```


Create a [`DimArray`](/api/reference#DimensionalData.DimArray) with a fill value of `x`.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to  that `AbstractVector`, and detect the dimension lookup.
  
- A `Dimension` holding an `Integer` will set the length of the axis, and set the dimension lookup to [`NoLookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.NoLookup).
  

Keywords are the same as for [`DimArray`](/api/reference#DimensionalData.DimArray).

**Example**

```julia
julia> using DimensionalData, Random; Random.seed!(123);

julia> fill(true, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 1  1  1  1
 1  1  1  1
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L525-L552" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Base.rand' href='#Base.rand'><span class="jlbinding">Base.rand</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
Base.rand(x, dims::Dimension...; kw...) => DimArray
Base.rand(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray
Base.rand(r::AbstractRNG, x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray
Base.rand(r::AbstractRNG, x, dims::Dimension...; kw...) => DimArray
```


Create a [`DimArray`](/api/reference#DimensionalData.DimArray) of random values.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to  that `AbstractVector`, and detect the dimension lookup.
  
- A `Dimension` holding an `Integer` will set the length of the axis, and set the dimension lookup to [`NoLookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.NoLookup).
  

Keywords are the same as for [`DimArray`](/api/reference#DimensionalData.DimArray).

**Example**

```julia
julia> using DimensionalData

julia> rand(Bool, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 0  0  0  0
 1  0  0  1

julia> rand(X([:a, :b, :c]), Y(100.0:50:200.0))
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────────── dims ┐
  ↓ X Categorical{Symbol} [:a, …, :c] ForwardOrdered,
  → Y Sampled{Float64} 100.0:50.0:200.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────┘
 ↓ →  100.0       150.0       200.0
  :a    0.443494    0.253849    0.867547
  :b    0.745673    0.334152    0.0802658
  :c    0.512083    0.427328    0.311448
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L555-L595" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Base.zeros' href='#Base.zeros'><span class="jlbinding">Base.zeros</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
Base.zeros(x, dims::Dimension...; kw...) => DimArray
Base.zeros(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray
```


Create a [`DimArray`](/api/reference#DimensionalData.DimArray) of zeros.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to  that `AbstractVector`, and detect the dimension lookup.
  
- A `Dimension` holding an `Integer` will set the length of the axis, and set the dimension lookup to [`NoLookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.NoLookup).
  

Keywords are the same as for [`DimArray`](/api/reference#DimensionalData.DimArray).

**Example**

```julia
julia> using DimensionalData

julia> zeros(Bool, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 0  0  0  0
 0  0  0  0

julia> zeros(X([:a, :b, :c]), Y(100.0:50:200.0))
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────────── dims ┐
  ↓ X Categorical{Symbol} [:a, …, :c] ForwardOrdered,
  → Y Sampled{Float64} 100.0:50.0:200.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────┘
 ↓ →  100.0  150.0  200.0
  :a    0.0    0.0    0.0
  :b    0.0    0.0    0.0
  :c    0.0    0.0    0.0

```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L598-L637" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Base.ones' href='#Base.ones'><span class="jlbinding">Base.ones</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
Base.ones(x, dims::Dimension...; kw...) => DimArray
Base.ones(x, dims::Tuple{Vararg{Dimension}}; kw...) => DimArray
```


Create a [`DimArray`](/api/reference#DimensionalData.DimArray) of ones.

There are two kinds of `Dimension` value acepted:
- A `Dimension` holding an `AbstractVector` will set the dimension index to  that `AbstractVector`, and detect the dimension lookup.
  
- A `Dimension` holding an `Integer` will set the length of the axis, and set the dimension lookup to [`NoLookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.NoLookup).
  

Keywords are the same as for [`DimArray`](/api/reference#DimensionalData.DimArray).

**Example**

```julia
julia> using DimensionalData

julia> ones(Bool, X(2), Y(4))
┌ 2×4 DimArray{Bool, 2} ┐
├───────────────── dims ┤
  ↓ X, → Y
└───────────────────────┘
 1  1  1  1
 1  1  1  1

julia> ones(X([:a, :b, :c]), Y(100.0:50:200.0))
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────────── dims ┐
  ↓ X Categorical{Symbol} [:a, …, :c] ForwardOrdered,
  → Y Sampled{Float64} 100.0:50.0:200.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────┘
 ↓ →  100.0  150.0  200.0
  :a    1.0    1.0    1.0
  :b    1.0    1.0    1.0
  :c    1.0    1.0    1.0

```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L640-L679" target="_blank" rel="noreferrer">source</a></Badge>

</details>


Functions for getting information from objects:
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.dims' href='#DimensionalData.Dimensions.dims'><span class="jlbinding">DimensionalData.Dimensions.dims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
dims(x, [dims::Tuple]) => Tuple{Vararg{Dimension}}
dims(x, dim) => Dimension
```


Return a tuple of `Dimension`s for an object, in the order that matches the axes or columns of the underlying data.

`dims` can be `Dimension`, `Dimension` types, or `Symbols` for `Dim{Symbol}`.

The default is to return `nothing`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L49-L59" target="_blank" rel="noreferrer">source</a></Badge>



```julia
dims(x, query) => Tuple{Vararg{Dimension}}
dims(x, query...) => Tuple{Vararg{Dimension}}
```


Get the dimension(s) matching the type(s) of the query dimension.

Lookup can be an Int or an Dimension, or a tuple containing any combination of either.

**Arguments**
- `x`: any object with a `dims` method, or a `Tuple` of `Dimension`.
  
- `query`: Tuple or a single `Dimension` or `Dimension` `Type`.
  

**Example**

```julia
julia> using DimensionalData

julia> A = DimArray(ones(2, 3, 2), (X, Y, Z))
┌ 2×3×2 DimArray{Float64, 3} ┐
├────────────────────── dims ┤
  ↓ X, → Y, ↗ Z
└────────────────────────────┘
[:, :, 1]
 1.0  1.0  1.0
 1.0  1.0  1.0

julia> dims(A, (X, Y))
(↓ X, → Y)

```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L116-L146" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.refdims' href='#DimensionalData.Dimensions.refdims'><span class="jlbinding">DimensionalData.Dimensions.refdims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
refdims(x, [dims::Tuple]) => Tuple{Vararg{Dimension}}
refdims(x, dim) => Dimension
```


Reference dimensions for an array that is a slice or view of another array with more dimensions.

`slicedims(a, dims)` returns a tuple containing the current new dimensions and the new reference dimensions. Refdims can be stored in a field or discarded, as it is mostly to give context to plots. Ignoring refdims will simply leave some captions empty.

The default is to return an empty `Tuple` `()`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L62-L75" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.metadata' href='#DimensionalData.Dimensions.Lookups.metadata'><span class="jlbinding">DimensionalData.Dimensions.Lookups.metadata</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
metadata(x) => (object metadata)
metadata(x, dims::Tuple)  => Tuple (Dimension metadata)
metadata(xs::Tuple) => Tuple
```


Returns the metadata for an object or for the specified dimension(s)

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L117-L126" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.name' href='#DimensionalData.Dimensions.name'><span class="jlbinding">DimensionalData.Dimensions.name</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
name(x) => Symbol
name(xs:Tuple) => NTuple{N,Symbol}
name(x, dims::Tuple) => NTuple{N,Symbol}
name(x, dim) => Symbol
```


Get the name of an array or Dimension, or a tuple of of either as a Symbol.

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L129-L139" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.otherdims' href='#DimensionalData.Dimensions.otherdims'><span class="jlbinding">DimensionalData.Dimensions.otherdims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
otherdims(x, query) => Tuple{Vararg{Dimension,N}}
```


Get the dimensions of an object _not_ in `query`.

**Arguments**
- `x`: any object with a `dims` method, a `Tuple` of `Dimension`.
  
- `query`: Tuple or single `Dimension` or dimension `Type`.
  
- `f`: `<:` by default, but can be `>:` to match abstract types to concrete types.
  

A tuple holding the unmatched dimensions is always returned.

**Example**

```julia
julia> using DimensionalData, DimensionalData.Dimensions

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> otherdims(A, X)
(↓ Y, → Z)

julia> otherdims(A, (Y, Z))
(↓ X)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L275-L299" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.dimnum' href='#DimensionalData.Dimensions.dimnum'><span class="jlbinding">DimensionalData.Dimensions.dimnum</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
dimnum(x, query::Tuple) => NTuple{Int}
dimnum(x, query) => Int
```


Get the number(s) of `Dimension`(s) as ordered in the dimensions of an object.

**Arguments**
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
  
- `query`: Tuple, Array or single `Dimension` or dimension `Type`.
  

The return type will be a Tuple of `Int` or a single `Int`, depending on whether `query` is a `Tuple` or single `Dimension`.

**Example**

```julia
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> dimnum(A, (Z, X, Y))
(3, 1, 2)

julia> dimnum(A, Y)
2
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L188-L214" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.hasdim' href='#DimensionalData.Dimensions.hasdim'><span class="jlbinding">DimensionalData.Dimensions.hasdim</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hasdim([f], x, query::Tuple) => NTuple{Bool}
hasdim([f], x, query...) => NTuple{Bool}
hasdim([f], x, query) => Bool
```


Check if an object `x` has dimensions that match or inherit from the `query` dimensions.

**Arguments**
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
  
- `query`: Tuple or single `Dimension` or dimension `Type`.
  
- `f`: `<:` by default, but can be `>:` to match abstract types to concrete types.
  

Check if an object or tuple contains an `Dimension`, or a tuple of dimensions.

**Example**

```julia
julia> using DimensionalData

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> hasdim(A, X)
true

julia> hasdim(A, (Z, X, Y))
(true, true, true)

julia> hasdim(A, Ti)
false
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L236-L265" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Multi-array datasets {#Multi-array-datasets}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.AbstractDimStack' href='#DimensionalData.AbstractDimStack'><span class="jlbinding">DimensionalData.AbstractDimStack</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractDimStack
```


Abstract supertype for dimensional stacks.

These have multiple layers of data, but share dimensions.

Notably, their behaviour lies somewhere between a `DimArray` and a `NamedTuple`:
- indexing with a `Symbol` as in `dimstack[:symbol]` returns a `DimArray` layer.
  
- iteration and `map` apply over array layers, as indexed with a `Symbol`.
  
- `getindex` and many base methods are applied as for `DimArray` - to avoid the need to always use `map`.
  

This design gives very succinct code when working with many-layered, mixed-dimension objects. But it may be jarring initially - the most surprising outcome is that `dimstack[1]` will return a `NamedTuple` of values for the first index in all layers, while `first(dimstack)` will return the first value of the iterator - the `DimArray` for the first layer.

See [`DimStack`](/api/reference#DimensionalData.DimStack) for the concrete implementation. Most methods are defined on the abstract type.

To extend `AbstractDimStack`, implement argument and keyword version of [`rebuild`](/api/reference#DimensionalData.Dimensions.Lookups.rebuild) and also [`rebuild_from_arrays`](/api/reference#DimensionalData.rebuild_from_arrays).

The constructor of an `AbstractDimStack` must accept a `NamedTuple`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/stack.jl#L1-L27" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimStack' href='#DimensionalData.DimStack'><span class="jlbinding">DimensionalData.DimStack</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimStack <: AbstractDimStack

DimStack(data::AbstractDimArray...; kw...)
DimStack(data::Union{AbstractArray,Tuple,NamedTuple}, [dims::DimTuple]; kw...)
DimStack(data::AbstractDimArray; layersfrom, kw...)
```


DimStack holds multiple objects sharing some dimensions, in a `NamedTuple`.

**Arguments**
- `data`: `AbstractDimArray` or an `AbstractArray`, `Tuple` or `NamedTuple` of `AbstractDimArray`s or `AbstractArray`s.
  
- `dims`: `DimTuple` of `Dimension`s. Required when `data` is not `AbstractDimArray`s.
  

**Keywords**
- `name`: `Array` or `Tuple` of `Symbol` names for each layer. By default   the names of `DimArrays` are or keys of a `NamedTuple` are used,    or `:layer1`, `:layer2`, etc.
  
- `metadata`: `AbstractDict` or `NamedTuple` metadata for the stack. 
  
- `layersfrom`: A dimension to slice layers from if data is a single   `DimArray`. Defaults to `nothing`. 
  

(These are for advanced uses)
- `layerdims`: `Array`, `Tuple` or `NamedTuple` of dimension tuples to match the   dimensions of each layer. Dimensions in `layerdims` must also be in `dims`.
  
- `layermetadata`: `Array`, `Tuple` or `NamedTuple` of metadata for each layer.
  
- `refdims`: `NamedTuple` of `Dimension`s for each layer, `()` by default.
  

**Details**

`DimStack` behaviour lies somewhere between a `DimArray` and a `NamedTuple`:
- indexing with a `Symbol` as in `dimstack[:layername]` or using `getproperty`    `dimstack.layername` returns a `DimArray` layer.
  
- A `DimStack` iterates `NamedTuple`s corresponding to the value of each layer. This means functions like `map`, `broadcast`, and `collect` behave as if the `DimStack` were a `DimArray{<:NamedTuple}`
  
- `getindex` or `view` with a `Vector` or `Colon` will return another `DimStack` where   all data layers have been sliced, unless this resolves to a single element, in which case    `getindex` returns a `NamedTuple`
  
- `setindex!` must pass a `Tuple` or `NamedTuple` matching the layers.
  
- many base and `Statistics` methods (`sum`, `mean` etc) will work as for a `DimArray`,   applied to all layers separately.
  
- to apply a function to each layer of a `DimStack`, use [`maplayers`](/api/reference#DimensionalData.maplayers).
  

```julia
function DimStack(A::AbstractDimArray;
    layersfrom=nothing, name=nothing, metadata=metadata(A), refdims=refdims(A), kw...
)
```


For example, here we take the mean over the time dimension for all layers:

```julia
mean(mydimstack; dims=Ti)
```


And this equivalent to:

```julia
maplayers(A -> mean(A; dims=Ti), mydimstack)
```


This design gives succinct code when working with many-layered, mixed-dimension objects.

But it may be jarring initially - the most surprising outcome is that `dimstack[1]` will return a `NamedTuple` of values for the first index in all layers, while `first(dimstack)` will return the first value of the iterator - the `DimArray` for the first layer.

`DimStack` can be constructed from multiple `AbstractDimArray` or a `NamedTuple` of `AbstractArray` and a matching `dims` tuple.

Most `Base` and `Statistics` methods that apply to `AbstractArray` can be used on all layers of the stack simulataneously. The result is a `DimStack`, or a `NamedTuple` if methods like `mean` are used without `dims` arguments, and return a single non-array value.

**Example**

```julia
julia> using DimensionalData

julia> A = [1.0 2.0 3.0; 4.0 5.0 6.0];

julia> dimz = (X([:a, :b]), Y(10.0:10.0:30.0))
(↓ X [:a, :b],
→ Y 10.0:10.0:30.0)

julia> da1 = DimArray(1A, dimz; name=:one);

julia> da2 = DimArray(2A, dimz; name=:two);

julia> da3 = DimArray(3A, dimz; name=:three);

julia> s = DimStack(da1, da2, da3);

julia> s[At(:b), At(10.0)]
(one = 4.0, two = 8.0, three = 12.0)

julia> s[X(At(:a))] isa DimStack
true
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/stack.jl#L311-L413" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.maplayers' href='#DimensionalData.maplayers'><span class="jlbinding">DimensionalData.maplayers</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
maplayers(f, s::Union{AbstractDimStack,NamedTuple}...)
```


Map function `f` over the layers of `s`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/stack.jl#L227-L231" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## DimTree {#DimTree}

These objects and methods are still experimental and subject to breaking changes _without_ breaking versions.
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.AbstractDimTree' href='#DimensionalData.AbstractDimTree'><span class="jlbinding">DimensionalData.AbstractDimTree</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractDimTree
```


Abstract supertype for tree-like dimensional data.

These objects are mutable and fast compiled, as an alternative to the flat, immutable `AbstractDimStack`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/tree/tree.jl#L1-L8" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimTree' href='#DimensionalData.DimTree'><span class="jlbinding">DimensionalData.DimTree</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimTree
```


A nested tree of dimensional arrays.

Still in expermental stage: breaking changes may occurr without  a major version bump to DimensionalData. Please report any issues and  feedback on GitHub to push this towards a stable implementation.

`DimTree` is loosely typed and based on `OrderedDict` rather than `NamedTuple` of `DimStack`, so it is slower to index but very fast to compile, and very flexible.

Trees can be nested indefinately, branches inheriting dimensions from the tree. 

**Getting and setting layers and branches**

Local layers are accessed with `getindex` and a `Symbol`, returning a `DimArray`, e.g. `dt[:layer]` or a `DimStack` with `dt[(:layer1, :layer2)]`. 

Branches are accessed with `getproperty`, e.g. `dt.branch`. 

Layers and branches can be set with `setindex!` and `setproperty!` respectively.

**Dimensions and branches**

Dimensions that are shared with the base of the tree must be identical. They are stored at the base level of the tree that they are used in,  and propagate out to branches.

Within a branch, all layers use a subset of the dimensions available to the branch.

Accross branches, there may be versions of the same dimensions with  different lookup values. These may cover different extents, resolutions,  or whatever properties of lookups are required to vary.

This property can be used for tiles with differen X/Y extents or pyramid layers with different resolutions, for example.

**Example**

`julia xdim, ydim = X(1:10), Y(1:15),  z1, z2 = Z([:a, :b, :c]), Z([:d, :e, :f]) a = rand(xdim, ydim) b = rand(Float32, xdim, ydim) c = rand(Int, xdim, ydim, z1) d = rand(Int, xdim, z2) DimTree(a, b)``


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/tree/tree.jl#L328-L381" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.prune' href='#DimensionalData.prune'><span class="jlbinding">DimensionalData.prune</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
prune(dt::AbstractDimTree; keep::Union{Symbol,Pair{Symbol}})
```


Prune a tree to remove branches.

`keep` specifies a branch to incorprate into the tree, after it is also pruned. A `Pair` can be used to specify a branch to keep in that branch, and these may be chained as e.g. `keep=:branch => :smallbranch => :leaf`.

`prune` results in a DimTree that is completely convertable to a  [`DimStack`](/api/reference#DimensionalData.DimStack), as it no longer has branches with divergent dimensions.

**Example**

```julia
pruned = prune(dimtree; keep=:branch => :leaf)
DimStack(pruned)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/tree/tree.jl#L286-L305" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Dimension generators {#Dimension-generators}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimIndices' href='#DimensionalData.DimIndices'><span class="jlbinding">DimensionalData.DimIndices</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimIndices <: AbstractArray

DimIndices(x)
DimIndices(dims::Tuple)
DimIndices(dims::Dimension)
```


Like `CartesianIndices`, but for `Dimension`s. Behaves as an `Array` of `Tuple` of `Dimension(i)` for all combinations of the axis indices of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and is especially useful when combined with `otherdims`, to iterate over the indices of unknown dimension.

`DimIndices` can be used directly in `getindex` like `CartesianIndices`, and freely mixed with individual `Dimension`s or tuples of `Dimension`.

**Example**

Index a `DimArray` with `DimIndices`.

Notice that unlike CartesianIndices, it doesn&#39;t matter if the dimensions are not in the same order. Or even if they are not all contained in each.

```julia
julia> A = rand(Y(0.0:0.3:1.0), X('a':'f'))
┌ 4×6 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.3:0.9 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':1:'f' ForwardOrdered
└──────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'b'       'c'        'd'        'e'       'f'
 0.0  0.9063    0.253849  0.0991336  0.0320967  0.774092  0.893537
 0.3  0.443494  0.334152  0.125287   0.350546   0.183555  0.354868
 0.6  0.745673  0.427328  0.692209   0.930332   0.297023  0.131798
 0.9  0.512083  0.867547  0.136551   0.959434   0.150155  0.941133

julia> di = DimIndices((X(1:2:4), Y(1:2:4)))
┌ 2×2 DimIndices{Tuple{X{Int64}, Y{Int64}}, 2} ┐
├──────────────────────────────────────── dims ┤
  ↓ X 1:2:3,
  → Y 1:2:3
└──────────────────────────────────────────────┘
 ↓ →  1                3
 1     (↓ X 1, → Y 1)   (↓ X 1, → Y 3)
 3     (↓ X 3, → Y 1)   (↓ X 3, → Y 3)

julia> A[di] # Index A with these indices
┌ 2×2 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.6:0.6 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':2:'c' ForwardOrdered
└──────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'c'
 0.0  0.9063    0.0991336
 0.6  0.745673  0.692209
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/dimindices.jl#L30-L87" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimSelectors' href='#DimensionalData.DimSelectors'><span class="jlbinding">DimensionalData.DimSelectors</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimSelectors <: AbstractArray

DimSelectors(x; selectors, atol...)
DimSelectors(dims::Tuple; selectors, atol...)
DimSelectors(dims::Dimension; selectors, atol...)
```


Like [`DimIndices`](/api/reference#DimensionalData.DimIndices), but returns `Dimensions` holding the chosen [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s.

Indexing into another `AbstractDimArray` with `DimSelectors` is similar to doing an interpolation.

**Keywords**
- `selectors`: `Near`, `At` or `Contains`, or a mixed tuple of these. `At` is the default, meaning only exact or within `atol` values are used.
  
- `atol`: used for `At` selectors only, as the `atol` value. Ignored where    `atol` is set inside individual `At` selectors.
  

**Example**

Here we can interpolate a `DimArray` to the lookups of another `DimArray` using `DimSelectors` with `Near`. This is essentially equivalent to nearest neighbour interpolation.

```julia
julia> A = rand(X(1.0:3.0:30.0), Y(1.0:5.0:30.0), Ti(1:2));

julia> target = rand(X(1.0:10.0:30.0), Y(1.0:10.0:30.0));

julia> A[DimSelectors(target; selectors=Near), Ti=2]
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴────────────────────────────────────── dims ┐
  ↓ X Sampled{Float64} [1.0, …, 22.0] ForwardOrdered Irregular Points,
  → Y Sampled{Float64} [1.0, …, 21.0] ForwardOrdered Irregular Points
└───────────────────────────────────────────────────────────────────────┘
  ↓ →  1.0        11.0       21.0
  1.0  0.691162    0.218579   0.539076
 10.0  0.0303789   0.420756   0.485687
 22.0  0.0967863   0.864856   0.870485
```


Using `At` would make sure we only use exact interpolation, while `Contains` with sampling of `Intervals` would make sure that each values is taken only from an Interval that is present in the lookups.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/dimindices.jl#L182-L228" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimPoints' href='#DimensionalData.DimPoints'><span class="jlbinding">DimensionalData.DimPoints</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimPoints <: AbstractArray

DimPoints(x; order)
DimPoints(dims::Tuple; order)
DimPoints(dims::Dimension; order)
```


Like `CartesianIndices`, but for the point values of the dimension index. Behaves as an `Array` of `Tuple` lookup values (whatever they are) for all combinations of the lookup values of `dims`.

Either a `Dimension`, a `Tuple` of `Dimension` or an object `x` that defines a `dims` method can be passed in.

**Keywords**
- `order`: determines the order of the points, the same as the order of `dims` by default.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/dimindices.jl#L135-L152" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Tables.jl/TableTraits.jl interface {#Tables.jl/TableTraits.jl-interface}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.AbstractDimTable' href='#DimensionalData.AbstractDimTable'><span class="jlbinding">DimensionalData.AbstractDimTable</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractDimTable <: Tables.AbstractColumns
```


Abstract supertype for dim tables


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/tables.jl#L1-L5" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimTable' href='#DimensionalData.DimTable'><span class="jlbinding">DimensionalData.DimTable</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimTable <: AbstractDimTable

DimTable(s::AbstractDimStack; mergedims=nothing)
DimTable(x::AbstractDimArray; layersfrom=nothing, mergedims=nothing)
DimTable(xs::Vararg{AbstractDimArray}; layernames=nothing, mergedims=nothing)
```


Construct a Tables.jl/TableTraits.jl compatible object out of an `AbstractDimArray` or `AbstractDimStack`.

This table will have columns for the array data and columns for each `Dimension` index, as a [`DimColumn`]. These are lazy, and generated as required.

Column names are converted from the dimension types using [`DimensionalData.name`](/api/reference#DimensionalData.Dimensions.name). This means type `Ti` becomes the column name `:Ti`, and `Dim{:custom}` becomes `:custom`.

To get dimension columns, you can index with `Dimension` (`X()`) or `Dimension` type (`X`) as well as the regular `Int` or `Symbol`.

**Keywords**
- `mergedims`: Combine two or more dimensions into a new dimension.
  
- `layersfrom`: Treat a dimension of an `AbstractDimArray` as layers of an `AbstractDimStack`.
  

**Example**

```julia
julia> using DimensionalData, Tables

julia> a = DimArray(ones(16, 16, 3), (X, Y, Dim{:band}))
┌ 16×16×3 DimArray{Float64, 3} ┐
├──────────────────────── dims ┤
  ↓ X, → Y, ↗ band
└──────────────────────────────┘
[:, :, 1]
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 ⋮                        ⋮              ⋱       ⋮                        ⋮
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0     1.0  1.0  1.0  1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0  1.0  1.0  1.0  1.0  …  1.0  1.0  1.0  1.0  1.0  1.0  1.0

julia> 

```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/tables.jl#L38-L92" target="_blank" rel="noreferrer">source</a></Badge>

</details>


# Group by methods {#Group-by-methods}

For transforming DimensionalData objects:
<details class='jldocstring custom-block' open>
<summary><a id='DataAPI.groupby' href='#DataAPI.groupby'><span class="jlbinding">DataAPI.groupby</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
groupby(A::Union{AbstractDimArray,AbstractDimStack}, dims::Pair...)
groupby(A::Union{AbstractDimArray,AbstractDimStack}, dims::Dimension{<:Callable}...)
```


Group `A` by grouping functions or [`Bins`](/api/reference#DimensionalData.Bins) over multiple dimensions.

**Arguments**
- `A`: any `AbstractDimArray` or `AbstractDimStack`.
  
- `dims`: `Pair`s such as `groups = groupby(A, :dimname => groupingfunction)` or wrapped [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension)s like `groups = groupby(A, DimType(groupingfunction))`. Instead of a grouping function [`Bins`](/api/reference#DimensionalData.Bins) can be used to specify group bins.
  

**Return value**

A [`DimGroupByArray`](/api/reference#DimensionalData.DimGroupByArray) is returned, which is basically a regular `AbstractDimArray` but holding the grouped `AbstractDimArray` or `AbstractDimStack`. Its `dims` hold the sorted values returned by the grouping function/s.

Base julia and package methods work on `DimGroupByArray` as for any other `AbstractArray` of `AbstractArray`.

It is common to broadcast or `map` a reducing function over groups, such as `mean` or `sum`, like `mean.(groups)` or `map(mean, groups)`. This will return a regular `DimArray`, or `DimGroupByArray` if `dims` keyword is used in the reducing function or it otherwise returns an `AbstractDimArray` or `AbstractDimStack`.

**Example**

Group some data along the time dimension:

```julia
julia> using DimensionalData, Dates

julia> A = rand(X(1:0.1:20), Y(1:20), Ti(DateTime(2000):Day(3):DateTime(2003)));

julia> groups = groupby(A, Ti => month) # Group by month
┌ 12-element DimGroupByArray{DimArray{Float64,3},1} ┐
├───────────────────────────────────────────────────┴──────── dims ┐
  ↓ Ti Sampled{Int64} [1, …, 12] ForwardOrdered Irregular Points
├──────────────────────────────────────────────────────── metadata ┤
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>month
├───────────────────────────────────────────────────┴── group dims ┐
  ↓ X, → Y, ↗ Ti
└──────────────────────────────────────────────────────────────────┘
  1  191×20×32 DimArray
  2  191×20×28 DimArray
  ⋮
 12  191×20×31 DimArray
```


And take the mean:

```julia
julia> groupmeans = mean.(groups) # Take the monthly mean
┌ 12-element DimArray{Float64, 1} ┐
├─────────────────────────────────┴────────────────────────── dims ┐
  ↓ Ti Sampled{Int64} [1, …, 12] ForwardOrdered Irregular Points
├──────────────────────────────────────────────────────── metadata ┤
  Dict{Symbol, Any} with 1 entry:
  :groupby => :Ti=>month
└──────────────────────────────────────────────────────────────────┘
  1  0.500064
  2  0.499762
  3  0.500083
  ⋮
 10  0.500874
 11  0.498704
 12  0.50047
```


Calculate daily anomalies from the monthly mean. Notice we map a broadcast `.-` rather than `-`. This is because the size of the arrays to not match after application of `mean`.

```julia
julia> map(.-, groupby(A, Ti=>month), mean.(groupby(A, Ti=>month), dims=Ti));
```


Or do something else with Y:

```julia
julia> groupmeans = mean.(groupby(A, Ti=>month, Y=>isodd))
┌ 12×2 DimArray{Float64, 2} ┐
├───────────────────────────┴──────────────────────────────── dims ┐
  ↓ Ti Sampled{Int64} [1, …, 12] ForwardOrdered Irregular Points,
  → Y Sampled{Bool} [false, true] ForwardOrdered Irregular Points
├──────────────────────────────────────────────────────── metadata ┤
  Dict{Symbol, Any} with 1 entry:
  :groupby => (:Ti=>month, :Y=>isodd)
└──────────────────────────────────────────────────────────────────┘
  ↓ →  false         true
  1        0.499594     0.500533
  2        0.498145     0.501379
  ⋮
 11        0.498606     0.498801
 12        0.501643     0.499298
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L219-L319" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimGroupByArray' href='#DimensionalData.DimGroupByArray'><span class="jlbinding">DimensionalData.DimGroupByArray</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DimGroupByArray <: AbstractDimArray
```


`DimGroupByArray` is essentially a `DimArray` but holding the results of a `groupby` operation.

Its dimensions are the sorted results of the grouping functions used in `groupby`.

This wrapper allows for specialisations on later broadcast or reducing operations, e.g. for chunk reading with DiskArrays.jl, because we know the data originates from a single array.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L1-L13" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Bins' href='#DimensionalData.Bins'><span class="jlbinding">DimensionalData.Bins</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Bins(f, bins; labels, pad)
Bins(bins; labels, pad)
```


Specify bins to reduce groups after applying function `f`.
- `f`: a grouping function of the lookup values, by default `identity`.
  
- `bins`:
  - an `Integer` will divide the group values into equally spaced sections.
    
  - an `AbstractArray` of values will be treated as exact   matches for the return value of `f`. For example, `1:3` will create 3 bins - 1, 2, 3.
    
  - an `AbstractArray` of `IntervalSets.Interval` can be used to   explicitly define the intervals. Overlapping intervals have undefined behaviour.
    
  

**Keywords**
- `pad`: fraction of the total interval to pad at each end when `Bins` contains an  `Integer`. This avoids losing the edge values. Note this is a messy solution -  it will often be prefereble to manually specify a `Vector` of chosen `Interval`s  rather than relying on passing an `Integer` and `pad`.
  
- `labels`: a list of descriptive labels for the bins. The labels need to have the same length as `bins`.
  

When the return value of `f` is a tuple, binning is applied to the _last_ value of the tuples.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L104-L127" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.ranges' href='#DimensionalData.ranges'><span class="jlbinding">DimensionalData.ranges</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
ranges(A::AbstractRange{<:Integer})
```


Generate a `Vector` of `UnitRange` with length `step(A)`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L449-L453" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.intervals' href='#DimensionalData.intervals'><span class="jlbinding">DimensionalData.intervals</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
intervals(A::AbstractRange)
```


Generate a `Vector` of `UnitRange` with length `step(A)`


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L442-L446" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.CyclicBins' href='#DimensionalData.CyclicBins'><span class="jlbinding">DimensionalData.CyclicBins</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
CyclicBins(f; cycle, start, step, labels)
```


Cyclic bins to reduce groups after applying function `f`. Groups can wrap around the cycle. This is used for grouping in [`seasons`](/api/reference#DimensionalData.seasons), [`months`](/api/reference#DimensionalData.months) and [`hours`](/api/reference#DimensionalData.hours) but can also be used for custom cycles.
- `f`: a grouping function of the lookup values, by default `identity`.
  

**Keywords**
- `cycle`: the length of the cycle, in return values of `f`.
  
- `start`: the start of the cycle: a return value of `f`.
  
- `step` the number of sequential values to group.
  
- `labels`: either a vector of labels matching the number of groups,    or a function that generates labels from `Vector{Int}` of the selected bins.
  

When the return value of `f` is a tuple, binning is applied to the _last_ value of the tuples.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L142-L160" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.seasons' href='#DimensionalData.seasons'><span class="jlbinding">DimensionalData.seasons</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
seasons(; [start=Dates.December, labels])
```


Generates `CyclicBins` for three month periods.

**Keywords**
- `start`: By default seasons start in December, but any integer `1:12` can be used.
  
- `labels`: either a vector of four labels, or a function that generates labels from `Vector{Int}` of the selected quarters.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L175-L184" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.months' href='#DimensionalData.months'><span class="jlbinding">DimensionalData.months</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
months(step; [start=Dates.January, labels])
```


Generates `CyclicBins` for grouping to arbitrary month periods.  These can wrap around the end of a year.
- `step` the number of months to group.
  

**Keywords**
- `start`: By default months start in January, but any integer `1:12` can be used.
  
- `labels`: either a vector of labels matching the number of groups,    or a function that generates labels from `Vector{Int}` of the selected months.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L187-L200" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.hours' href='#DimensionalData.hours'><span class="jlbinding">DimensionalData.hours</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hours(step; [start=0, labels])
```


Generates `CyclicBins` for grouping to arbitrary hour periods.  These can wrap around the end of the day.
- `steps` the number of hours to group.
  

**Keywords**
- `start`: By default seasons start at `0`, but any integer `1:24` can be used.
  
- `labels`: either a vector of four labels, or a function that generates labels   from `Vector{Int}` of the selected hours of the day.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/groupby.jl#L203-L216" target="_blank" rel="noreferrer">source</a></Badge>

</details>


# Utility methods {#Utility-methods}

For transforming DimensionalData objects:
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.set' href='#DimensionalData.Dimensions.Lookups.set'><span class="jlbinding">DimensionalData.Dimensions.Lookups.set</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
set(x, val)
set(x, args::Pairs...) => x with updated field/s
set(x, args...; kw...) => x with updated field/s
set(x, args::Tuple{Vararg{Dimension}}; kw...) => x with updated field/s

set(dim::Dimension, index::AbstractArray) => Dimension
set(dim::Dimension, lookup::Lookup) => Dimension
set(dim::Dimension, lookupcomponent::LookupTrait) => Dimension
set(dim::Dimension, metadata::AbstractMetadata) => Dimension
```


Set the properties of an object, its internal data or the traits of its dimensions and lookup index.

As DimensionalData is so strongly typed you do not need to specify what field of a [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) to `set` - there is no ambiguity.

To set fields of a `Lookup` you need to specify the dimension. This can be done using `X => val` pairs, `X = val` keyword arguments, or `X(val)` wrapped arguments.

You can also set the fields of all dimensions by simply passing a single [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) or lookup trait - it will be set for all dimensions.

When a `Dimension` or `Lookup` is passed to `set` to replace the existing ones, fields that are not set will keep their original values.

**Notes:**

Changing a lookup index range/vector will also update the step size and order where applicable.

Setting the [`Order`](/api/lookuparrays#Order) like `ForwardOrdered` will _not_ reverse the array or dimension to match. Use `reverse` and [`reorder`](/object_modification#reorder) to do this.

**Examples**

```julia
julia> using DimensionalData; const DD = DimensionalData;

julia> da = DimArray(zeros(3, 4), (custom=10.0:010.0:30.0, Z=-20:010.0:10.0));

julia> set(da, ones(3, 4))
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────────────── dims ┐
  ↓ custom Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Regular Points,
  → Z Sampled{Float64} -20.0:10.0:10.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────────┘
  ↓ →  -20.0  -10.0  0.0  10.0
 10.0    1.0    1.0  1.0   1.0
 20.0    1.0    1.0  1.0   1.0
 30.0    1.0    1.0  1.0   1.0
```


Change the `Dimension` wrapper type:

```julia
julia> set(da, :Z => Ti, :custom => Z)
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────────── dims ┐
  ↓ Z Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Regular Points,
  → Ti Sampled{Float64} -20.0:10.0:10.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────┘
  ↓ →  -20.0  -10.0  0.0  10.0
 10.0    0.0    0.0  0.0   0.0
 20.0    0.0    0.0  0.0   0.0
 30.0    0.0    0.0  0.0   0.0
```


Change the lookup `Vector`:

```julia
julia> set(da, Z => [:a, :b, :c, :d], :custom => [4, 5, 6])
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴────────────────────────────────── dims ┐
  ↓ custom Sampled{Int64} [4, …, 6] ForwardOrdered Regular Points,
  → Z Sampled{Symbol} [:a, …, :d] ForwardOrdered Regular Points
└───────────────────────────────────────────────────────────────────┘
 ↓ →   :a   :b   :c   :d
 4    0.0  0.0  0.0  0.0
 5    0.0  0.0  0.0  0.0
 6    0.0  0.0  0.0  0.0
```


Change the `Lookup` type:

```julia
julia> set(da, Z=DD.NoLookup(), custom=DD.Sampled())
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴───────────────────────────────────────── dims ┐
  ↓ custom Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Regular Points,
  → Z
└──────────────────────────────────────────────────────────────────────────┘
 10.0  0.0  0.0  0.0  0.0
 20.0  0.0  0.0  0.0  0.0
 30.0  0.0  0.0  0.0  0.0
```


Change the `Sampling` trait:

```julia
julia> set(da, :custom => DD.Irregular(10, 12), Z => DD.Regular(9.9))
┌ 3×4 DimArray{Float64, 2} ┐
├──────────────────────────┴─────────────────────────────────────────── dims ┐
  ↓ custom Sampled{Float64} 10.0:10.0:30.0 ForwardOrdered Irregular Points,
  → Z Sampled{Float64} -20.0:10.0:10.0 ForwardOrdered Regular Points
└────────────────────────────────────────────────────────────────────────────┘
  ↓ →  -20.0  -10.0  0.0  10.0
 10.0    0.0    0.0  0.0   0.0
 20.0    0.0    0.0  0.0   0.0
 30.0    0.0    0.0  0.0   0.0
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/set.jl#L3-L113" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.rebuild' href='#DimensionalData.Dimensions.Lookups.rebuild'><span class="jlbinding">DimensionalData.Dimensions.Lookups.rebuild</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
rebuild(x; kw...)
```


Rebuild an object struct with updated field values.

`x` can be a `AbstractDimArray`, a `Dimension`, `Lookup` or other custom types.

This is an abstraction that allows inbuilt and custom types to be rebuilt to update their fields, as most objects in DimensionalData.jl are immutable.

Rebuild is mostly automated using `ConstructionBase.setproperties`.  It should only be defined if your object has fields with  with different names to DimensionalData objects. Try not to do that!

The arguments required are defined for the abstract type that has a `rebuild` method.

**`AbstractBasicDimArray`:**
- `dims`: a `Tuple` of `Dimension` 
  

**`AbstractDimArray`:**
- `data`: the parent object - an `AbstractArray`
  
- `dims`: a `Tuple` of `Dimension` 
  
- `refdims`: a `Tuple` of `Dimension` 
  
- `name`: A Symbol, or `NoName` and `Name` on GPU.
  
- `metadata`: A `Dict`-like object
  

**`AbstractDimStack`:**
- `data`: the parent object, often a `NamedTuple`
  
- `dims`, `refdims`, `metadata`
  

**`Dimension`:**
- `val`: anything.
  

**`Lookup`:**
- `data`: the parent object, an `AbstractArray`
  
- Note: argument `rebuild` is deprecated on `AbstractDimArray` and 
  

`AbstractDimStack` in favour of always using the keyword version.  In future the argument version will only be used on `Dimension`, which only have one argument.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L3-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.modify' href='#DimensionalData.modify'><span class="jlbinding">DimensionalData.modify</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
modify(f, A::AbstractDimArray) => AbstractDimArray
modify(f, s::AbstractDimStack) => AbstractDimStack
modify(f, dim::Dimension) => Dimension
modify(f, x, lookupdim::Dimension) => typeof(x)
```


Modify the parent data, rebuilding the object wrapper without change. `f` must return a `AbstractArray` of the same size as the original.

This method is mostly useful as a way of swapping the parent array type of an object.

**Example**

If we have a previously-defined `DimArray`, we can copy it to an Nvidia GPU with:

```julia
A = DimArray(rand(100, 100), (X, Y))
modify(CuArray, A)
```


This also works for all the data layers in a `DimStack`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/utils.jl#L64-L86" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.@d' href='#DimensionalData.@d'><span class="jlbinding">DimensionalData.@d</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@d broadcast_expression options
```


Dimensional broadcast macro extending Base Julia broadcasting to work with missing and permuted dimensions.

Will permute and reshape singleton dimensions so that all [`AbstractDimArray`](/api/reference#DimensionalData.AbstractDimArray) in a broadcast will broadcast over matching dimensions.

It is possible to pass options as the second argument of  the macro to control the behaviour, as a single assignment or as a NamedTuple. Options names must be written explicitly, not passed in namedtuple variable.

**Options**
- `dims`: Pass a Tuple of `Dimension`s, `Dimension` types or `Symbol`s   to fix the dimension order of the output array. Otherwise dimensions   will be in order of appearance. If dims with lookups are passed, these will    be applied to the returned array with  `set`.
  
- `strict`: `true` or `false`. Check that all lookup values match explicitly.
  

All other keywords are passed to `DimensionalData.rebuild`. This means `name`, `metadata`, etc for the returned array can be set here,  or for example `missingval` in Rasters.jl.

**Example**

```julia
using DimensionalData
da1 = ones(X(3))
da2 = fill(2, Y(4), X(3))

@d da1 .* da2
@d da1 .* da2 .+ 5 dims=(Y, X)
@d da1 .* da2 .+ 5 (dims=(Y, X), strict=false, name=:testname)
```


**Use with `@.`**

`@d` does not imply `@.`. You need to specify each broadcast.  But `@.` can be used with `@d` as the _inner_ macro.

```julia
using DimensionalData
da1 = ones(X(3))
da2 = fill(2, Y(4), X(3))

@d @. da1 * da2
# Use parentheses around `@.` if you need to pass options
@d (@. da1 * da2 .+ 5) dims=(Y, X)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/broadcast.jl#L104-L158" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.broadcast_dims' href='#DimensionalData.broadcast_dims'><span class="jlbinding">DimensionalData.broadcast_dims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
broadcast_dims(f, sources::AbstractDimArray...) => AbstractDimArray
```


Broadcast function `f` over the `AbstractDimArray`s in `sources`, permuting and reshaping dimensions to match where required. The result will contain all the dimensions in  all passed in arrays in the order in which they are found.

**Arguments**
- `sources`: `AbstractDimArrays` to broadcast over with `f`.
  

This is like broadcasting over every slice of `A` if it is sliced by the dimensions of `B`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/utils.jl#L110-L123" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.broadcast_dims!' href='#DimensionalData.broadcast_dims!'><span class="jlbinding">DimensionalData.broadcast_dims!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
broadcast_dims!(f, dest::AbstractDimArray, sources::AbstractDimArray...) => dest
```


Broadcast function `f` over the `AbstractDimArray`s in `sources`, writing to `dest`.  `sources` are permuting and reshaping dimensions to match where required.

The result will contain all the dimensions in all passed in arrays, in the order in which they are found.

**Arguments**
- `dest`: `AbstractDimArray` to update.
  
- `sources`: `AbstractDimArrays` to broadcast over with `f`.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/utils.jl#L141-L154" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.mergedims' href='#DimensionalData.mergedims'><span class="jlbinding">DimensionalData.mergedims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
mergedims(old_dims => new_dim) => Dimension
```


Return a dimension `new_dim` whose indices are a [`MergedLookup`](/api/lookuparrays#DimensionalData.Dimensions.MergedLookup) of the indices of `old_dims`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L773-L778" target="_blank" rel="noreferrer">source</a></Badge>



```julia
mergedims(dims, old_dims => new_dim, others::Pair...) => dims_new
```


If dimensions `old_dims`, `new_dim`, etc. are found in `dims`, then return new `dims_new` where all dims in `old_dims` have been combined into a single dim `new_dim`. The returned dimension will keep only the name of `new_dim`. Its coords will be a [`MergedLookup`](/api/lookuparrays#DimensionalData.Dimensions.MergedLookup) of the coords of the dims in `old_dims`. New dimensions are always placed at the end of `dims_new`. `others` contains other dimension pairs to be merged.

**Example**

```julia
julia> using DimensionalData

julia> ds = (X(0:0.1:0.4), Y(10:10:100), Ti([0, 3, 4]))
(↓ X 0.0:0.1:0.4,
→ Y 10:10:100,
↗ Ti [0, …, 4])

julia> mergedims(ds, (X, Y) => :space)
(↓ Ti [0, …, 4],
→ space MergedLookup{Tuple{Float64, Int64}} [(0.0, 10), …, (0.4, 100)] (↓ X, → Y))
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L784-L807" target="_blank" rel="noreferrer">source</a></Badge>



```julia
mergedims(A::AbstractDimArray, dim_pairs::Pair...) => AbstractDimArray
mergedims(A::AbstractDimStack, dim_pairs::Pair...) => AbstractDimStack
```


Return a new array or stack whose dimensions are the result of [`mergedims(dims(A), dim_pairs)`](/api/reference#DimensionalData.mergedims).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L837-L842" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.unmergedims' href='#DimensionalData.unmergedims'><span class="jlbinding">DimensionalData.unmergedims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
unmergedims(merged_dims::Tuple{Vararg{Dimension}}) => Tuple{Vararg{Dimension}}
```


Return the unmerged dimensions from a tuple of merged dimensions. However, the order of the original dimensions are not necessarily preserved.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L854-L858" target="_blank" rel="noreferrer">source</a></Badge>



```julia
unmergedims(A::AbstractDimArray, original_dims) => AbstractDimArray
unmergedims(A::AbstractDimStack, original_dims) => AbstractDimStack
```


Return a new array or stack whose dimensions are restored to their original prior to calling [`mergedims(A, dim_pairs)`](/api/reference#DimensionalData.mergedims).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/array.jl#L865-L870" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.reorder' href='#DimensionalData.reorder'><span class="jlbinding">DimensionalData.reorder</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
reorder(A::Union{AbstractDimArray,AbstractDimStack}, order::Pair...)
reorder(A::Union{AbstractDimArray,AbstractDimStack}, order)
reorder(A::Dimension, order::Order)
```


Reorder every dims index/array to `order`, or reorder index for the given dimension(s) in `order`.

`order` can be an [`Order`](/api/lookuparrays#Order), `Dimension => Order` pairs. A Tuple of Dimensions or any object that defines `dims` can be used in which case the dimensions of this object are used for reordering.

If no axis reversal is required the same objects will be returned, without allocation.

**Example**

```julia
using DimensionalData

# Create a DimArray
da = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(300:-100:100)))

# Reverse it
rev = reverse(da, dims=Y)

# using `da` in reorder will return it to the original order
reorder(rev, da) == da

# output
true
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/utils.jl#L2-L33" target="_blank" rel="noreferrer">source</a></Badge>

</details>


# Global lookup strictness settings {#Global-lookup-strictness-settings}

Control how strict DimensionalData when comparing [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup)s before doing broadcasts and matrix multipications.

In some cases (especially `DimVector` and small `DimArray`) checking  lookup values match may be too costly compared to the operations. You can turn check the current setting and turn them on or off with these methods.
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.strict_broadcast' href='#DimensionalData.strict_broadcast'><span class="jlbinding">DimensionalData.strict_broadcast</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
strict_broadcast()
```


Check if strict broadcasting checks are active.

With `strict=true` we check [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) [`Order`](/api/lookuparrays#Order) and values  before brodcasting, to ensure that dimensions match closely. 

An exception to this rule is when dimension are of length one,  as these is ignored in broadcasts.

We always check that dimension names match in broadcasts. If you don&#39;t want this either, explicitly use `parent(A)` before broadcasting to remove the `AbstractDimArray` wrapper completely.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/broadcast.jl#L16-L22" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.strict_broadcast!' href='#DimensionalData.strict_broadcast!'><span class="jlbinding">DimensionalData.strict_broadcast!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
strict_broadcast!(x::Bool)
```


Set global broadcasting checks to `strict`, or not for all `AbstractDimArray`.

With `strict=true` we check [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) [`Order`](/api/lookuparrays#Order) and values  before brodcasting, to ensure that dimensions match closely. 

An exception to this rule is when dimension are of length one,  as these is ignored in broadcasts.

We always check that dimension names match in broadcasts. If you don&#39;t want this either, explicitly use `parent(A)` before broadcasting to remove the `AbstractDimArray` wrapper completely.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/broadcast.jl#L25-L31" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.strict_matmul' href='#DimensionalData.strict_matmul'><span class="jlbinding">DimensionalData.strict_matmul</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
strict_matmul()
```


Check if strickt broadcasting checks are active.

With `strict=true` we check [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) [`Order`](/api/lookuparrays#Order) and values  before attempting matrix multiplication, to ensure that dimensions match closely. 

We always check that dimension names match in matrix multiplication. If you don&#39;t want this either, explicitly use `parent(A)` before multiplying to remove the `AbstractDimArray` wrapper completely.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/matmul.jl#L13-L19" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.strict_matmul!' href='#DimensionalData.strict_matmul!'><span class="jlbinding">DimensionalData.strict_matmul!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
strict_matmul!(x::Bool)
```


Set global matrix multiplication checks to `strict`, or not for all `AbstractDimArray`.

With `strict=true` we check [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) [`Order`](/api/lookuparrays#Order) and values  before attempting matrix multiplication, to ensure that dimensions match closely. 

We always check that dimension names match in matrix multiplication. If you don&#39;t want this either, explicitly use `parent(A)` before multiplying to remove the `AbstractDimArray` wrapper completely.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/matmul.jl#L22-L28" target="_blank" rel="noreferrer">source</a></Badge>

</details>


Base methods
<details class='jldocstring custom-block' open>
<summary><a id='Base.cat' href='#Base.cat'><span class="jlbinding">Base.cat</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
Base.cat(stacks::AbstractDimStack...; [keys=keys(stacks[1])], dims)
```


Concatenate all or a subset of layers for all passed in stacks.

**Keywords**
- `keys`: `Tuple` of `Symbol` for the stack keys to concatenate.
  
- `dims`: Dimension of child array to concatenate on.
  

**Example**

Concatenate the :sea_surface_temp and :humidity layers in the time dimension:

```julia
cat(stacks...; keys=(:sea_surface_temp, :humidity), dims=Ti)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/methods.jl#L98-L115" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Base.copy!' href='#Base.copy!'><span class="jlbinding">Base.copy!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
Base.copy!(dst::AbstractArray, src::AbstractDimStack, key::Key)
```


Copy the stack layer `key` to `dst`, which can be any `AbstractArray`.

**Example**

Copy the `:humidity` layer from `stack` to `array`.

```julia
copy!(array, stack, :humidity)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/methods.jl#L3-L15" target="_blank" rel="noreferrer">source</a></Badge>



```julia
Base.copy!(dst::AbstractDimStack, src::AbstractDimStack, [keys=keys(dst)])
```


Copy all or a subset of layers from one stack to another.

**Example**

Copy just the `:sea_surface_temp` and `:humidity` layers from `src` to `dst`.

```julia
copy!(dst::AbstractDimStack, src::AbstractDimStack, keys=(:sea_surface_temp, :humidity))
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/methods.jl#L18-L30" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='Base.eachslice' href='#Base.eachslice'><span class="jlbinding">Base.eachslice</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
Base.eachslice(A::AbstractDimArray; dims,drop=true)
```


Create a generator that iterates over dimensions `dims` of `A`, returning arrays that select all the data from the other dimensions in `A` using views.

The generator has `size` and `axes` equivalent to those of the provided `dims` if `drop=true`. Otherwise it will have the same dimensionality as the underlying array with inner dimensions having size 1.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/methods.jl#L133-L141" target="_blank" rel="noreferrer">source</a></Badge>



```julia
Base.eachslice(stack::AbstractDimStack; dims, drop=true)
```


Create a generator that iterates over dimensions `dims` of `stack`, returning stacks that select all the data from the other dimensions in `stack` using views.

The generator has `size` and `axes` equivalent to those of the provided `dims`.

**Examples**

```julia
julia> ds = DimStack((
           x=DimArray(randn(2, 3, 4), (X([:x1, :x2]), Y(1:3), Z)),
           y=DimArray(randn(2, 3, 5), (X([:x1, :x2]), Y(1:3), Ti))
       ));

julia> slices = eachslice(ds; dims=(Z, X));

julia> size(slices)
(4, 2)

julia> map(dims, axes(slices))
(↓ Z Base.OneTo(4),
→ X Base.OneTo(2))

julia> first(slices)
┌ 3×5 DimStack ┐
├──────────────┴─────────────────────────────────── dims ┐
  ↓ Y Sampled{Int64} 1:3 ForwardOrdered Regular Points,
  → Ti
├──────────────────────────────────────────────── layers ┤
  :x eltype: Float64 dims: Y size: 3
  :y eltype: Float64 dims: Y, Ti size: 3×5
└────────────────────────────────────────────────────────┘
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/methods.jl#L49-L84" target="_blank" rel="noreferrer">source</a></Badge>

</details>


Most base methods work as expected, using `Dimension` wherever a `dims` keyword is used. They are not all specifically documented here.

## Name {#Name}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.AbstractName' href='#DimensionalData.AbstractName'><span class="jlbinding">DimensionalData.AbstractName</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractName
```


Abstract supertype for name wrappers.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/name.jl#L1-L5" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Name' href='#DimensionalData.Name'><span class="jlbinding">DimensionalData.Name</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Name <: AbstractName

Name(name::Union{Symbol,Name) => Name
Name(name::NoName) => NoName
```


Name wrapper. This lets arrays keep symbol names when the array wrapper needs to be `isbits`, like for use on GPUs. It makes the name a property of the type. It&#39;s not necessary to use in normal use, a symbol is probably easier.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/name.jl#L23-L32" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.NoName' href='#DimensionalData.NoName'><span class="jlbinding">DimensionalData.NoName</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
NoName <: AbstractName

NoName()
```


NoName specifies an array is not named, and is the default `name` value for all `AbstractDimArray`s.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/name.jl#L10-L17" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Internal interface {#Internal-interface}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimArrayInterface' href='#DimensionalData.DimArrayInterface'><span class="jlbinding">DimensionalData.DimArrayInterface</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
    DimArrayInterface
```


An Interfaces.jl `Interface` with mandatory components `(:dims, :refdims_base, :ndims, :size, :rebuild_parent, :rebuild_dims, :rebuild_parent_kw, :rebuild_dims_kw, :rebuild)` and optional components `(:refdims, :name, :metadata)`.

This is an early stage of inteface definition, many things are not yet tested.

Pass constructed AbstractDimArrays as test data.

They must not be zero dimensional, and should test at least 1, 2, and 3 dimensions.

**Extended help**

**Mandatory keys:**
- `dims`:
  - defines a `dims` method
    
  - dims are updated on getindex
    
  
- `refdims_base`: `refdims` returns a tuple of Dimension or empty
  
- `ndims`: number of dims matches dimensions of array
  
- `size`: length of dims matches dimensions of array
  
- `rebuild_parent`: rebuild parent from args
  
- `rebuild_dims`: rebuild paaarnet and dims from args
  
- `rebuild_parent_kw`: rebuild parent from args
  
- `rebuild_dims_kw`: rebuild dims from args
  
- `rebuild`: all rebuild arguments and keywords are accepted
  

**Optional keys:**
- `refdims`:
  - refdims are updated in args rebuild
    
  - refdims are updated in kw rebuild
    
  - dropped dimensions are added to refdims
    
  
- `name`:
  - rebuild updates name in arg rebuild
    
  - rebuild updates name in kw rebuild
    
  
- `metadata`:
  - rebuild updates metadata in arg rebuild
    
  - rebuild updates metadata in kw rebuild
    
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/Interfaces.jl/blob/v0.3.2/src/interface.jl#L86-L94" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.DimStackInterface' href='#DimensionalData.DimStackInterface'><span class="jlbinding">DimensionalData.DimStackInterface</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
    DimStackInterface
```


An Interfaces.jl `Interface` with mandatory components `(:dims, :refdims_base, :ndims, :size, :rebuild_parent, :rebuild_dims, :rebuild_layerdims, :rebuild_dims_kw, :rebuild_parent_kw, :rebuild_layerdims_kw, :rebuild)` and optional components `(:refdims, :metadata)`.

This is an early stage of inteface definition, many things are not yet tested.

Pass constructed AbstractDimArrays as test data.

They must not be zero dimensional, and should test at least 1, 2, and 3 dimensions.

**Extended help**

**Mandatory keys:**
- `dims`:
  - defines a `dims` method
    
  - dims are updated on getindex
    
  
- `refdims_base`: `refdims` returns a tuple of Dimension or empty
  
- `ndims`: number of dims matches ndims of stack
  
- `size`: length of dims matches size of stack
  
- `rebuild_parent`: rebuild parent from args
  
- `rebuild_dims`: rebuild paaarnet and dims from args
  
- `rebuild_layerdims`: rebuild paaarnet and dims from args
  
- `rebuild_dims_kw`: rebuild dims from args
  
- `rebuild_parent_kw`: rebuild parent from args
  
- `rebuild_layerdims_kw`: rebuild parent from args
  
- `rebuild`: all rebuild arguments and keywords are accepted
  

**Optional keys:**
- `refdims`:
  - refdims are updated in args rebuild
    
  - refdims are updated in kw rebuild
    
  - dropped dimensions are added to refdims
    
  
- `metadata`:
  - rebuild updates metadata in arg rebuild
    
  - rebuild updates metadata in kw rebuild
    
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/Interfaces.jl/blob/v0.3.2/src/interface.jl#L86-L94" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.rebuild_from_arrays' href='#DimensionalData.rebuild_from_arrays'><span class="jlbinding">DimensionalData.rebuild_from_arrays</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
rebuild_from_arrays(s::AbstractDimStack, das::NamedTuple{<:Any,<:Tuple{Vararg{AbstractDimArray}}}; kw...)
```


Rebuild an `AbstractDimStack` from a `Tuple` or `NamedTuple` of `AbstractDimArray` and an existing stack.

**Keywords**

Keywords are simply the fields of the stack object:
- `data`
  
- `dims`
  
- `refdims`
  
- `metadata`
  
- `layerdims`
  
- `layermetadata`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/stack/stack.jl#L96-L112" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.show_main' href='#DimensionalData.show_main'><span class="jlbinding">DimensionalData.show_main</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
show_main(io::IO, mime, A::AbstractDimArray)
show_main(io::IO, mime, A::AbstractDimStack)
```


Interface methods for adding the main part of `show`.

At the least, you likely want to call:

```julia
print_top(io, mime, A)
```


`show_main` will also call `print_metadata_block`.

But read the DimensionalData.jl `show.jl` code for details.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/show.jl#L31-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.show_after' href='#DimensionalData.show_after'><span class="jlbinding">DimensionalData.show_after</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
show_after(io::IO, mime, A::AbstractDimArray)
show_after(io::IO, mime, A::AbstractDimStack)
```


Interface methods for adding additional `show` text for AbstractDimArray/AbstractDimStack subtypes.

_Always include `kw` to avoid future breaking changes_

Additional keywords may be added at any time.

`blockwidth` is passed in context

```julia
blockwidth = get(io, :blockwidth, 10000)
```


Note - a ANSI box is left unclosed. This method needs to close it, or add more. `blockwidth` is the maximum length of the inner text.

Most likely you always want to at least close the show blocks with:

```julia
print_block_close(io, blockwidth)
```


But read the DimensionalData.jl `show.jl` code for details.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/array/show.jl#L62-L90" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.refdims_title' href='#DimensionalData.refdims_title'><span class="jlbinding">DimensionalData.refdims_title</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
refdims_title(A::AbstractDimArray)
refdims_title(refdims::Tuple)
refdims_title(refdim::Dimension)
```


Generate a title string based on reference dimension values.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/plotrecipes.jl#L159-L165" target="_blank" rel="noreferrer">source</a></Badge>

</details>

