module DimensionalDataMakieExt

using DimensionalData
using Makie
using IntervalSets
using DimensionalData.Dimensions, DimensionalData.LookupArrays

const DD = DimensionalData

# Shared docstrings: keep things consistent.

function Makie_attribute_names(P)
    if isdefined(Makie, :MakieCore) # To work with Makie <0.24
        Makie.MakieCore.attribute_names(P)
    else
        Makie.attribute_names(P) # For Makie >=0.24
    end
end

const AXISLEGENDKW_DOC = """
- `axislegend`: attributes to pass to `axislegend`.
"""
_keyword_heading_doc(f) = """
# Keywords

Keywords for $f work as usual.
"""

_xy(f) = """
- `x`: A `Dimension`, `Dimension` type or `Symbol` for the `Dimension` that should go on the x axis of the plot.
- `y`: A `Dimension`, `Dimension` type or `Symbol` for the `Dimension` that should go on the y axis of the plot.
"""
_z(f) = """
- `z`: A `Dimension`, `Dimension` type or `Symbol` for the `Dimension` that should go on the z axis of the plot.
"""

_labeldim_detection_doc(f) = """
Labels are found automatically, following this logic:
1. Use the `labeldim` keyword if it is passsed in.
2. Find the first dimension with a `Categorical` lookup.
3. Find the first `<: DependentDim` dimension, which will include
    `Ti` (time), `X` and any other `<: XDim` dimensions.
4. Fallback: just use the first dimension of the array for labels.

$(_keyword_heading_doc(f))

- `labeldim`: manual specify the dimension to use as series and get 
    the `labels` attribute from. Can be a `Dimension`, `Type`, `Symbol` or `Int`.
"""

# Only `heatmap` and `contourf` get a colorbar
function _maybe_colorbar_doc(f) 
    if f in (:heatmap, :contourf)
        """
        - `colorbar`: keywords to pass to `Makie.Colorbar`.
        """
    else
        ""
    end
end

obs_f(f, A::Observable) = lift(x -> f(x), A)
obs_f(f, A) = f(A)

const MayObs{T} = Union{T, Makie.Observable{<:T}}

const MakieGrids = Union{Makie.GridPosition, Makie.GridSubposition}

PlotTypes_1D = (Lines, Scatter, ScatterLines, Stairs, Stem, BarPlot,  Waterfall, LineSegments)
PlotTypes_Cat_1D = (BoxPlot, Violin, RainClouds)
PlotTypes_2D = (Heatmap, Image, Contour, Contourf, Contour3d, Spy, Surface) 
PlotTypes_3D = (Volume, VolumeSlices)

for p in (PlotTypes_1D..., PlotTypes_2D..., PlotTypes_3D..., Series, PlotTypes_Cat_1D...)
    f = Makie.plotkey(p)
    @eval begin
        function Makie.$f(A::MayObs{<:AbstractDimArray}; figure = (;), attributes...)
            fig = Figure(; figure...)
            ax, plt = $f(fig[1,1], A; attributes...)
            return Makie.FigureAxisPlot(fig, ax, plt)
        end
    end
end

function error_if_has_content(grid::G) where G
    G <: GridSubposition && Makie.GridLayoutBase.get_layout_at!(grid.parent; createmissing=true)
    c = contents(grid; exact=true) # Error from Makie
    if !isempty(c)
        error("""
        You have used the non-mutating plotting syntax with a GridPosition, which requires an empty GridLayout slot to create an axis in, but there are already the following objects at this layout position:
        $(c)
        If you meant to plot into an axis at this position, use the plotting function with `!` (e.g. `func!` instead of `func`).
        If you really want to place an axis on top of other blocks, make your intention clear and create it manually.
        """)
    end
end


