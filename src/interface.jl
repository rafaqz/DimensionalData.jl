# `rebuild` and `dims` are key methods to add for a new type

"""
    rebuild(x, args...)
    rebuild(x; kw...)

Rebuild an object struct with updated field values.

`x` can be a `AbstractDimArray`, a `Dimension`, `LookupArray` or other custom types.

This is an abstraction that alows inbuilt and custom types to be rebuilt
to update their fields, as most objects in DimensionalData.jl are immutable.

The arguments version can be concise but depends on a fixed order defined for some
DimensionalData objects. It should be defined based on the object type in DimensionalData,
adding the fields specific to your object.

The keyword version ignores order, and is mostly automated 
using `ConstructionBase.setproperties`. It should only be defined if your object has 
missing fields or fields with different names to DimensionalData objects.

The arguments required are defined for the abstract type that has a `rebuild` method.
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
    lookup(x::Dimension) => LookupArray
    lookup(x, [dims::Tuple]) => Tuple{Vararg{LookupArray}}
    lookup(x::Tuple) => Tuple{Vararg{LookupArray}}
    lookup(x, dim) => LookupArray

Returns the [`LookupArray`](@ref) of a dimension. This dictates
properties of the dimension such as array axis and index order,
and sampling properties.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
function lookup end

# Methods to retreive Object/Dimension/LookupArray properties
#
# These work on AbstractDimStack, AbstractDimArray, Dimension
# LookupArray, and tuples of Dimension/LookupArray. A `dims` argument
# can be supplied to select a subset of dimensions or a single
# Dimension.

"""
    index(x) => Tuple{Vararg{AbstractArray}}
    index(x, dims::Tuple) => Tuple{Vararg{AbstractArray}}
    index(dims::Tuple) => Tuple{Vararg{AbstractArray}}}
    index(x, dim) => AbstractArray
    index(dim::Dimension) => AbstractArray

Return the contained index of a `Dimension`.

Only valid when a `Dimension` contains an `AbstractArray`
or a Val tuple like `Val{(:a, :b)}()`. The `Val` is unwrapped
to return just the `Tuple`

`dims` can be a `Dimension`, or a tuple of `Dimension`.
"""
function index end

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
    bounds(dim::Union{Dimension,LookupArray}) => Tuple{T,T}

Return the bounds of all dimensions of an object, of a specific dimension,
or of a tuple of dimensions.

If bounds are not known, one or both values may be `nothing`.

`dims` can be a `Dimension`, a dimension type, or a tuple of either.
"""
function bounds end

"""
    order(x, [dims::Tuple]) => Tuple
    order(xs::Tuple) => Tuple
    order(x::Union{Dimension,LookupArray}) => Order

Return the `Ordering` of the dimension index for each dimension:
`ForwardOrdered`, `ReverseOrdered`, or [`Unordered`](@ref) 

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function order end

"""
    sampling(x, [dims::Tuple]) => Tuple
    sampling(x, dim) => Sampling
    sampling(xs::Tuple) => Tuple{Vararg{Sampling}}
    sampling(x:Union{Dimension,LookupArray}) => Sampling

Return the [`Sampling`](@ref) for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function sampling end

"""
    span(x, [dims::Tuple]) => Tuple
    span(x, dim) => Span
    span(xs::Tuple) => Tuple{Vararg{Span,N}}
    span(x::Union{Dimension,LookupArray}) => Span

Return the [`Span`](@ref) for each dimension.

Second argument `dims` can be `Dimension`s, `Dimension` types,
or `Symbols` for `Dim{Symbol}`.
"""
function span end

