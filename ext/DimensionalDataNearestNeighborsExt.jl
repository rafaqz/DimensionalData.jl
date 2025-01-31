module DimensionalDataNearestNeighborsExt

using DimensionalData
using NearestNeighbors
using NearestNeighbors.StaticArrays

const DD = DimensionalData

function DD.Lookups.select_array_lookups(
    lookups::Tuple{<:ArrayLookup,<:ArrayLookup,Vararg{ArrayLookup}}, 
    selectors::Tuple{<:Union{At,Near},<:Union{Near,At},Vararg{Union{Near,At}}}
)
    vals = map(val, selectors)
    idx, dists = nn(tree(first(lookups)), SVector(vals))
    map(selectors, dists) do s, d
        s isa At ? (d == zero(first(dists))) : true
    end |> all || throw(ArgumentError("$(vals) not found in lookup"))
    return idx
end

function DD.Dimensions.format_unaligned(
    lookups::Tuple{<:ArrayLookup,<:ArrayLookup,Vararg{ArrayLookup}}, dims,
)
    tree = knntree(ArrayOfPoints(map(matrix, lookups)))
    return map(lookups, dims) do l, d
        rebuild(d, rebuild(l; tree))
    end
end

end