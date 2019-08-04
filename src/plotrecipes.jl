cleanup(x::AbstractFloat) = round(x, sigdigits=4)
cleanup(x) = x

getstring(::Nothing) = ""
getstring(x) = string(x)

dimlabel(dim) = join((dimname(dim), getstring(dim.units)), " ")

reflabel(a) = join(join.(zip(shortname.(refdims(a)), cleanup(val.(refdims(a)))), ": ", ), ", ")

@recipe function f(ga::AbstractGeoArray{T,3,<:Tuple{<:Lat,<:Lon,D}}) where {T,D}
    nplots = size(ga, 3)
    layout --> nplots
    if nplots > 1
        for i in 1:nplots
            @series begin
                seriestype := :heatmap
                colorbar := false
                ticks := false
                subplot := i
                replace(parent(ga[:, :, i]), missingval(ga) => NaN)
            end   
        end
    else
        ga[:, :, 1]
    end
end

@recipe function f(ga::AbstractGeoArray{T,3,<:Tuple{<:Lon,<:Lat,D}}) where {T,D}
    permutedims(ga, (Lat(), Lon(), 3))
end

@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:Lat,<:Lon}}) where T
    seriestype --> :heatmap
    aspect_ratio --> 1
    grid --> false
    ylabel --> dimlabel(dims(ga)[1])
    xlabel --> dimlabel(dims(ga)[2])
    colorbar_title --> name(ga)
    title --> reflabel(ga)
    data = replace(parent(ga), missingval(ga) => NaN)
    reverse(val.(dims(ga)))..., data
end

@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:Lon,<:Lat}}) where T
    permutedims(ga)
end

@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:AbstractGeoDim,<:Time}}) where T
    ticks --> true
    ylabel --> name(ga)
    xlabel --> dimlabel(dims(ga)[1])
    legendtitle --> dimlabel(dims(ga)[1])
    title --> reflabel(ga)
    replace(parent(ga), missingval(ga) => NaN)
end

@recipe function f(ga::AbstractGeoArray{T,2,<:Tuple{<:Time,<:AbstractGeoDim}}) where T
    permutedims(ga)
end

@recipe function f(ga::AbstractGeoArray{T,1,<:Tuple{<:AbstractGeoDim}}) where T
    ylabel --> name(ga)
    xlabel --> dimlabel(dims(ga)[1])
    legend --> false
    title --> reflabel(ga)
    val(dims(ga)[1]), replace(parent(ga), missingval(ga) => NaN)
end
