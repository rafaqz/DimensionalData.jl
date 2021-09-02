"""
    DimIndices <: AbstractArray

    DimIndices(x)
    DimIndices(dims::Tuple)
    DimIndices(dims::Dimension)

Like CartesianIndices, but for Dimensions. Behaves as an Array of Tuples
of Dimensions for all combinations of the axis values of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and
is especially useful when combined with `otherdims`, ti iterate over the
indices of unknown dimension.
"""
struct DimIndices{T,N,D<:Tuple{<:Dimension,Vararg{<:Dimension}}} <: AbstractArray{T,N}
    dims::D
end
DimIndices(dim::Dimension) = DimIndices((dim,))
function DimIndices(dims::D) where {D<:Tuple{<:Dimension,Vararg{<:Dimension}}}
    T = typeof(map(d -> basetypeof(d)(1), dims))
    N = length(dims)
    DimIndices{T,N,D}(dims)
end
DimIndices(x) = DimIndices(dims(x))

dims(di::DimIndices) = di.dims

Base.size(di::DimIndices) = map(length, dims(di))
Base.axes(di::DimIndices) = map(d -> axes(d, 1), dims(di))

for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds Base.$f(A::DimIndices, I::Union{Val,Selector}...) = Base.$f(A, dims2indices(A, I)...)
        @propagate_inbounds function Base.$f(A::DimIndices, I::Dimension...; kw...)
            Base.$f(A, dims2indices(A, I..., _kwdims(kw.data)...)...)
        end
    end
end

@propagate_inbounds function Base.getindex(A::DimIndices, i1::Union{Int,Colon,AbstractArray}, I::Union{Int,Colon,AbstractArray}...)
    ds = map(dims(A), (i1, I...)) do d, i
        i isa Int ? nothing : basetypeof(d)(d[i])
    end |> _remove_nothing
    DimIndices(ds)
end
function Base.getindex(di::DimIndices, i1::Int, I::Int...)
    map(dims(di), (i1, I...)) do d, i
        basetypeof(d)(getindex(axes(d, 1), i))
    end
end
