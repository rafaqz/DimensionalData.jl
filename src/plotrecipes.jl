@recipe function f(ga::AbstractDimensionalArray{T,2,<:Tuple{<:AbstractDimension,<:Time}}) where T
    ylabel --> label(ga)
    xlabel --> label(dims(ga)[1])
    legendtitle --> label(dims(ga)[1])
    title --> label(refdims(ga))
    parent(ga)
end

@recipe function f(ga::AbstractDimensionalArray{T,2,<:Tuple{<:Time,<:AbstractDimension}}) where T
    permutedims(ga)
end

@recipe function f(ga::AbstractDimensionalArray{T,1,<:Tuple{<:AbstractDimension}}) where T
    ylabel --> label(ga)
    xlabel --> label(dims(ga)[1])
    # legend --> false
    title --> label(refdims(ga))
    val(dims(ga)[1]), parent(ga)
end
