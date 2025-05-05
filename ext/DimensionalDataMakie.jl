module DimensionalDataMakie

using DimensionalData
using Makie
using IntervalSets
using DimensionalData.Dimensions, DimensionalData.LookupArrays

const DD = DimensionalData

# Shared docstrings: keep things consistent.

const AXISLEGENDKW_DOC = """
- `axislegendkw`: attributes to pass to `axislegend`.
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
        - `colorbarkw`: keywords to pass to `Makie.Colorbar`.
        """
    else
        ""
    end
end

obs_f(f, A::Observable) = lift(x -> f(x), A)
obs_f(f, A) = f(A)

const MayObs{T} = Union{T, Makie.Observable{<:T}}

PlotTypes_1D = (Lines, Scatter, ScatterLines, Stairs, Stem, BarPlot, BoxPlot, Waterfall, Series, Violin, RainClouds, LineSegments)
PlotTypes_2D = (Heatmap, Image, Contour, Contourf, Contour3d, Spy, Surface) 
PlotTypes_3D = (Volume, VolumeSlices)

for p in (PlotTypes_1D..., PlotTypes_2D..., PlotTypes_3D...)
    f = Makie.plotkey(p)
    eval(quote
        function Makie.$f(A::MayObs{<:AbstractDimArray}; figure = (;), attributes...)
            fig = Figure(; figure...)
            ax, plt = $f(fig[1,1], A; attributes...)
            display(fig)
            return Makie.FigureAxisPlot(fig, ax, plt)
        end
    end)
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
        function Makie.$f1(fig, A::MayObs{AbstractDimVector}; axislegendkw=(;merge = false, unique = false), axis = (;), plot_user_attributes...)

            ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type($p1, A)
            axis_att = axis_attributes($p1, A)
            axis_att_for_function = filter_keywords(merge(filter_keywords_axis!(ax_type, axis_att), axis), (:type,), !)

            plot_attr = merge(plot_attributes($p1, A), plot_user_attributes)

            ax = ax_type(fig; axis_att_for_function...)
            p = $f1!(ax, A; plot_attr...)
            
            add_labels_to_lscene(ax, axis_att)

            axislegend(ax; axislegendkw)
            return Makie.AxisPlot(ax, p)
        end
    end
end


function Makie.series(fig, A::MayObs{AbstractDimMatrix}; labeldim = nothing, axislegendkw=(;merge = false, unique = false), axis = (;), plot_user_attributes...)
    axis_attr = merge(axis_attributes(Makie.Series, A; labeldim = labeldim), axis)
    plot_attr = merge(plot_attributes(Makie.Series, A), plot_user_attributes, )

    ax = Axis(fig; axis_attr...)

    p = Makie.series!(ax, A; labeldim = labeldim, plot_attr...)
    
    axislegend(ax; axislegendkw)
    return ax, p
end


function axis_attributes(::Type{P}, A::MayObs{DD.AbstractDimVector}) where P <: Union{Lines, LineSegments, Scatter, ScatterLines, Stairs, Stem, BarPlot, BoxPlot, Waterfall, Violin, RainClouds}
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

