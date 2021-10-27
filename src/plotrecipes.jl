struct HeatMapLike end
struct WireframeLike end
struct SeriesLike end
struct HistogramLike end
struct ViolinLike end

struct DimensionalPlot end


@recipe function f(A::AbstractDimArray)
    DimensionalPlot(), A
end

@recipe function f(::DimensionalPlot, A::AbstractArray)
    A_fwd = reorder(A, ForwardOrdered())
    sertype = get(plotattributes, :seriestype, :none)
    if !(sertype in [:marginalhist])
        :title --> refdims_title(A_fwd)
    end
    if ndims(A) > 2
        parent(A)
    elseif sertype in [:heatmap, :contour, :volume, :marginalhist,
                       :surface, :contour3d, :wireframe, :scatter3d]
        HeatMapLike(), A_fwd
    elseif sertype in [:histogram, :stephist, :density, :barhist, :scatterhist, :ea_histogram]
        HistogramLike(), A_fwd
    elseif sertype in [:hline]
        :yguide --> label(A_fwd)
        parent(A_fwd)
    elseif sertype in [:vline, :andrews]
        :xguide --> label(A_fwd)
        parent(A_fwd)
    elseif sertype in [:violin, :dotplot, :boxplot]
        ViolinLike(), A_fwd
    elseif sertype in [:plot, :histogram2d, :none, :line, :path, :shape, :steppre, 
                       :steppost, :sticks, :scatter, :hexbin, :barbins, :scatterbins, 
                       :stepbins, :bins2d, :bar]
        SeriesLike(), A_fwd
    else
        parent(A_fwd)
    end
end

@recipe function f(s::SeriesLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    _xticks!(plotattributes, s, dim)
    _withaxes(dim, A)
end
@recipe function f(s::SeriesLike, A::AbstractArray{T,2}) where T
    A = permutedims(A, commondims(>:, (TimeDim, XDim, IndependentDim, YDim, ZDim, DependentDim, Dimension, Dimension), dims(A)))
    ind, dep = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(val(dep))
    :tickfontalign --> :left
    _xticks!(plotattributes, s, ind)
    _withaxes(ind, A)
end
@recipe function f(s::SeriesLike, A::AbstractArray{T,3}) where T
    A = permutedims(A, commondims(>:, (TimeDim, XDim, IndependentDim, YDim, ZDim, DependentDim, DependentDim, Dimension, Dimension, Dimension), dims(A)))
    ind, dep1, dep2 = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(val(dep))
    :tickfontalign --> :left
    _xticks!(plotattributes, s, ind)
    _withaxes(ind, A)
end

@recipe function f(s::HistogramLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(A)
    _withaxes(dim, A)
end
@recipe function f(s::HistogramLike, A::AbstractArray{T,2}) where T
    A = permutedims(A, commondims(>:, (ZDim, YDim, DependentDim, IndependentDim, XDim, TimeDim, IndependentDim, Dimension, Dimension), dims(A)))
    ind, dep = dims(A)
    :xguide --> label(A)
    :legendtitle --> label(dep)
    :label --> permutedims(index(dep))
    _withaxes(ind, A)
end

@recipe function f(::ViolinLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :yguide --> label(A)
    parent(A)
end
@recipe function f(s::ViolinLike, A::AbstractArray{T,2}) where T
    A = permutedims(A, commondims(>:, (ZDim, YDim, DependentDim, XDim, TimeDim, IndependentDim, Dimension, Dimension), dims(A)))
    dep, ind = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(ind)
    :label --> permutedims(index(ind))
    _xticks!(plotattributes, s, ind)
    parent(A)
end

@recipe function f(s::HeatMapLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    _xticks!(plotattributes, s, dim)
    parent(A)
end

@recipe function f(s::HeatMapLike, A::AbstractArray{T,2}) where T
    A = permutedims(A, commondims(>:, (ZDim, YDim, XDim, TimeDim, Dimension, Dimension), dims(A)))
    y, x = dims(A)
    :xguide --> label(x)
    :yguide --> label(y)
    :zguide --> label(A)
    :colorbar_title --> label(A)
    _xticks!(plotattributes, s, x)
    _yticks!(plotattributes, s, y)
    _withaxes(x, y, A)
end

_withaxes(dim::Dimension, A::AbstractDimArray) =
    _withaxes(lookup(dim), index(dim), parent(A))
_withaxes(::NoLookup, index, A::AbstractArray) = A
_withaxes(::LookupArray, index, A::AbstractArray) = index, A
_withaxes(::Categorical, index, A::AbstractArray) = eachindex(index), A

_withaxes(dx::Dimension, dy::Dimension, A::AbstractDimArray) =
    _withaxes(lookup(dx), lookup(dy), index(dx), index(dy), parent(A))
_withaxes(::LookupArray, ::LookupArray, ix, iy, A) = ix, iy, A
_withaxes(::NoLookup, ::LookupArray, ix, iy, A) = axes(A, 2), iy, A
_withaxes(::LookupArray, ::NoLookup, ix, iy, A) = ix, axes(A, 1), A
_withaxes(::NoLookup, ::NoLookup, ix, iy, A) = axes(A, 2), axes(A, 1), A

_xticks!(attr, s, d::Dimension) = _xticks!(attr, s, lookup(d), index(d))
_xticks!(attr, s, ::Categorical, index) =
    RecipesBase.is_explicit(attr, :xticks) || (attr[:xticks] = (eachindex(index), index))
_xticks!(attr, s, ::LookupArray, index) = nothing

_yticks!(attr, s, d::Dimension) = _yticks!(attr, s, lookup(d), index(d))
_yticks!(attr, s, ::Categorical, index) =
    RecipesBase.is_explicit(attr, :yticks) || (attr[:yticks] = (eachindex(index), index))
_yticks!(attr, s, ::LookupArray, index) = nothing

"""
    refdims_title(A::AbstractDimArray)
    refdims_title(refdims::Tuple)
    refdims_title(refdim::Dimension)

Generate a title string based on reference dimension values.
"""
function refdims_title end
refdims_title(A::AbstractArray; kw...) = refdims_title(refdims(A); kw...)
function refdims_title(refdims::Tuple; kw...)
    join(map(rd -> refdims_title(rd; kw...), refdims), ", ")
end
function refdims_title(refdim::Dimension; kw...)
    string(name(refdim), ": ", refdims_title(lookup(refdim), refdim; kw...))
end
function refdims_title(lookup::AbstractSampled, refdim::Dimension; kw...)
    start, stop = map(string, bounds(refdim))
    if start == stop
        start
    else
         "$start to $stop"
    end
end
refdims_title(lookup::LookupArray, refdim::Dimension; kw...) = string(val(refdim))

