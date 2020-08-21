"""
Dimension is the abstract supertype of all dimension types.

Example concrete implementations are `X`, `Y`, `Z`, 
`Ti` (Time), and the custom `Dim{:custom}` dimension.

`Dimension`s label the axes of an `AbstractDimesnionalArray`, 
or other dimensional data. 

They may also provide an alternate index to lookup for each array axis.
This may be any `AbstractArray` matching the array axis length, or a `Val`
holding a tuple for compile-time index lookups.

`Dimension`s also have `mode` and `metadata` fields. 

`mode` gives more details about the dimension, such as that it is 
[`Categorical`](@ref) or [`Sampled`](@ref) as [`Points`](@ref) or 
[`Intervals`](@ref) along some transect. DimensionalData will
attempt to guess the mode from the passed-in index value.

`metadata` can hold any metadata object adding more information about 
the array axis - useful for extending DimensionalData for specific 
contexts, like geospatial data in GeoData.jl. By default it is `nothing`.

Example:

```jldoctest Dimension
using Dates
x = X(2:2:10)
y = Y(['a', 'b', 'c'])
ti = Ti(DateTime(2021, 1):Month(1):DateTime(2021, 12))

A = DimArray(rand(3, 5, 12), (y, x, ti))

# output

DimArray with dimensions:
 Y: Char[a, b, c]
 X: 2:2:10
 Time (type Ti): DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00")
and data: 3×5×12 Array{Float64,3}
[:, :, 1]
 0.590845  0.460085  0.200586  0.579672   0.066423
 0.766797  0.794026  0.298614  0.648882   0.956753
 0.566237  0.854147  0.246837  0.0109059  0.646691
[and 11 more slices...]
```

For simplicity, the same `Dimension` types are also used as wrappers 
in `getindex`, like:

```jldoctest Dimension
x = A[X(2), Y(3)]

# output

DimArray with dimensions:
 Time (type Ti): DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00")
and referenced dimensions:
 Y: c
 X: 4
and data: 12-element Array{Float64,1}
[0.854147, 0.950498, 0.496169, 0.658815, 0.082207, 0.431188, 0.0878598, 0.468079, 0.0677996, 0.836482, 0.0813266, 0.661835]
```

A `Dimension` can also wrap [`Selector`](@ref).

```jldoctest Dimension
x = A[X(Between(3, 4)), Y(At('b'))]

# output

DimArray with dimensions:
 X: 4:2:4
 Time (type Ti): DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00")
and referenced dimensions:
 Y: b
and data: 1×12 Array{Float64,2}
 0.794026  0.842714  0.0460428  0.499531  …  0.182757  0.140473  0.52376
```

`Dimension` objects may have [`mode`](@ref) and [`metadata`](@ref) fields
to track additional information about the data and the index, and their relationship.
"""
abstract type Dimension{T,IM,M} end

"""
Abstract supertype for independent dimensions. Thise will plot on the X axis.
"""
abstract type IndependentDim{T,IM,M} <: Dimension{T,IM,M} end

"""
Abstract supertype for Dependent dimensions. These will plot on the Y axis.
"""
abstract type DependentDim{T,IM,M} <: Dimension{T,IM,M} end

"""
Abstract parent type for all X dimensions. 
"""
abstract type XDim{T,IM,M} <: IndependentDim{T,IM,M} end

"""
Abstract parent type for all Y dimensions.
"""
abstract type YDim{T,IM,M} <: DependentDim{T,IM,M} end

"""
Abstract parent type for all Z dimensions.
"""
abstract type ZDim{T,IM,M} <: Dimension{T,IM,M} end

"""
Abstract parent type for all time dimensions.

An index in a `TimeDime` with `Interval` sampling the locus will automatically be
set to `Start()`, as a date/time index generally defines the start of a 
month, second etc, not the central point as is more common with spatial data.
`"""
abstract type TimeDim{T,IM,M} <: IndependentDim{T,IM,M} end

ConstructionBase.constructorof(d::Type{<:Dimension}) = basetypeof(d)

const DimType = Type{<:Dimension}
const DimTuple = Tuple{<:Dimension,Vararg{<:Dimension}}
const DimTypeTuple = Tuple{<:DimType,Vararg{<:DimType}}
const VectorOfDim = Vector{<:Dimension}
const DimOrDimType = Union{Dimension,DimType}
const AllDims = Union{Dimension,DimTuple,DimType,DimTypeTuple,VectorOfDim}


# Getters
val(dim::Dimension) = dim.val
mode(dim::Dimension) = dim.mode
mode(dim::Type{<:Dimension}) = NoIndex()
metadata(dim::Dimension) = dim.metadata

order(dim::Dimension) = order(mode(dim))
indexorder(dim::Dimension) = indexorder(order(dim))
arrayorder(dim::Dimension) = arrayorder(order(dim))
relationorder(dim::Dimension) = relationorder(order(dim))