function plot_attributes(::Type{P}, A::MayObs{<:DD.AbstractDimMatrix}) where P <: Union{Makie.Series}
    plot_attributes = (; 
        label=obs_f(DD.label, A),
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

function plot_attributes(::Type{P}, A::MayObs{<:DD.AbstractDimVector}) where P <: Union{Lines, Scatter, ScatterLines, Stairs, Stem, BarPlot, BoxPlot, Waterfall, RainClouds, Violin, LineSegments}
    plot_attributes = (; 
        label=obs_f(DD.label, A),
    )
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
        function Makie.$f1(fig, A::MayObs{AbstractDimMatrix}; 
            x=nothing, y=nothing, colorbar=(;), axis = (;), plot_attributes...
        )
        
            ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type($p1, to_value(A); x = x, y = y)
            axis_att = axis_attributes($p1, A; x = x, y = y)
            axis_att_for_function = filter_keywords(merge(filter_keywords_axis!(ax_type, axis_att), axis), [:type], !)
            ax = ax_type(fig[1,1]; axis_att_for_function...)
            p = $f1!(ax, A; plot_attributes..., x = x, y = y)
            add_labels_to_lscene(ax, axis_att)

            if colorbar != false && $(f1 in (:heatmap, :contourf, :surface, :spy))
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
        function Makie.$f1(fig, A::MayObs{AbstractDimArray{<:Any,3}}; 
            x=nothing, y=nothing, z =nothing, colorbar=(;), axis = (;), plot_attributes...
        )
        
            ax_type = haskey(axis, :type) ? axis[:type] : default_axis_type($p1, A; x = x, y = y, z = z)
            axis_att = axis_attributes($p1, A; x = x, y = y, z = z)
            axis_att_for_function = merge(filter_keywords_axis!(ax_type, axis_att), axis)
            
            ax = ax_type(fig[1,1]; axis_att_for_function...)
            p = $f1!(ax, A; plot_attributes..., x = x, y = y, z = z)

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
    filter_keywords(att, Makie.MakieCore.attribute_names(ax_type), identity)
end

function filter_keywords(collecti, to_filter, f)
    keys_filt = filter(i -> f(i in to_filter), keys(collecti))
    collecti[keys_filt]
end

function axis_attributes(::Type{P}, dd; x, y) where P <: Union{Heatmap, Image, Surface, Contour, Contourf, Contour3d, Spy}
    dims_axes = obs_f(i -> get_dimensions_of_makie_axis(i, (x, y)), dd)
    lookup_attributes = get_axis_ticks(to_value(dims_axes))

    merge(
        lookup_attributes,
        (;
        xlabel = obs_f(i -> DD.label(i[1]), dims_axes),
        ylabel = obs_f(i -> DD.label(i[2]), dims_axes),
        title = obs_f(DD.refdims_title, dd)),
    )
end

function axis_attributes(::Type{P}, dd; x, y, z) where P <: Union{Volume, VolumeSlices}
    dims_axes = obs_f(i -> get_dimensions_of_makie_axis(i, (x, y, z)), dd)

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
_plottype(::Type{AbstractDimVector}) = Makie.Scatter
_plottype(::Type{AbstractDimMatrix}) = Makie.Heatmap
_plottype(::Type{AbstractDimArray{<:Any,3}}) = Makie.Volume
_plottype(::Type{DimPoints}) = Makie.Scatter
for DD in (AbstractDimVector, AbstractDimMatrix, AbstractDimArray{<:Any,3}, DimPoints)
    p = _plottype(DD)
    f = Makie.plotkey(p)
    f! = Symbol(f, '!')
    eval(quote
        Makie.plot(dd::$DD; kwargs...) = Makie.$f(dd; kwargs...)
        Makie.plot(fig, dd::$DD; kwargs...) = Makie.$f(fig, dd; kwargs...)
        Makie.plot!(ax, dd::$DD; kwargs...) = Makie.$f!(ax, dd; kwargs...)
    end)
end

Makie.used_attributes(::Type{Series}, A::DD.AbstractDimMatrix) = (:labeldim,)
Makie.used_attributes(::Type{<:Union{Contour, Contourf, Contour3d, Image, Heatmap, Surface}}, A::DD.AbstractDimMatrix) = (:x, :y)
Makie.used_attributes(::ImageLike, A::DD.AbstractDimMatrix) = (:x, :y)
Makie.used_attributes(::Type{Spy}, A::DD.AbstractDimMatrix) = (:x, :y)
Makie.used_attributes(::Type{<:Union{VolumeSlices, Volume}}, A::DD.AbstractDimArray{<:Any, 3}) = (:x, :y, :z)

function Makie.convert_arguments(P::Type{T}, A::AbstractDimMatrix; x = nothing , y = nothing) where T<:Union{Contour, Contourf, Surface, Contour3d}
    dims_axes = get_dimensions_of_makie_axis(A, (x, y))
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

function Makie.convert_arguments(P::Makie.SampleBased, A::AbstractDimVector)
    xs = parent(lookup(A, 1)) |> get_number_version
    return Makie.convert_arguments(P, xs, parent(A))
end

function Makie.convert_arguments(P::Type{Makie.RainClouds}, A::AbstractDimVector)
    xs = parent(lookup(A, 1)) |> get_number_version
    return Makie.convert_arguments(P, xs, parent(A))
end

# Grid based conversions (surface, image, heatmap, contour, meshimage, etc)

# ImageLike is for e.g. image, meshimage, etc. It uses an interval based sampling method so requires regular spacing.
function Makie.convert_arguments(P::Type{T}, A::AbstractDimMatrix; x = nothing, y = nothing) where T<:Union{Image, Spy}
    dims_axes = get_dimensions_of_makie_axis(A, (x, y))
    xlookup, ylookup = lookup(dims_axes[1]), lookup(dims_axes[2])

    _check_regular_or_categorical_sampling(xlookup; axis = :x)
    _check_regular_or_categorical_sampling(ylookup; axis = :y)

    Makie.convert_arguments(P, _lookup_to_interval(xlookup), _lookup_to_interval(ylookup), parent(permutedims(A, (dims_axes[1], dims_axes[2])))) 
end

# CellGrid is for e.g. heatmap, contourf, etc. It uses vertices as corners of cells, so 
# there have to be n+1 vertices for n cells on an axis.
function Makie.convert_arguments(
    P::Type{Heatmap}, A::AbstractDimMatrix; x = nothing, y = nothing)
    dims_axes = get_dimensions_of_makie_axis(A, (x, y))
    xlookup, ylookup = (lookup(dims_axes[1]), lookup(dims_axes[2])) .|> parent .|> get_number_version

    return Makie.convert_arguments(P, xlookup, ylookup, parent(permutedims(A, (dims_axes[1], dims_axes[2]))))
end

# VolumeLike is for e.g. volume, volumeslices, etc. It uses a regular grid.
function Makie.convert_arguments(P::Type{T}, A::AbstractDimArray{<:Any,3}; x = nothing, y = nothing, z = nothing) where T<:Union{Volume}
    dims_axes = get_dimensions_of_makie_axis(A, (x, y, z))
    map((l, ax) ->_check_regular_or_categorical_sampling(l; axis = ax, conversiontrait = P), dims_axes, (:x, :y, :z))
    xs, ys, zs = map(_lookup_to_interval, dims_axes) .|> get_number_version
    return Makie.convert_arguments(P, xs, ys, zs, parent(permutedims(A, dims_axes)))
end

function Makie.convert_arguments(P::Type{Makie.VolumeSlices}, A::AbstractDimArray{<:Any,3}; x = nothing, y = nothing, z = nothing)
    dims_axes = get_dimensions_of_makie_axis(A, (x, y, z))
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

get_number_version(x::AbstractVector) = x # Need to be generic to accept Quantities from Unitful
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


# Give the data in A2 the names from A1 working backwards from what was replaced earlier
_restore_dim_names(A2, A1, replacements::Pair) = _restore_dim_names(A2, A1, (replacements,)) 
_restore_dim_names(A2, A1, replacements::Tuple{<:Pair,Vararg{T}}) where T<:Pair =
    _restore_dim_names(A2, A1, map(p -> basetypeof(name2dim(p[1]))(basetypeof(name2dim(p[2]))()), replacements))
function _restore_dim_names(A2, A1, replacements::Tuple=())
    all_replacements = _get_replacement_dims(A1, replacements)
    # Invert our replacement dimensions - `set` sets the outer wrapper
    # dimension to the inner/wrapped dimension
    inverted_replacements = map(all_replacements) do r
        basetypeof(val(r))(basetypeof(r)())
    end
    # Set the dimensions back to the originals now they are in the right order
    return set(A2, inverted_replacements...) 
end

# Replace the existing dimensions with X/Y/Z so we have a 1:1 
# relationship with the possible Makie.jl plot axes. 
function _get_replacement_dims(A::AbstractDimArray{<:Any,N}, replacements::Tuple) where N
    xyz_dims = (X(), Y(), Z())[1:N]
    map(replacements) do d
        # Make sure replacements contain X/Y/Z only
        hasdim(A, d) || throw(ArgumentError("object does not have a dimension $(basetypeof(d))"))
    end
    # Find and sort remaining dims
    replacements
    source_dims_remaining = dims(otherdims(A, replacements), DD.PLOT_DIMENSION_ORDER)
    xyz_remaining = otherdims(xyz_dims, map(val, replacements))[1:length(source_dims_remaining)]
    other_replacements = map(rebuild, source_dims_remaining, xyz_remaining)
    return (replacements..., other_replacements...)
end

# Get all lookups in ascending/forward order
_reorder(A) = reorder(A, DD.ForwardOrdered)

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

function _keywords2dimpairs(x, y, z)
    reduce((x => X, y => Y, z => Z); init=()) do acc, (source, dest)
        isnothing(source) ? acc : (acc..., source => dest)
    end
end
function _keywords2dimpairs(x, y)
    reduce((x => X, y => Y); init=()) do acc, (source, dest)
        isnothing(source) ? acc : (acc..., source => dest)
    end
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
        l
    end
    return IntervalSets.Interval(bounds(l1)...)
end

_floatornan(A::AbstractArray{<:Union{Missing,<:Real}}) = _floatornan64.(A)
_floatornan(A::AbstractArray{<:Union{Missing,Float64}}) = _floatornan64.(A)
_floatornan(A::AbstractArray{<:Char}) = float(A)
_floatornan(A) = A
_floatornan32(x) = ismissing(x) ? NaN32 : Float32(x)
_floatornan64(x) = ismissing(x) ? NaN64 : Float64(x)

end