# 1d plots are scatter by default
for (p1) in PlotTypes_1D
    f1 = Makie.plotkey(p1)
    f1! = Symbol(f1, '!')
    
    docstring = """
        $f1(A::AbstractDimVector; attributes...)
        
    Plot a 1-dimensional `AbstractDimArray` with `Makie`.

    The X axis will be labelled with the dimension name and and use ticks from its lookup.

    """
    @eval begin
        @doc $docstring
        function Makie.$f1(fig::MakieGrids, A::MayObs{AbstractDimArray}; axislegend =(;merge = false, unique = false), axis = (;), plot_user_attributes...)
            error_if_has_content(fig)

            ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type($p1, A)
            axis_att = axis_attributes($p1, A)
            axis_att_for_function = filter_keywords(merge(filter_keywords_axis!(ax_type, axis_att), axis), (:type,), !)

            plot_attr = merge(plot_attributes($p1, A), plot_user_attributes)

            ax = ax_type(fig; axis_att_for_function...)
            p = $f1!(ax, A; plot_attr...)
            
            add_labels_to_lscene(ax, axis_att)

            axislegend != false && Makie.axislegend(ax; axislegend...)
            return Makie.AxisPlot(ax, p)
        end
    end
end


function Makie.series(fig::MakieGrids, A::MayObs{AbstractDimMatrix}; color = :lighttest, labeldim = nothing, axislegend = (;merge = false, unique = false), axis = (;), plot_user_attributes...)
    error_if_has_content(fig)

    ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type(Series, A)
    axis_att = axis_attributes(Series, A; labeldim = labeldim)
    axis_att_for_function = filter_keywords(merge(filter_keywords_axis!(ax_type, axis_att), axis), (:type,), !)

    plot_attr = merge(plot_attributes(Series, A; labeldim = labeldim), plot_user_attributes)

    ax = ax_type(fig; axis_att_for_function...)

    n_colors = size(to_value(A), _categorical_or_dependent(to_value(A), labeldim))
    default_colormap = Makie.to_colormap(color)
    colormap = n_colors > 7 ? Makie.resample_cmap(default_colormap, n_colors) : default_colormap
    
    p = series!(ax, A; labeldim = labeldim, color = colormap, plot_attr...)
            
    add_labels_to_lscene(ax, axis_att)

    axislegend != false && Makie.axislegend(ax; axislegend...)
    return Makie.AxisPlot(ax, p)
end

for (p1) in PlotTypes_Cat_1D
    f1 = Makie.plotkey(p1)
    f1! = Symbol(f1, '!')
    
    @eval begin
        function Makie.$f1(fig::MakieGrids, A::MayObs{AbstractDimMatrix}; categoricaldim = nothing, axis = (;), plot_user_attributes...)
            error_if_has_content(fig)

            ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type($p1, A)
            axis_att = axis_attributes($p1, A; categoricaldim = categoricaldim)
            axis_att_for_function = filter_keywords(merge(filter_keywords_axis!(ax_type, axis_att), axis), (:type,), !)

            plot_attr = merge(plot_attributes($p1, A), plot_user_attributes)

            ax = ax_type(fig; axis_att_for_function...)

            p = $f1!(ax, A; categoricaldim = categoricaldim, plot_attr...)

            add_labels_to_lscene(ax, axis_att)

            return Makie.AxisPlot(ax, p)
        end
    end
end


function axis_attributes(::Type{P}, A::MayObs{DD.AbstractDimArray}) where P <: Union{Lines, LineSegments, Scatter, ScatterLines, Stairs, Stem, BarPlot, Waterfall}
    lookup_attributes = get_axis_ticks(obs_f(i -> dims(i, 1), A), 1)
    merge(
        lookup_attributes,
        (;
            xlabel = obs_f(i -> string(label(dims(i, 1))), A), 
            ylabel = obs_f(DD.label, A),
            title = obs_f(DD.refdims_title, A),
        ),
    )
end

function plot_attributes(::Type{P}, A::MayObs{<:DD.AbstractDimMatrix}; labeldim = nothing) where P <: Union{Makie.Series}
    categoricaldim = obs_f(i -> _categorical_or_dependent(i, labeldim), A)
    plot_attributes = (; 
        labels=obs_f(i -> string.(parent(i)), categoricaldim),
    )
end

function axis_attributes(::Type{Series}, A::MayObs{DD.AbstractDimMatrix}; labeldim)
    categoricaldim = _categorical_or_dependent(to_value(A), labeldim)
    isnothing(categoricaldim) && throw(ArgumentError("No dimensions have Categorical lookups"))
    otherdim = only(otherdims(to_value(A), categoricaldim))

    lookup_attributes = get_axis_ticks((dims(to_value(A), otherdim),))

    merge(
        lookup_attributes,
        (;
            xlabel=obs_f(i -> string(label(dims(i, otherdim))), A), 
            ylabel=obs_f(DD.label, A),
            title=obs_f(DD.refdims_title, A),
        ),
    )
