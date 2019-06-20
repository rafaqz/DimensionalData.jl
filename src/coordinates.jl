#= We need to be able to handle both affine maps and simple bounding
box style coordinates.

Generalising this becomes interesting when we add vertical and time dimenstions
How much is included in an affine map?
If the vertical dimensions is not in the affine map, how do we generalise the problem?

I assume time allways has its own separate map (ie a start/stop times/dataes and calendar).

Cases:
- all dimensions are tracked separately
- lat/long transforms are stored in an affine map
- lat/long/vert are stored in an affine map?? (does anyone use this?)

=#

# Coordinate trait

struct HasAffineMap end
struct HasDimCoords end
struct NoCoords end

coordtype(a::AbstractGeoArray) = NoCoords()

coords(a::AbstractGeoArray, dims...) = coords(coords(a), sortdims(a, dims))
coords(coorddims::Tuple, indexdims::Tuple) = 
    (coords(coorddims[1], indexdims[1])..., coords(tail(coorddims), tail(indexdims))...)
coords(coorddims::Tuple{}, indexdims::Tuple{}) = ()
coords(coorddim::AbstractGeoDim, indexdim::Nothing) = ()
coords(coorddim::AbstractGeoDim, indexdim::AbstractGeoDim) = 
    (collect(val(coorddim))[val(indexdim)],)


lattitude(a::AbstractGeoArray, i) = coords(a, LatDim(i))[1]
longitude(a::AbstractGeoArray, i) = coords(a, LongDim(i))[1]
vertical(a::AbstractGeoArray, i) = coords(a, VertDim(i))[1]
timespan(a::AbstractGeoArray, i) = coords(a, TimeDim(i))[1]
