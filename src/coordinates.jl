#= We need to be able to handle both affine maps and simple bounding
box style coordinates.

Generalising this becomes interesting when we add vertical and time dimenstions:
how much is included in an affine map?

Do we need traits for all combinations?

I assume time allways has its own separate map (ie a start/stop times/dataes and calendar).

Cases:
- all dimensions are tracked separately
- lat/long transforms are stored in an affine map, vert (and maybe time) stored separately
- lat/long/vert are stored in an affine map   with time separate (does anyone use/need this?)

=#

# Coordinate trait

coords(a::AbstractGeoArray, dims...) = coords(dims(a), sortdims(a, dims))
coords(coorddims::Tuple, indexdims) = 
    (coords(coorddims[1], indexdims[1])..., coords(tail(coorddims), tail(indexdims))...)
coords(coorddims::Tuple{}, indexdims::Tuple{}) = ()

coords(coorddim::AbstractGeoDim, indexdim::Nothing) = ()
coords(coorddim::AbstractGeoDim, indexdim::AbstractGeoDim) = 
    (basetype(coorddim)(collect(val(coorddim))[val(indexdim)]),)

# Generate upper left coordinates for specic index
coords(aff::AbsractAffineDims, point) = val(aff)(point .- 1)

# Generate center coordinates for specific index
centercoords(aff::AbsractAffineDims, point) = val(aff)(point .- 0.5)

# Convert coordinates to indices
indices(aff:AbstractAffinceDims, point) = 
    map(x -> round(Int, x), inv(val(aff))(point)) .+ 1

