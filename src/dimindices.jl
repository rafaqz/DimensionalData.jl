abstract type AbstractDimIndices{T,N,D} <: AbstractDimArray{T,N,D,AbstractArray{T,N}} end

# We need to be able to return a non-DimArray from `parent`
# to prevent stack overflows in dispatch. so we just wrap.
struct ParentWrapper{T,N,A<:AbstractDimIndices{T,N}} <: AbstractArray{T,N}
    child::A
end

Base.size(A::ParentWrapper) = size(A.child)
Base.getindex(A::ParentWrapper, I::Int...) = getindex(A.child, I...)

dims(di::AbstractDimIndices) = di.dims
refdims(A::AbstractDimIndices) = ()
data(A::AbstractDimIndices) = ParentWrapper(A)
metadata(A::AbstractDimIndices) = NoMetadata()
name(A::AbstractDimIndices) = Symbol("")

rebuild(di::AbstractDimIndices; kw...) = rebuild(DimArray(di); kw...) 
rebuild(di::AbstractDimIndices, args...) = rebuild(DimArray(di), args...)

Base.size(di::AbstractDimIndices) = map(length, dims(di))
Base.axes(di::AbstractDimIndices) = map(d -> axes(d, 1), dims(di))

for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds Base.$f(A::AbstractDimIndices, i1::Selector, I::Selector...) =
            Base.$f(A, dims2indices(A, i1, I)...)
        @propagate_inbounds function Base.$f(A::AbstractDimIndices, i1::Dimension, I::Dimension...; kw...)
            Base.$f(A, dims2indices(A, i1, I..., kwdims(values(kw))...)...)
        end
    end
end

(::Type{T})(::Nothing; kw...) where T<:AbstractDimIndices = throw(ArgumentError("Object has no `dims` method"))
(::Type{T})(x; kw...) where T<:AbstractDimIndices = T(dims(x); kw...)
(::Type{T})(dim::Dimension; kw...) where T<:AbstractDimIndices = T((dim,); kw...)

_format(dims::Tuple{}) = ()
function _format(dims::Tuple)
    ax = map(d -> axes(val(d), 1), dims)
    return format(dims, ax)
end

"""
    DimIndices <: AbstractDimArray

    DimIndices(x)
    DimIndices(dims::Tuple)
    DimIndices(dims::Dimension)

Like `CartesianIndices`, but for `Dimension`s. Behaves as an `Array` of `Tuple`
of `Dimension(i)` for all combinations of the axis indices of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and
is especially useful when combined with `otherdims`, to iterate over the
indices of unknown dimension.
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
    dims = N > 0 ? _format(dims) : dims
    DimIndices{T,N,typeof(dims)}(dims)
end
function DimIndices(dims::NamedTuple{K}) where K
    DimIndices(map((d, v) -> rebuild(d, v), key2dim(K), values(dims)))
end

name(A::DimIndices) = :indices

function Base.getindex(di::DimIndices, i1::Int, i2::Int, I::Int...)
    map(dims(di), (i1, i2, I...)) do d, i
        rebuild(d, axes(d, 1)[i])
    end
end
function Base.getindex(di::DimIndices{<:Any,1}, i::Int)
    d = dims(di, 1)
    (rebuild(d, axes(d, 1)[i]),)
end
function Base.getindex(di::DimIndices{<:Any,N}, i::Int) where N
    I = Tuple(CartesianIndices(di)[i])
    map(dims(di), I) do d, i
        rebuild(d, axes(d, 1)[i])
    end
end

"""
    DimPoints <: AbstractDimArray

    DimPoints(x; order)
    DimPoints(dims::Tuple; order)
    DimPoints(dims::Dimension; order)

Like `CartesianIndices`, but for the point values of the dimension index. 
Behaves as an `Array` of `Tuple` lookup values (whatever they are) for all
combinations of the lookup values of `dims`.

Either a `Dimension`, a `Tuple` of `Dimension` or an object that defines a
`dims` method can be passed in.

# Keywords

