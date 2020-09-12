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
        parent(Afwd)
    elseif sertype in [:vline, :andrews]
        :xguide --> label(Afwd)
        parent(Afwd)
    elseif sertype in [:violin, :dotplot, :boxplot]
        ViolinLike(), Afwd
    elseif sertype in [:plot, :histogram2d, :none, :line, :path, :steppre, :steppost, :sticks, :scatter, 
                       :hexbin, :barbins, :scatterbins, :stepbins, :bins2d, :bar]
        SeriesLike(), Afwd
    else
        parent(Afwd)
    end
end

@recipe function f(::SeriesLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    index(dim), parent(A)
end
@recipe function f(::SeriesLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(val(dep))
    index(ind), parent(A)
end

@recipe function f(::HistogramLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(A)
    index(dim), parent(A)
end
@recipe function f(::HistogramLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(index(dep))
    index(ind), parent(A)
end

@recipe function f(::ViolinLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :yguide --> label(A)
    parent(A)
end
@recipe function f(::ViolinLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (IndependentDim, DependentDim))
    ind, dep = dims(A)
    :xguide --> label(dep)
    :yguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(index(dep))
    parent(A)
end

@recipe function f(::HeatMapLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    index(dim), parent(A)
end

@recipe function f(::HeatMapLike, A::AbstractArray{T,2}) where T
    A = maybe_permute(A, (YDim, XDim))
    y, x = dims(A)
    :xguide --> label(x)
    :yguide --> label(y)
    :zguide --> label(A)
    :colorbar_title --> label(A)
    reverse(map(index, dims(A)))..., parent(A)
end

@recipe function f(::ImageLike, A::AbstractArray{T,2}) where T
    parent(A)
end

maybe_permute(A, dims) = all(hasdim(A, dims)) ? permutedims(A, dims) : A

forwardorder(A::AbstractArray) =
    reorder(A, ForwardIndex) |> a -> reorder(a, ForwardRelation)

refdims_title(A::AbstractArray) = join(map(refdims_title, refdims(A)), ", ")
refdims_title(refdim::Dimension) = 
    string(name(refdim), ": ", refdims_title(mode(refdim), refdim))
refdims_title(mode::AbstractSampled, refdim::Dimension) = begin
    start, stop = map(string, bounds(refdim))
    if start == stop
        start
    else
         "$start to $stop"
    end
end
refdims_title(mode::IndexMode, refdim::Dimension) = string(val(refdim))

