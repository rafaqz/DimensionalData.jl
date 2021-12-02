
abstract type AbstractDimIndices{T,N} <: AbstractArray{T,N} end

dims(di::AbstractDimIndices) = di.dims

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

(::Type{<:AbstractDimIndices})(::Nothing; kw...) = throw(ArgumentError("Object has no `dims` method"))
(::Type{T})(x; kw...) where T<:AbstractDimIndices = T(dims(x); kw...)
(::Type{T})(dim::Dimension; kw...) where T<:AbstractDimIndices = T((dim,); kw...)

_format(dims::Tuple{}) = ()
function _format(dims::Tuple)
    ax = map(d -> axes(val(d), 1), dims)
    return format(dims, ax)
end

"""
    DimIndices <: AbstractArray

    DimIndices(x)
    DimIndices(dims::Tuple)
    DimIndices(dims::Dimension)

Like CartesianIndices, but for Dimensions. Behaves as an `Array` of `Tuple`
of `Dimension(i)` for all combinations of the axis indices of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and
is especially useful when combined with `otherdims`, to iterate over the
indices of unknown dimension.
"""
struct DimIndices{T,N,D<:Tuple{Vararg{<:Dimension}}} <: AbstractDimIndices{T,N}
    dims::D
end
function DimIndices(dims::D) where {D<:Tuple{Vararg{<:Dimension}}}
    T = typeof(map(d -> rebuild(d, 1), dims))
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimIndices{T,N,typeof(dims)}(dims)
end

function Base.getindex(di::DimIndices, i1::Int, I::Int...)
    map(dims(di), (i1, I...)) do d, i
        rebuild(d, axes(d, 1)[i])
    end
end


"""
    DimPoints <: AbstractArray

    DimPoints(x)
    DimPoints(dims::Tuple)
    DimPoints(dims::Dimension)

Like CartesianIndices, but for Dimensions. Behaves as an `Array` of `Tuple`
of `Dimension(i)` for all combinations of the axis indices of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and
is especially useful when combined with `otherdims`, to iterate over the
indices of unknown dimension.
"""
struct DimPoints{T,N,D<:DimTuple,O} <: AbstractDimIndices{T,N}
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

function Base.getindex(dp::DimPoints, i1::Int, I::Int...)
    # Get dim-wrapped point values at i1, I...
    pointdims = map(dims(dp), (i1, I...)) do d, i
        rebuild(d, d[i])
    end
    # Return the unwrapped point sorted by `order
    return map(val, DD.dims(pointdims, dp.order))
end

"""
    DimKeys <: AbstractArray

    DimKeys(x)
    DimKeys(dims::Tuple)
    DimKeys(dims::Dimension)

Like CartesianIndices, but for the key values of Dimensions. Behaves as an
`Array` of `Tuple` of `Dimension(At(keyvalue))` for all combinations of the
axis values of `dims`.
"""
struct DimKeys{T,N,D<:Tuple{<:Dimension,Vararg{<:Dimension}},S} <: AbstractDimIndices{T,N}
    dims::D
    selectors::S
end
function DimKeys(dims::DimTuple; atol=nothing, selectors=_selectors(dims, atol))
    DimKeys(dims, selectors)
end
function DimKeys(dims::DimTuple, selectors)
    T = typeof(map(rebuild, dims, selectors))
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimKeys{T,N,typeof(dims),typeof(selectors)}(dims, selectors)
end

function _selectors(dims, atol)
    map(dims) do d
        atol1 = _atol(eltype(d), atol)
        At{eltype(d),typeof(atol1),Nothing}(first(d), atol1, nothing)
    end
end
function _selectors(dims, atol::Tuple)
    map(dims, atol) do d, a
        atol1 = _atol(eltype(d), a)
        At{eltype(d),typeof(atol1),Nothing}(first(d), atol1, nothing)
    end
end 
function _selectors(dims, atol::Nothing)
    map(dims) do d
        atolx = _atol(eltype(d), nothing)
        v = first(val(d))
        At{typeof(v),typeof(atolx),Nothing}(v, atolx, nothing)
    end
end

_atol(::Type, atol) = atol
_atol(T::Type{<:AbstractFloat}, atol::Nothing) = eps(T)

function Base.getindex(di::DimKeys, i1::Int, I::Int...)
    map(dims(di), di.selectors, (i1, I...)) do d, s, i
        rebuild(d, rebuild(s; val=index(d)[i])) # At selector with the value at i
    end
end