end

function axis_attributes(::Type{<:Union{RainClouds, BoxPlot, Violin}}, A::MayObs{DD.AbstractDimMatrix}; categoricaldim)
    categoricaldim = _categorical_or_dependent(to_value(A), categoricaldim)
    isnothing(categoricaldim) && throw(ArgumentError("No dimensions have Categorical lookups"))

    lookup_attributes = get_axis_ticks((dims(to_value(A), categoricaldim),))

    merge(
        lookup_attributes,
        (;
            xlabel=obs_f(i -> string(label(dims(i, categoricaldim))), A), 
            ylabel=obs_f(DD.label, A),
            title=obs_f(DD.refdims_title, A),
        ),
    )
end

function plot_attributes(::Type{P}, A::MayObs{<:DD.AbstractDimArray}) where P <: Union{Lines, Scatter, ScatterLines, Stairs, Stem, BarPlot, BoxPlot, Waterfall, RainClouds, Violin, LineSegments}
    plot_attributes = (; 
        label=obs_f(plot_label, A),
    )
    plot_attributes
end


""" 
    plot_label(A::AbstractDimArray)

Returns the label of a `DimensionalData` object, or a space if no label is found. This function is needed because an empty label passed to the Legend leds to an error in Makie.
"""
function plot_label(A)
    lab = DD.label(A)
    if isempty(lab)
        return " "
    else
        lab
    end
end


for p1 in PlotTypes_2D
    f1 = Makie.plotkey(p1)
    f1! = Symbol(f1, '!')
    docstring = """
        $f1(A::AbstractDimMatrix; attributes...)
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f1`.

    $(_keyword_heading_doc(f1))
    $(_xy(f1))
    $(_maybe_colorbar_doc(f1))
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(fig::MakieGrids, A::MayObs{AbstractDimMatrix{T}}; 
            xdim = nothing, ydim = nothing, colorbar=(;), axis = (;), plot_attributes...
        ) where T
            error_if_has_content(fig)

            ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type($p1, to_value(A); xdim = xdim, ydim = ydim)
            axis_att = axis_attributes($p1, A; xdim = xdim, ydim = ydim)
            axis_att_for_function = filter_keywords(merge(filter_keywords_axis!(ax_type, axis_att), axis), [:type], !)
            ax = ax_type(fig[1,1]; axis_att_for_function...)
            p = $f1!(ax, A; plot_attributes..., xdim = xdim, ydim = ydim)
            add_labels_to_lscene(ax, axis_att)

            if colorbar != false && $(f1 in (:heatmap, :contourf, :surface, :spy)) && T <: Real
                # T check is to not add if using RGB
                Colorbar(fig[1, 2], p;
                    label=obs_f(DD.label, A), colorbar...
                )
            end
            return Makie.AxisPlot(ax, p)
        end
    end
end

for p1 in PlotTypes_3D
    f1 = Makie.plotkey(p1)
    f1! = Symbol(f1, '!')
    docstring = """
        $f1(A::AbstractDimMatrix; attributes...)
        
    Plot a 3-dimensional `AbstractDimArray` with `Makie.$f1`.

    $(_keyword_heading_doc(f1))
    $(_xy(f1))
    $(_maybe_colorbar_doc(f1))
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(fig::MakieGrids, A::MayObs{AbstractDimArray{<:Any,3}}; 
            xdim=nothing, ydim=nothing, zdim=nothing, colorbar=(;), axis = (;), plot_attributes...
        )
            error_if_has_content(fig)
            ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type($p1, A; xdim = xdim, ydim = ydim, zdim = zdim)
            axis_att = axis_attributes($p1, A; xdim = xdim, ydim = ydim, zdim = zdim)
            axis_att_for_function = filter_keywords(merge(filter_keywords_axis!(ax_type, axis_att), axis), [:type], !)

            ax = ax_type(fig[1,1]; axis_att_for_function...)
            p = $f1!(ax, A; plot_attributes..., xdim = xdim, ydim = ydim, zdim = zdim)

            if colorbar != false
                Colorbar(fig[1, 2], p;
                    label=obs_f(DD.label, A), colorbar...
                )
            end
            add_labels_to_lscene(ax, axis_att)
            return Makie.AxisPlot(ax, p)
        end
    end

