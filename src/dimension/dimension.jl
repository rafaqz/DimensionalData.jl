"""
    Dimension 

Abstract supertype of all dimension types.

Example concrete implementations are [`X`](@ref), [`Y`](@ref), [`Z`](@ref),
[`Ti`](@ref) (Time), and the custom [`Dim`]@ref) dimension.

`Dimension`s label the axes of an [`AbstractDimArray`](@ref),
or other dimensional objects, and are used to index into the array.

They may also provide an alternate index to lookup for each array axis.
This may be any `AbstractVector` matching the array axis length, or a `Val`
holding a tuple for compile-time index lookups.

`Dimension`s also have `lookup` and `metadata` fields.

`lookup` gives more details about the dimension, such as that it is
[`Categorical`](@ref) or [`Sampled`](@ref) as [`Points`](@ref) or
[`Intervals`](@ref) along some transect. DimensionalData will
attempt to guess the lookup from the passed-in index value.

Example:

```jldoctest Dimension
using DimensionalData, Dates

x = X(2:2:10)
y = Y(['a', 'b', 'c'])
ti = Ti(DateTime(2021, 1):Month(1):DateTime(2021, 12))

A = DimArray(zeros(3, 5, 12), (y, x, ti))

# output

3×5×12 DimArray{Float64,3} with dimensions:
  Y Categorical Char[a, b, c] ForwardOrdered,
  X Sampled 2:2:10 ForwardOrdered Regular Points,
  Ti Sampled DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
[:, :, 1]
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
 0.0  0.0  0.0  0.0  0.0
[and 11 more slices...]
```

For simplicity, the same `Dimension` types are also used as wrappers
in `getindex`, like:

```jldoctest Dimension
x = A[X(2), Y(3)]

# output

12-element DimArray{Float64,1} with dimensions:
  Ti Sampled DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
and reference dimensions:
  Y Categorical Char[c] ForwardOrdered,
  X Sampled 4:2:4 ForwardOrdered Regular Points
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
 0.0
```

A `Dimension` can also wrap [`Selector`](@ref).

```jldoctest Dimension
x = A[X(Between(3, 4)), Y(At('b'))]

# output

1×12 DimArray{Float64,2} with dimensions:
  X Sampled 4:2:4 ForwardOrdered Regular Points,
  Ti Sampled DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
and reference dimensions:
  Y Categorical Char[b] ForwardOrdered
 0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0  0.0
```

`Dimension` objects may have [`lookup`](@ref) and [`metadata`](@ref) fields
to track additional information about the data and the index, and their relationship.
"""
abstract type Dimension{T} end

"""
    IndependentDim <: Dimension

Abstract supertype for independent dimensions. Thise will plot on the X axis.
"""
abstract type IndependentDim{T} <: Dimension{T} end

"""
    DependentDim <: Dimension

Abstract supertype for Dependent dimensions. These will plot on the Y axis.
"""
abstract type DependentDim{T} <: Dimension{T} end

"""
    XDim <: IndependentDim

Abstract supertype for all X dimensions.
"""
abstract type XDim{T} <: IndependentDim{T} end

"""
    YDim <: DependentDim

Abstract supertype for all Y dimensions.
"""
abstract type YDim{T} <: DependentDim{T} end

"""
    ZDim <: DependentDim

Abstract supertype for all Z dimensions.
"""
abstract type ZDim{T} <: DependentDim{T} end

"""
    TimeDim <: IndependentDim

Abstract supertype for all time dimensions.

In a `TimeDime` with `Interval` sampling the locus will automatically
be set to `Start()`. Dates and times generally refer to the start of a
month, hour, second etc., not the central point as is more common with spatial data.
`"""
abstract type TimeDim{T} <: IndependentDim{T} end

ConstructionBase.constructorof(d::Type{<:Dimension}) = basetypeof(d)
Adapt.adapt_structure(to, dim::Dimension) = rebuild(dim; val=Adapt.adapt(to, val(dim)))

const DimType = Type{<:Dimension}
const DimTuple = Tuple{<:Dimension,Vararg{<:Dimension}}
const DimTypeTuple = Tuple{<:DimType,Vararg{<:DimType}}
const VectorOfDim = Vector{<:Dimension}
const DimOrDimType = Union{Dimension,DimType}
const AllDims = Union{Dimension,DimTuple,DimType,DimTypeTuple,VectorOfDim}

# DimensionalData interface methods

"""
    rebuild(dim::Dimension, val) => Dimension
    rebuild(dim::Dimension; val=val(dim)) => Dimension

Rebuild dim with fields from `dim`, and new fields passed in.
"""
function rebuild(dim::D, val) where D <: Dimension
    ConstructionBase.constructorof(D)(val)
end

dims(dim::Union{Dimension,DimType,Val{<:Dimension}}) = dim
dims(dims::DimTuple) = dims
dims(x) = nothing
dims(::Nothing) = error("No dims found")

