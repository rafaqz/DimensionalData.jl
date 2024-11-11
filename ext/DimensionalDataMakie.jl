module DimensionalDataMakie

using DimensionalData
using Makie
using IntervalSets
using DimensionalData.Dimensions, DimensionalData.LookupArrays

const DD = DimensionalData

_paired(args...) = map(x -> x isa Pair ? x : x => x, args)

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


# 1d PointBased

# 1d plots are scatter by default
for (f1, f2) in _paired(:plot => :scatter, :scatter, :lines, :scatterlines, :stairs, :stem, :barplot, :waterfall)
    f1!, f2! = Symbol(f1, '!'), Symbol(f2, '!')
    docstring = """
        $f1(A::AbstractDimVector; attributes...)
        
    Plot a 1-dimensional `AbstractDimArray` with `Makie.$f2`.

    The X axis will be labelled with the dimension name and and use ticks from its lookup.

    $(_keyword_heading_doc(f1))
    $AXISLEGENDKW_DOC     
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(A::AbstractDimVector; axislegendkw=(;), axis = (;), figure = (;), attributes...)
            args, merged_attributes = _pointbased1(A, attributes)
            axis_kw, figure_kw = _handle_axis_figure_attrs(merged_attributes, axis, figure)
            p = Makie.$f2(args...; axis = axis_kw, figure = figure_kw, merged_attributes...)
            axislegend(p.axis; merge=false, unique=false, axislegendkw...)
            return p
        end
        function Makie.$f1!(ax, A::AbstractDimVector; axislegendkw=(;), attributes...)
            args, merged_attributes = _pointbased1(A, attributes; set_axis_attributes=false)
            return Makie.$f2!(ax, args...; merged_attributes...)
        end
    end
end

function _pointbased1(A, attributes; set_axis_attributes=true)
    # Array/Dimension manipulation
    A1 = _prepare_for_makie(A)
    lookup_attributes, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, newdims[1] => newdims[1]), A)
    args = Makie.convert_arguments(Makie.PointBased(), A2)
    # Plot attribute generation
    user_attributes = Makie.Attributes(; attributes...)
    axis_attributes = if set_axis_attributes 
        Attributes(; 
            axis=(; 
                xlabel=string(label(dims(A, 1))), 
                ylabel=DD.label(A),
                title=DD.refdims_title(A),
            ),
        )
    else
        Attributes()
    end
    plot_attributes = Attributes(; 
        label=DD.label(A),
    )
    merged_attributes = merge(user_attributes, axis_attributes, plot_attributes, lookup_attributes)
    if !set_axis_attributes
        delete!(merged_attributes, :axis)
    end
    return args, merged_attributes
end


# 2d SurfaceLike

for (f1, f2) in _paired(:plot => :heatmap, :heatmap, :image, :contour, :contourf, :spy, :surface)
    f1!, f2! = Symbol(f1, '!'), Symbol(f2, '!')
    docstring = """
        $f1(A::AbstractDimMatrix; attributes...)
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f2`.

    $(_keyword_heading_doc(f1))
    $(_xy(f1))
    $(_maybe_colorbar_doc(f1))
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(A::AbstractDimMatrix{T}; 
            x=nothing, y=nothing, colorbarkw=(;), axis = (;), figure = (;), attributes...
        ) where T
            replacements = _keywords2dimpairs(x, y)
            A1, A2, args, merged_attributes = _surface2(A, $f2, attributes, replacements)

            axis_kw, figure_kw = _handle_axis_figure_attrs(merged_attributes, axis, figure)

            axis_type = if haskey(axis_kw, :type)
                to_value(axis_kw[:type])
            else
                Makie.args_preferred_axis(Makie.Plot{$f2}, args...)
            end

            p = if axis_type isa Type && axis_type <: Union{LScene, Makie.PolarAxis}
                # LScene can only take a limited set of attributes
                # so we extract those that can be passed.
                # TODO: do the same for polaraxis,
                # or filter out shared attributes from axis_kw somehow.
                lscene_attrs = Dict{Symbol, Any}()
                lscene_attrs[:type] = axis_type
                haskey(axis_kw, :scenekw) && (lscene_attrs[:scenekw] = axis_kw[:scenekw])
                haskey(axis_kw, :show_axis) && (lscene_attrs[:show_axis] = axis_kw[:show_axis])
                # surface is an LScene so we cant pass some axis attributes
                p = Makie.$f2(args...; figure = figure_kw, axis = lscene_attrs, merged_attributes...)
                # And instead set axisnames manually
                if p.axis isa LScene && !isnothing(p.axis.scene[OldAxis])
                    p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
                end
                p
            else # axis_type isa Nothing, axis_type isa Makie.Axis or GeoAxis or similar
                Makie.$f2(args...; axis = axis_kw, figure = figure_kw, merged_attributes...)
            end
            # Add a Colorbar for heatmaps and contourf
            # TODO: why not surface too?
            if T isa Real && $(f1 in (:plot, :heatmap, :contourf)) 
                Colorbar(p.figure[1, 2], p.plot;
                    label=DD.label(A), colorbarkw...
                )
            end
            p
            return p
        end
        function Makie.$f1!(ax, A::AbstractDimMatrix; 
            x=nothing, y=nothing, colorbarkw=(;), attributes...
        )
            replacements = _keywords2dimpairs(x, y)
            _, _, args, _ = _surface2(A, $f2, attributes, replacements)
            # No Colorbar in the ! in-place versions
            return Makie.$f2!(ax, args...; attributes...)
        end
        function Makie.$f1!(axis, A::Observable{<:AbstractDimMatrix};
            x=nothing, y=nothing, colorbarkw=(;), attributes...
        )
            replacements = _keywords2dimpairs(x,y)
            args =  lift(x->_surface2(x, $f2, attributes, replacements)[3], A)
            p = Makie.$f2!(axis, lift(x->x[1], args),lift(x->x[2], args),lift(x->x[3], args); attributes...)
            return p
        end
    end
end

function _surface2(A, plotfunc, attributes, replacements)
    # Array/Dimension manipulation
    A1 = _prepare_for_makie(A, replacements)
    lookup_attributes, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, map(Pair, newdims, newdims)...), A, replacements)
    P = Plot{plotfunc}
    PTrait = Makie.conversion_trait(P, A2)
    # We define conversions by trait for all of the explicitly overridden functions,
    # so we can just use the trait here.
    args = Makie.convert_arguments(PTrait, A2)

    # if status === true
    #     args = converted
    # else
    #     args = Makie.convert_arguments(P, converted...)
    # end



    # Plot attribute generation
    dx, dy = DD.dims(A2)
    user_attributes = Makie.Attributes(; attributes...)
    plot_attributes = Makie.Attributes(; 
        axis=(; 
            xlabel=DD.label(dx),
            ylabel=DD.label(dy),
            title=DD.refdims_title(A),
        ),
    )
    merged_attributes = merge(user_attributes, plot_attributes, lookup_attributes)

    return A1, A2, args, merged_attributes
end

# 3d VolumeLike

for (f1, f2) in _paired(:plot => :volume, :volume, :volumeslices)
    f1!, f2! = Symbol(f1, '!'), Symbol(f2, '!')
    docstring = """
        $f1(A::AbstractDimArray{<:Any,3}; attributes...)
        
    Plot a 3-dimensional `AbstractDimArray` with `Makie.$f2`.

    $(_keyword_heading_doc(f1))
    $(_xy(f1))
    $(_z(f1))
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(A::AbstractDimArray{<:Any,3}; x=nothing, y=nothing, z=nothing, axis = (;), figure = (;), attributes...)
            replacements = _keywords2dimpairs(x, y, z)
            A1, A2, args, merged_attributes = _volume3(A, $f2, attributes, replacements)
            axis_kw, figure_kw = _handle_axis_figure_attrs(merged_attributes, axis, figure)
            p = Makie.$f2(args...; axis = axis_kw, figure = figure_kw, merged_attributes...)
            if p.axis isa LScene
                p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
            end
            return p
        end
        function Makie.$f1!(ax, A::AbstractDimArray{<:Any,3}; x=nothing, y=nothing, z=nothing, attributes...)
            replacements = _keywords2dimpairs(x, y, z)
            _, _, args, _ = _volume3(A, $f2, attributes, replacements)
            return Makie.$f2!(ax, args...; attributes...)
        end
    end
end

function _volume3(A, plotfunc, attributes, replacements)
    # Array/Dimension manipulation
    A1 = _prepare_for_makie(A, replacements)
    _, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, map(Pair, newdims, newdims)...), A, replacements)
    args = Makie.convert_arguments(Plot{plotfunc}, A2)

    # Plot attribute generation
    user_attributes = Makie.Attributes(; attributes...)
    plot_attributes = Makie.Attributes(; 
        # axis=(; cant actually set much here for LScene)
    )
    merged_attributes = merge(user_attributes, plot_attributes)

    return A1, A2, args, merged_attributes
end

# series

"""
    series(A::AbstractDimMatrix; attributes...)
    
Plot a 2-dimensional `AbstractDimArray` with `Makie.series`.

$(_labeldim_detection_doc(series))
"""
function Makie.series(A::AbstractDimMatrix; 
    color=:lighttest, axislegendkw=(;), axis = (;), figure = (;), labeldim=nothing, attributes...,
)
    args, merged_attributes = _series(A, attributes, labeldim)

    axis_kw, figure_kw = _handle_axis_figure_attrs(merged_attributes, axis, figure)

    n = size(last(args), 1)
    p = if n > 7
            color = resample_cmap(color, n) 
            Makie.series(args...; axis = axis_kw, figure = figure_kw, color, merged_attributes...)
        else
            Makie.series(args...; axis = axis_kw, figure = figure_kw, color, merged_attributes...)
        end
    axislegend(p.axis; merge=true, unique=false, axislegendkw...)
    return p
end
function Makie.series!(axis, A::AbstractDimMatrix; axislegendkw=(;), labeldim=nothing, attributes...)
    args, _ = _series(A, attributes, labeldim)
    return Makie.series!(axis, args...; attributes...)
end

function _series(A, attributes, labeldim)
    # Array/Dimension manipulation
    categoricaldim = _categorical_or_dependent(A, labeldim)
    isnothing(categoricaldim) && throw(ArgumentError("No dimensions have Categorical lookups"))
    categoricallookup = parent(categoricaldim)
    otherdim = only(otherdims(A, categoricaldim))
    lookup_attributes, otherdim1 = _split_attributes(X(lookup(otherdim)))
    args = vec(lookup(otherdim1)), parent(permutedims(A, (categoricaldim, otherdim)))

    # Plot attribute generation
    user_attributes = Makie.Attributes(; attributes...)
    plot_attributes = Makie.Attributes(; 
        labels=string.(parent(categoricallookup)),
        axis=(; 
            xlabel=DD.label(otherdim),
            ylabel=DD.label(A),
            title=DD.refdims_title(A),
        ),
    )
    merged_attributes = merge(user_attributes, lookup_attributes, plot_attributes)

    return args, merged_attributes
end


# boxplot and friends

for f in (:violin, :boxplot, :rainclouds)
    f! = Symbol(f, '!')
    docstring = """
        $f(A::AbstractDimMatrix; attributes...)
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f`.

    $(_labeldim_detection_doc(f))
    """
    @eval begin
        @doc $docstring
        function Makie.$f(A::AbstractDimMatrix; labeldim=nothing, axis = (;), figure = (;), attributes...)
            args, merged_attributes = _boxplotlike(A, attributes, labeldim)
            axis_kw, figure_kw = _handle_axis_figure_attrs(merged_attributes, axis, figure)
            return Makie.$f(args...; axis = axis_kw, figure = figure_kw, merged_attributes...)
        end
        function Makie.$f!(ax, A::AbstractDimMatrix; labeldim=nothing, attributes...)
            args, _ = _boxplotlike(A, attributes, labeldim)
            return Makie.$f!(ax, args...; attributes...)
        end
    end
end

function _boxplotlike(A, attributes, labeldim)
    # Array/Dimension manipulation
    categoricaldim = _categorical_or_dependent(A, labeldim)
    categoricallookup = lookup(categoricaldim)
    otherdim = only(otherdims(A, categoricaldim))
    # Create a new array with an `Int` category to match each value in `A`
    indices = DimArray(eachindex(categoricaldim), categoricaldim)
    category_ints = broadcast_dims((_, c) -> c, A, indices)
    args = vec(category_ints), vec(A)

    # Array/Dimension manipulation
    user_attributes = Makie.Attributes(; attributes...)
    plot_attributes = Makie.Attributes(; 
        axis=(; 
            xlabel=DD.label(categoricaldim),
            xticks=axes(categoricaldim, 1),
            xtickformat=I -> map(string, categoricallookup[map(Int, I)]),
            ylabel=DD.label(A),
            title=DD.refdims_title(A),
        ),
    )
    merged_attributes = merge(user_attributes, plot_attributes)

    return args, merged_attributes
end

# Plot type definitions. Not sure they will ever get called?
Makie.plottype(::AbstractDimVector) = Makie.Scatter
Makie.plottype(::AbstractDimMatrix) = Makie.Heatmap
Makie.plottype(::AbstractDimArray{<:Any,3}) = Makie.Volume
Makie.plottype(::DimPoints) = Makie.Scatter

# TODO this needs to be added to Makie
# Makie.to_endpoints(x::Tuple{Makie.Unitful.AbstractQuantity,Makie.Unitful.AbstractQuantity}) = (ustrip(x[1]), ustrip(x[2]))
# Makie.expand_dimensions(::Makie.PointBased, y::IntervalSets.AbstractInterval) = (keys(y), y)

# Conversions
# Generic conversion for arbitrary recipes that don't define a conversion trait
function Makie.convert_arguments(t::Type{<:Makie.AbstractPlot}, A::AbstractDimMatrix)
    A1 = _prepare_for_makie(A)
    tr = Makie.conversion_trait(t, A)
    if tr isa ImageLike
        xs, ys = map(_lookup_to_interval, lookup(A1))
    else
        xs, ys = map(_lookup_to_vector, lookup(A1))
    end
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end
# PointBased conversions (scatter, lines, poly, etc)
function Makie.convert_arguments(t::Makie.PointBased, A::AbstractDimVector)
    A1 = _prepare_for_makie(A)
    xs = parent(lookup(A, 1))
    return Makie.convert_arguments(t, xs, _floatornan(parent(A)))
end
function Makie.convert_arguments(t::Makie.PointBased, A::AbstractDimMatrix)
    return Makie.convert_arguments(t, parent(A))
end
# Grid based conversions (surface, image, heatmap, contour, meshimage, etc)

# VertexGrid is for e.g. contour and surface, it uses a position per vertex.
function Makie.convert_arguments(t::Makie.VertexGrid, A::AbstractDimMatrix)
    A1 = _prepare_for_makie(A)
    # If the lookup is intervals, use the midpoint of each interval
    # as the sampling point.
    # If the lookup is points, just use the points.
    xs, ys = map(_lookup_to_vertex_vector, lookup(A1))
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end
# ImageLike is for e.g. image, meshimage, etc. It uses an interval based sampling method so requires regular spacing.
function Makie.convert_arguments(t::Makie.ImageLike, A::AbstractDimMatrix)
    A1 = _prepare_for_makie(A)
    xlookup, ylookup, = lookup(A1) # take the first two dimensions only
    # We need to make sure the lookups are regular intervals.
    _check_regular_or_categorical_sampling(xlookup; axis = :x)
    _check_regular_or_categorical_sampling(ylookup; axis = :y)
    # Convert the lookups to intervals (<: Makie.EndPoints).
    xs, ys = map(_lookup_to_interval, (xlookup, ylookup))
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end

# CellGrid is for e.g. heatmap, contourf, etc. It uses vertices as corners of cells, so 
# there have to be n+1 vertices for n cells on an axis.
function Makie.convert_arguments(
    t::Makie.CellGrid, A::AbstractDimMatrix
)
    A1 = _prepare_for_makie(A)
    xs, ys = map(_lookup_to_vector, lookup(A1))
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end

function Makie.convert_arguments(t::Type{<:Makie.Spy}, A::AbstractDimMatrix{<:Real})
    A1 = _prepare_for_makie(A)
    xs, ys = map(_lookup_to_interval, lookup(A1))
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end

# VolumeLike is for e.g. volume, volumeslices, etc. It uses a regular grid.
function Makie.convert_arguments(t::Makie.VolumeLike, A::AbstractDimArray{<:Any,3})
    A1 = _prepare_for_makie(A)
    xl, yl, zl = lookup(A1)
    _check_regular_or_categorical_sampling(xl; axis = :x, conversiontrait = t)
    _check_regular_or_categorical_sampling(yl; axis = :y, conversiontrait = t)
    _check_regular_or_categorical_sampling(zl; axis = :z, conversiontrait = t)
    xs, ys, zs = map(_lookup_to_interval, (xl, yl, zl))
    return xs, ys, zs, last(Makie.convert_arguments(t, parent(A1)))
end

function Makie.convert_arguments(t::Type{Plot{Makie.volumeslices}}, A::AbstractDimArray{<:Any,3})
    A1 = _prepare_for_makie(A)
    xs, ys, zs = map(_lookup_to_vector, lookup(A1))
    # the following will not work for irregular spacings
    return xs, ys, zs, last(Makie.convert_arguments(t, parent(A1)))
end

# the generic fallback for all plot types
function Makie.convert_arguments(t::Makie.NoConversion, A::AbstractDimArray{<:Any,N}) where {N}
    A1 = _prepare_for_makie(A)
    return Makie.convert_arguments(t, parent(A1))
end
# # fallbacks with descriptive error messages
function Makie.convert_arguments(t::Makie.ConversionTrait, A::AbstractDimArray{<:Any,N}) where {N}
    @warn "Conversion trait $t not implemented for `AbstractDimArray` with $N dims, falling back to parent array type"
    return Makie.convert_arguments(t, parent(A))
end

function Makie.convert_arguments(t::Makie.PointBased, A::DimPoints)
    return Makie.convert_arguments(t, vec(A))
end
# This doesn't work, but it will at least give the normal Makie error
function Makie.convert_arguments(t::Makie.PointBased, A::DimPoints{<:Any,1})
    return Makie.convert_arguments(t, collect(A))
end

@static if :expand_dimensions in names(Makie; all=true)
    # We also implement expand_dimensions for recognized plot traits.
    # These can just forward to the relevant converts.
    Makie.expand_dimensions(t::Makie.NoConversion, A::AbstractDimArray) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Makie.PointBased, A::AbstractDimVector) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Makie.PointBased, A::AbstractDimMatrix) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Makie.VertexGrid, A::AbstractDimMatrix) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Makie.ImageLike, A::AbstractDimMatrix) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Makie.CellGrid, A::AbstractDimMatrix) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Makie.VolumeLike, A::AbstractDimArray{<:Any,3}) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Type{Plot{Makie.volumeslices}}, A::AbstractDimArray{<:Any,3}) = Makie.convert_arguments(t, A)
    Makie.expand_dimensions(t::Type{Makie.Spy}, A::AbstractDimArray{<:Real,2}) = Makie.convert_arguments(t, A)
end

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

# Simplify dimension lookups and move information to axis attributes
_split_attributes(A) = _split_attributes(dims(A))
function _split_attributes(dims::DD.DimTuple)
    reduce(dims; init=(Attributes(), ())) do (attr, ds), d  
        l = lookup(d)
        if l isa AbstractCategorical
            ticks = axes(l, 1)
            int_dim = rebuild(d, NoLookup(ticks))
            dim_attr = if d isa X
                Attributes(; axis=(xticks=ticks, xtickformat=I -> map(string, parent(l)[map(Int, I)])))
            elseif d isa Y
                Attributes(; axis=(yticks=ticks, ytickformat=I -> map(string, parent(l)[map(Int, I)])))
            else
                Attributes(; axis=(zticks=ticks, ztickformat=I -> map(string, parent(l)[map(Int, I)])))
            end
            merge(attr, dim_attr), (ds..., int_dim)
        else
            attr, (ds..., d)
        end
    end
end
function _split_attributes(dim::Dimension)
    attributes, dims = _split_attributes((dim,))
    return attributes, dims[1]
end

function _handle_axis_figure_attrs(merged_attributes, axis, figure)
    akw = haskey(merged_attributes, :axis) ? pop!(merged_attributes, :axis)[] : Attributes()
    fkw = haskey(merged_attributes, :figure) ? pop!(merged_attributes, :figure)[] : Attributes()
    axis_kw = merge(akw, Attributes(axis)).attributes |> Dict{Symbol, Any} # to get a dict
    if haskey(axis_kw, :type)
        axis_kw[:type] = axis_kw[:type][]
    end
    figure_kw = merge(fkw, Attributes(figure)).attributes |> Dict{Symbol, Any} # to get a dict
    return axis_kw, figure_kw
end

function _prepare_for_makie(A, replacements=())
    _permute_xyz(maybeshiftlocus(Center(), A; dims=(XDim, YDim)), replacements) |> _reorder
end

# Permute the data after replacing the dimensions with X/Y/Z
_permute_xyz(A::AbstractDimArray, replacements::Pair) = _permute_xyz(A, (replacements,))
_permute_xyz(A::AbstractDimArray, replacements::Tuple{<:Pair,Vararg{T}}) where T<:Pair =
    _permute_xyz(A, map(p -> basetypeof(name2dim(p[1]))(basetypeof(name2dim(p[2]))()), replacements))
function _permute_xyz(A::AbstractDimArray{<:Any,N}, replacements::Tuple) where N
    xyz_dims = (X(), Y(), Z())[1:N]
    all_replacements = _get_replacement_dims(A, replacements)
    A_replaced_dims = set(A, all_replacements...)
    # Permute to X/Y/Z order
    permutedims(A_replaced_dims, xyz_dims)
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
    source_dims_remaining = dims(otherdims(A, replacements), DD.PLOT_DIMENSION_ORDER)
    xyz_remaining = otherdims(xyz_dims, map(val, replacements))[1:length(source_dims_remaining)]
    other_replacements = map(rebuild, source_dims_remaining, xyz_remaining)
    return (replacements..., other_replacements...)
end

# Get all lookups in ascending/forward order
_reorder(A) = reorder(A, DD.ForwardOrdered)

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
_floatornan(A) = A
_floatornan32(x) = ismissing(x) ? NaN32 : Float32(x)
_floatornan64(x) = ismissing(x) ? NaN64 : Float64(x)

end