end

function filter_keywords_axis!(ax_type, att)
    filter_keywords(att, Makie_attribute_names(ax_type), identity)
end

function filter_keywords(collecti, to_filter, f)
    keys_filt = filter(i -> f(i in to_filter), keys(collecti))
    collecti[keys_filt]
end

function axis_attributes(::Type{P}, dd; xdim, ydim) where P <: Union{Heatmap, Image, Surface, Contour, Contourf, Contour3d, Spy}
    dims_axes = obs_f(i -> get_dimensions_of_makie_axis(i, (xdim, ydim)), dd)
    lookup_attributes = get_axis_ticks(to_value(dims_axes))

    merge(
        lookup_attributes,
        (;
        xlabel = obs_f(i -> DD.label(i[1]), dims_axes),
        ylabel = obs_f(i -> DD.label(i[2]), dims_axes),
        title = obs_f(DD.refdims_title, dd)),
    )
end

function axis_attributes(::Type{P}, dd; xdim, ydim, zdim) where P <: Union{Volume, VolumeSlices}
    dims_axes = obs_f(i -> get_dimensions_of_makie_axis(i, (xdim, ydim, zdim)), dd)

    lookup_attributes = get_axis_ticks(to_value(dims_axes))
    att = merge(
        lookup_attributes,
        (;
        xlabel = obs_f(i -> DD.label(i[1]), dims_axes),
        ylabel = obs_f(i -> DD.label(i[2]), dims_axes),
        zlabel = obs_f(i -> DD.label(i[3]), dims_axes),
        title = obs_f(DD.refdims_title, dd)),
    )
end

function default_axis_type(::Type{P}, dd; kwargs...) where P
    output = Makie.convert_arguments(P, to_value(dd); kwargs...)
    default_type = Makie.args_preferred_axis(P, output...) 
    isnothing(default_type) ? Axis : default_type
end

function add_labels_to_lscene(ax, axis_att)
    if ax isa Makie.LScene && !isnothing(ax.scene[Makie.OldAxis])
        ax.scene[Makie.OldAxis][:names, :axisnames][] = (axis_att[:xlabel], axis_att[:ylabel], haskey(axis_att, :zlabel) ? axis_att[:zlabel] : "") .|> to_value
    end
end


# Definition of plot functions 
Makie.plottype(::D) where D<:Union{<:AbstractDimArray, <:DimPoints} = _plottype(D)
_plottype(::Type{<:MayObs{AbstractDimVector}}) = Makie.Scatter
_plottype(::Type{<:MayObs{AbstractDimMatrix}}) = Makie.Heatmap
_plottype(::Type{<:MayObs{AbstractDimArray{<:Any,3}}}) = Makie.Volume
_plottype(::Type{<:MayObs{DimPoints}}) = Makie.Scatter
for DD in (AbstractDimVector, AbstractDimMatrix, AbstractDimArray{<:Any,3}, DimPoints)
    p = _plottype(DD)
    f = Makie.plotkey(p)
    f! = Symbol(f, '!')
    eval(quote
        Makie.plot(dd::MayObs{$DD}; kwargs...) = Makie.$f(dd; kwargs...)
        Makie.plot(fig::MakieGrids, dd::MayObs{$DD}; kwargs...) = Makie.$f(fig, dd; kwargs...)
        Makie.plot!(ax, dd::MayObs{$DD}; kwargs...) = Makie.$f!(ax, dd; kwargs...)
    end)
end

Makie.used_attributes(::Type{<:Series}, A::DD.AbstractDimMatrix) = (:labeldim,)
Makie.used_attributes(::Type{<:Union{RainClouds, BoxPlot, Violin}}, A::DD.AbstractDimArray) = (:categoricaldim,)
Makie.used_attributes(::Type{<:Union{Contour, Contourf, Contour3d, Image, Heatmap, Surface, Spy}}, A::DD.AbstractDimMatrix) = (:xdim, :ydim)
Makie.used_attributes(::Type{<:Union{VolumeSlices, Volume}}, A::DD.AbstractDimArray{<:Any, 3}) = (:xdim, :ydim, :zdim)

