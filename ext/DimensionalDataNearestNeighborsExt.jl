module DimensionalDataNearestNeighborsExt

using DimensionalData
using NearestNeighbors
using NearestNeighbors.StaticArrays
using DimensionalData.Lookups
using DimensionalData.Dimensions

using DimensionalData.Lookups: ArrayLookup, matrix, atol, AutoDim

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
    map(selectors, Tuple(found_vals)) do s, t
        s isa At ? Lookups._is_at(s, t) : true
    end |> all || throw(ArgumentError("$(selectors) not found in lookup"))
    return CartesianIndices(matrix(first(lookups)))[idx] |> Tuple
end

function DD.Dimensions.format_unaligned(
    lookups::Tuple{<:ArrayLookup,<:ArrayLookup,Vararg{ArrayLookup}}, dims::DD.DimTuple, axes,
)
    dims = basedims(DD.dims(lookups[1]) isa Union{Nothing,AutoDim} ? dims : DD.dims(lookups[1]))
    # This may be expensive, we are doubling 
    # the memory use of the lookup matrices
    points = vec(SVector.(zip(map(matrix, lookups)...)))
    idxvec = Vector{Int}(undef, 1)
    distvec = Vector{NN.get_T(eltype(points))}(undef, 1)
    tree = NN.KDTree(points, NN.Euclidean(); reorder=false)
    return map(lookups, dims, axes) do l, d, a
        data = parent(l) isa AutoValues ? a : parent(l)
        dim = basedims(DD.dim(l) isa AutoDim ? d : DD.dim(l))
        newl = rebuild(l; data, tree, dim, dims, idxvec, distvec)
        rebuild(d, newl) 
    end
end

end
