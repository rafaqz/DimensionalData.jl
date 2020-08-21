struct HeatMapLike end
struct ImageLike end
struct WireframeLike end
struct SeriesLike end
struct HistogramLike end
struct ViolinLike end

struct DimensionalPlot end

@recipe function f(A::AbstractDimArray) 
    DimensionalPlot(), A
end

@recipe function f(::DimensionalPlot, A::AbstractArray)
    Afwd = forwardorder(A)
    sertype = get(plotattributes, :seriestype, :none)
    if !(sertype in [:marginalhist])
        :title --> refdims_title(Afwd)
    end
    if sertype in [:heatmap, :contour, :volume, :marginalhist, 
                   :surface, :contour3d, :wireframe, :scatter3d]
        HeatMapLike(), Afwd
    elseif sertype in [:histogram, :stephist, :density, :barhist, :scatterhist, :ea_histogram]
        HistogramLike(), Afwd
    elseif sertype in [:hline]
        :yguide --> label(Afwd)
        data(Afwd)
    elseif sertype in [:vline, :andrews]
        :xguide --> label(Afwd)
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

@recipe function f(::SeriesLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    unwrap(index(dim)), parent(A)
end
@recipe function f(::SeriesLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(index(dep))
    index(ind), data(A)
end

@recipe function f(::HistogramLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(A)
    index(dim), data(A)
end
@recipe function f(::HistogramLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(index(dep))
    index(ind), data(A)
end

@recipe function f(::ViolinLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :yguide --> label(A)
    data(A)
end
@recipe function f(::ViolinLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xguide --> label(dep)
    :yguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(index(dep))
    data(A)
end

@recipe function f(::HeatMapLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    index(dim), data(A)
end

@recipe function f(::HeatMapLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (YDim, XDim))
    y, x = dims(A)
    :xguide --> label(x)
    :yguide --> label(y)
    :zguide --> label(A)
    :colorbar_title --> label(A)
    reverse(map(index, dims(A)))..., data(A)
end

@recipe function f(::ImageLike, A::AbstractArray{T,2}) where T
    data(A)
end

maybe_permute(A, dims) = all(hasdim(A, dims)) ? permutedims(A, dims) : A

forwardorder(A::AbstractArray) =
    reorderindex(A, Forward()) |> a -> reorderrelation(a, Forward())

refdims_title(A::AbstractArray) = join(map(refdims_title, refdims(A)), ", ")
refdims_title(dim::Dimension) = string(name(dim), ": ", refdims_title(mode(dim), dim))
refdims_title(mode::AbstractSampled, dim::Dimension) = begin
    start, stop = map(string, bounds(dim))
    if start == stop
        start
    else
         "$start to $stop"
    end
end
refdims_title(mode::IndexMode, dim::Dimension) = string(index(dim))