function Makie.convert_arguments(P::Type{T}, A::AbstractDimMatrix; xdim = nothing , ydim = nothing) where T<:Union{Contour, Contourf, Surface, Contour3d}
    dims_axes = get_dimensions_of_makie_axis(A, (xdim, ydim))
    xlookup, ylookup = (lookup(dims_axes[1]), lookup(dims_axes[2])) .|> parent .|> get_number_version
    z = parent(permutedims(A, (dims_axes[1], dims_axes[2]))) 
    Makie.convert_arguments(P, xlookup, ylookup, z) 
end

function Makie.convert_arguments(P::Type{<:Series}, A::AbstractDimMatrix; labeldim = nothing)
    categoricaldim = _categorical_or_dependent(A, labeldim)
    isnothing(categoricaldim) && throw(ArgumentError("No dimensions have Categorical lookups")) # This should never happen
    otherdim = only(otherdims(A, categoricaldim))
    xs = parent(lookup(A, otherdim)) |> get_number_version 
    return Makie.convert_arguments(P, xs, parent(permutedims(A, (categoricaldim, otherdim))))
end

# PointBased conversions (scatter, lines, poly, etc)
function Makie.convert_arguments(P::Makie.PointBased, A::AbstractDimVector)
    xs = parent(lookup(A, 1)) |> get_number_version
    return Makie.convert_arguments(P, xs, parent(A))
end

# PointBased conversions (scatter, lines, poly, etc)
function Makie.convert_arguments(P::Makie.PointBased, A::DimPoints)
    return Makie.convert_arguments(P, vec(A))
end
# This doesn't work, but it will at least give the normal Makie error
function Makie.convert_arguments(t::Makie.PointBased, A::DimPoints{<:Any,1})
    return Makie.convert_arguments(t, collect(A))
end

function Makie.convert_arguments(P::Makie.SampleBased, A::AbstractDimVector; categoricaldim = nothing)
    if !isnothing(categoricaldim) 
        dimnum(A, categoricaldim) # Returns an error if dim does not exist
    end
    xs = parent(lookup(A, 1)) |> get_number_version
    return Makie.convert_arguments(P, xs, parent(A))
end

function Makie.convert_arguments(P::Type{<:RainClouds}, A::AbstractDimVector; categoricaldim = nothing)
    if !isnothing(categoricaldim) 
        dimnum(A, categoricaldim) # Returns an error if dim does not exist
    end
    xs = parent(lookup(A, 1)) |> get_number_version
    return Makie.convert_arguments(P, xs, parent(A))
end

function Makie.convert_arguments(P::Type{<:Union{Makie.RainClouds, BoxPlot, Violin}}, A::AbstractDimMatrix; categoricaldim = nothing)
    dd_categoricaldim = _categorical_or_dependent(A, categoricaldim)
    isnothing(dd_categoricaldim) && throw(ArgumentError("No dimensions have Categorical lookups")) # This should never happen
    otherdim = only(otherdims(A, dd_categoricaldim))
    xs = lookup(A, dd_categoricaldim)
    matrix_xs = repeat(parent(xs), outer = (1, size(A, otherdim)))

    matrix_xs, parent(permutedims(A, (otherdim, dd_categoricaldim) ))
    return Makie.convert_arguments(P, get_number_version(vec(matrix_xs)), parent(permutedims(A, (otherdim, dd_categoricaldim))) |> vec)
end

# Grid based conversions (surface, image, heatmap, contour, meshimage, etc)

# ImageLike is for e.g. image, meshimage, etc. It uses an interval based sampling method so requires regular spacing.
function Makie.convert_arguments(P::Type{T}, A::AbstractDimMatrix; xdim = nothing, ydim = nothing) where T<:Union{Image, Spy}
    dims_axes = get_dimensions_of_makie_axis(A, (xdim, ydim))
    xlookup, ylookup = lookup(dims_axes[1]), lookup(dims_axes[2])

    _check_regular_or_categorical_sampling(xlookup; axis = :x)
    _check_regular_or_categorical_sampling(ylookup; axis = :y)

    Makie.convert_arguments(P, _lookup_to_interval(xlookup), _lookup_to_interval(ylookup), parent(permutedims(A, (dims_axes[1], dims_axes[2])))) 
