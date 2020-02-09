@recipe function f(ga::AbstractDimensionalArray{T,2,<:Tuple{<:AbstractDimension,<:Ti}}) where T
    ylabel --> label(ga)
    xlabel --> label(dims(ga)[1])
    legendtitle --> label(dims(ga)[1])
    title --> label(refdims(ga))
    parent(ga)
end

@recipe function f(ga::AbstractDimensionalArray{T,2,<:Tuple{<:Ti,<:AbstractDimension}}) where T
    permutedims(ga)
end

@recipe function f(ga::AbstractDimensionalArray{T,1,<:Tuple{<:AbstractDimension}}) where T
    ylabel --> label(ga)
    xlabel --> label(dims(ga)[1])
    # legend --> false
    title --> label(refdims(ga))
    val(dims(ga)[1]), parent(ga)
end

struct HeatMapLike end
@recipe function f(ga::AbstractDimensionalArray{<:Any,2})
    sertyp = get(plotattributes, :seriestype, nothing)
    if sertyp in [:heatmap, :contour, :surface, :wireframe]
        ga, HeatMapLike()
    else
        parent(ga)
    end
end

@recipe function f(ga::AbstractDimensionalArray, ::HeatMapLike)
    @assert ndims(ga) == 2
    dim1, dim2 = dims(ga)
    # Notice that dim1 corresponds to Y
    # and dim2 corresponds to X
    # This is because in Plots.jl
    # The first axis of a matrix is the Y axis
    :ylabel --> label(dim1)
    :xlabel --> label(dim2)
    val(dim2), val(dim1), parent(ga)
end