locus(dim::Dimension) = locus(mode(dim))
sampling(dim::Dimension) = sampling(mode(dim))

index(dim::Dimension) = unwrap(val(dim))

# DimensionalData interface methods
rebuild(dim::D, val, mode::IndexMode=mode(dim), metadata=metadata(dim)) where D <: Dimension =
    constructorof(D)(val, mode, metadata)

dims(x::Dimension) = x
dims(x::DimTuple) = x
name(dim::Dimension) = name(typeof(dim))
shortname(d::Dimension) = shortname(typeof(d))
shortname(d::Type{<:Dimension}) = name(d) # Use `name` as fallback
units(dim::Dimension) =
    metadata(dim) == nothing ? nothing : get(metadata(dim), :units, nothing)


bounds(dim::Dimension) = bounds(mode(dim), dim)
bounds(dims::DimTuple) = map(bounds, dims)
bounds(dims::Tuple{}) = ()
bounds(dims::DimTuple, lookupdims::Tuple) = map(l -> bounds(dims, l), lookupdims)
bounds(dims::DimTuple, lookupdim::DimOrDimType) = bounds(dims[dimnum(dims, lookupdim)])


# Base methods
Base.eltype(dim::Type{<:Dimension{T}}) where T = T
Base.eltype(dim::Type{<:Dimension{A}}) where A<:AbstractArray{T} where T = T
Base.size(dim::Dimension) = size(val(dim))
Base.size(dim::Dimension{<:Val}) = (length(unwrap(val(dim))),)
Base.axes(dim::Dimension) = axes(val(dim))
Base.axes(dim::Dimension{<:Val}) = (Base.OneTo(length(dim)),)
Base.eachindex(dim::Dimension) = eachindex(val(dim))
Base.length(dim::Dimension{<:Union{AbstractArray,Number}}) = length(val(dim))
Base.length(dim::Dimension{<:Val}) = length(unwrap(val(dim)))
Base.ndims(dim::Dimension) = 0
Base.ndims(dim::Dimension{<:AbstractArray}) = ndims(val(dim))
Base.ndims(dim::Dimension{<:Val}) = 1
Base.getindex(dim::Dimension) = val(dim)
Base.getindex(dim::Dimension{<:AbstractArray}, I...) = getindex(val(dim), I...)
Base.getindex(dim::Dimension{<:Val}, i) = Val(getindex(unwrap(val(dim)), i))
Base.iterate(dim::Dimension{<:AbstractArray}, args...) = iterate(val(dim), args...)
Base.first(dim::Dimension) = val(dim)
Base.first(dim::Dimension{<:AbstractArray}) = first(val(dim))
Base.first(dim::Dimension{<:Val}) = first(unwrap(val(dim)))
Base.last(dim::Dimension) = val(dim)
Base.last(dim::Dimension{<:AbstractArray}) = last(val(dim))
Base.last(dim::Dimension{<:Val}) = last(unwrap(val(dim)))
Base.firstindex(dim::Dimension) = 1
Base.lastindex(dim::Dimension) = 1
Base.firstindex(dim::Dimension{<:AbstractArray}) = firstindex(val(dim))
Base.lastindex(dim::Dimension{<:AbstractArray}) = lastindex(val(dim))
Base.lastindex(dim::Dimension{<:Val}) = lastindex(unwrap(val(dim)))
Base.step(dim::Dimension) = step(mode(dim))
Base.Array(dim::Dimension{<:AbstractArray}) = Array(val(dim))
Base.Array(dim::Dimension{<:Val}) = [unwrap(val(dim))...]
Base.:(==)(dim1::Dimension, dim2::Dimension) =
    typeof(dim1) == typeof(dim2) &&
    val(dim1) == val(dim2) &&
    mode(dim1) == mode(dim2) &&
    metadata(dim1) == metadata(dim2)


"""
Dimensions with user-set type paremeters
"""
abstract type ParametricDimension{X,T,IM,M} <: Dimension{T,IM,M} end

"""
    Dim{:X}()
    Dim{:X}(val, mode, metadata)
    Dim{:X}(val=:; [mode=AutoMode()], [metadata=nothing])

A generic dimension. For use when custom dims are required when loading
data from a file. The sintax is ugly and verbose to use for indexing,
ie `Dim{:lat}(1:9)` rather than `Lat(1:9)`. This is the main reason
they are not the only type of dimension availabile.

```jldoctest
dim = Dim{:custom}(['a', 'b', 'c'])

# output

dimension Dim custom (type Dim):
val: Char[a, b, c]
mode: AutoMode{AutoOrder}(AutoOrder())
metadata: nothing
type: Dim{:custom,Array{Char,1},AutoMode{AutoOrder},Nothing}
```
"""
struct Dim{X,T,IM<:IndexMode,M} <: ParametricDimension{X,T,IM,M}
    val::T
    mode::IM
    metadata::M
    Dim{X}(val, mode, metadata) where X =
        new{X,typeof(val),typeof(mode),typeof(metadata)}(val, mode, metadata)