refdims(x) = ()

val(dim::Dimension) = dim.val
lookup(dim::Dimension{<:AbstractArray}) = val(dim)
lookup(dim::Union{DimType,Val{<:Dimension}}) = NoLookup()
metadata(dim::Dimension) = metadata(lookup(dim))

index(dim::Dimension{<:AbstractArray}) = index(val(dim))
index(dim::Dimension{<:Val}) = unwrap(index(val(dim)))

name(dim::Dimension) = name(typeof(dim))
name(dim::Val{D}) where D = name(D)

bounds(dim::Dimension) = bounds(val(dim))

lookuptype(dim::Dimension) = typeof(lookup(dim))
lookuptype(::Type{<:Dimension{L}}) where L = L
lookuptype(x) = NoLookup

function hasselection(x, selectors::Union{DimTuple,SelTuple,Selector,Dimension})
    hasselection(dims(x), selectors)
end
hasselection(x::Nothing, selectors::Union{DimTuple,SelTuple,Selector,Dimension}) = false
function hasselection(dims::DimTuple, seldims::DimTuple)
    sorted = DD.dims(seldims, dims)
    hasselection(DD.dims(dims, sorted), map(val, sorted))
end
hasselection(dims::DimTuple, selectors::SelTuple) = all(map(hasselection, dims, selectors))
function hasselection(dims::DimTuple, selector::Dimension)
    hasselection(DD.dims(dims, selector), selector)
end
function hasselection(dims::DimTuple, selector::Selector)
    throw(ArgumentError("Cannot select from multiple Dimensions with a single Selector"))
end
hasselection(dim::Dimension, seldim::Dimension) = hasselection(dim, val(seldim))
hasselection(dim::Dimension, sel::Selector) = hasselection(lookup(dim), sel)

for func in (:order, :span, :sampling, :locus)
    @eval ($func)(dim::Dimension) = ($func)(lookup(dim))
end

# Dipatch on Tuple{<:Dimension}, and map to single dim methods
for f in (:val, :index, :lookup, :metadata, :order, :sampling, :span, :bounds, :locus,
          :name, :label, :units)
    @eval begin
        $f(dims::DimTuple) = map($f, dims)
        $f(dims::Tuple{}) = ()
        $f(dims::DimTuple, i1, I...) = $f(dims, (i1, I...))
        $f(dims::DimTuple, I) = $f(DD.dims(dims, key2dim(I)))
    end
end

@inline function selectindices(x, selectors)
    if dims(x) isa Nothing
        # This object has no dimensions and no `selectindices` method.
        # Just return whatever it is, maybe the underlying array can use it.
        return selectors
    else
        # Otherwise select indices based on the object `Dimension`s
        return selectindices(dims(x), selectors)
    end
end
@inline selectindices(dims::DimTuple, sel...) = selectindices(dims, sel)
@inline selectindices(dims::DimTuple, sel::Tuple) = selectindices(val(dims), sel)
@inline selectindices(dim::Dimension, sel) = selectindices(val(dim), sel)

# Base methods
const ArrayOrVal = Union{AbstractArray,Val}

Base.eltype(d::Type{<:Dimension{T}}) where T = T
Base.eltype(d::Type{<:Dimension{A}}) where A<:AbstractArray{T} where T = T
Base.size(d::Dimension, args...) = size(val(d), args...)
Base.axes(d::Dimension, args...) = axes(val(d), args...)
Base.eachindex(d::Dimension) = eachindex(val(d))
Base.length(d::Dimension) = length(val(d))
Base.ndims(d::Dimension) = 0
Base.ndims(d::Dimension{<:AbstractArray}) = ndims(val(d))

@inline Base.getindex(d::Dimension) = val(d)
for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds function Base.$f(d::Dimension{<:AbstractArray}, i::StandardIndices)
            x = Base.$f(val(d), i)
            x isa AbstractArray ? rebuild(d, x) : x
        end
        @propagate_inbounds function Base.$f(d::Dimension{<:AbstractArray}, i)
            x = Base.$f(val(d), selectindices(val(d), i))
            x isa AbstractArray ? rebuild(d, x) : x
        end
    end
end
# @propagate_inbounds Base.getindex(d::Dimension{<:Val{Index}}, i) where Index =
    # rebuild(getindex(Index, selectindices(d, i))

Base.iterate(d::Dimension{<:AbstractArray}, args...) = iterate(lookup(d), args...)
Base.first(d::Dimension) = val(d)
Base.first(d::Dimension{<:AbstractArray}) = first(lookup(d))
Base.last(d::Dimension) = val(d)
Base.last(d::Dimension{<:AbstractArray}) = last(lookup(d))
Base.firstindex(d::Dimension) = 1
Base.lastindex(d::Dimension) = 1
Base.firstindex(d::Dimension{<:AbstractArray}) = firstindex(lookup(d))
Base.lastindex(d::Dimension{<:AbstractArray}) = lastindex(lookup(d))
Base.step(d::Dimension) = step(lookup(d))
Base.Array(d::Dimension{<:AbstractArray}) = collect(lookup(d))
function Base.:(==)(d1::Dimension, d2::Dimension)
    basetypeof(d1) == basetypeof(d2) && val(d1) == val(d2)
