# Key methods to add for a new dimensional data type

"""
    rebuild(x, args...)
    rebuild(x; kw...)

Rebuild an object struct with updated field values.

This is an abstraction that alows inbuilt and custom types to be rebuilt
functionally to update them, as most objects in DimensionalData are immutable.

`x` can be a `AbstractDimArray`, a `Dimension`, `IndexMode` or other custom types.

The arguments reuired are defined for the abstract type that has a `rebuild` method.
"""
function rebuild end
rebuild(x; kw...) = ConstructionBase.setproperties(x, (; kw...))

"""
    dims(x) => Tuple{Vararg{<:Dimension}}
    dims(x, dims::Tuple) => Tuple{Vararg{<:Dimension}}
    dims(x, dim) => Dimension

Return a tuple of `Dimension`s for an object, in the order that matches
the axes or columns etc. of the underlying data.

`dims` can be `Dimension`, `Dimension` types, or `Symbols` for `Dim{Symbol}`.

The default is to return `nothing`.
"""
function dims end

"""
    refdims(x) => Tuple{Vararg{<:Dimension}}
    refdims(x, dims::Tuple) => Tuple{Vararg{<:Dimension}}
    refdims(x, dim) => Dimension

Reference dimensions for an array that is a slice or view of another
array with more dimensions.

`slicedims(a, dims)` returns a tuple containing the current new dimensions
and the new reference dimensions. Refdims can be stored in a field or disgarded,
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
    index(dim::Dimension{<:Val}) => Tuple
    index(dim::Dimension{<:AbstractArray}) => AbstractArray
    index(dims::NTuple{N}) => Tuple{Vararg{Union{AbstractArray,Tuple},N}}

Return the contained index of a `Dimension`.

Only valid when a `Dimension` contains an `AbstractArray`
or a Val tuple like `Val{(:a, :b)}()`. The `Val` is unwrapped
to return just the `Tuple`

`dims` can be a `Dimension`, or a tuple of `Dimension`.
"""
function index end

"""
    mode(dim:Dimension) => IndexMode
    mode(dims::Tuple) => Tuple{Vararg{<:IndexMode,N}}
    mode(A::AbstractDimArray, [dims::Tuple]) => Tuple

Returns the [`IndexMode`](@ref) of a dimension. This dictates
properties of the dimension such as array axis and index order,
and sampling properties.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
function mode end

"""
    metadata(dim::Dimension)
    metadata(dims::Tuple{<:Dimension,Vararg})
    metadata(A::AbstractDimArray, dims::Tuple)  => (Dim metadata)
    metadata(A::AbstractDimArray) => (Array metadata)

Returns the metadata for an array or the specified dimension(s).
`dims` can be a `Symbol` (with `Dim{X}`, a `Dimension`, a `Dimension` type,
or a mixed tuple.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
function metadata end

"""
    bounds(dim::Dimension) => Tuple{T,T}}
    bounds(dims::Tuple{<:Dimension,Vararg}) => Tuple{Vararg{<:Tuple{T,T}}}
    bounds(A::AbstractArray, [dims]) => Tuple{Vararg{Tuple{T,T},N}}
    bounds(A::AbstractArray, dim) => Tuple{T,T}

Return the bounds of all dimensions of an object, of a specific dimension,
or of a tuple of dimensions.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
function bounds end

"""
    name(x) => String
    name(xs::NTuple{N,<:Dimension}) => NTuple{N,String}
    name(A::AbstractDimArray, dims::NTuple{N}) => NTuple{N,String}

Get the name of an array or Dimension, or a tuple of of either.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function name end

"""
    units(x) => Union{Nothing,Any}
    units(::NTuple{N}) => NTuple{N}
    unit(A::AbstractDimArray, dims::NTuple{N}) => NTuple{N,String}

Get the units of an array or `Dimension`, or a tuple of of either.

Units do not have a set field, and may or may not be included in `metadata`.
This method is to facilitate use in labels and plots when units are available,
not a guarantee that they will be. If not available, `nothing` is returned.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function units end

"""
    label(x) => String
    label(dims::NTuple{N,<:Dimension}) => NTuple{N,String}
    label(A::AbstractDimArray, dims::NTuple{N,<:Dimension}) => NTuple{N,String}

Get a plot label for data or a dimension. This will include the name and units
if they exist, and anything else that should be shown on a plot.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function label end


"""
    order(dim:Dimension) => Order
    order(dims::Tuple) => Tuple{Vararg{<:Order,N}}
    order(A::AbstractDimArray, [dims::Tuple]) => Tuple

Return the [`Order`](@ref) for each dimension.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function order end

"""
    sampling(dim:Dimension) => Sampling
    sampling(dims::Tuple) => Tuple{Vararg{<:Sampling,N}}
    sampling(A::AbstractDimArray, [dims::Tuple]) => Tuple

Return the [`Sampling`](@ref) for each dimension.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function sampling end

"""
    span(dim:Dimension) => Span
    span(dims::Tuple) => Tuple{Vararg{<:Span,N}}
    span(A::AbstractDimArray, [dims::Tuple]) => Tuple

Return the [`Span`](@ref) for each dimension.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function span end

"""
    locus(dim:Dimension) => Locus
    locus(dims::Tuple) => Tuple{Vararg{<:Locus,N}}
    locus(A::AbstractDimArray, [dims::Tuple]) => Tuple

Return the [`Locus`](@ref) for each dimension.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function locus end

"""
    arrayorder(dim:Dimension) => Union{Forward,Reverse}
    arrayorder(dims::Tuple) => Tuple{Vararg{<:Union{Forward,Reverse},N}}
    arrayorder(A::AbstractDimArray, [dims::Tuple]) => Tuple

Return the [`Order`](@ref) (`Forward` or `Reverse`) of the array,
for each dimension.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function arrayorder end

"""
    indexorder(dim:Dimension) => Union{Forward,Reverse}
    indexorder(dims::Tuple) => Tuple{Vararg{<:Union{Forward,Reverse},N}}
    indexorder(A::AbstractDimArray, [dims::Tuple]) => Tuple

Return the [`Order`](@ref) (`Forward` or `Reverse`) of the dimension index,
for each dimension.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function indexorder end

"""
    relation(dim:Dimension) => Union{Forward,Reverse}
    relation(dims::Tuple) => Tuple{Vararg{<:Union{Forward,Reverse},N}}
    relation(A::AbstractDimArray, [dims::Tuple]) => Tuple

Return the relation (`Forward` or `Reverse`) between the dimension index
and the array axis, for each dimension.

`dims` can be `Dimension`s, `Dimension` types, or `Symbols` for `Dim{Symbol}`.
"""
function relation end
