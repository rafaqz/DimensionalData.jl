
struct HeatMapLike end
struct WireframeLike end
struct SeriesLike end
struct HistogramLike end
struct ViolinLike end

@recipe function f(A::AbstractDimensionalArray)
    # Reverse any axes marked as reverse
    Af = forwardorder(A)
    sertype = get(plotattributes, :seriestype, :none)
    println(sertype)
    if !(sertype in [:marginalhist])
        :title --> refdims_title(A)
    end
    if sertype in [:heatmap, :contour, :volume, :marginalhist, :image, 
                   :surface, :contour3d, :wireframe, :scatter3d]
        Af, HeatMapLike()
    elseif sertype in [:histogram, :stephist, :density, :barhist, :scatterhist, :ea_histogram]
        Af, HistogramLike()
    elseif sertype in [:hline]
        :ylabel --> label(A)
        data(Af)
    elseif sertype in [:vline, :andrews]
        :xlabel --> label(A)
        data(Af)
    elseif sertype in [:violin, :dotplot, :boxplot]
        Af, ViolinLike()
    elseif sertype in [:plot, :histogram2d, :none, :line, :path, :steppre, :steppost, :sticks, :scatter, 
                       :hexbin, :barbins, :scatterbins, :stepbins, :bins2d, :bar]
        Af, SeriesLike() 
    else
        data(Af)
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
    ind, dep = dims(A)
    :xlabel --> label(ind)
    :ylabel --> label(A)
    :legendtitle --> label(dep)
    :labels --> permutedims(val(dep))
    val(ind), data(A)
end

@recipe function f(A::AbstractArray{T,1}, ::HistogramLike) where T
    dim = dims(A, 1)
    :xlabel --> label(A)
    val(dim), data(A)
end
@recipe function f(A::AbstractArray{T,2}, ::HistogramLike) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xlabel --> label(A)
    :legendtitle --> label(dep)
    :labels --> permutedims(val(dep))
    val(ind), data(A)
end

@recipe function f(A::AbstractArray{T,1}, ::ViolinLike) where T
    dim = dims(A, 1)
    :ylabel --> label(A)
    data(A)
end
@recipe function f(A::AbstractArray{T,2}, ::ViolinLike) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    println(ind, dep)
    :xlabel --> label(dep)
    :ylabel --> label(A)
    :legendtitle --> label(dep)
    :labels --> permutedims(val(dep))
    data(A)
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

refdims_title(A::AbstractArray) = join(map(refdims_title, refdims(A)), ", ")
refdims_title(dim::AbDim) = string(name(dim), ": ", refdims_title(grid(dim), dim))
refdims_title(grid::Union{BoundedGrid,RegularGrid}, dim::AbDim) =
    ((start, stop) = bounds(dim); "$start to $stop")
refdims_title(grid, dim::AbDim) = val(dim)
