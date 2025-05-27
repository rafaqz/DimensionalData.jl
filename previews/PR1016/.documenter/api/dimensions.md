
# Dimensions {#Dimensions}

Dimensions are kept in the sub-module `Dimensions`.
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions' href='#DimensionalData.Dimensions'><span class="jlbinding">DimensionalData.Dimensions</span></a> <Badge type="info" class="jlObjectType jlModule" text="Module" /></summary>



```julia
Dimensions
```


Sub-module for [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension)s wrappers, and operations on them used in DimensionalData.jl.

To load `Dimensions` types and methods into scope:

```julia
using DimensionalData
using DimensionalData.Dimensions
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/Dimensions.jl#L1-L13" target="_blank" rel="noreferrer">source</a></Badge>

</details>


Dimensions have a type-hierarchy that organises plotting and dimension matching.
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Dimension' href='#DimensionalData.Dimensions.Dimension'><span class="jlbinding">DimensionalData.Dimensions.Dimension</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Dimension
```


Abstract supertype of all dimension types.

Example concrete implementations are [`X`](/api/dimensions#DimensionalData.Dimensions.X), [`Y`](/api/dimensions#DimensionalData.Dimensions.Y), [`Z`](/api/dimensions#DimensionalData.Dimensions.Z), [`Ti`](/api/dimensions#DimensionalData.Dimensions.Ti) (Time), and the custom [`Dim`](/api/dimensions#DimensionalData.Dimensions.Dim) dimension.

`Dimension`s label the axes of an `AbstractDimArray`, or other dimensional objects, and are used to index into an array.

They may also wrap lookup values for each array axis. This may be any `AbstractVector` matching the array axis length, but will usually be converted to a `Lookup` when use in a constructed object.

A `Lookup` gives more details about the dimension, such as that it is [`Categorical`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical) or [`Sampled`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Sampled) as [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points) or [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) along some transect. DimensionalData will attempt to guess the lookup from the passed-in index value.

Example:

```julia
using DimensionalData, Dates

x = X(2:2:10)
y = Y(['a', 'b', 'c'])
ti = Ti(DateTime(2021, 1):Month(1):DateTime(2021, 12))

A = DimArray(zeros(3, 5, 12), (y, x, ti))

# output

┌ 3×5×12 DimArray{Float64, 3} ┐
├─────────────────────────────┴────────────────────────────────────────── dims ┐
  ↓ Y Categorical{Char} ['a', …, 'c'] ForwardOrdered,
  → X Sampled{Int64} 2:2:10 ForwardOrdered Regular Points,
  ↗ Ti Sampled{DateTime} DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────────────┘
[:, :, 1]
 ↓ →   2    4    6    8    10
  'a'  0.0  0.0  0.0  0.0   0.0
  'b'  0.0  0.0  0.0  0.0   0.0
  'c'  0.0  0.0  0.0  0.0   0.0
```


For simplicity, the same `Dimension` types are also used as wrappers in `getindex`, like:

```julia
x = A[X(2), Y(3)]

# output

┌ 12-element DimArray{Float64, 1} ┐
├─────────────────────────────────┴────────────────────────────────────── dims ┐
  ↓ Ti Sampled{DateTime} DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────────────┘
 2021-01-01T00:00:00  0.0
 2021-02-01T00:00:00  0.0
 2021-03-01T00:00:00  0.0
 2021-04-01T00:00:00  0.0
 2021-05-01T00:00:00  0.0
 ⋮
 2021-08-01T00:00:00  0.0
 2021-09-01T00:00:00  0.0
 2021-10-01T00:00:00  0.0
 2021-11-01T00:00:00  0.0
 2021-12-01T00:00:00  0.0
```


A `Dimension` can also wrap [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector).

```julia
x = A[X(Between(3, 4)), Y(At('b'))]

# output

┌ 1×12 DimArray{Float64, 2} ┐
├───────────────────────────┴──────────────────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 4:2:4 ForwardOrdered Regular Points,
  → Ti Sampled{DateTime} DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────────────┘
 ↓ →   2021-01-01T00:00:00   2021-02-01T00:00:00  …   2021-12-01T00:00:00
 4    0.0                   0.0                      0.0
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L1-L88" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.DependentDim' href='#DimensionalData.Dimensions.DependentDim'><span class="jlbinding">DimensionalData.Dimensions.DependentDim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
DependentDim <: Dimension
```


Abstract supertype for dependent dimensions. These will plot on the Y axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L98-L102" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.IndependentDim' href='#DimensionalData.Dimensions.IndependentDim'><span class="jlbinding">DimensionalData.Dimensions.IndependentDim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
IndependentDim <: Dimension
```


Abstract supertype for independent dimensions. These will plot on the X axis.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L91-L95" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.XDim' href='#DimensionalData.Dimensions.XDim'><span class="jlbinding">DimensionalData.Dimensions.XDim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
XDim <: IndependentDim
```


Abstract supertype for all X dimensions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L105-L109" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.YDim' href='#DimensionalData.Dimensions.YDim'><span class="jlbinding">DimensionalData.Dimensions.YDim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
YDim <: DependentDim
```


Abstract supertype for all Y dimensions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L112-L116" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.ZDim' href='#DimensionalData.Dimensions.ZDim'><span class="jlbinding">DimensionalData.Dimensions.ZDim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ZDim <: DependentDim
```


Abstract supertype for all Z dimensions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L119-L123" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.TimeDim' href='#DimensionalData.Dimensions.TimeDim'><span class="jlbinding">DimensionalData.Dimensions.TimeDim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
TimeDim <: IndependentDim
```


Abstract supertype for all time dimensions.

In a `TimeDime` with `Interval` sampling the locus will automatically be set to `Start()`. Dates and times generally refer to the start of a month, hour, second etc., not the central point as is more common with spatial data. `


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L126-L134" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.X' href='#DimensionalData.Dimensions.X'><span class="jlbinding">DimensionalData.Dimensions.X</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
X <: XDim

X(val=:)
```


X [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension). `X <: XDim <: IndependentDim`

**Examples**

```julia
xdim = X(2:2:10)
```


```julia
val = A[X(1)]
```


```julia
mean(A; dims=X)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L485-L505" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Y' href='#DimensionalData.Dimensions.Y'><span class="jlbinding">DimensionalData.Dimensions.Y</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Y <: YDim

Y(val=:)
```


Y [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension). `Y <: YDim <: DependentDim`

**Examples**

```julia
ydim = Y(['a', 'b', 'c'])
```


```julia
val = A[Y(1)]
```


```julia
mean(A; dims=Y)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L508-L528" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Z' href='#DimensionalData.Dimensions.Z'><span class="jlbinding">DimensionalData.Dimensions.Z</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Z <: ZDim

Z(val=:)
```


Z [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension). `Z <: ZDim <: Dimension`

**Example:**

```julia
zdim = Z(10:10:100)
```


```julia
val = A[Z(1)]
```


```julia
mean(A; dims=Z)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L531-L550" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Ti' href='#DimensionalData.Dimensions.Ti'><span class="jlbinding">DimensionalData.Dimensions.Ti</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



m     Ti &lt;: TimeDim

```
Ti(val=:)
```


Time [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension). `Ti <: TimeDim <: IndependentDim`

`Time` is already used by Dates, and `T` is a common type parameter, We use `Ti` to avoid clashes.

**Example:**

```julia
timedim = Ti(DateTime(2021, 1):Month(1):DateTime(2021, 12))
```


```julia
val = A[Ti(1)]
```


```julia
mean(A; dims=Ti)
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L553-L576" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Dim' href='#DimensionalData.Dimensions.Dim'><span class="jlbinding">DimensionalData.Dimensions.Dim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Dim{S}(val=:)
```


A generic dimension. For use when custom dims are required when loading data from a file. Can be used as keyword arguments for indexing.

Dimension types take precedence over same named `Dim` types when indexing with symbols, or e.g. creating Tables.jl keys.

```julia
julia> dim = Dim{:custom}(['a', 'b', 'c'])
custom ['a', …, 'c']
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L370-L383" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.AnonDim' href='#DimensionalData.Dimensions.AnonDim'><span class="jlbinding">DimensionalData.Dimensions.AnonDim</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AnonDim <: Dimension

AnonDim()
```


Anonymous dimension. Used when extra dimensions are created, such as during transpose of a vector.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L408-L415" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.@dim' href='#DimensionalData.Dimensions.@dim'><span class="jlbinding">DimensionalData.Dimensions.@dim</span></a> <Badge type="info" class="jlObjectType jlMacro" text="Macro" /></summary>



```julia
@dim typ [supertype=Dimension] [label::String=string(typ)]
```


Macro to easily define new dimensions. 

The supertype will be inserted into the type of the dim.  The default is simply `YourDim <: Dimension`. 

Making a Dimension inherit from `XDim`, `YDim`, `ZDim` or `TimeDim` will affect automatic plot layout and other methods that dispatch on these types. `<: YDim` are plotted on the Y axis, `<: XDim` on the X axis, etc.

`label` is used in plots and similar,  if the dimension is short for a longer word.

Example:

```julia
using DimensionalData
using DimensionalData: @dim, YDim, XDim
@dim Lat YDim "Latitude"
@dim Lon XDim "Longitude"
# output

```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/dimension.jl#L424-L448" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Exported methods {#Exported-methods}

These are widely useful methods for working with dimensions.
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.dims-api-dimensions' href='#DimensionalData.Dimensions.dims-api-dimensions'><span class="jlbinding">DimensionalData.Dimensions.dims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



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
<summary><a id='DimensionalData.Dimensions.otherdims-api-dimensions' href='#DimensionalData.Dimensions.otherdims-api-dimensions'><span class="jlbinding">DimensionalData.Dimensions.otherdims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



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
<summary><a id='DimensionalData.Dimensions.dimnum-api-dimensions' href='#DimensionalData.Dimensions.dimnum-api-dimensions'><span class="jlbinding">DimensionalData.Dimensions.dimnum</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



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
<summary><a id='DimensionalData.Dimensions.hasdim-api-dimensions' href='#DimensionalData.Dimensions.hasdim-api-dimensions'><span class="jlbinding">DimensionalData.Dimensions.hasdim</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



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


### Non-exported methods {#Non-exported-methods}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.lookup' href='#DimensionalData.Dimensions.lookup'><span class="jlbinding">DimensionalData.Dimensions.lookup</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
lookup(x::Dimension) => Lookup
lookup(x, [dims::Tuple]) => Tuple{Vararg{Lookup}}
lookup(x::Tuple) => Tuple{Vararg{Lookup}}
lookup(x, dim) => Lookup
```


Returns the [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) of a dimension. This dictates properties of the dimension such as array axis and lookup order, and sampling properties.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.

This is separate from `val` in that it will only work when dimensions actually contain an `AbstractArray` lookup, and can be used on a  `DimArray` or `DimStack` to retrieve all lookups, as there is no ambiguity  of meaning as there is with `val`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L91-L107" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.label' href='#DimensionalData.Dimensions.label'><span class="jlbinding">DimensionalData.Dimensions.label</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
label(x) => String
label(x, dims::Tuple) => NTuple{N,String}
label(x, dim) => String
label(xs::Tuple) => NTuple{N,String}
```


Get a plot label for data or a dimension. This will include the name and units if they exist, and anything else that should be shown on a plot.

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L159-L170" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.format' href='#DimensionalData.Dimensions.format'><span class="jlbinding">DimensionalData.Dimensions.format</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
format(dims, x) => Tuple{Vararg{Dimension,N}}
```


Format the passed-in dimension(s) `dims` to match the object `x`.

Errors are thrown if dims don&#39;t match the array dims or size,  and any fields holding `Auto-` objects are filled with guessed objects.

If a [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) hasn&#39;t been specified, a lookup is chosen based on the type and element type of the values.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/format.jl#L5-L15" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.dims2indices' href='#DimensionalData.Dimensions.dims2indices'><span class="jlbinding">DimensionalData.Dimensions.dims2indices</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
dims2indices(dim::Dimension, I) => NTuple{Union{Colon,AbstractArray,Int}}
```


Convert a `Dimension` or `Selector` `I` to indices of `Int`, `AbstractArray` or `Colon`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/indexing.jl#L26-L30" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.selectindices' href='#DimensionalData.Dimensions.Lookups.selectindices'><span class="jlbinding">DimensionalData.Dimensions.Lookups.selectindices</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
selectindices(lookups, selectors)
```


Converts [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector) to regular indices.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L1050-L1054" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Primitive methods {#Primitive-methods}

These low-level methods are really for internal use, but  can be useful for writing dimensional algorithms.

They are not guaranteed to keep their interface, but usually will.
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.commondims' href='#DimensionalData.Dimensions.commondims'><span class="jlbinding">DimensionalData.Dimensions.commondims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
commondims([f], x, query) => Tuple{Vararg{Dimension}}
```


This is basically `dims(x, query)` where the order of the original is kept, unlike [`dims`](/extending_dd#dims) where the query tuple determines the order

Also unlike `dims`,`commondims` always returns a `Tuple`, no matter the input. No errors are thrown if dims are absent from either `x` or `query`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.

```julia
julia> using DimensionalData, .Dimensions

julia> A = DimArray(ones(10, 10, 10), (X, Y, Z));

julia> commondims(A, X)
(↓ X)

julia> commondims(A, (X, Z))
(↓ X, → Z)

julia> commondims(A, Ti)
()

```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L154-L180" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.name2dim' href='#DimensionalData.Dimensions.name2dim'><span class="jlbinding">DimensionalData.Dimensions.name2dim</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
name2dim(s::Symbol) => Dimension
name2dim(dims...) => Tuple{Dimension,Vararg}
name2dim(dims::Tuple) => Tuple{Dimension,Vararg}
```


Convert a symbol to a dimension object. `:X`, `:Y`, `:Ti` etc will be converted to `X()`, `Y()`, `Ti()`, as with any other dims generated with the [`@dim`](/api/dimensions#DimensionalData.Dimensions.@dim) macro.

All other `Symbol`s `S` will generate `Dim{S}()` dimensions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L40-L49" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.reducedims' href='#DimensionalData.Dimensions.reducedims'><span class="jlbinding">DimensionalData.Dimensions.reducedims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
reducedims(x, dimstoreduce) => Tuple{Vararg{Dimension}}
```


Replace the specified dimensions with an index of length 1. This is usually to match a new array size where an axis has been reduced with a method like `mean` or `reduce` to a length of 1, but the number of dimensions has not changed.

`Lookup` traits are also updated to correspond to the change in cell step, sampling type and order.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L480-L490" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.swapdims' href='#DimensionalData.Dimensions.swapdims'><span class="jlbinding">DimensionalData.Dimensions.swapdims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
swapdims(x::T, newdims) => T
swapdims(dims::Tuple, newdims) => Tuple{Vararg{Dimension}}
```


Swap dimensions for the passed in dimensions, in the order passed.

Passing in the `Dimension` types rewraps the dimension lookup, keeping the index values and metadata, while constructed `Dimension` objects replace the original dimension. `nothing` leaves the original dimension as-is.

**Arguments**
- `x`: any object with a `dims` method or a `Tuple` of `Dimension`.
  
- `newdim`: Tuple of `Dimension` or dimension `Type`.
  

**Example**

```julia
using DimensionalData
A = ones(X(2), Y(4), Z(2))
Dimensions.swapdims(A, (Dim{:a}, Dim{:b}, Dim{:c}))

# output
┌ 2×4×2 DimArray{Float64, 3} ┐
├────────────────────── dims ┤
  ↓ a, → b, ↗ c
└────────────────────────────┘
[:, :, 1]
 1.0  1.0  1.0  1.0
 1.0  1.0  1.0  1.0
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L349-L381" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.slicedims' href='#DimensionalData.Dimensions.slicedims'><span class="jlbinding">DimensionalData.Dimensions.slicedims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
slicedims(x, I) => Tuple{Tuple,Tuple}
slicedims(f, x, I) => Tuple{Tuple,Tuple}
```


Slice the dimensions to match the axis values of the new array.

All methods return a tuple containing two tuples: the new dimensions, and the reference dimensions. The ref dimensions are no longer used in the new struct but are useful to give context to plots.

Called at the array level the returned tuple will also include the previous reference dims attached to the array.

**Arguments**
- `f`: a function `getindex`,  `view` or `dotview`. This will be used for slicing   `getindex` is the default if `f` is not included.
  
- `x`: An `AbstractDimArray`, `Tuple` of `Dimension`, or `Dimension`
  
- `I`: A tuple of `Integer`, `Colon` or `AbstractArray`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L394-L413" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.comparedims' href='#DimensionalData.Dimensions.comparedims'><span class="jlbinding">DimensionalData.Dimensions.comparedims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
comparedims(A::AbstractDimArray...; kw...)
comparedims(A::Tuple...; kw...)
comparedims(A::Dimension...; kw...)
comparedims(::Type{Bool}, args...; kw...)
```


Check that dimensions or tuples of dimensions passed as each argument are the same, and return the first valid dimension. If `AbstractDimArray`s are passed as arguments their dimensions are compared.

Empty tuples and `nothing` dimension values are ignored, returning the `Dimension` value if it exists.

Passing `Bool` as the first argument means `true`/`false` will be returned, rather than throwing an error.

**Keywords**

These are all `Bool` flags:
- `type`: compare dimension type, `true` by default.
  
- `valtype`: compare wrapped value type, `false` by default.
  
- `val`: compare wrapped values, `false` by default.
  
- `order`: compare order, `false` by default.
  
- `length`: compare lengths, `true` by default.
  
- `ignore_length_one`: ignore length `1` in comparisons, and return whichever   dimension is not length 1, if any. This is useful in e.g. broadcasting comparisons.   `false` by default.
  
- `msg`: DimensionalData.Warn or DimensionalData.Throw. Both may contain string,   which will be added to error or warning mesages.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L507-L537" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.combinedims' href='#DimensionalData.Dimensions.combinedims'><span class="jlbinding">DimensionalData.Dimensions.combinedims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
combinedims(xs; check=true, kw...)
```


Combine the dimensions of each object in `xs`, in the order they are found.

Keywords are passed to [`comparedims`](/api/dimensions#DimensionalData.Dimensions.comparedims).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L703-L709" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.sortdims' href='#DimensionalData.Dimensions.sortdims'><span class="jlbinding">DimensionalData.Dimensions.sortdims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
sortdims([f], tosort, order) => Tuple
```


Sort dimensions `tosort` by `order`. Dimensions in `order` but missing from `tosort` are replaced with `nothing`.

`tosort` and `order` can be `Tuple`s or `Vector`s or Dimension or dimension type. Abstract supertypes like [`TimeDim`](/api/dimensions#DimensionalData.Dimensions.TimeDim) can be used in `order`.

`f` is `<:` by default, but can be `>:` to sort abstract types by concrete types.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L62-L73" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.basetypeof' href='#DimensionalData.Dimensions.Lookups.basetypeof'><span class="jlbinding">DimensionalData.Dimensions.Lookups.basetypeof</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
basetypeof(x) => Type
```


Get the &quot;base&quot; type of an object - the minimum required to define the object without it&#39;s fields. By default this is the full `UnionAll` for the type. But custom `basetypeof` methods can be defined for types with free type parameters.

In DimensionalData this is primarily used for comparing `Dimension`s, where `Dim{:x}` is different from `Dim{:y}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/utils.jl#L62-L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.basedims' href='#DimensionalData.Dimensions.basedims'><span class="jlbinding">DimensionalData.Dimensions.basedims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
basedims(ds::Tuple)
basedims(d::Union{Dimension,Symbol,Type})
```


Returns `basetypeof(d)()` or a `Tuple` of called on a `Tuple`.

See [`basetypeof`](/api/dimensions#DimensionalData.Dimensions.Lookups.basetypeof)


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L737-L744" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.setdims' href='#DimensionalData.Dimensions.setdims'><span class="jlbinding">DimensionalData.Dimensions.setdims</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
setdims(X, newdims) => AbstractArray
setdims(::Tuple, newdims) => Tuple{Vararg{Dimension,N}}
```


Replaces the first dim matching `<: basetypeof(newdim)` with newdim, and returns a new object or tuple with the dimension updated.

**Arguments**
- `x`: any object with a `dims` method, a `Tuple` of `Dimension` or a single `Dimension`.
  
- `newdim`: Tuple or single `Dimension`, `Type` or `Symbol`.
  

**Example**

```julia
using DimensionalData, DimensionalData.Dimensions, DimensionalData.Lookups
A = ones(X(10), Y(10:10:100))
B = setdims(A, Y(Categorical('a':'j'; order=ForwardOrdered())))
lookup(B, Y)
# output
Categorical{Char} ForwardOrdered
wrapping: 'a':1:'j'
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L318-L339" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.dimsmatch' href='#DimensionalData.Dimensions.dimsmatch'><span class="jlbinding">DimensionalData.Dimensions.dimsmatch</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
dimsmatch([f], dim, query) => Bool
dimsmatch([f], dims::Tuple, query::Tuple) => Bool
```


Compare 2 dimensions or `Tuple` of `Dimension` are of the same base type, or are at least rotations/transformations of the same type.

`f` is `<:` by default, but can be `>:` to match abstract types to concrete types.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/primitives.jl#L4-L12" target="_blank" rel="noreferrer">source</a></Badge>

</details>

