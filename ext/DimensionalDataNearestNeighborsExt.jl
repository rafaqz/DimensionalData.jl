module DimensionalDataNearestNeighborsExt

using DimensionalData
using NearestNeighbors
using NearestNeighbors.StaticArrays
using DimensionalData.Lookups
using DimensionalData.Dimensions

using DimensionalData.Lookups: ArrayLookup, VecOfPoints, matrix, atol

const DD = DimensionalData
const NN = NearestNeighbors

function DD.Lookups.select_array_lookups(
    lookups::Tuple{<:ArrayLookup,<:ArrayLookup,Vararg{ArrayLookup}}, 
    selectors::Tuple{<:Union{At,Near},<:Union{Near,At},Vararg{Union{Near,At}}}
)
    f1 = first(lookups)
    vals = SVector(map(val, selectors))
    tree = Lookups.tree(f1)
    knn!(f1.idxvec, f1.distvec, tree, vals, 1)
    idx = f1.idxvec[1]
    found_vals = tree.data[idx]
    # @show idx vals found_vals
    map(selectors, Tuple(found_vals)) do s, t
        s isa At ? isapprox(val(s), t; atol=atol(s)) : true
    end |> all || throw(ArgumentError("$(selectors) not found in lookup"))
    return CartesianIndices(matrix(first(lookups)))[idx] |> Tuple
end

function DD.Dimensions.format_unaligned(
    lookups::Tuple{<:ArrayLookup,<:ArrayLookup,Vararg{ArrayLookup}}, dims, axes,
)
    points = vec(SVector.(zip(map(matrix, lookups)...)))
    idxvec = Vector{Int}(undef, 1)
    distvec = Vector{NN.get_T(eltype(points))}(undef, 1)
    tree = NN.KDTree(points, NN.Euclidean(); reorder=false)
    return map(lookups, dims, axes) do l, d, a
        newl = rebuild(l; 
            data=a, tree, dim=basedims(d), dims=basedims(dims), idxvec, distvec
        )
        rebuild(d, newl) 
    end
end


# An array to lazily combine dimension matrices into points
struct VecOfPoints{T,M,A<:Tuple{AbstractArray{<:Any},Vararg}} <: AbstractArray{T,1}
    arrays::A
end
function VecOfPoints(arrays::A) where A<:Tuple
    all(x -> size(x) == size(first(arrays)), arrays) ||
        throw(ArgumentError("Size of matrices must match"))
    T = typeof(SVector(map(A -> zero(eltype(A)), arrays)))
    M = length(arrays)
    VecOfPoints{T,M,A}(arrays)
end

Base.size(aop::VecOfPoints) = size(first(aop.arrays))
Base.@propagate_inbounds function Base.getindex(aop::VecOfPoints, I::Int...)
    @boundscheck checkbounds(first(aop.arrays), I...)
    SVector(map(A -> (@inbounds A[I...]), aop.arrays))
end

end