
abstract type AbstractDimIndices{T,N,D} <: AbstractBasicDimArray{T,N,D} end

dims(di::AbstractDimIndices) = di.dims

Base.size(di::AbstractDimIndices) = map(length, dims(di))
Base.axes(di::AbstractDimIndices) = map(d -> axes(d, 1), dims(di))

# Indexing that returns a new AbstractDimIndices
for f in (:getindex, :dotview, :view)
    T = Union{Colon,AbstractUnitRange}
    @eval function Base.$f(di::AbstractDimIndices, i1::$T, i2::$T, Is::$T...)
        I = (i1, i2, Is...)
        newdims, _ = slicedims(dims(di), I)
        rebuild(di; dims=newdims)
    end
    @eval function Base.$f(di::AbstractDimIndices{<:Any,1}, i::$T)
        rebuild(di; dims=dims(di, 1)[i])
    end
end

(::Type{T})(::Nothing; kw...) where T<:AbstractDimIndices = throw(ArgumentError("Object has no `dims` method"))
(::Type{T})(x; kw...) where T<:AbstractDimIndices = T(dims(x); kw...)
(::Type{T})(dim::Dimension; kw...) where T<:AbstractDimIndices = T((dim,); kw...)

"""
    DimIndices <: AbstractArray

    DimIndices(x)
    DimIndices(dims::Tuple)
    DimIndices(dims::Dimension)

Like `CartesianIndices`, but for `Dimension`s. Behaves as an `Array` of `Tuple`
of `Dimension(i)` for all combinations of the axis indices of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and
is especially useful when combined with `otherdims`, to iterate over the
indices of unknown dimension.

`DimIndices` can be used directly in `getindex` like `CartesianIndices`, 
and freely mixed with individual `Dimension`s or tuples of `Dimension`.

## Example

Index a `DimArray` with `DimIndices`.

Notice that unlike CartesianIndices, it doesn't matter if
the dimensions are not in the same order. Or even if they
are not all contained in each.

```julia
julia> A = rand(Y(0.0:0.3:1.0), X('a':'f'))
╭─────────────────────────╮
│ 4×6 DimArray{Float64,2} │
├─────────────────────────┴─────────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.3:0.9 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':1:'f' ForwardOrdered
└───────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'b'        'c'       'd'       'e'       'f'
 0.0  0.513225  0.377972   0.771862  0.666855  0.837314  0.274402
 0.3  0.13363   0.519241   0.937604  0.288436  0.437421  0.745771
 0.6  0.837621  0.0987936  0.441426  0.88518   0.551162  0.728571
 0.9  0.399042  0.750191   0.56436   0.47882   0.54036   0.113656

julia> di = DimIndices((X(1:2:4), Y(1:2:4)))
╭──────────────────────────────────────────────╮
│ 2×2 DimIndices{Tuple{X{Int64}, Y{Int64}},2}  │
├──────────────────────────────────────────────┴── dims ┐
  ↓ X 1:2:3,
  → Y 1:2:3
└───────────────────────────────────────────────────────┘
 ↓ X 1, → Y 1  ↓ X 1, → Y 3
 ↓ X 3, → Y 1  ↓ X 3, → Y 3

julia> A[di] # Index A with these indices
dims(d) = (X{StepRange{Int64, Int64}}(1:2:3), Y{StepRange{Int64, Int64}}(1:2:3))
╭─────────────────────────╮
│ 2×2 DimArray{Float64,2} │
├─────────────────────────┴─────────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.6:0.6 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':2:'c' ForwardOrdered
└───────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'c'
 0.0  0.513225  0.771862
 0.6  0.837621  0.441426
"""
struct DimIndices{T,N,D<:Tuple{Vararg{Dimension}}} <: AbstractDimIndices{T,N,D}
    dims::D
    # Manual inner constructor for ambiguity only
    function DimIndices{T,N,D}(dims::Tuple{Vararg{Dimension}}) where {T,N,D<:Tuple{Vararg{Dimension}}}
        new{T,N,D}(dims)
    end
end
function DimIndices(dims::D) where {D<:Tuple{Vararg{Dimension}}}
    T = typeof(map(d -> rebuild(d, 1), dims))
    N = length(dims)
    dims = N > 0 ? _dimindices_format(dims) : dims
    DimIndices{T,N,typeof(dims)}(dims)
end

