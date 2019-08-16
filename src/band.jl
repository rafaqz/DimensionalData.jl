
"""
A band dimension for multi-band data. Also used inside another
dimension when it has multiple bands, as is common in NetCDF files.
"""
struct Band{X,T,M} <: AbstractParametricDimension{X,T,M} 
    val::T
    metadata::M
    Band{X}(val, metadata) where X = 
        new{X,typeof(val),typeof(metadata)}(val, metadata)
end
Band{X}(val=:; metadata=nothing) where X = Band{X}(val, metadata)
basetype(::Type{<:Band{X}}) where X = Band{X}
dimname(dim::Type{Band{X}}) where X = "Band $X"


# For bands indices are accepted for half the underlying dimension size, and converted
# to match the required dimension
@inline dims2indices(dim::AbDim{<:Band{B}}, lookup::AbDim{<:Band{X}}, emptyval) where {B,X} =
    (val(val(lookup)) .- 1) .* B .+ X
@inline dims2indices(dim::AbDim{<:Band{B}}, lookup::AbDim{<:Band{X,<:Colon}}, emptyval) where {B,X} = begin
    range = val(val(dim))
    start, stop = (((firstindex(range), lastindex(range)) .- 1) .* B .+ X)
    start:B:stop
end

@inline formatdims(a, dim::AbDim{<:Band{B}}, n) where B =
    basetype(dim)(linrange(val(dim), size(a, n) ÷ B))

@inline slicedims(d::AbDim, i::Band{X}) where X = begin
    range = val(d)
    start, stop, len = range[first(i)], range[last(i)], length(i)
    d = typeof(d)(LinRange(start, stop, len), metadata(d))
    ((d,), ())
end
