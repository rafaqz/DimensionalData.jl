"""
    Dimension 

Abstract supertype of all dimension types.

Example concrete implementations are [`X`](@ref), [`Y`](@ref), [`Z`](@ref),
[`Ti`](@ref) (Time), and the custom [`Dim`](@ref) dimension.

`Dimension`s label the axes of an `AbstractDimArray`,
or other dimensional objects, and are used to index into an array.

They may also wrap lookup values for each array axis.
This may be any `AbstractVector` matching the array axis length,
but will usually be converted to a `Lookup` when use in a constructed
object.

A `Lookup` gives more details about the dimension, such as that it is
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

┌ 3×5×12 DimArray{Float64, 3} ┐
├─────────────────────────────┴────────────────────────────────────────── dims ┐
  ↓ Y  Categorical{Char} ['a', 'b', 'c'] ForwardOrdered,
  → X  Sampled{Int64} 2:2:10 ForwardOrdered Regular Points,
  ↗ Ti Sampled{DateTime} DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────────────┘
[:, :, 1]
 ↓ →   2    4    6    8    10
  'a'  0.0  0.0  0.0  0.0   0.0
  'b'  0.0  0.0  0.0  0.0   0.0
  'c'  0.0  0.0  0.0  0.0   0.0
```

For simplicity, the same `Dimension` types are also used as wrappers
in `getindex`, like:

```jldoctest Dimension
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
 2021-06-01T00:00:00  0.0
 2021-07-01T00:00:00  0.0
 2021-08-01T00:00:00  0.0
 2021-09-01T00:00:00  0.0
 2021-10-01T00:00:00  0.0
 2021-11-01T00:00:00  0.0
 2021-12-01T00:00:00  0.0
```

A `Dimension` can also wrap [`Selector`](@ref).

```jldoctest Dimension
x = A[X(Between(3, 4)), Y(At('b'))]

# output

┌ 1×12 DimArray{Float64, 2} ┐
├───────────────────────────┴──────────────────────────────────────────── dims ┐
  ↓ X  Sampled{Int64} 4:2:4 ForwardOrdered Regular Points,
  → Ti Sampled{DateTime} DateTime("2021-01-01T00:00:00"):Month(1):DateTime("2021-12-01T00:00:00") ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────────────────┘
 ↓ →   2021-01-01T00:00:00   2021-02-01T00:00:00  …   2021-12-01T00:00:00
 4    0.0                   0.0                      0.0
```
"""
abstract type Dimension{T} end

"""
    IndependentDim <: Dimension

Abstract supertype for independent dimensions. These will plot on the X axis.
"""
abstract type IndependentDim{T} <: Dimension{T} end

