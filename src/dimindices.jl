
abstract type AbstractDimIndices{T,N} <: AbstractArray{T,N} end

dims(di::AbstractDimIndices) = di.dims

Base.size(di::AbstractDimIndices) = map(length, dims(di))
Base.axes(di::AbstractDimIndices) = map(d -> axes(d, 1), dims(di))

for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds Base.$f(A::AbstractDimIndices, I::Union{Val,Selector}...) = Base.$f(A, dims2indices(A, I)...)
        @propagate_inbounds function Base.$f(A::AbstractDimIndices, I::Dimension...; kw...)
            Base.$f(A, dims2indices(A, I..., _kwdims(values(kw))...)...)
        end
    end
end

@propagate_inbounds function Base.getindex(
    A::DI, i1::Union{Int,Colon,AbstractArray}, I::Union{Int,Colon,AbstractArray}...
) where DI<:AbstractDimIndices
    ds = map(dims(A), (i1, I...)) do d, i
        i isa Int ? nothing : basetypeof(d)(d[i])
    end |> _remove_nothing
    basetypeof(DI)(ds)
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
struct DimIndices{T,N,D<:Tuple{<:Dimension,Vararg{<:Dimension}}} <: AbstractDimIndices{T,N}
    dims::D
end
DimIndices(dim::Dimension) = DimIndices((dim,))
function DimIndices(dims::D) where {D<:Tuple{<:Dimension,Vararg{<:Dimension}}}
    T = typeof(map(d -> basetypeof(d)(1), dims))
    N = length(dims)
    DimIndices{T,N,D}(dims)
end
DimIndices(x) = DimIndices(dims(x))
DimIndices(::Nothing) = throw(ArgumentError("Object has no `dims` method"))

function Base.getindex(di::DimIndices, i1::Int, I::Int...)
    map(dims(di), (i1, I...)) do d, i
        basetypeof(d)(axes(d, 1)[i])
    end
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
DimKeys(dim::Dimension; kw...) = DimKeys((dim,); kw...)
function DimKeys(dims::D; atol=nothing, selectors=_selectors(dims, atol)) where {D<:Tuple{<:Dimension,Vararg{<:Dimension}}}
    T = typeof(map((d, s) -> basetypeof(d)(s), dims, selectors))
    N = length(dims)
    DimKeys{T,N,D,typeof(selectors)}(dims, selectors)
end
DimKeys(x; kw...) = DimKeys(dims(x); kw...)
DimKeys(::Nothing; kw...) = throw(ArgumentError("Object has no `dims` method"))

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
        At{eltype(d),typeof(atolx),Nothing}(first(d), atolx, nothing)
    end
end

_atol(::Type, atol) = atol
_atol(T::Type{<:AbstractFloat}, atol::Nothing) = eps(T)

function Base.getindex(di::DimKeys, i1::Int, I::Int...)
    map(dims(di), di.selectors, (i1, I...)) do d, s, i
        basetypeof(d)(rebuild(s; val=d[relate(d, i)])) # At selector with the value at i
    end
end
