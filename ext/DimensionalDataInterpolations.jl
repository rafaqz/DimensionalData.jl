module DimensionalDataInterpolations

using DimensionalData, Interpolations
using DimensionalData.Dimensions, DimensionalData.LookupArrays
# using Rasters

# const DD = DimensionalData

# function interp(A::AbstractDimArray; 
#     to=nothing, res=nothing, size=nothing, degree=nothing
# )
#     isempty(otherdims(to, dims(A))) || throw(DimensionMismatch("Cannot interpolate over dimensions not in the source array"))
#     # TODO handle permutations
#     shared_dims = commondims(A, to)
#     # TODO move `_extent2dims` to DimensionalData`
#     dest_dims = dims(Rasters._extent2dims(commondims(to, shared_dims); size, res), shared_dims)
#     other_dims = otherdims(A, to)
#     degrees = if isnothing(degree) 
#         map(_ -> Linear(), dims(A))
#     elseif !(degree isa Tuple)
#         map(_ -> degree, dims(A))
#     else
#         degree
#     end

#     data = if isregular(A, (XDim, YDim)) # Do linear interpolation
#         interpmode = map(dims(A), degrees) do d, deg
#             BSpline(deg)
#         end
#         if isempty(other_dims)
#             itp = interpolate(A, BSpline(Cubic(Line(OnGrid()))))
#             sitp = scale(itp, map(parent,  lookup(shared_dims))...)
#             sitp(map(parent, lookup(dest_dims))...)
#         else
#             for D in DimIndices(other_dims)
#                 itp = interpolate(view(A, D...), BSpline(Cubic(Line(OnGrid()))))
#                 sitp = scale(itp, map(parent, lookup(shared_dims))...)
#                 sitp(map(parent, lookup(dest_dims))...)
#             end
#         end
#     else
#         error("interpolate is only implemented for regular grids")
#     end

#     return DimArray(data, dest_dims)
# end

function Interpolations.linear_interpolation(A::AbstractDimArray)


    isrange(vec) = typeof(vec) <: AbstractRange 

    if all(DD.isregular, dims(A))
        itp = interpolate(A, BSpline(Linear()))
        sitp = scale(itp, DD.index(dims(A))...)        
    else
        sitp = interpolate(Tuple(raw_dims),A,Gridded(Linear()))
    end
end

end