end

Dim{X}(val=:; mode=AutoMode(), metadata=nothing) where X =
    Dim{X}(val, mode, metadata)
name(::Type{<:Dim{X}}) where X = "Dim $X"
shortname(::Type{<:Dim{X}}) where X = "$X"
basetypeof(::Type{<:Dim{X}}) where {X} = Dim{X}

"""
    AnonDim()

Anonymous dimension. Used when extra dimensions are created, 
such as during transpose of a vector.
"""
struct AnonDim{T} <: Dimension{T,NoIndex,Nothing} 
    val::T
end
AnonDim() = AnonDim(Colon())
AnonDim(val, arg1, args...) = AnonDim(val)

val(dim::AnonDim) = dim.val
mode(::AnonDim) = NoIndex()
metadata(::AnonDim) = nothing
name(::AnonDim) = "Anon"

"""
    @dim typ [supertype=Dimension] [name=string(typ)] [shortname=string(typ)]

Macro to easily define new dimensions. The supertype will be inserted
into the type of the dim. The default is simply `YourDim <: Dimension`. Making
a Dimesion inherit from `XDim`, `YDim`, `ZDim` or `TimeDim` will affect 
automatic plot layout and other methods that dispatch on these types. `<: YDim`
are plotted on the Y axis, `<: XDim` on the X axis, etc.

Example:
```julia
@dim Lat "Lattitude" "lat"
@dim Lon XDim "Longitude"
```
"""
macro dim end

macro dim(typ::Symbol, args...)
    dimmacro(typ::Symbol, :Dimension, args...)
end

macro dim(typ::Symbol, supertyp::Symbol, args...)
    dimmacro(typ, supertyp, args...)
end

dimmacro(typ, supertype, name=string(typ), shortname=string(typ)) =
    esc(quote
        Base.@__doc__ struct $typ{T,IM<:IndexMode,M} <: $supertype{T,IM,M}
            val::T
            mode::IM
            metadata::M
        end
        $typ(val=:; mode=AutoMode(), metadata=nothing) =
            $typ(val, mode, metadata)
        DimensionalData.name(::Type{<:$typ}) = $name
        DimensionalData.shortname(::Type{<:$typ}) = $shortname
    end)

# Define some common dimensions.

"""
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

"""
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

# Time dimensions need to default to the Start() locus, as that is
# nearly always the format and Center intervals are difficult to
# calculate with DateTime step values.
identify(locus::AutoLocus, dimtype::Type{<:TimeDim}, index) = Start()

const Time = Ti # For some backwards compat


"""
    formatdims(A, dims)

Format the passed-in dimension(s) `dims` to match the array `A`.

This means converting indexes of `Tuple` to `LinRange`, and running
`identify` on . 
Errors are also thrown if
dims don't match the array dims or size.

If a [`IndexMode`](@ref) hasn't been specified, an mode is chosen
based on the type and element type of the index:
"""
formatdims(A::AbstractArray{T,N} where T, dims::NTuple{N,Any}) where N =
    formatdims(axes(A), dims)
formatdims(axes::Tuple{Vararg{<:AbstractRange}},
           dims::Tuple{Vararg{<:Union{<:Dimension,<:UnionAll}}}) =
    map(formatdims, axes, dims)

formatdims(axis::AbstractRange, dimtype::Type{<:Dimension}) =
    dimtype(axis, NoIndex(), nothing)
formatdims(axis::AbstractRange, dim::Dimension) = begin
    checkaxis(dim, axis)
    rebuild(dim, val(dim), identify(mode(dim), basetypeof(dim), val(dim)))
end
formatdims(axis::AbstractRange, dim::Dimension{<:NTuple{2}}) = begin
    start, stop = val(dim)
    range = LinRange(start, stop, length(axis))
    formatdims(axis, rebuild(dim, range))
end
# Dimensions holding colon dispatch on mode
formatdims(axis::AbstractRange, dim::Dimension{Colon}) =
    formatdims(mode(dim), axis, dim)

# Dimensions holding colon has the array axis inserted as the index
formatdims(mode::AutoMode, axis::AbstractRange, dim::Dimension{Colon}) =
    rebuild(dim, axis, NoIndex())
# Dimensions holding colon has the array axis inserted as the index
formatdims(mode::IndexMode, axis::AbstractRange, dim::Dimension{Colon}) =
    rebuild(dim, axis, mode)

checkaxis(dim, axis) =
    first(axes(dim)) == axis ||
        throw(DimensionMismatch(
            "axes of $(basetypeof(dim)) of $(first(axes(dim))) do not match array axis of $axis"))
