module DimensionalDataNearestNeighborsExt

using DimensionalData
using NearestNeighbors
using NearestNeighbors.StaticArrays

const DD = DimensionalData

function select_array_lookups(
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

end