"""
    DependentDim <: Dimension

Abstract supertype for dependent dimensions. These will plot on the Y axis.
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
const DimTuple = Tuple{Dimension,Vararg{Dimension}}
const SymbolTuple = Tuple{Symbol,Vararg{Symbol}}
const DimTypeTuple = Tuple{DimType,Vararg{DimType}}
const VectorOfDim = Vector{<:Union{Dimension,DimType,Symbol}}
const DimOrDimType = Union{Dimension,DimType,Symbol}
const AllDims = Union{Symbol,Dimension,DimTuple,SymbolTuple,DimType,DimTypeTuple,VectorOfDim}

# DimensionalData interface methods

struct AutoVal{T,K}
    val::T
    kw::K
end
val(av::AutoVal) = av.val

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
dims(::Tuple{}) = ()
dims(x) = nothing

val(dim::Dimension) = dim.val
refdims(x) = ()

lookup(dim::Dimension{<:AbstractArray}) = val(dim)
lookup(dim::Union{DimType,Val{<:Dimension}}) = NoLookup()

lookuptype(dim::Dimension) = typeof(lookup(dim))
lookuptype(::Type{<:Dimension{L}}) where L = L
lookuptype(x) = NoLookup

name(dim::Dimension) = name(typeof(dim))
name(dim::Val{D}) where D = name(D)
name(dim::Type{D}) where D<:Dimension = nameof(D)
name(s::Symbol) = s

label(x) = string(name(x))

# Lookups methods
Lookups.metadata(dim::Dimension) = metadata(lookup(dim))

Lookups.bounds(dim::Dimension) = bounds(val(dim))
Lookups.intervalbounds(dim::Dimension, args...) = intervalbounds(val(dim), args...)
for f in (:shiftlocus, :maybeshiftlocus)
    @eval function Lookups.$f(locus::Locus, x; dims=Dimensions.dims(x))
        newdims = map(Dimensions.dims(x, dims)) do d
            Lookups.$f(locus, d)
        end
        return setdims(x, newdims)
    end
    @eval Lookups.$f(locus::Locus, d::Dimension) =
        rebuild(d, Lookups.$f(locus, lookup(d)))
end

function hasselection(x, selectors::Union{DimTuple,SelTuple,Selector,Dimension})
    hasselection(dims(x), selectors)
end
hasselection(x::Nothing, selectors::Union{DimTuple,SelTuple,Selector,Dimension}) = false
function hasselection(ds::DimTuple, seldims::DimTuple)
    sorted = dims(seldims, ds)
    hasselection(dims(ds, sorted), map(val, sorted))
end
hasselection(ds::DimTuple, selectors::SelTuple) = all(map(hasselection, ds, selectors))
hasselection(ds::DimTuple, selector::Dimension) = hasselection(dims(ds, selector), selector)
function hasselection(ds::DimTuple, selector::Selector)
    throw(ArgumentError("Cannot select from multiple Dimensions with a single Selector"))
end
hasselection(dim::Dimension, seldim::Dimension) = hasselection(dim, val(seldim))
hasselection(dim::Dimension, sel::Selector) = hasselection(lookup(dim), sel)

for func in (:order, :span, :sampling, :locus)
    @eval ($func)(dim::Dimension) = ($func)(lookup(dim))
end

# Dispatch on Tuple{<:Dimension}, and map to single dim methods
for f in (:val, :index, :lookup, :metadata, :order, :sampling, :span, :locus, :bounds, :intervalbounds,
          :name, :label, :units)
    @eval begin
        $f(ds::Tuple) = map($f, ds)
        $f(::Tuple{}) = ()
        $f(ds::Tuple, i1, I...) = $f(ds, (i1, I...))
        $f(ds::Tuple, I) = $f(dims(ds, name2dim(I)))
    end
end

@inline function selectindices(x, selectors; kw...)
    if dims(x) isa Nothing
        # This object has no dimensions and no `selectindices` method.
        # Just return whatever selectors is, maybe the underlying array can use it.
        return selectors
    else
        # Otherwise select indices based on the object `Dimension`s
        return selectindices(dims(x), selectors; kw...)
    end
end
@inline selectindices(ds::Tuple, sel...; kw...) = selectindices(ds, sel; kw...)
# Cant get this to compile away without a generated function
# The nothing handling is for if `err=_False`, and we want to combine
# multiple `nothing` into a single `nothing` return value
@generated function selectindices(ds::Tuple, sel::Tuple; kw...) 
    tuple_exp = Expr(:tuple)
    for i in eachindex(ds.parameters)
        expr = quote 
            x = selectindices(ds[$i], sel[$i]; kw...)
            isnothing(x) && return nothing
            x
        end
        push!(tuple_exp.args, expr)
    end
    return tuple_exp
end
@inline selectindices(ds::Tuple, sel::Tuple{}; kw...) = () 
@inline selectindices(dim::Dimension, sel; kw...) = selectindices(val(dim), sel; kw...)

# Deprecated
Lookups.index(dim::Dimension{<:AbstractArray}) = index(val(dim))
Lookups.index(dim::Dimension{<:Val}) = unwrap(index(val(dim)))

# Base methods
const ArrayOrVal = Union{AbstractArray,Val}

Base.parent(d::Dimension) = val(d)
Base.eltype(d::Type{<:Dimension{T}}) where T = T
Base.eltype(d::Type{<:Dimension{A}}) where A<:AbstractArray{T} where T = T
Base.size(d::Dimension, args...) = size(val(d), args...)
Base.axes(d::Dimension) = (val(d) isa DimUnitRange ? val(d) : DimUnitRange(axes(val(d), 1), d),)
Base.axes(d::Dimension, i) = axes(d)[i]
Base.eachindex(d::Dimension) = eachindex(val(d))
Base.length(d::Dimension) = length(val(d))
Base.ndims(d::Dimension) = 0
Base.ndims(d::Dimension{<:AbstractArray}) = ndims(val(d))
Base.iterate(d::Dimension{<:AbstractArray}, args...) = iterate(lookup(d), args...)
Base.first(d::Dimension) = val(d)
Base.first(d::Dimension{<:AbstractArray}) = first(lookup(d))
Base.last(d::Dimension) = val(d)
Base.last(d::Dimension{<:AbstractArray}) = last(lookup(d))
Base.IteratorSize(d::Dimension{<:AbstractArray}) = Base.IteratorSize(parent(d))
Base.firstindex(d::Dimension) = 1
Base.lastindex(d::Dimension) = 1
Base.firstindex(d::Dimension{<:AbstractArray}) = firstindex(lookup(d))
Base.lastindex(d::Dimension{<:AbstractArray}) = lastindex(lookup(d))
Base.step(d::Dimension) = step(lookup(d))
Base.Array(d::Dimension{<:AbstractArray}) = collect(lookup(d))
function Base.:(==)(d1::Dimension, d2::Dimension)
    basetypeof(d1) == basetypeof(d2) && val(d1) == val(d2)
end

LookupArrays.ordered_first(d::Dimension{<:AbstractArray}) = ordered_first(lookup(d))
LookupArrays.ordered_last(d::Dimension{<:AbstractArray}) = ordered_last(lookup(d))
LookupArrays.ordered_firstindex(d::Dimension{<:AbstractArray}) = ordered_firstindex(lookup(d))
LookupArrays.ordered_lastindex(d::Dimension{<:AbstractArray}) = ordered_lastindex(lookup(d))

Base.size(dims::DimTuple) = map(length, dims)
Base.CartesianIndices(dims::DimTuple) = CartesianIndices(map(d -> axes(d, 1), dims))

# Extents.jl
function Extents.extent(ds::DimTuple, args...)
    extent_dims = _astuple(dims(ds, args...))
    extent_bounds = bounds(extent_dims)
    return Extents.Extent{name(extent_dims)}(extent_bounds)
end

dims(extent::Extents.Extent{K}) where K = map(rebuild, name2dim(K), values(extent))
dims(extent::Extents.Extent, ds) = dims(dims(extent), ds)

# Produce a 2 * length(dim) matrix of interval bounds from a dim
dim2boundsmatrix(dim::Dimension)  = dim2boundsmatrix(lookup(dim))
function dim2boundsmatrix(lookup::Lookup)
    samp = sampling(lookup)
    samp isa Intervals || error("Cannot create a bounds matrix for $(nameof(typeof(samp)))")
    _dim2boundsmatrix(locus(lookup), span(lookup), lookup)
end

_dim2boundsmatrix(::Locus, span::Explicit, lookup) = val(span)
function _dim2boundsmatrix(::Locus, span::Regular, lookup)
    # Only offset starts and reuse them for ends, 
    # so floating point error is the same.
    starts = Lookups._shiftlocus(Start(), lookup)
    dest = Array{eltype(starts),2}(undef, 2, length(starts))
    # Use `bounds` as the start/end values
    if order(lookup) isa ReverseOrdered
        for i in 1:length(starts) - 1
            dest[1, i] = dest[2, i + 1] = starts[i + firstindex(starts) - 1]
        end
        dest[1, end], dest[2, 1] = bounds(lookup)
    else
        for i in 1:length(starts) - 1
            dest[1, i + 1] = dest[2, i] = starts[i + firstindex(starts)]
        end
        dest[1, 1], dest[2, end] = bounds(lookup)
    end
    return dest
end
@noinline _dim2boundsmatrix(::Center, span::Regular{Dates.TimeType}, lookupj) =
    error("Cannot convert a Center TimeType index to Explicit automatically: use a bounds matrix e.g. Explicit(bnds)")
@noinline _dim2boundsmatrix(::Start, span::Irregular, lookupj) =
    error("Cannot convert Irregular to Explicit automatically: use a bounds matrix e.g. Explicit(bnds)")

"""
    Dim{S}(val=:)

