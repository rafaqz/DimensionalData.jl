# A baseic dimensional dataset

struct DimensionalDataset{N,D,R,Da} <: AbstractDimensionalDataset{N,D}
    dims::D
    refdims::R
    data::Da
end