end

"""
Abstract supertype for Dimensions with user-set type paremeters
"""
abstract type ParametricDimension{X,T} <: Dimension{T} end

"""
    Dim{S}(val=:)

A generic dimension. For use when custom dims are required when loading
data from a file. Can be used as keyword arguments for indexing.

Dimension types take precedence over same named `Dim` types when indexing
with symbols, or e.g. creating Tables.jl keys.

```jldoctest
using DimensionalData

dim = Dim{:custom}(['a', 'b', 'c'])

# output

Dim{:custom} Char[a, b, c]
```
"""
struct Dim{S,T} <: ParametricDimension{S,T}
    val::T
end
Dim{S}(val::T) where {S,T} = Dim{S,T}(val)
function Dim{S}(val::AbstractArray; kw...) where S
    if length(kw) > 0
        val = AutoLookup(val, values(kw))
    end
    Dim{S,typeof(val)}(val)
end
Dim{S}() where S = Dim{S}(:)

name(::Type{<:Dim{S}}) where S = S
basetypeof(::Type{<:Dim{S}}) where S = Dim{S}
key2dim(s::Val{S}) where S = Dim{S}()
dim2key(::Type{D}) where D<:Dim{S} where S = S

"""
    AnonDim <: Dimension

    AnonDim()

Anonymous dimension. Used when extra dimensions are created,
such as during transpose of a vector.
"""
struct AnonDim{T} <: Dimension{T}
    val::T
end
AnonDim() = AnonDim(Colon())
AnonDim(val, arg1, args...) = AnonDim(val)

lookup(::AnonDim) = NoLookup()
metadata(::AnonDim) = NoMetadata()
name(::AnonDim) = :Anon

"""
    @dim typ [supertype=Dimension] [name::String=string(typ)]

Macro to easily define new dimensions. The supertype will be inserted
into the type of the dim. The default is simply `YourDim <: Dimension`. Making
a Dimesion inherit from `XDim`, `YDim`, `ZDim` or `TimeDim` will affect
automatic plot layout and other methods that dispatch on these types. `<: YDim`
are plotted on the Y axis, `<: XDim` on the X axis, etc.

Example:
```julia
@dim Lat YDim "latitude"
@dim Lon XDim "Longitude"
```
"""
macro dim end
macro dim(typ::Symbol, args...)
    dimmacro(typ::Symbol, :(DimensionalData.Dimension), args...)
end
macro dim(typ::Symbol, supertyp::Symbol, args...)
    dimmacro(typ, supertyp, args...)
end

function dimmacro(typ, supertype, name::String=string(typ))
    quote
        Base.@__doc__ struct $typ{T} <: $supertype{T}
            val::T
        end
        function $typ(val::AbstractArray; kw...)
            if length(kw) > 0
                val = AutoLookup(val, values(kw))
            end
            $typ{typeof(val)}(val)
        end
        $typ() = $typ(:)
        DimensionalData.name(::Type{<:$typ}) = $(QuoteNode(Symbol(name)))
        DimensionalData.key2dim(::Val{$(QuoteNode(typ))}) = $typ()
    end |> esc
end

# Define some common dimensions.

"""
    X <: XDim

    X(val=:)

X [`Dimension`](@ref). `X <: XDim <: IndependentDim`

## Example:
```julia
xdim = X(2:2:10)
# Or
val = A[X(1)]
# Or
mean(A; dims=X)
```
"""
@dim X XDim

"""
    Y <: YDim

    Y(val=:)

Y [`Dimension`](@ref). `Y <: YDim <: DependentDim`

## Example:
```julia
ydim = Y(['a', 'b', 'c'])
# Or
val = A[Y(1)]
# Or
mean(A; dims=Y)
```
"""
@dim Y YDim

"""
    Z <: ZDim

    Z(val=:)

Z [`Dimension`](@ref). `Z <: ZDim <: Dimension`

## Example:
```julia
zdim = Z(10:10:100)
# Or
val = A[Z(1)]
# Or
mean(A; dims=Z)
```
"""
@dim Z ZDim

"""m
    Ti <: TimeDim
    
    Ti(val=:)

Time [`Dimension`](@ref). `Ti <: TimeDim <: IndependentDim`

`Time` is already used by Dates, and `T` is a common type parameter,
We use `Ti` to avoid clashes.

## Example:
```julia
timedim = Ti(DateTime(2021, 1):Month(1):DateTime(2021, 12))
# Or
val = A[Ti(1)]
# Or
mean(A; dims=Ti)
```
"""
@dim Ti TimeDim "Time"

const Time = Ti # For some backwards compat
