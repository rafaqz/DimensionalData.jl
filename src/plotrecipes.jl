struct HeatMapLike end
struct WireframeLike end
struct SeriesLike end
struct HistogramLike end
struct ViolinLike end

@recipe function f(A::AbstractDimensionalArray)
    Afwd = forwardorder(A)
    sertype = get(plotattributes, :seriestype, :none)
    if !(sertype in [:marginalhist])
        :title --> refdims_title(Afwd)
    end
    if sertype in [:heatmap, :contour, :volume, :marginalhist, :image, 
                   :surface, :contour3d, :wireframe, :scatter3d]
        HeatMapLike(), Afwd
    elseif sertype in [:histogram, :stephist, :density, :barhist, :scatterhist, :ea_histogram]
        HistogramLike(), Afwd
    elseif sertype in [:hline]
        :ylabel --> label(Afwd)
        data(Afwd)
    elseif sertype in [:vline, :andrews]
        :xlabel --> label(Afwd)
        data(Afwd)
    elseif sertype in [:violin, :dotplot, :boxplot]
        ViolinLike(), Afwd
    elseif sertype in [:plot, :histogram2d, :none, :line, :path, :steppre, :steppost, :sticks, :scatter, 
                       :hexbin, :barbins, :scatterbins, :stepbins, :bins2d, :bar]
        SeriesLike(), Afwd
    else
        data(Afwd)
    end
end

@recipe function f(::SeriesLike, A::AbstractDimensionalArray{T,1}) where T
    dim = dims(A, 1)
    :ylabel --> label(A)
    :xlabel --> label(dim)
    val(dim), parent(A)
end
@recipe function f(::SeriesLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xlabel --> label(ind)
    :ylabel --> label(A)
    :legendtitle --> label(dep)
    :labels --> permutedims(val(dep))
    val(ind), data(A)
end

@recipe function f(::HistogramLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xlabel --> label(A)
    val(dim), data(A)
end
@recipe function f(::HistogramLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xlabel --> label(A)
    :legendtitle --> label(dep)
    :labels --> permutedims(val(dep))
    val(ind), data(A)
end

@recipe function f(::ViolinLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :ylabel --> label(A)
    data(A)
end
@recipe function f(::ViolinLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xlabel --> label(dep)
    :ylabel --> label(A)
    :legendtitle --> label(dep)
    :labels --> permutedims(val(dep))
    data(A)
end

@recipe function f(::HeatMapLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xlabel --> label(dim)
    :ylabel --> label(A)
    val(dim), data(A)
end

@recipe function f(::HeatMapLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (YDim, XDim))
    y, x = dims(A)
    :xlabel --> label(x)
    :ylabel --> label(y)
    :zlabel --> label(A)
    :colorbar_title --> label(A)
    val(x), val(y), data(A)
end

maybe_permute(A, dims) = all(hasdim(A, dims)) ? permutedims(A, dims) : A

forwardorder(A::AbstractArray) =
    reorderindex(A, Forward()) |> a -> reorderrelation(a, Forward())

refdims_title(A::AbstractArray) = join(map(refdims_title, refdims(A)), ", ")
refdims_title(dim::Dimension) = string(name(dim), ": ", refdims_title(mode(dim), dim))
refdims_title(mode::AbstractSampled, dim::Dimension) = begin
    start, stop = map(string, bounds(dim))
    println("bounds: ", bounds(dim))
    if start == stop
        start
    else
         "$start to $stop"
    end
end
refdims_title(mode::IndexMode, dim::Dimension) = string(val(dim))