A generic dimension. For use when custom dims are required when loading
data from a file. Can be used as keyword arguments for indexing.

Dimension types take precedence over same named `Dim` types when indexing
with symbols, or e.g. creating Tables.jl keys.

```jldoctest; setup = :(using DimensionalData)
julia> dim = Dim{:custom}(['a', 'b', 'c'])
custom ['a', 'b', 'c']
```
"""
struct Dim{S,T} <: Dimension{T}
    val::T
    function Dim{S}(val; kw...) where {S}
        if length(kw) > 0
            val = AutoVal(val, values(kw))
        end
        new{S,typeof(val)}(val)
    end
    function Dim{S}(val::AbstractArray; kw...) where S
        if length(kw) > 0
            val = AutoLookup(val, values(kw))
        end
        Dim{S,typeof(val)}(val)
    end
    function Dim{S,T}(val::T) where {S,T}
        new{S,T}(val)
    end
end
Dim{S}() where S = Dim{S}(:)

name(::Type{<:Dim{S}}) where S = S
basetypeof(::Type{<:Dim{S}}) where S = Dim{S}
name2dim(s::Val{S}) where S = Dim{S}()

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

metadata(::AnonDim) = NoMetadata()

"""
    @dim typ [supertype=Dimension] [label::String=string(typ)]

