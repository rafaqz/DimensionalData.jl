
# Lookups {#Lookups}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups' href='#DimensionalData.Dimensions.Lookups'><span class="jlbinding">DimensionalData.Dimensions.Lookups</span></a> <Badge type="info" class="jlObjectType jlModule" text="Module" /></summary>



```julia
Lookups
```


Module for [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup)s and [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s used in DimensionalData.jl

`Lookup` defines traits and `AbstractArray` wrappers that give specific behaviours for a lookup index when indexed with [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector).

For example, these allow tracking over array order so fast indexing works even when  the array is reversed.

To load `Lookup` types and methods into scope:

```julia
using DimensionalData
using DimensionalData.Lookups
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/Lookups.jl#L1-L18" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Lookup' href='#DimensionalData.Dimensions.Lookups.Lookup'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Lookup</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Lookup
```


Types defining the behaviour of a lookup index, how it is plotted and how [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s like [`Between`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Between) work.

A `Lookup` may be [`NoLookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.NoLookup) indicating that there are no lookup values, [`Categorical`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical) for ordered or unordered categories, or a [`Sampled`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Sampled) index for [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points) or [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L1-L10" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Aligned' href='#DimensionalData.Dimensions.Lookups.Aligned'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Aligned</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Aligned <: Lookup
```


Abstract supertype for [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup)s where the lookup is aligned with the array axes.

This is by far the most common supertype for `Lookup`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L98-L105" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AbstractSampled' href='#DimensionalData.Dimensions.Lookups.AbstractSampled'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AbstractSampled</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractSampled <: Aligned
```


Abstract supertype for [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup)s where the lookup is aligned with the array, and is independent of other dimensions. [`Sampled`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Sampled) is provided by this package.

`AbstractSampled` must have  `order`, `span` and `sampling` fields, or a `rebuild` method that accepts them as keyword arguments.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L168-L177" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Sampled' href='#DimensionalData.Dimensions.Lookups.Sampled'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Sampled</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Sampled <: AbstractSampled

Sampled(data::AbstractVector, order::Order, span::Span, sampling::Sampling, metadata)
Sampled(data=AutoValues(); order=AutoOrder(), span=AutoSpan(), sampling=Points(), metadata=NoMetadata())
```


A concrete implementation of the [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) [`AbstractSampled`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.AbstractSampled). It can be used to represent [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points) or [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals).

`Sampled` is capable of representing gridded data from a wide range of sources, allowing correct `bounds` and [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s for points or intervals of regular, irregular, forward and reverse lookups.

On `AbstractDimArray` construction, `Sampled` lookup is assigned for all lookups of `AbstractRange` not assigned to [`Categorical`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical).

**Arguments**
- `data`: An `AbstractVector` of lookup values, matching the length of the curresponding   array axis.
  
- `order`: [`Order`](/api/lookuparrays#Order)) indicating the order of the lookup,   [`AutoOrder`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.AutoOrder) by default, detected from the order of `data`   to be [`ForwardOrdered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.ForwardOrdered), [`ReverseOrdered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.ReverseOrdered) or [`Unordered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Unordered).   These can be provided explicitly if they are known and performance is important.
  
- `span`: indicates the size of intervals or distance between points, and will be set to   [`Regular`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Regular) for `AbstractRange` and [`Irregular`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Irregular) for `AbstractArray`,   unless assigned manually.
  
- `sampling`: is assigned to [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points), unless set to [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) manually.   Using [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) will change the behaviour of `bounds` and `Selectors`s   to take account for the full size of the interval, rather than the point alone.
  
- `metadata`: a `Dict` or `Metadata` wrapper that holds any metadata object adding more   information about the array axis - useful for extending DimensionalData for specific   contexts, like geospatial data in Rasters.jl. By default it is `NoMetadata()`.
  

**Example**

Create an array with `Interval` sampling, and `Regular` span for a vector with known spacing.

We set the [`locus`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.locus) of the `Intervals` to `Start` specifying that the lookup values are for the locus at the start of each interval.

```julia
using DimensionalData, DimensionalData.Lookups

x = X(Sampled(100:-20:10; sampling=Intervals(Start())))
y = Y(Sampled([1, 4, 7, 10]; span=Regular(3), sampling=Intervals(Start())))
A = ones(x, y)

# output
┌ 5×4 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 100:-20:20 ReverseOrdered Regular Intervals{Start},
  → Y Sampled{Int64} [1, …, 10] ForwardOrdered Regular Intervals{Start}
└─────────────────────────────────────────────────────────────────────────┘
   ↓ →  1    4    7    10
 100    1.0  1.0  1.0   1.0
  80    1.0  1.0  1.0   1.0
  60    1.0  1.0  1.0   1.0
  40    1.0  1.0  1.0   1.0
  20    1.0  1.0  1.0   1.0
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L259-L307" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AbstractCyclic' href='#DimensionalData.Dimensions.Lookups.AbstractCyclic'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AbstractCyclic</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractCyclic <: AbstractSampled
```


An abstract supertype for cyclic lookups.

These are `AbstractSampled` lookups that are cyclic for `Selectors`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L337-L343" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Cyclic' href='#DimensionalData.Dimensions.Lookups.Cyclic'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Cyclic</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Cyclic <: AbstractCyclic

Cyclic(data; order=AutoOrder(), span=AutoSpan(), sampling=Points(), metadata=NoMetadata(), cycle)
```


A `Cyclic` lookup is similar to `Sampled` but out of range `Selectors` [`At`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.At),  [`Near`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Near), [`Contains`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Contains) will cycle the values to `typemin` or `typemax`  over the length of `cycle`. [`Where`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Where) and `..` work as for [`Sampled`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Sampled).

This is useful when we are using mean annual datasets over a real time-span, or for wrapping longitudes so that `-360` and `360` are the same.

**Arguments**
- `data`: An `AbstractVector` of lookup values, matching the length of the curresponding   array axis.
  
- `order`: [`Order`](/api/lookuparrays#Order)) indicating the order of the lookup,   [`AutoOrder`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.AutoOrder) by default, detected from the order of `data`   to be [`ForwardOrdered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.ForwardOrdered), [`ReverseOrdered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.ReverseOrdered) or [`Unordered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Unordered).   These can be provided explicitly if they are known and performance is important.
  
- `span`: indicates the size of intervals or distance between points, and will be set to   [`Regular`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Regular) for `AbstractRange` and [`Irregular`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Irregular) for `AbstractArray`,   unless assigned manually.
  
- `sampling`: is assigned to [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points), unless set to [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) manually.   Using [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) will change the behaviour of `bounds` and `Selectors`s   to take account for the full size of the interval, rather than the point alone.
  
- `metadata`: a `Dict` or `Metadata` wrapper that holds any metadata object adding more   information about the array axis - useful for extending DimensionalData for specific   contexts, like geospatial data in Rasters.jl. By default it is `NoMetadata()`.
  
- `cycle`: the length of the cycle. This does not have to exactly match the data,   the `step` size is `Week(1)` the cycle can be `Years(1)`.
  

**Notes**
1. If you use dates and e.g. cycle over a `Year`, every year will have the   number and spacing of `Week`s and `Day`s as the cycle year. Using `At` may not be reliable  in terms of exact dates, as it will be applied to the specified date plus or minus `n` years.
  
2. Indexing into a `Cycled` with any `AbstractArray` or `AbstractRange` will return   a [`Sampled`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Sampled) as the full cycle is likely no longer available.
  
3. `..` or `Between` selectors do not work in a cycled way: they work as for [`Sampled`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Sampled).   This may change in future to return cycled values, but there are problems with this, such as  leap years breaking correct date cycling of a single year. If you actually need this behaviour,   please make a GitHub issue.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L390-L419" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AbstractCategorical' href='#DimensionalData.Dimensions.Lookups.AbstractCategorical'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AbstractCategorical</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractCategorical <: Aligned
```


[`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup)s where the values are categories.

[`Categorical`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical) is the provided concrete implementation. But this can easily be extended, all methods are defined for `AbstractCategorical`.

All `AbstractCategorical` must provide a `rebuild` method with `data`, `order` and `metadata` keyword arguments.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L455-L465" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Categorical' href='#DimensionalData.Dimensions.Lookups.Categorical'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Categorical</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Categorical <: AbstractCategorical

Categorical(o::Order)
Categorical(; order=Unordered())
```


A [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) where the values are categories.

This will be automatically assigned if the lookup contains `AbstractString`, `Symbol` or `Char`. Otherwise it can be assigned manually.

[`Order`](/api/lookuparrays#Order) will be determined automatically where possible.

**Arguments**
- `data`: An `AbstractVector` matching the length of the corresponding   array axis.
  
- `order`: [`Order`](/api/lookuparrays#Order)) indicating the order of the lookup,   [`AutoOrder`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.AutoOrder) by default, detected from the order of `data`   to be `ForwardOrdered`, `ReverseOrdered` or `Unordered`.   Can be provided if this is known and performance is important.
  
- `metadata`: a `Dict` or `Metadata` wrapper that holds any metadata object adding more   information about the array axis - useful for extending DimensionalData for specific   contexts, like geospatial data in Rasters.jl. By default it is `NoMetadata()`.
  

**Example**

Create an array with [`Interval`] sampling.

```julia
using DimensionalData

ds = X(["one", "two", "three"]), Y([:a, :b, :c, :d])
A = DimArray(rand(3, 4), ds)
Dimensions.lookup(A)

# output

Categorical{String} ["one", …, "three"] Unordered,
Categorical{Symbol} [:a, …, :d] ForwardOrdered
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L478-L519" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Unaligned' href='#DimensionalData.Dimensions.Lookups.Unaligned'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Unaligned</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Unaligned <: Lookup
```


Abstract supertype for [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) where the lookup is not aligned to the grid.

Indexing an [`Unaligned`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Unaligned) with [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s must provide all other [`Unaligned`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Unaligned) dimensions.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L540-L547" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Transformed' href='#DimensionalData.Dimensions.Lookups.Transformed'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Transformed</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Transformed <: Unaligned

Transformed(f, dim::Dimension; metadata=NoMetadata())
```


[`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) that uses an affine transformation to convert dimensions from `dims(lookup)` to `dims(array)`. This can be useful when the dimensions are e.g. rotated from a more commonly used axis.

Any function can be used to do the transformation, but transformations from CoordinateTransformations.jl may be useful.

**Arguments**
- `f`: transformation function
  
- `dim`: a dimension to transform to.
  

**Keyword Arguments**
- `metadata`:
  

**Example**

```julia
using DimensionalData, DimensionalData.Lookups, CoordinateTransformations

m = LinearMap([0.5 0.0; 0.0 0.5])
A = [1 2  3  4
     5 6  7  8
     9 10 11 12];
da = DimArray(A, (X(Transformed(m)), Y(Transformed(m))))

da[X(At(6.0)), Y(At(2.0))]

# output
9
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L550-L587" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.MergedLookup' href='#DimensionalData.Dimensions.MergedLookup'><span class="jlbinding">DimensionalData.Dimensions.MergedLookup</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
MergedLookup <: MultiDimensionalLookup <: Lookup

MergedLookup(data, dims; [metadata])
```


A [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) that holds multiple combined dimensions.

`MergedLookup` can be indexed with [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s like `At`,  `Between`, and `Where` although `Near` has undefined meaning.

**Examples**

The easiest way to create a `MergedLookup` is to use the `mergedims` function:

```julia
da = rand(X(1:3), Y(1:3), Ti(1:3))
merged = mergedims(da, (X, Y) => :space)

julia> merged = mergedims(da, (X, Y) => :space)
┌ 3×9 DimArray{Float64, 2} ┐
├──────────────────────────┴─────────────────────────────────────────────────────────────────────────────── dims ┐
  ↓ Ti    Sampled{Int64} 1:3 ForwardOrdered Regular Points,
  → space MergedLookup{Tuple{Int64, Int64}} [(1, 1), (2, 1), …, (2, 3), (3, 3)] ↓ X, → Y
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
 ↓ →   (1, 1)    (2, 1)   (3, 1)    (1, 2)    (2, 2)    (3, 2)    (1, 3)     (2, 3)     (3, 3)
 ⋮                                           ⋮                                         
 3    0.832755  0.89284  0.184938  0.434221  0.552545  0.612124  0.0630973  0.0365063  0.103989
```


Then, you can index into the merged dimensions in two ways: by referring specifically to the merged dimension,

```julia
merged[space=1:2]
merged[space=(X(At(1)), Y(At(2))), Ti(At(2))]
```


or by using the `Coord` type, which is able to infer the merged lookup from the dimension names:

```julia
merged[space=(X(At(1)), Y(At(2))), Ti(At(2))]
```


or by directly passing selectors for the merged dimensions:

```julia
merged[X(At(1)), Y(At(2)), Ti(At(2))] == merged[space=(X(At(1)), Y(At(2))), Ti(At(2))]
```


This allows quite a bit of very powerful behaviour!

**Arguments**
- `data`: A `Vector` of `Tuple`.
  
- `dims`: A `Tuple` of [`Dimension`](/api/dimensions#DimensionalData.Dimensions.Dimension) indicating the dimensions in the tuples in `data`.
  

**Keywords**
- `metadata`: a `Dict` or `Metadata` object to attach dimension metadata.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Dimensions/merged.jl#L3-L58" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.NoLookup' href='#DimensionalData.Dimensions.Lookups.NoLookup'><span class="jlbinding">DimensionalData.Dimensions.Lookups.NoLookup</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
NoLookup <: Lookup

NoLookup()
```


A [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) that is identical to the array axis. [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s can&#39;t be used on this lookup.

**Example**

Defining a `DimArray` without passing lookup values to the dimensions, it will be assigned `NoLookup`:

```julia
using DimensionalData

A = DimArray(rand(3, 3), (X, Y))
Dimensions.lookup(A)

# output

NoLookup, NoLookup
```


Which is identical to:

```julia
using .Lookups
A = DimArray(rand(3, 3), (X(NoLookup()), Y(NoLookup())))
Dimensions.lookup(A)

# output

NoLookup, NoLookup
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L118-L153" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AutoLookup' href='#DimensionalData.Dimensions.Lookups.AutoLookup'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AutoLookup</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AutoLookup <: Lookup

AutoLookup()
AutoLookup(values=AutoValues(); kw...)
```


Automatic [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup), the default lookup. It will be converted automatically to another [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup) when it is possible to detect it from the lookup values.

Keywords will be used in the detected `Lookup` constructor.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_arrays.jl#L65-L75" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AutoValues' href='#DimensionalData.Dimensions.Lookups.AutoValues'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AutoValues</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AutoValues
```


Detect `Lookup` values from the context. This is used in `NoLookup` to simply use the array axis as the index when the array is constructed, and in `set` to change the `Lookup` type without changing the index values.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L278-L284" target="_blank" rel="noreferrer">source</a></Badge>

</details>


The generic value getter `val`
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.val' href='#DimensionalData.Dimensions.Lookups.val'><span class="jlbinding">DimensionalData.Dimensions.Lookups.val</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
val(x)
val(dims::Tuple) => Tuple
```


Return the contained value of a wrapper object.

`dims` can be `Dimension`, `Dimension` types, or `Symbols` for `Dim{Symbol}`.

Objects that don&#39;t define a `val` method are returned unaltered.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L79-L88" target="_blank" rel="noreferrer">source</a></Badge>

</details>


Lookup methods:
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.bounds' href='#DimensionalData.Dimensions.Lookups.bounds'><span class="jlbinding">DimensionalData.Dimensions.Lookups.bounds</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
bounds(xs, [dims::Tuple]) => Tuple{Vararg{Tuple{T,T}}}
bounds(xs::Tuple) => Tuple{Vararg{Tuple{T,T}}}
bounds(x, dim) => Tuple{T,T}
bounds(dim::Union{Dimension,Lookup}) => Tuple{T,T}
```


Return the bounds of all dimensions of an object, of a specific dimension, or of a tuple of dimensions.

If bounds are not known, one or both values may be `nothing`.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L173-L185" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.hasselection' href='#DimensionalData.Dimensions.Lookups.hasselection'><span class="jlbinding">DimensionalData.Dimensions.Lookups.hasselection</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
hasselection(x, selector) => Bool
hasselection(x, selectors::Tuple) => Bool
```


Check if indexing into x with `selectors` can be performed, where x is some object with a `dims` method, and `selectors` is a `Selector` or `Dimension` or a tuple of either.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L240-L247" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.sampling' href='#DimensionalData.Dimensions.Lookups.sampling'><span class="jlbinding">DimensionalData.Dimensions.Lookups.sampling</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
sampling(x, [dims::Tuple]) => Tuple
sampling(x, dim) => Sampling
sampling(xs::Tuple) => Tuple{Vararg{Sampling}}
sampling(x:Union{Dimension,Lookup}) => Sampling
```


Return the [`Sampling`](/api/lookuparrays#Sampling) for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L201-L211" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.span' href='#DimensionalData.Dimensions.Lookups.span'><span class="jlbinding">DimensionalData.Dimensions.Lookups.span</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
span(x, [dims::Tuple]) => Tuple
span(x, dim) => Span
span(xs::Tuple) => Tuple{Vararg{Span,N}}
span(x::Union{Dimension,Lookup}) => Span
```


Return the [`Span`](/api/lookuparrays#Span) for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L214-L224" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.order' href='#DimensionalData.Dimensions.Lookups.order'><span class="jlbinding">DimensionalData.Dimensions.Lookups.order</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
order(x, [dims::Tuple]) => Tuple
order(xs::Tuple) => Tuple
order(x::Union{Dimension,Lookup}) => Order
```


Return the `Ordering` of the dimension lookup for each dimension: `ForwardOrdered`, `ReverseOrdered`, or [`Unordered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Unordered) 

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L188-L198" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.locus' href='#DimensionalData.Dimensions.Lookups.locus'><span class="jlbinding">DimensionalData.Dimensions.Lookups.locus</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
locus(x, [dims::Tuple]) => Tuple
locus(x, dim) => Locus
locus(xs::Tuple) => Tuple{Vararg{Locus,N}}
locus(x::Union{Dimension,Lookup}) => Locus
```


Return the [`Position`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Position) of lookup values for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L227-L237" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.shiftlocus' href='#DimensionalData.Dimensions.Lookups.shiftlocus'><span class="jlbinding">DimensionalData.Dimensions.Lookups.shiftlocus</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
shiftlocus(locus::Locus, x)
```


Shift the values of `x` from the current locus to the new locus.

We only shift `Sampled`, `Regular` or `Explicit`, `Intervals`. 


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/utils.jl#L1-L7" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Selectors {#Selectors}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Selector' href='#DimensionalData.Dimensions.Lookups.Selector'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Selector</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Selector
```


Abstract supertype for all selectors.

Selectors are wrappers that indicate that passed values are not the array indices, but values to be selected from the dimension lookup, such as `DateTime` objects for a `Ti` dimension.

Selectors provided in DimensionalData are:
- [`At`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.At)
  
- [`Between`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Between)
  
- [`Touches`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Touches)
  
- [`Near`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Near)
  
- [`Where`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Where)
  
- [`Contains`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Contains)
  

Note: Selectors can be modified using:
- `Not`: as in `Not(At(x))`
  

And IntervalSets.jl `Interval` can be used instead of `Between`
- `..`
  
- `Interval`
  
- `OpenInterval`
  
- `ClosedInterval`
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L16-L41" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.IntSelector' href='#DimensionalData.Dimensions.Lookups.IntSelector'><span class="jlbinding">DimensionalData.Dimensions.Lookups.IntSelector</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
IntSelector <: Selector
```


Abstract supertype for [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s that return a single `Int` index.

IntSelectors provided by DimensionalData are:
- [`At`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.At)
  
- [`Contains`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Contains)
  
- [`Near`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Near)
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L52-L62" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.ArraySelector' href='#DimensionalData.Dimensions.Lookups.ArraySelector'><span class="jlbinding">DimensionalData.Dimensions.Lookups.ArraySelector</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ArraySelector <: Selector
```


Abstract supertype for [`Selector`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Selector)s that return an `AbstractArray`.

ArraySelectors provided by DimensionalData are:
- [`Between`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Between)
  
- [`Touches`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Touches)
  
- [`Where`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Where)
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L65-L75" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.At' href='#DimensionalData.Dimensions.Lookups.At'><span class="jlbinding">DimensionalData.Dimensions.Lookups.At</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
At <: IntSelector

At(x; atol=nothing, rtol=nothing)
At(a, b; kw...)
```


Selector that exactly matches the value on the passed-in dimensions, or throws an error. For ranges and arrays, every intermediate value must match an existing value - not just the end points.

`x` can be any value to select a single index, or a `Vector` of values to select vector of indices. If two values `a` and `b` are used, the range between them will be selected.

Keyword `atol` is passed to `isapprox`.

**Example**

```julia
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(At(20)), Y(At(6))]

# output

5
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L82-L109" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Near' href='#DimensionalData.Dimensions.Lookups.Near'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Near</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Near <: IntSelector

Near(x)
Near(a, b)
```


Selector that selects the nearest index to `x`.

With [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points) this is simply the lookup values nearest to the `x`, however with [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) it is the interval _center_ nearest to `x`. This will be offset from the index value for `Start` and [`End`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.End) locus.

`x` can be any value to select a single index, or a `Vector` of values to select vector of indices. If two values `a` and `b`  are used, the range between the nearsest value to each of them will be selected.

**Example**

```julia
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(Near(23)), Y(Near(5.1))]

# output
4
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L235-L262" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Between' href='#DimensionalData.Dimensions.Lookups.Between'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Between</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Between <: ArraySelector

Between(a, b)
```


Depreciated: use `a..b` instead of `Between(a, b)`. Other `Interval` objects from IntervalSets.jl, like `OpenInterval(a, b) will also work, giving the correct open/closed boundaries.

`Between` will e removed in future to avoid clashes with `DataFrames.Between`.

Selector that retrieve all indices located between 2 values, evaluated with `>=` for the lower value, and `<` for the upper value. This means the same value will not be counted twice in 2 adjacent `Between` selections.

For [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) the whole interval must be lie between the values. For [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points) the points must fall between the values. Different [`Sampling`](/api/lookuparrays#Sampling) types may give different results with the same input - this is the intended behaviour.

`Between` for [`Irregular`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Irregular) intervals is a little complicated. The interval is the distance between a value and the next (for `Start` locus) or previous (for [`End`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.End) locus) value.

For [`Center`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Center), we take the mid point between two index values as the start and end of each interval. This may or may not make sense for the values in your index, so use `Between` with `Irregular` `Intervals(Center())` with caution.

**Example**

```julia
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(Between(15, 25)), Y(Between(4, 6.5))]

# output

┌ 1×2 DimArray{Int64, 2} ┐
├────────────────────────┴────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 20:10:20 ForwardOrdered Regular Points,
  → Y Sampled{Int64} 5:6 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────┘
  ↓ →  5  6
 20    4  5
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L521-L570" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Touches' href='#DimensionalData.Dimensions.Lookups.Touches'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Touches</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Touches <: ArraySelector

Touches(a, b)
```


Selector that retrieves all indices touching the closed interval 2 values, for the maximum possible area that could interact with the supplied range.

This can be better than `..` when e.g. subsetting an area to rasterize, as you may wish to include pixels that just touch the area, rather than those that fall within it.

Touches is different to using closed intervals when the lookups also contain intervals - if any of the intervals touch, they are included. With `..` they are discarded unless the whole cell interval falls inside the selector interval.

**Example**

```julia
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(5:7)))
A[X(Touches(15, 25)), Y(Touches(4, 6.5))]

# output
┌ 1×2 DimArray{Int64, 2} ┐
├────────────────────────┴────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 20:10:20 ForwardOrdered Regular Points,
  → Y Sampled{Int64} 5:6 ForwardOrdered Regular Points
└─────────────────────────────────────────────────────────────┘
  ↓ →  5  6
 20    4  5
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L791-L825" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Contains' href='#DimensionalData.Dimensions.Lookups.Contains'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Contains</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Contains <: IntSelector

Contains(x)
Contains(a, b)
```


Selector that selects the interval the value is contained by. If the interval is not present in the lookup, an error will be thrown.

Can only be used for [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals) or [`Categorical`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical). For [`Categorical`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Categorical) it falls back to using [`At`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.At). `Contains` should not be confused with `Base.contains` - use `Where(contains(x))`  to check for if values are contain in categorical values like strings.

`x` can be any value to select a single index, or a `Vector` of values to select vector of indices. If two values `a` and `b`  are used, the range between them will be selected.

**Example**

```julia
using DimensionalData; const DD = DimensionalData
dims_ = X(10:10:20; sampling=DD.Intervals(DD.Center())),
        Y(5:7; sampling=DD.Intervals(DD.Center()))
A = DimArray([1 2 3; 4 5 6], dims_)
A[X(Contains(8)), Y(Contains(6.8))]

# output
3
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L332-L361" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Where' href='#DimensionalData.Dimensions.Lookups.Where'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Where</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Where <: ArraySelector

Where(f::Function)
```


Selector that filters a dimension lookup by any function that accepts a single value and returns a `Bool`.

**Example**

```julia
using DimensionalData

A = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(19:21)))
A[X(Where(x -> x > 15)), Y(Where(x -> x in (19, 21)))]

# output

┌ 1×2 DimArray{Int64, 2} ┐
├────────────────────────┴─────────────────────────────── dims ┐
  ↓ X Sampled{Int64} [20] ForwardOrdered Irregular Points,
  → Y Sampled{Int64} [19, 21] ForwardOrdered Irregular Points
└──────────────────────────────────────────────────────────────┘
  ↓ →  19  21
 20     4   6
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L966-L992" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.All' href='#DimensionalData.Dimensions.Lookups.All'><span class="jlbinding">DimensionalData.Dimensions.Lookups.All</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
All <: Selector

All(selectors::Selector...)
```


Selector that combines the results of other selectors. The indices used will be the union of all result sorted in ascending order.

**Example**

```julia
using DimensionalData, Unitful

dimz = X(10.0:20:200.0), Ti(1u"s":5u"s":100u"s")
A = DimArray((1:10) * (1:20)', dimz)
A[X=All(At(10.0), At(50.0)), Ti=All(1u"s"..10u"s", 90u"s"..100u"s")]

# output

┌ 2×4 DimArray{Int64, 2} ┐
├────────────────────────┴─────────────────────────────────────────────── dims ┐
  ↓ X Sampled{Float64} [10.0, 50.0] ForwardOrdered Irregular Points,
  → Ti Sampled{Unitful.Quantity{Int64, 𝐓, Unitful.FreeUnits{(s,), 𝐓, nothing}}} [1 s, …, 96 s] ForwardOrdered Irregular Points
└──────────────────────────────────────────────────────────────────────────────┘
  ↓ →  1 s  6 s  91 s  96 s
 10.0  1    2    19    20
 50.0  3    6    57    60
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/selector.jl#L1006-L1034" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Lookup traits {#Lookup-traits}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.LookupTrait' href='#DimensionalData.Dimensions.Lookups.LookupTrait'><span class="jlbinding">DimensionalData.Dimensions.Lookups.LookupTrait</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
LookupTrait
```


Abstract supertype of all traits of a [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup).

These modify the behaviour of the lookup index.

The term &quot;Trait&quot; is used loosely - these may be fields of an object of traits hard-coded to specific types.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L2-L11" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Order {#Order}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Order' href='#DimensionalData.Dimensions.Lookups.Order'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Order</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Order <: LookupTrait
```


Traits for the order of a [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup). These determine how `searchsorted` finds values in the index, and how objects are plotted.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L14-L19" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Ordered' href='#DimensionalData.Dimensions.Lookups.Ordered'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Ordered</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Ordered <: Order
```


Supertype for the order of an ordered [`Lookup`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Lookup), including [`ForwardOrdered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.ForwardOrdered) and [`ReverseOrdered`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.ReverseOrdered).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L22-L27" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.ForwardOrdered' href='#DimensionalData.Dimensions.Lookups.ForwardOrdered'><span class="jlbinding">DimensionalData.Dimensions.Lookups.ForwardOrdered</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ForwardOrdered <: Ordered

ForwardOrdered()
```


Indicates that the `Lookup` index is in the normal forward order.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L40-L46" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.ReverseOrdered' href='#DimensionalData.Dimensions.Lookups.ReverseOrdered'><span class="jlbinding">DimensionalData.Dimensions.Lookups.ReverseOrdered</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
ReverseOrdered <: Ordered

ReverseOrdered()
```


Indicates that the `Lookup` index is in the reverse order.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L49-L55" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Unordered' href='#DimensionalData.Dimensions.Lookups.Unordered'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Unordered</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Unordered <: Order

Unordered()
```


Indicates that `Lookup` is unordered.

This means the index cannot be searched with `searchsortedfirst` or similar optimised methods - instead it will use `findfirst`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L58-L67" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AutoOrder' href='#DimensionalData.Dimensions.Lookups.AutoOrder'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AutoOrder</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AutoOrder <: Order

AutoOrder()
```


Specifies that the `Order` of a `Lookup` will be found automatically where possible.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L30-L37" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Span {#Span}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Span' href='#DimensionalData.Dimensions.Lookups.Span'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Span</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Span <: LookupTrait
```


Defines the type of span used in a [`Sampling`](/api/lookuparrays#Sampling) index. These are [`Regular`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Regular) or [`Irregular`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Irregular).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L194-L199" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Regular' href='#DimensionalData.Dimensions.Lookups.Regular'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Regular</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Regular <: Span

Regular(step=AutoStep())
```


`Points` or `Intervals` that have a fixed, regular step.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L221-L227" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Irregular' href='#DimensionalData.Dimensions.Lookups.Irregular'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Irregular</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Irregular <: Span

Irregular(bounds::Tuple)
Irregular(lowerbound, upperbound)
```


`Points` or `Intervals` that have an `Irregular` step size. To enable bounds tracking and accurate selectors, the starting bounds are provided as a 2 tuple, or 2 arguments. `(nothing, nothing)` is acceptable input, the bounds will be guessed from the index, but may be inaccurate.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L238-L248" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Explicit' href='#DimensionalData.Dimensions.Lookups.Explicit'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Explicit</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Explicit(bounds::AbstractMatrix)
```


Intervals where the span is explicitly listed for every interval.

This uses a matrix where with length 2 columns for each index value, holding the lower and upper bounds for that specific index.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L260-L267" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AutoSpan' href='#DimensionalData.Dimensions.Lookups.AutoSpan'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AutoSpan</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AutoSpan <: Span

AutoSpan()
```


The span will be guessed and replaced in `format` or `set`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L206-L212" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Sampling {#Sampling}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Sampling' href='#DimensionalData.Dimensions.Lookups.Sampling'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Sampling</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Sampling <: LookupTrait
```


Indicates the sampling method used by the index: [`Points`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Points) or [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L148-L153" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Points' href='#DimensionalData.Dimensions.Lookups.Points'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Points</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Points <: Sampling

Points()
```


[`Sampling`](/api/lookuparrays#Sampling) lookup where single samples at exact points.

These are always plotted at the center of array cells.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L162-L170" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Intervals' href='#DimensionalData.Dimensions.Lookups.Intervals'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Intervals</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Intervals <: Sampling

Intervals(locus::Position)
```


[`Sampling`](/api/lookuparrays#Sampling) specifying that sampled values are the mean (or similar) value over an _interval_, rather than at one specific point.

Intervals require a [`locus`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.locus) of [`Start`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Start), [`Center`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Center) or [`End`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.End) to define the location in the interval that the index values refer to.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L175-L185" target="_blank" rel="noreferrer">source</a></Badge>

</details>


### Positions {#Positions}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Position' href='#DimensionalData.Dimensions.Lookups.Position'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Position</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Position <: LookupTrait
```


Abstract supertype of types that indicate the locus of index values where they represent [`Intervals`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Intervals).

These allow for values array cells to align with the [`Start`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Start), [`Center`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.Center), or [`End`](/api/lookuparrays#DimensionalData.Dimensions.Lookups.End) of values in the lookup index.

This means they can be plotted with correct axis markers, and allows automatic conversions to between formats with different standards (such as NetCDF and GeoTiff).


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L74-L85" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Center' href='#DimensionalData.Dimensions.Lookups.Center'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Center</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Center <: Position

Center()
```


Used to specify lookup values correspond to the center locus in an interval.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L88-L94" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Start' href='#DimensionalData.Dimensions.Lookups.Start'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Start</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Start <: Position

Start()
```


Used to specify lookup values correspond to the start locus of an interval.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L97-L103" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Begin' href='#DimensionalData.Dimensions.Lookups.Begin'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Begin</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Begin <: Position

Begin()
```


Used to specify the `begin` index of a `Dimension` axis,  as regular `begin` will not work with named dimensions.

Can be used with `:` to create a `BeginEndRange` or  `BeginEndStepRange`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L106-L116" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.End' href='#DimensionalData.Dimensions.Lookups.End'><span class="jlbinding">DimensionalData.Dimensions.Lookups.End</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
End <: Position

End()
```


Used to specify the `end` index of a `Dimension` axis,  as regular `end` will not work with named dimensions. Can be used with `:` to create a `BeginEndRange` or  `BeginEndStepRange`.

Also used to specify lookup values correspond to the end  locus of an interval.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L119-L131" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AutoPosition' href='#DimensionalData.Dimensions.Lookups.AutoPosition'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AutoPosition</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AutoPosition <: Position

AutoPosition()
```


Indicates a interval where the index locus is not yet known. This will be filled with a default value on object construction.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/lookup_traits.jl#L134-L141" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Metadata {#Metadata}
<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.AbstractMetadata' href='#DimensionalData.Dimensions.Lookups.AbstractMetadata'><span class="jlbinding">DimensionalData.Dimensions.Lookups.AbstractMetadata</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
AbstractMetadata{X,T}
```


Abstract supertype for all metadata wrappers.

Metadata wrappers allow tracking the contents and origin of metadata. This can  facilitate conversion between metadata types (for saving a file to a different format) or simply saving data back to the same file type with identical metadata.

Using a wrapper instead of `Dict` or `NamedTuple` also lets us pass metadata  objects to [`set`](/object_modification#set) without ambiguity about where to put them.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/metadata.jl#L2-L13" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.Metadata' href='#DimensionalData.Dimensions.Lookups.Metadata'><span class="jlbinding">DimensionalData.Dimensions.Lookups.Metadata</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
Metadata <: AbstractMetadata

Metadata{X}(val::Union{Dict,NamedTuple})
Metadata{X}(pairs::Pair...) => Metadata{Dict}
Metadata{X}(; kw...) => Metadata{NamedTuple}
```


General [`Metadata`](/api/lookuparrays#Metadata) object. The `X` type parameter categorises the metadata for method dispatch, if required. 


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/metadata.jl#L31-L40" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.NoMetadata' href='#DimensionalData.Dimensions.Lookups.NoMetadata'><span class="jlbinding">DimensionalData.Dimensions.Lookups.NoMetadata</span></a> <Badge type="info" class="jlObjectType jlType" text="Type" /></summary>



```julia
NoMetadata <: AbstractMetadata

NoMetadata()
```


Indicates an object has no metadata. But unlike using `nothing`,  `get`, `keys` and `haskey` will still work on it, `get` always returning the fallback argument. `keys` returns `()` while `haskey` always returns `false`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/Lookups/metadata.jl#L67-L76" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='DimensionalData.Dimensions.Lookups.units' href='#DimensionalData.Dimensions.Lookups.units'><span class="jlbinding">DimensionalData.Dimensions.Lookups.units</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
units(x) => Union{Nothing,Any}
units(xs:Tuple) => Tuple
unit(A::AbstractDimArray, dims::Tuple) => Tuple
unit(A::AbstractDimArray, dim) => Union{Nothing,Any}
```


Get the units of an array or `Dimension`, or a tuple of of either.

Units do not have a set field, and may or may not be included in `metadata`. This method is to facilitate use in labels and plots when units are available, not a guarantee that they will be. If not available, `nothing` is returned.

Second argument `dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/rafaqz/DimensionalData.jl/blob/8446f5fd08ccf8a1d6af118e834781bcd077e812/src/interface.jl#L142-L156" target="_blank" rel="noreferrer">source</a></Badge>

</details>

