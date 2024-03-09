## Plots.jl recipes

abstract type DimPlotMode end
struct HeatMapLike <: DimPlotMode seriestype::Symbol end
struct WireframeLike <: DimPlotMode seriestype::Symbol end
struct SeriesLike <: DimPlotMode seriestype::Symbol end
struct HistogramLike <: DimPlotMode seriestype::Symbol end
struct ViolinLike <: DimPlotMode seriestype::Symbol end

struct DimensionalPlot end


@recipe function f(A::AbstractDimArray)
    DimensionalPlot(), A
end

@recipe function f(::DimensionalPlot, A::AbstractDimArray)
    A_fwd = reorder(A, ForwardOrdered())
    sertype = get(plotattributes, :seriestype, :none)::Symbol
    if !(sertype in (:marginalhist,))
        :title --> refdims_title(A_fwd)
    end
    if ndims(A) > 3
        parent(A)
    elseif sertype in (:heatmap, :contour, :volume, :marginalhist,
                       :surface, :contour3d, :wireframe, :scatter3d)
        HeatMapLike(sertype), A_fwd
    elseif sertype in (:histogram, :stephist, :density, :barhist, :scatterhist, :ea_histogram)
        HistogramLike(sertype), A_fwd
    elseif sertype in (:hline,)
        :yguide --> label(A_fwd)
        parent(A_fwd)
    elseif sertype in (:vline, :andrews)
        :xguide --> label(A_fwd)
        parent(A_fwd)
    elseif sertype in (:violin, :dotplot, :boxplot)
        ViolinLike(sertype), A_fwd
    elseif sertype in (:plot, :histogram2d, :none, :line, :path, :shape, :steppre, 
                       :steppost, :sticks, :scatter, :hexbin, :barbins, :scatterbins, 
                       :stepbins, :bins2d, :bar)
        SeriesLike(sertype), A_fwd
    else
        parent(A_fwd)
    end
end

@recipe function f(s::SeriesLike, A::AbstractDimArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    :label --> string(name(A))
    _xticks!(plotattributes, s, dim)
    _withaxes(dim, A)
end
@recipe function f(s::SeriesLike, A::AbstractDimArray{T,2}) where T
    A = permutedims(A, forward_order_plot_dims(A))
    ind, dep = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(dep)
    :label --> string.(permutedims(val(dep)))
    :tickfontalign --> :left
    _xticks!(plotattributes, s, ind)
    _withaxes(ind, A)
end

@recipe function f(s::HistogramLike, A::AbstractDimArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(A)
    _withaxes(dim, A)
end
@recipe function f(s::HistogramLike, A::AbstractDimArray{T,2}) where T
    ds = reverse_order_plot_dims(A)
    A = permutedims(A, ds)
    ind, dep = dims(A)
    :xguide --> label(A)
    :legendtitle --> label(dep)
    :label --> string.(permutedims(parent(lookup(dep))))
    _withaxes(ind, A)
end

@recipe function f(::ViolinLike, A::AbstractDimArray{T,1}) where T
    dim = dims(A, 1)
    :yguide --> label(A)
    parent(A)
end
@recipe function f(s::ViolinLike, A::AbstractDimArray{T,2}) where T
    ds = reverse_order_plot_dims(A)
    A = permutedims(A, ds)
    dep, ind = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(ind)
    :label --> string.(permutedims(parent(lookup(ind))))
    _xticks!(plotattributes, s, ind)
    parent(A)
end
@recipe function f(s::ViolinLike, A::AbstractDimArray{T,3}) where T
    ds = reverse_order_plot_dims(A)
    A = permutedims(A, ds)
    dep2, dep1, ind = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(ind)
    :label --> string.(permutedims(parent(lookup(ind))))
    _xticks!(plotattributes, s, ind)
    parent(A)
end

@recipe function f(s::HeatMapLike, A::AbstractDimArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    _xticks!(plotattributes, s, dim)
    parent(A)
end
@recipe function f(s::HeatMapLike, A::AbstractDimArray{T,2}) where T
    ds = reverse_order_plot_dims(A)
    A = permutedims(A, ds)
    y, x = dims(A)
    :xguide --> label(x)
    :yguide --> label(y)
    :zguide --> label(A)
    :colorbar_title --> label(A)
    _xticks!(plotattributes, s, x)
    _yticks!(plotattributes, s, y)
    _withaxes(x, y, A)
end
@recipe function f(x::DimPlotMode, A::AbstractDimArray{T,N}) where {T,N}
    throw(ArgumentError("$(x.seriestype) not implemented in $N dimensions"))
end


_withaxes(dim::Dimension, A::AbstractDimArray) =
    _withaxes(lookup(dim), parent(lookup(dim)), parent(A))
_withaxes(::NoLookup, values, A::AbstractArray) = A
_withaxes(::Lookup, values, A::AbstractArray) = values, A
_withaxes(::Categorical, values, A::AbstractArray) = eachindex(values), A

_withaxes(dx::Dimension, dy::Dimension, A::AbstractDimArray) =
    _withaxes(lookup(dx), lookup(dy), parent(lookup(dx)), parent(lookup(dy)), parent(A))
_withaxes(::Lookup, ::Lookup, ix, iy, A) = ix, iy, A
_withaxes(::NoLookup, ::Lookup, ix, iy, A) = axes(A, 2), iy, A
_withaxes(::Lookup, ::NoLookup, ix, iy, A) = ix, axes(A, 1), A
_withaxes(::NoLookup, ::NoLookup, ix, iy, A) = axes(A, 2), axes(A, 1), A

_xticks!(attr, s, d::Dimension) = _xticks!(attr, s, lookup(d), parent(lookup(d)))
_xticks!(attr, s, ::Categorical, values) =
    RecipesBase.is_explicit(attr, :xticks) || (attr[:xticks] = (eachindex(values), values))
_xticks!(attr, s, ::Lookup, values) = nothing

_yticks!(attr, s, d::Dimension) = _yticks!(attr, s, lookup(d), parent(lookup(d)))
_yticks!(attr, s, ::Categorical, values) =
    RecipesBase.is_explicit(attr, :yticks) || (attr[:yticks] = (eachindex(values), values))
_yticks!(attr, s, ::Lookup, values) = nothing

### Shared utils

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
function refdims_title(lookup::Lookup, refdim::Dimension; kw...)
    if parent(refdim) isa AbstractArray
        string(first(parent(refdim)))
    else
        string(parent(refdim))
    end
end

const PLOT_DIMENSION_ORDER = (TimeDim, XDim, IndependentDim, IndependentDim, YDim, ZDim, DependentDim, DependentDim, Dimension, Dimension, Dimension)
forward_order_plot_dims(x) = dims(dims(x), PLOT_DIMENSION_ORDER)
reverse_order_plot_dims(x) = reverse(forward_order_plot_dims(reverse(dims(x))))