- `order`: determines the order of the points, the same as the order of `dims` by default.
"""
struct DimPoints{T,N,D<:DimTuple,O} <: AbstractDimIndices{T,N,D}
    dims::D
    order::O
end
function DimPoints(dims::DimTuple; order=dims)
    order = map(d -> basetypeof(d)(), order)
    T = Tuple{map(eltype, dims)...}
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimPoints{T,N,typeof(dims),typeof(order)}(dims, order)
end
function DimPoints(dims::NamedTuple{K}) where K
    DimPoints(map((d, v) -> rebuild(d, v), key2dim(K), values(dims)))
end

name(A::DimPoints) = :points

function Base.getindex(dp::DimPoints, i1::Int, i2::Int, I::Int...)
    # Get dim-wrapped point values at i1, I...
    pointdims = map(dims(dp), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
    # Return the unwrapped point sorted by `order
    return map(val, DD.dims(pointdims, dp.order))
end
Base.getindex(di::DimPoints{<:Any,1}, i::Int) = (dims(di, 1)[i],)
Base.getindex(di::DimPoints, i::Int) = di[Tuple(CartesianIndices(di)[i])...]

"""
    DimSelectors <: AbstractArray

    DimSelectors(x)
    DimSelectors(dims::Tuple)
    DimSelectors(dims::Dimension)

Like `CartesianIndices`, but for the lookup values of Dimensions. Behaves as an
`Array` of `Tuple` of `Dimension(At(lookupvalue))` for all combinations of the
lookup values of `dims`.
"""
struct DimSelectors{T,N,D<:Tuple{Dimension,Vararg{Dimension}},S} <: AbstractDimIndices{T,N,D}
    dims::D
    selectors::S
end
function DimSelectors(dims::DimTuple; 
    type::Type{<:LookupArrays.IntSelector}=At, atol=nothing, selectors=_selectors(dims, type, atol)
)
    DimSelectors(dims, selectors)
end
function DimSelectors(dims::DimTuple, selectors)
    T = typeof(map(rebuild, dims, selectors))
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimSelectors{T,N,typeof(dims),typeof(selectors)}(dims, selectors)
end
function DimSelectors(dims::NamedTuple{K}; kw...) where K
    DimSelectors(map((d, v) -> rebuild(d, v), key2dim(K), values(dims)); kw...)
end

name(A::DimSelectors) = :selectors

@deprecate DimKeys DimSelectors

function _selectors(dims, type, atol)
    map(dims) do d
        atol1 = _atol(eltype(d), atol)
        At{eltype(d),typeof(atol1),Nothing}(first(d), atol1, nothing)
    end
end
function _selectors(dims, type, atol::Tuple)
    map(dims, atol) do d, a
        atol1 = _atol(eltype(d), a)
        At{eltype(d),typeof(atol1),Nothing}(first(d), atol1, nothing)
    end
end 
function _selectors(dims, type, atol::Nothing)
    map(dims) do d
        atol = _atol(eltype(d), nothing)
        v = first(val(d))
        _construct_selector(type, v, atol)
    end
end

_construct_selector(::Type{At}, v, atol) =
    At{typeof(v),typeof(atol),Nothing}(v, atol, nothing)
_construct_selector(::Type{Near}, v, atol) =
    Near{typeof(v)}(v)
_construct_selector(::Type{Contains}, v, atol) =
    Contains{typeof(v)}(v)

_atol(::Type, atol) = atol
_atol(T::Type{<:AbstractFloat}, atol::Nothing) = eps(T)

function Base.getindex(di::DimSelectors, i1::Int, i2::Int, I::Int...)
    map(dims(di), di.selectors, (i1, i2, I...)) do d, s, i
        rebuild(d, rebuild(s; val=d[i])) # At selector with the value at i
    end
end
function Base.getindex(di::DimSelectors{<:Any,1}, i::Int) 
    d = dims(di, 1)
    (rebuild(d, rebuild(di.selectors[1]; val=d[i])),)
end
Base.getindex(di::DimSelectors, i::Int) = di[Tuple(CartesianIndices(di)[i])...]