end

# Needed to avoid ambiguous definition of convert_arguments
function Makie.convert_arguments(P::Type{T}, A::AbstractDimMatrix) where T<:Spy
    Makie.convert_arguments(P, A; xdim = nothing, ydim = nothing)
end

# CellGrid is for e.g. heatmap, contourf, etc. It uses vertices as corners of cells, so 
# there have to be n+1 vertices for n cells on an axis.
function Makie.convert_arguments(
    P::Type{Heatmap}, A::AbstractDimMatrix; xdim = nothing, ydim = nothing)
    dims_axes = get_dimensions_of_makie_axis(A, (xdim, ydim))
    xlookup, ylookup = (lookup(dims_axes[1]), lookup(dims_axes[2])) .|> parent .|> get_number_version
    z = parent(permutedims(A, (dims_axes[1], dims_axes[2])))
    return Makie.convert_arguments(P, xlookup, ylookup, z)
end

# VolumeLike is for e.g. volume, volumeslices, etc. It uses a regular grid.
function Makie.convert_arguments(P::Type{T}, A::AbstractDimArray{<:Any,3}; xdim = nothing, ydim = nothing, zdim = nothing) where T<:Union{Volume}
    dims_axes = get_dimensions_of_makie_axis(A, (xdim, ydim, zdim))
    map((l, ax) -> _check_regular_or_categorical_sampling(l; axis = ax, conversiontrait = P), dims_axes, (:x, :y, :z))
    xs, ys, zs = map(_lookup_to_interval, dims_axes) .|> get_number_version
    return Makie.convert_arguments(P, xs, ys, zs, parent(permutedims(A, dims_axes)))
end

function Makie.convert_arguments(P::Type{Makie.VolumeSlices}, A::AbstractDimArray{<:Any,3}; xdim = nothing, ydim = nothing, zdim = nothing)
    dims_axes = get_dimensions_of_makie_axis(A, (xdim, ydim, zdim))
    xs, ys, zs = map(_lookup_to_vector, dims_axes) .|> get_number_version
    return Makie.convert_arguments(P, xs, ys, zs, parent(permutedims(A, dims_axes)))
end

Makie.expand_dimensions(t::Makie.NoConversion, A::AbstractDimArray) = return
Makie.expand_dimensions(t::Makie.PointBased, A::Union{AbstractDimVector, AbstractDimMatrix}) = return
Makie.expand_dimensions(t::Makie.SampleBased, A::AbstractDimVector) = return
Makie.expand_dimensions(t::Makie.Series, A::AbstractDimMatrix) = return
Makie.expand_dimensions(t::Makie.VertexGrid, A::AbstractDimMatrix) = return
Makie.expand_dimensions(t::Makie.ImageLike, A::AbstractDimMatrix) = return
Makie.expand_dimensions(t::Makie.CellGrid, A::AbstractDimMatrix) = return
Makie.expand_dimensions(t::Makie.VolumeLike, A::AbstractDimArray{<:Any,3}) = return
Makie.expand_dimensions(t::Type{VolumeSlices}, A::AbstractDimArray{<:Any,3}) = return
Makie.expand_dimensions(t::Type{Spy}, A::AbstractDimArray{<:Real,2}) = return

# Utility methods

# Get Categorical lookups or DependentDim
_categorical_or_dependent(A, labeldim) = dims(A, labeldim)
function _categorical_or_dependent(A, ::Nothing)
    categoricaldim = reduce(dims(A); init=nothing) do acc, d
        if isnothing(acc)
            lookup(d) isa AbstractCategorical ? d : nothing
        else
            acc
        end
    end
    isnothing(categoricaldim) || return categoricaldim
    dependentdim = reduce(dims(A); init=nothing) do acc, d
        if isnothing(acc)
            d isa DD.DependentDim ? d : nothing
        else
            acc
        end
    end
    if isnothing(dependentdim)
        return first(dims(A)) # Fallback uses whatever is first
    else
        return dependentdim
    end
end