"""
    locus(x, [dims::Tuple]) => Tuple
    locus(x, dim) => Locus
    locus(xs::Tuple) => Tuple{Vararg{Locus,N}}
    locus(x::Union{Dimension,LookupArray}) => Locus

Return the [`Locus`](@ref) for each dimension.

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



# Interfaces.jl interface

function rebuild_all(A)
    # argument version
    A1 = rebuild(A, parent(A), dims(A), refdims(A), name(A), metadata(A))
    # keyword version, will work magically using ConstructionBase.jl if you use the same fieldnames.
    # If not, define it and remap these names to your fields.
    A2 = rebuild(A; data=parent(A), dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A))
    # all should be identical. If any fields are not used, they will always be `nothing` or `()` for `refdims`
    return parent(A) === parent(A1) === parent(A2) &&
        dims(A) === dims(A1) === dims(A2) &&
        refdims(A) === refdims(A1) === refdims(A2) &&
        metadata(A) === metadata(A1) === metadata(A2) &&
        name(A) === name(A1) === name(A2)
end


const array_test = (;
    mandatory = (
        dims = (
            "defines a `dims` method" => A -> dims(A) isa Tuple{Vararg{Dimension}},
            "dims are updated on getindex" => A -> dims(view(A, rebuild(first(dims(A)), 1))),
        ),
        refdims_base = "`refdims` returns a tuple of Dimension or empty" => A -> refdims(A) isa Tuple{Vararg{Dimension}},
        ndims = "number of dims matches dimensions of array" => A -> length(dims(A)) == ndims(A),
        size = "length of dims matches dimensions of array" => A -> map(length, dims(A)) == size(A),
        rebuild=rebuild_all,
        rebuild_parent = A -> parent(rebuild(A, parent(A))) == parent(A),
        rebuild_dims = A -> dims(rebuild(A, parent(A), dims(A))) == dims(A),
        rebuild_parent_kw = A -> parent(rebuild(A; data=parent(A))) == parent(A),
        rebuild_dims_kw = A -> dims(rebuild(A; dims=dims(A))) == dims(A),
        getindex_dims = A -> dims(rebuild(A; dims=dims(A))) == dims(A),
    ),
    optional = (;
        refdims = (
            "refdims are updated in args rebuild" =>
              A -> refdims(rebuild(A, parent(A), dims(A), refdims(A))) == refdims(A),
            "refdims are updated in kw rebuild" =>
              A -> refdims(rebuild(A; refdims=refdims(A))) == refdims(A),
            "dropped dimensions are added to refdims" =>
                  A -> refdims(view(A, rebuild(first(dims(A)), 1))) isa Tuple{<:Dimension},
        ),
        name = (
            "rebuild updates name in arg rebuild" =>
                A -> DD.name(rebuild(A, parent(A), DD.dims(A), DD.refdims(A), DD.name(A))) === DD.name(A),
            "rebuild updates name in kw rebuild" =>
                A -> DD.name(rebuild(A; name=DD.name(A))) === DD.name(A),
        ),
        metadata = (
            "rebuild updates metadata in arg rebuild" => 
                A -> metadata(rebuild(A, parent(A), DD.dims(A), refdims(A), name(A), metadata(A))) === metadata(A),
            "rebuild updates metadata in kw rebuild" => 
                A -> metadata(rebuild(A; metadata=metadata(A))) === metadata(A),
        )
    )
) 

const stack_tests = (;
    mandatory = (
        dims = (
            "defines a `dims` method" => A -> dims(A) isa Tuple{Vararg{Dimension}},
            "dims are updated on getindex" => A -> dims(view(A, rebuild(first(dims(A)), 1))),
        ),
        refdims_base = "`refdims` returns a tuple of Dimension or empty" => A -> refdims(A) isa Tuple{Vararg{Dimension}},
        ndims = "number of dims matches dimensions of array" => A -> length(dims(A)) == ndims(A),
        size = "length of dims matches dimensions of array" => A -> map(length, dims(A)) == size(A),
        rebuild=rebuild_all,
        rebuild_parent = A -> parent(rebuild(A, parent(A))) == parent(A),
        rebuild_dims = A -> dims(rebuild(A, parent(A), dims(A))) == dims(A),
        rebuild_parent_kw = A -> parent(rebuild(A; data=parent(A))) == parent(A),
        rebuild_dims_kw = A -> dims(rebuild(A; dims=dims(A))) == dims(A),
    ),
    optional = (;
        refdims = (
            "refdims are updated in args rebuild" =>
              A -> refdims(rebuild(A, parent(A), dims(A), refdims(A))) == refdims(A),
            "refdims are updated in kw rebuild" =>
              A -> refdims(rebuild(A; refdims=refdims(A))) == refdims(A),
            "dropped dimensions are added to refdims" =>
                  A -> refdims(view(A, rebuild(first(dims(A)), 1))) isa Tuple{<:Dimension},
        ),
        name = (
            "rebuild updates name in arg rebuild" =>
                A -> DD.name(rebuild(A, parent(A), DD.dims(A), DD.refdims(A), DD.name(A))) === DD.name(A),
            "rebuild updates name in kw rebuild" =>
                A -> DD.name(rebuild(A; name=DD.name(A))) === DD.name(A),
        ),
        metadata = (
            "rebuild updates metadata in arg rebuild" => 
                A -> metadata(rebuild(A, parent(A), DD.dims(A), refdims(A), name(A), metadata(A))) === metadata(A),
            "rebuild updates metadata in kw rebuild" => 
                A -> metadata(rebuild(A; metadata=metadata(A))) === metadata(A),
        )
    )
) 


const array_docs = """
Pass constructed AbstractDimArrays as test data. 

They must not be zero dimensional, and should test at least 1, 2, and 3 dimensions.
"""

const stack_docs = """
Pass constructed AbstractDimArrays as test data. 

They must not be zero dimensional, and should test at least 1, 2, and 3 dimensions.
"""

@interface DimArrayInterface AbstractDimArray array_components array_docs
@interface DimStackInterface AbstractDimStack stack_tests stack_docs


# Interfaces.jl implementations

Interfaces.@implements DimArrayInterface{(:refdims,:name,:metadata)} DimArray [rand(X(10), Y(10)), zeros(Z(10))]
Interfaces.@implements DimStackInterface{(:refdims,:name,:metadata)} DimStack [DimStack(zeros(Z(10))), DimStack(rand(X(10), Y(10))), DimStack(rand(X(10), Y(10)), rand(X(10)))]

