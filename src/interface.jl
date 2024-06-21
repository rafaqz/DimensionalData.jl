# `rebuild` and `dims` are key methods to add for a new type

"""
    rebuild(x; kw...)

Rebuild an object struct with updated field values.

`x` can be a `AbstractDimArray`, a `Dimension`, `Lookup` or other custom types.

This is an abstraction that allows inbuilt and custom types to be rebuilt
to update their fields, as most objects in DimensionalData.jl are immutable.

Rebuild is mostly automated using `ConstructionBase.setproperties`. 
It should only be defined if your object has fields with 
with different names to DimensionalData objects. Try not to do that!

The arguments required are defined for the abstract type that has a `rebuild` method.

#### `AbstractBasicDimArray`:
- `dims`: a `Tuple` of `Dimension` 

#### `AbstractDimArray`:

- `data`: the parent object - an `AbstractArray`
- `dims`: a `Tuple` of `Dimension` 
- `refdims`: a `Tuple` of `Dimension` 
- `name`: A Symbol, or `NoName` and `Name` on GPU.
- `metadata`: A `Dict`-like object

#### `AbstractDimStack`:

- `data`: the parent object, often a `NamedTuple`
- `dims`, `refdims`, `metadata`

#### `Dimension`:

- `val`: anything.

#### `Lookup`:

- `data`: the parent object, an `AbstractArray`

* Note: argument `rebuild` is deprecated on `AbstractDimArray` and 
`AbstractDimStack` in favour of always using the keyword version. 
In future the argument version will only be used on `Dimension`, which only have one argument.
"""
function rebuild end

"""
    dims(x, [dims::Tuple]) => Tuple{Vararg{Dimension}}
    dims(x, dim) => Dimension

Return a tuple of `Dimension`s for an object, in the order that matches
the axes or columns of the underlying data.

`dims` can be `Dimension`, `Dimension` types, or `Symbols` for `Dim{Symbol}`.

The default is to return `nothing`.
"""
function dims end

"""
    refdims(x, [dims::Tuple]) => Tuple{Vararg{Dimension}}
    refdims(x, dim) => Dimension

Reference dimensions for an array that is a slice or view of another
array with more dimensions.

`slicedims(a, dims)` returns a tuple containing the current new dimensions
and the new reference dimensions. Refdims can be stored in a field or discarded,
as it is mostly to give context to plots. Ignoring refdims will simply leave some
captions empty.

The default is to return an empty `Tuple` `()`.
"""
function refdims end
refdims(x, lookup) = dims(refdims(x), lookup)

"""
    val(x)
    val(dims::Tuple) => Tuple

Return the contained value of a wrapper object.

`dims` can be `Dimension`, `Dimension` types, or `Symbols` for `Dim{Symbol}`.

Objects that don't define a `val` method are returned unaltered.
"""
function val end

"""
    lookup(x::Dimension) => Lookup
    lookup(x, [dims::Tuple]) => Tuple{Vararg{Lookup}}
    lookup(x::Tuple) => Tuple{Vararg{Lookup}}
    lookup(x, dim) => Lookup

Returns the [`Lookup`](@ref) of a dimension. This dictates
properties of the dimension such as array axis and lookup order,
and sampling properties.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.

This is separate from `val` in that it will only work when dimensions
actually contain an `AbstractArray` lookup, and can be used on a 
`DimArray` or `DimStack` to retrieve all lookups, as there is no ambiguity 
of meaning as there is with `val`.
"""
function lookup end

# Methods to retrieve Object/Dimension/Lookup properties
#
# These work on AbstractDimStack, AbstractDimArray, Dimension
# Lookup, and tuples of Dimension/Lookup. A `dims` argument
# can be supplied to select a subset of dimensions or a single
# Dimension.

"""
    metadata(x) => (object metadata)
    metadata(x, dims::Tuple)  => Tuple (Dimension metadata)
    metadata(xs::Tuple) => Tuple

Returns the metadata for an object or for the specified dimension(s)

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function metadata end

"""
    name(x) => Symbol
    name(xs:Tuple) => NTuple{N,Symbol}
    name(x, dims::Tuple) => NTuple{N,Symbol}
    name(x, dim) => Symbol

Get the name of an array or Dimension, or a tuple of of either as a Symbol.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function name end

"""
    units(x) => Union{Nothing,Any}
    units(xs:Tuple) => Tuple
    unit(A::AbstractDimArray, dims::Tuple) => Tuple
    unit(A::AbstractDimArray, dim) => Union{Nothing,Any}

Get the units of an array or `Dimension`, or a tuple of of either.

Units do not have a set field, and may or may not be included in `metadata`.
This method is to facilitate use in labels and plots when units are available,
not a guarantee that they will be. If not available, `nothing` is returned.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function units end

"""
    label(x) => String
    label(x, dims::Tuple) => NTuple{N,String}
    label(x, dim) => String
    label(xs::Tuple) => NTuple{N,String}

Get a plot label for data or a dimension. This will include the name and units
if they exist, and anything else that should be shown on a plot.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function label end

"""
    bounds(xs, [dims::Tuple]) => Tuple{Vararg{Tuple{T,T}}}
    bounds(xs::Tuple) => Tuple{Vararg{Tuple{T,T}}}
    bounds(x, dim) => Tuple{T,T}
    bounds(dim::Union{Dimension,Lookup}) => Tuple{T,T}

Return the bounds of all dimensions of an object, of a specific dimension,
or of a tuple of dimensions.

If bounds are not known, one or both values may be `nothing`.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
function bounds end

"""
    order(x, [dims::Tuple]) => Tuple
    order(xs::Tuple) => Tuple
    order(x::Union{Dimension,Lookup}) => Order

Return the `Ordering` of the dimension lookup for each dimension:
`ForwardOrdered`, `ReverseOrdered`, or [`Unordered`](@ref) 

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function order end

"""
    sampling(x, [dims::Tuple]) => Tuple
    sampling(x, dim) => Sampling
    sampling(xs::Tuple) => Tuple{Vararg{Sampling}}
    sampling(x:Union{Dimension,Lookup}) => Sampling

Return the [`Sampling`](@ref) for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function sampling end

"""
    span(x, [dims::Tuple]) => Tuple
    span(x, dim) => Span
    span(xs::Tuple) => Tuple{Vararg{Span,N}}
    span(x::Union{Dimension,Lookup}) => Span

Return the [`Span`](@ref) for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function span end

"""
    locus(x, [dims::Tuple]) => Tuple
    locus(x, dim) => Locus
    locus(xs::Tuple) => Tuple{Vararg{Locus,N}}
    locus(x::Union{Dimension,Lookup}) => Locus

Return the [`Position`](@ref) of lookup values for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function locus end

"""
    hasselection(x, selector) => Bool
    hasselection(x, selectors::Tuple) => Bool

Check if indexing into x with `selectors` can be performed, where
x is some object with a `dims` method, and `selectors` is a `Selector`
or `Dimension` or a tuple of either.
"""
function hasselection end
