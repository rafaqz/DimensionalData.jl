
struct HeatMapLike end
struct WireframeLike end
struct SeriesLike end
struct HistogramLike end

@recipe function f(A::AbstractDimensionalArray)
    # Reverse any axes marked as reverse
    Af = forwardorder(A)
    :title --> refdims_title(A)
    sertype = get(plotattributes, :seriestype, :noseriestype)
    if sertype in [:heatmap, :contour, :path3d, :volume, :hexbin, 
                   :histogram2d, :histogram3d, :image, :density, 
                   :surface, :contour3d, :wireframe, :scatter3d]
        Af, HeatMapLike()
    elseif sertype in [:histogram, :stephist, :barhist, :scatterhist]
        Af, HistogramLike()
    elseif sertype == :vline
        :xlabel --> label(A)
        data(Af)
    elseif sertype == :hline
        :ylabel --> label(A)
        data(Af)
    else
        Af, SeriesLike() 
    end
end

@recipe function f(A::AbstractDimensionalArray{T,1}, ::SeriesLike) where T
    dim = dims(A, 1)
    :ylabel --> label(A)
    :xlabel --> label(dim)
    val(dim), parent(A)
end

@recipe function f(A::AbstractArray{T,2}, ::SeriesLike) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    println(A)
    ind, dep = dims(A)
    println(typeof(ind), typeof(dep))
    :xlabel --> label(ind)
    :ylabel --> label(A)
    :legendtitle --> label(dep)
    val(ind), data(A)
end

@recipe function f(A::AbstractArray{T,1}, ::HistogramLike) where T
    dim = dims(A, 1)
    :xlabel --> label(A)
    val(dim), data(A)
end

@recipe function f(A::AbstractArray{T,1}, ::HeatMapLike) where T
    dim = dims(A, 1)
    :xlabel --> label(dim)
    :ylabel --> label(A)
    val(dim), data(A)
end

@recipe function f(A::AbstractArray{T,2}, ::HeatMapLike) where T
    A = maybe_permute(A, (YDim, XDim))
    y, x = dims(A)
    :xlabel --> label(x)
    :ylabel --> label(y)
    :zlabel --> label(A)
    :colorbar_title --> label(A)
    val(x), val(y), data(A)
end

maybe_permute(A, dims) = all(hasdim(A, dims)) ? permutedims(A, dims) : A

forwardorder(A) = begin
    for (i, dim) in enumerate(dims(A))
        if arrayorder(dim) == Reverse()
            A = reverse(A; dims=dim)
        end
    end
    A
end

refdims_title(A) = join(map(d -> string(name(d), " ", val(d)), refdims(A)), ", ")

