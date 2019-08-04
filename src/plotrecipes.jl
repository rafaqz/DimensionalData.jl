cleanup(x::AbstractFloat) = round(x, sigdigits=4)
cleanup(x) = x

datalabel(ga::AbstractGeoArray) = begin
    reflabels = join(join.(zip(lowercase.(shortname.(refdims(ga))), cleanup(val.(refdims(ga)))), ": ", ), ", ")
    reflabels == "" ? label(ga) : string(label(ga), " at ", reflabels)
end


@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:LatDim,<:LongDim}}) where T
    seriestype --> :heatmap
    aspect_ratio --> 1
    grid --> false
    ylabel --> dimname(ga)[1] 
    xlabel --> dimname(ga)[2]
    colorbar_title --> datalabel(ga)
    data = @view replace(parent(ga), missingval(ga) => NaN)[:, :]
    reverse(val.(dims(ga)))..., data
end

@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:LongDim,<:LatDim}}) where T
    seriestype --> :heatmap
    aspect_ratio --> 1
    grid --> false
    xlabel --> dimname(ga)[1]
    ylabel --> dimname(ga)[2] 
    colorbar_title --> datalabel(ga)
    data = replace(parent(ga), missingval(ga) => NaN)[:, :]'
    val.(dims(ga))..., data
end

@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:AbstractGeoDim,<:TimeDim}}) where T
    ticks --> true
    ylabel --> datalabel(ga)
    xlabel --> dimname(ga)[1]
    legendtitle --> dimname(ga)[2]
    replace(parent(ga), missingval(ga) => NaN)
end

@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:TimeDim,<:AbstractGeoDim}}) where T
    ticks --> true
    ylabel --> datalabel(ga)
    xlabel --> dimname(ga)[1]
    legendtitle --> dimname(ga)[2]
    replace(parent(ga), missingval(ga) => NaN)
end

@recipe function f(ga::AbstractGeoArray{T,1,<:Tuple{<:AbstractGeoDim}}) where T
    ylabel --> datalabel(ga)
    xlabel --> dimname(ga)[1]
    legend --> false
    val(dims(ga)[1]), replace(parent(ga), missingval(ga) => NaN)
end