# Forces multiple indices not linear
function Base.getindex(di::DimIndices, i1::Int, i2::Int, I::Int...)
    map(dims(di), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
end
# Dispatch to avoid linear indexing in multidimensionsl DimIndices
function Base.getindex(di::DimIndices{<:Any,1}, i::Int)
    d = dims(di, 1)
    (rebuild(d, d[i]),)
end

_dimindices_format(dims::Tuple{}) = ()
_dimindices_format(dims::Tuple) = map(rebuild, dims, map(_dimindices_axis, dims))

# Allow only CartesianIndices arguments
_dimindices_axis(x::Integer) = Base.OneTo(x)
_dimindices_axis(x::AbstractRange{<:Integer}) = x
# And LookupArray, which we take the axes from
_dimindices_axis(x::Dimension) = parent(axes(x, 1))
_dimindices_axis(x::LookupArray) = axes(x, 1)
_dimindices_axis(x) =
    throw(ArgumentError("`$x` is not a valid input for `DimIndices`. Use `Dimension`s wrapping `Integer`, `AbstractArange{<:Integer}`, or a `LookupArray` (the `axes` will be used)"))

struct DimSlices{T,N,D<:Tuple{Vararg{Dimension}},P} <: AbstractDimIndices{T,N,D}
    parent::P
    dims::D
    # Manual inner constructor for ambiguity only
    function DimSlices{T,N,D,P}(parent::P, dims::D) where {T,N,D,P}
        new{T,N,D,P}(parent)
    end
end
function DimSlices(x; dims, drop=true)
    dims = basedims(DD.dims(x, dims))
    inds = map(d -> rebuild(d, firstindex(d)), dims)
    T = DimStack#typeof(view(x, map(d -> rebuild(d, first(axes(x, d))), dims)...))
    N = length(dims)
    D = typeof(dims)
    DimSlices{T,N,D,typeof(x)}(x, dims)
end

Base.parent(ds::DimSlices) = ds.parent
dims(ds::DimSlices) = dims(parent(ds))

function Base.getindex(ds::DimSlices, i1::Int, i2::Int, I::Int...)
    D = map(dims(ds), (i1, i2, I...)) do d, i
        rebuild(d, axes(d, 1)[i])
    end
    @show D
    view(parent(ds), D...)
end
# Dispatch to avoid linear indexing in multidimensionsl DimIndices
function Base.getindex(ds::DimSlices{<:Any,1}, i::Int)
    d = dims(ds, 1)
    view(parent(ds), rebuild(d, d[i]))
end


"""
    DimPoints <: AbstractArray

    DimPoints(x; order)
    DimPoints(dims::Tuple; order)
    DimPoints(dims::Dimension; order)

Like `CartesianIndices`, but for the point values of the dimension index. 
Behaves as an `Array` of `Tuple` lookup values (whatever they are) for all
combinations of the lookup values of `dims`.

Either a `Dimension`, a `Tuple` of `Dimension` or an object `x`
that defines a `dims` method can be passed in.

# Keywords

- `order`: determines the order of the points, the same as the order of `dims` by default.
"""
struct DimPoints{T,N,D<:DimTuple,O} <: AbstractDimIndices{T,N,D}
    dims::D
    order::O
end
DimPoints(dims::DimTuple; order=dims) = DimPoints(dims, order)
function DimPoints(dims::DimTuple, order::DimTuple)
    order = map(d -> basetypeof(d)(), order)
    T = Tuple{map(eltype, dims)...}
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimPoints{T,N,typeof(dims),typeof(order)}(dims, order)
end

function Base.getindex(dp::DimPoints, i1::Int, i2::Int, I::Int...)
    # Get dim-wrapped point values at i1, I...
    pointdims = map(dims(dp), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
    # Return the unwrapped point sorted by `order
    return map(val, DD.dims(pointdims, dp.order))
end
Base.getindex(di::DimPoints{<:Any,1}, i::Int) = (dims(di, 1)[i],)

_format(dims::Tuple{}) = ()
function _format(dims::Tuple)
    ax = map(d -> axes(val(d), 1), dims)
    return format(dims, ax)
end

# struct Indices{T} <: AbstractSampled{T,O,Regular{Int},Points}

struct DimViews{T,N,D<:DimTuple,A} <: AbstractDimIndices{T,N}
    data::A
    dims::D
    function DimViews(data::A, dims::D) where {A,D<:DimTuple}
        T = typeof(view(data, map(rebuild, dims, map(first, dims))...))
        N = length(dims)
        new{T,N,D,A}(data, dims)
    end
end

function Base.getindex(dv::DimViews, i1::Int, i2::Int, I::Int...)
    # Get dim-wrapped point values at i1, I...
    D = map(dims(dv), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
    # Return the unwrapped point sorted by `order
    return view(dv.data, D...)
end
function Base.getindex(dv::DimViews{<:Any,1}, i::Int) 
    d = dims(dv, 1)
    return view(dv.data, rebuild(d, d[i]))
end
Base.getindex(dv::DimViews, i::Int) = dv[Tuple(CartesianIndices(dv)[i])...]

"""
    DimSelectors <: AbstractArray

    DimSelectors(x; selectors, atol...)
    DimSelectors(dims::Tuple; selectors, atol...)
    DimSelectors(dims::Dimension; selectors, atol...)

Like [`DimIndices`](@ref), but returns `Dimensions` holding
the chosen [`Selector`](@ref)s. 

Indexing into another `AbstractDimArray` with `DimSelectors` 
is similar to doing an interpolation.

## Keywords

- `selectors`: `Near`, `At` or `Contains`, or a mixed tuple of these. 
    `At` is the default, meaning only exact or within `atol` values are used.
- `atol`: used for `At` selectors only, as the `atol` value.

## Example

Here we can interpolate a `DimArray` to the lookups of another `DimArray`
using `DimSelectors` with `Near`. This is essentially equivalent to 
nearest neighbour interpolation.

```julia
julia> A = rand(X(1.0:3.0:30.0), Y(1.0:5.0:30.0), Ti(1:2));

julia> target = rand(X(1.0:10.0:30.0), Y(1.0:10.0:30.0));

julia> A[DimSelectors(target; selectors=Near), Ti=2]
╭───────────────────────────╮
│ 3×3×2 DimArray{Float64,3} │
├───────────────────────────┴──────────────────────────────────────── dims ┐
  ↓ X  Sampled{Float64} [1.0, 10.0, 22.0] ForwardOrdered Irregular Points,
  → Y  Sampled{Float64} [1.0, 11.0, 21.0] ForwardOrdered Irregular Points,
└──────────────────────────────────────────────────────────────────────────┘
  ↓ →  1.0       11.0       21.0
  1.0  0.473548   0.773863   0.541381
 10.0  0.951457   0.176647   0.968292
 22.0  0.822979   0.980585   0.544853
```

Using `At` would make sure we only use exact interpolation,
while `Contains` with sampleing of `Intervals` would make sure that 
each values is taken only from an Interval that is present in the lookups.
"""
struct DimSelectors{T,N,D<:Tuple{Dimension,Vararg{Dimension}},S<:Tuple} <: AbstractDimIndices{T,N,D}
    dims::D
    selectors::S
end
function DimSelectors(dims::DimTuple; atol=nothing, selectors=At)
    s = _format_selectors(dims, selectors, atol)
    DimSelectors(dims, s)
end
function DimSelectors(dims::DimTuple, selectors::Tuple)
    T = typeof(map(rebuild, dims, selectors))
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimSelectors{T,N,typeof(dims),typeof(selectors)}(dims, selectors)
end

@inline _format_selectors(dims::Tuple, selector, atol) =
    _format_selectors(dims, map(_ -> selector, dims), atol)
@inline _format_selectors(dims::Tuple, selectors::Tuple, atol) =
    _format_selectors(dims, selectors, map(_ -> atol, dims))
@inline _format_selectors(dims::Tuple, selectors::Tuple, atol::Tuple) =
    map(_format_selectors, dims, selectors, atol)

@inline _format_selectors(d::Dimension, ::Type{Near}, atol) =
    Near(zero(eltype(d)))
@inline _format_selectors(d::Dimension, ::Type{Contains}, atol) =
    Contains(zero(eltype(d)))
@inline function _format_selectors(d::Dimension, ::Type{At}, atol)
    atolx = _atol(eltype(d), atol)
    v = first(val(d))
    At{typeof(v),typeof(atolx),Nothing}(v, atolx, nothing)
end

_atol(::Type, atol) = atol
_atol(T::Type{<:AbstractFloat}, atol::Nothing) = eps(T)

@propagate_inbounds function Base.getindex(di::DimSelectors, i1::Int, i2::Int, I::Int...)
    map(dims(di), di.selectors, (i1, i2, I...)) do d, s, i
        rebuild(d, rebuild(s; val=d[i])) # At selector with the value at i
    end
end
@propagate_inbounds function Base.getindex(di::DimSelectors{<:Any,1}, i::Int) 
    d = dims(di, 1)
    (rebuild(d, rebuild(di.selectors[1]; val=d[i])),)
end

# Depricated
const DimKeys = DimSelectors 