# Check for regular sampling on a lookup, throw an error if not.
# Here, we assume 
function _check_regular_or_categorical_sampling(l; axis = nothing, conversiontrait = ImageLike())
    if !(DD.isregular(l) || DD.iscategorical(l))
        @warn """
        DimensionalDataMakie: The $(isnothing(axis) ? "" : "$axis-axis ")lookup is not regularly spaced, which is required for $(conversiontrait) plot types in Makie.
        The lookup was:
        $l

        You can solve this by resampling your raster, or by using a more permissive plot type like `heatmap`, `surface`, `contour`, or `contourf`.
        
        Currently, DimensionalData ignores that the lookup is irregular, and assumes a regular lookup.  This may be fine,
        or it may give very incorrect results.  Be warned!
        """
    end
end

function get_axis_ticks(l::MayObs{D}, axis) where D<:DD.Dimension
    d = obs_f(lookup, l)
    if d isa MayObs{AbstractCategorical}
        dim_attr = if axis == 1
            (; xticks= obs_f(i -> (unique(get_number_version(parent(i))), 
                unique(string.(parent(lookup(i))))), l))
        elseif axis == 2
            (; yticks= obs_f(i -> (unique(get_number_version(parent(i))), 
                unique(string.(parent(lookup(i))))), l))
        else
            (; zticks= obs_f(i -> unique((get_number_version(parent(i))), 
                unique(string.(parent(lookup(i))))), l))
        end
        dim_attr
    else
        (;)
    end
end

get_number_version(x) = x
get_number_version(x::AbstractVector{<:AbstractChar}) = Int.(x)
get_number_version(x::AbstractVector{<:AbstractString}) = sum.(Int, x) # Sum all chars
get_number_version(x::AbstractVector{<:Symbol}) = get_number_version(string.(x))
get_number_version(x::IntervalSets.ClosedInterval{<:AbstractChar}) = IntervalSets.ClosedInterval((Int.(endpoints(x)) .+ (-.5, .5))...) # Needs to add half the step this do give the interval like heatmap
get_number_version(x::IntervalSets.ClosedInterval) = x

# Simplify dimension lookups and move information to axis attributes
function get_axis_ticks(A)
    get_axis_ticks(obs_f(dims, A))
end
function get_axis_ticks(dims::MayObs{DD.DimTuple})
    all_att = map((i, ax) -> get_axis_ticks(i, ax), dims, 1:length(dims))
    merge(all_att...)
end

# Returns the mapping to the axes of the Makie plot
function get_dimensions_of_makie_axis(A::AbstractDimArray{<:Any,N}, _dims_input::Tuple) where N
    length(_dims_input) == N || throw(ArgumentError("Error. Should never happen"))

    dims_input = filter(!isnothing, _dims_input)
    map(dims_input) do d
        # Make sure replacements contain X/Y/Z only
        hasdim(A, d) || throw(ArgumentError("object does not have a dimension $(basetypeof(d))"))
    end

    default_order = dims(otherdims(A, dims_input), DD.PLOT_DIMENSION_ORDER)
    index_default = 1
    dims_output = []
    for i in 1:N
        if isnothing(_dims_input[i])
            push!(dims_output, default_order[index_default])
            index_default += 1
        else
            push!(dims_output, dims(A, _dims_input[i]))
        end
    end
    (dims_output...,)
end

function _lookup_to_vector(l)
    if isintervals(l)
        bs = intervalbounds(l)
        x = first.(bs)
        push!(x, last(last(bs)))
    else # ispoints(l)
        collect(parent(l))
    end
end

function _lookup_to_vertex_vector(l)
    if isintervals(l)
        return parent(DD.shiftlocus(DD.Center(), l))
    else # ispoints(l)
        return collect(parent(l))
    end
end

function _lookup_to_interval(l)
    # TODO: warn or error if not regular sampling.
    # Maybe use Preferences.jl to determine if we should error or warn.
    l1 = if isnolookup(l)
        Sampled(parent(l); order=ForwardOrdered(), sampling=Intervals(Center()), span=Regular(1))
    elseif ispoints(l)
        set(l, Intervals()) # this sets the intervals to be `Intervals(Center())` by default.  Same as heatmap behaviour.
    else # isintervals(l)
        (l)
    end
    return IntervalSets.Interval(extrema(get_number_version(l1))...)
end
end
