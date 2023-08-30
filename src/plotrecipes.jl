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

@recipe function f(::DimensionalPlot, A::AbstractArray)
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

@recipe function f(s::SeriesLike, A::AbstractArray{T,1}) where T
    dim = dims(A, 1)
    :xguide --> label(dim)
    :yguide --> label(A)
    :label --> string(name(A))
    _xticks!(plotattributes, s, dim)
    _withaxes(dim, A)
end
@recipe function f(s::SeriesLike, A::AbstractArray{T,2}) where T
    A = permutedims(A, _fwdorderdims(A))
    ind, dep = dims(A)
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
    ds = _revorderdims(A)
    A = permutedims(A, ds)
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
    ds = _revorderdims(A)
    A = permutedims(A, ds)
    dep, ind = dims(A)
    :xguide --> label(ind)
    :yguide --> label(A)
    :legendtitle --> label(ind)
    :label --> permutedims(index(ind))
    _xticks!(plotattributes, s, ind)
    parent(A)
end
@recipe function f(s::ViolinLike, A::AbstractArray{T,3}) where T
    ds = _revorderdims(A)
    A = permutedims(A, ds)
    dep2, dep1, ind = dims(A)
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
    ds = _revorderdims(A)
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
@recipe function f(x::DimPlotMode, A::AbstractArray{T,N}) where {T,N}
    throw(ArgumentError("$(x.seriestype) not implemented in $N dimensions"))
end

### Makie.jl recipes

# First, define default plot types for DimArrays
MakieCore.plottype(A::AbstractDimArray{<:Union{Missing,Number},1}) = MakieCore.Scatter
MakieCore.plottype(A::AbstractDimArray{<:Union{Missing,Number},2}) = MakieCore.Heatmap
# 3d A are a little more complicated - if dim3 is a singleton, then heatmap, otherwise volume
function MakieCore.plottype(A::AbstractDimArray{<:Union{Missing,Number},3})
    if size(A, 3) == 1
        MakieCore.Heatmap
    else
        MakieCore.Volume
    end
end

# then, define how they are to be converted to plottable data
function MakieCore.convert_arguments(PB::MakieCore.PointBased, A::AbstractDimArray{<:Union{Number,Missing},1})
    A = _prepare_makie(A)
    return MakieCore.convert_arguments(PB, map(index, dims(A))..., parent(A))
end
# allow 3d A to be plotted as volumes
function MakieCore.convert_arguments(
    ::MakieCore.VolumeLike, A::AbstractDimArray{<:Union{Real,Missing},3}
) 
    A = _prepare_makie(A)
    xs, ys, zs = lookup(A)
    return (xs, ys, zs, parent(A))
end
# allow plotting 3d A with singleton third dimension (basically 2d A)
function MakieCore.convert_arguments(
    ::MakieCore.SurfaceLike, A::AbstractDimArray{<:Union{Missing,Number},2}
)
    A = _prepare_makie(A)
    xs, ys = lookup(A)
    return (xs, ys, parent(A))
end
function MakieCore.convert_arguments(
    ::MakieCore.PointBased, A::AbstractDimArray{<:Union{Missing,Number},1}
)
    A = _prepare_makie(A)
    xs = lookup(A, 1)
    return parent(xs), parent(A)
end
function MakieCore.convert_arguments(
    ::MakieCore.DiscreteSurface, A::AbstractDimArray{<:Union{Missing,Number},2}
)
    A = _prepare_makie(A)
    xs, ys = map(_lookup_edges, lookup(A))
    return (xs, ys, parent(A))
end
# fallbacks with descriptive error messages
MakieCore.convert_arguments(t::MakieCore.ConversionTrait, r::AbstractDimArray) =
    _makie_not_implemented_error(t, r)

### Shared utils

_fwdorderdims(x) = dims(dims(x), (TimeDim, XDim, IndependentDim, YDim, ZDim, DependentDim, DependentDim, Dimension, Dimension, Dimension))
_revorderdims(x) = reverse(_fwdorderdims(reverse(dims(x))))

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
function refdims_title(lookup::LookupArray, refdim::Dimension; kw...)
    if parent(refdim) isa AbstractArray
        string(first(parent(refdim)))
    else
        string(parent(refdim))
    end
end


function _lookup_edges(l::LookupArray)
    l = if l isa AbstractSampled 
        set(l, Intervals())
    else
        set(l, Sampled(; sampling=Intervals()))
    end
    if l == 1
        return [bounds(l)...]
    else
        ib = intervalbounds(l)
        if order(l) isa ForwardOrdered
            edges = first.(ib)
            push!(edges, last(last(ib)))
        else
            edges = last.(ib)
            push!(edges, first(last(ib)))
        end
        return edges
    end
end

_prepare_makie(A) = _missing_or_float32.(A) |> _permute_fwd |> _reorder

_missing_or_float32(num::Number) = Float32(num)
_missing_or_float32(::Missing) = missing

_reorder(A) = reorder(A, DD.ForwardOrdered)
_permute_fwd(A) = permutedims(A, _fwdorderdims(A))
_permute_rev(A) = permutedims(A, _revorderdims(A))