Macro to easily define new dimensions. 

The supertype will be inserted into the type of the dim. 
The default is simply `YourDim <: Dimension`. 

Making a Dimension inherit from `XDim`, `YDim`, `ZDim` or `TimeDim` will affect
automatic plot layout and other methods that dispatch on these types. `<: YDim`
are plotted on the Y axis, `<: XDim` on the X axis, etc.

`label` is used in plots and similar, 
if the dimension is short for a longer word.

Example:
```jldoctest
using DimensionalData
using DimensionalData: @dim, YDim, XDim
@dim Lat YDim "Latitude"
@dim Lon XDim "Longitude"
# output

```
"""
macro dim end
macro dim(typ::Symbol, args...)
    dimmacro(typ::Symbol, Dimension, args...)
end
macro dim(typ::Symbol, supertyp::Symbol, args...)
    dimmacro(typ, supertyp, args...)
end

function dimmacro(typ, supertype, label::String=string(typ))
    quote
        Base.@__doc__ struct $typ{T} <: $supertype{T}
            val::T
            function $typ(val; kw...)
                if length(kw) > 0
                    val = $Dimensions.AutoVal(val, values(kw))
                end
                new{typeof(val)}(val)
            end
            $typ{T}(val::T; kw...) where T = new(val::T)
        end
        function $typ(val::AbstractArray; kw...)
            if length(kw) > 0
                val = $Dimensions.AutoLookup(val, values(kw))
            end
            $typ{typeof(val)}(val)
        end
        $typ() = $typ(:)
        $Dimensions.name(::Type{<:$typ}) = $(QuoteNode(Symbol(typ)))
        $Dimensions.name2dim(::Val{$(QuoteNode(typ))}) = $typ()
        $Dimensions.label(::$typ) = $label
        $Dimensions.label(::Type{<:$typ}) = $label
    end |> esc
end

# Define some common dimensions.

"""
    X <: XDim

    X(val=:)

X [`Dimension`](@ref). `X <: XDim <: IndependentDim`

## Examples

```julia
xdim = X(2:2:10)
```

```julia
val = A[X(1)]
```

```julia
mean(A; dims=X)
```
"""
@dim X XDim

"""
    Y <: YDim

    Y(val=:)

Y [`Dimension`](@ref). `Y <: YDim <: DependentDim`

## Examples

```julia
ydim = Y(['a', 'b', 'c'])
```

```julia
val = A[Y(1)]
```

```julia
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
```

```julia
val = A[Z(1)]
```

```julia
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
```

```julia
val = A[Ti(1)]
```

```julia
mean(A; dims=Ti)
```
"""
@dim Ti TimeDim "Time"

const Time = Ti # For some backwards compat
