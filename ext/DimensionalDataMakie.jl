module DimensionalDataMakie

using DimensionalData, Makie
using DimensionalData.Dimensions, DimensionalData.LookupArrays

const DD = DimensionalData

# Handle changes between Makie 0.19 and 0.20
const SurfaceLikeCompat = isdefined(Makie, :SurfaceLike) ? Makie.SurfaceLike : Union{Makie.VertexGrid,Makie.CellGrid,Makie.ImageLike}

_paired(args...) = map(x -> x isa Pair ? x : x => x, args)

struct DimLines{T,N,D<:DD.DimTuple,O} <: DD.AbstractDimIndices{T,N}
    dims::D
    order::O
end
function DimLines(dims::DD.DimTuple; order=dims)
    @assert count(isintervals(dims)) == 1
    order = map(d -> basetypeof(d)(), order)
    T = typeof(_getline(dims, map(firstindex, dims)))
    N = length(dims)
    dims = N > 0 ? DD._format(dims) : dims
    DimLines{T,N,typeof(dims),typeof(order)}(dims, order)
end

Base.getindex(dp::DimLines, i1::Int, i2::Int, Is::Int...) = _getline(dims(dp), (i1, i2, Is...))
Base.getindex(di::DimLines{<:Any,1}, i::Int) = (dims(di, 1)[i],)
Base.getindex(di::DimLines, i::Int) = di[Tuple(CartesianIndices(di)[i])...]

function _getline(ds, I::Tuple)
    D = map(rebuild, ds, I)
    # Get dim-wrapped point values at i1, I...
    intervaldim = only(dims(ds, isintervals))
    ods = otherdims(ds, intervaldim)
    bounds = intervalbounds(lookup(intervaldim), val(dims(D, intervaldim))...)
    return map(bounds) do b
        (b, map(getindex, dims(ds, ods), map(val, dims(D, ods)))...)
    end
end

struct DimPolygons{T,N,D<:DD.DimTuple,O} <: DD.AbstractDimIndices{T,N}
    dims::D
    order::O
end
function DimPolygons(dims::DD.DimTuple; order=dims)
    @assert count(isintervals(dims)) == 2 "num intervaldims $(count(isintervals(dims))) is not 2"
    order = map(d -> basetypeof(d)(), order)
    T = typeof(_getpolygon(dims, map(firstindex, dims)))
    N = length(dims)
    dims = N > 0 ? DD._format(dims) : dims
    DimPolygons{T,N,typeof(dims),typeof(order)}(dims, order)
end

Base.getindex(dp::DimPolygons, i1::Int, i2::Int, Is::Int...) = _getpolygon(dims(dp), (i1, i2, Is...))
Base.getindex(di::DimPolygons{<:Any,1}, i::Int) = (dims(di, 1)[i],)
Base.getindex(di::DimPolygons, i::Int) = di[Tuple(CartesianIndices(di)[i])...]

function _getpolygon(ds::DD.DimTuple, I::Tuple)
    D = map(rebuild, ds, I)
    # Get dim-wrapped point values at i1, I...
    intervaldims = dims(ds, isintervals)
    ods = otherdims(ds, intervaldims)
    bvs = map(intervaldims) do id 
        rebuild(id, intervalbounds(lookup(id), val(dims(D, id))...))
    end
    ovs =  map(rebuild, ods, map(getindex, ods, val(dims(D, ods))))
    points = [
        _polypoint(ds, bvs, ovs, 1, 1),
        _polypoint(ds, bvs, ovs, 1, 2), 
        _polypoint(ds, bvs, ovs, 2, 2),
        _polypoint(ds, bvs, ovs, 2, 1),
        _polypoint(ds, bvs, ovs, 1, 1),
    ]
    return Makie.Polygon(Makie.LineString(points))
end
function _polypoint(order, (bs1, bs2), ovs, i, j)
    vs = (rebuild(bs1, val(bs1)[i]), rebuild(bs2, val(bs2)[j]), ovs...)
    Point(map(val, dims(vs, order)))
end


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
for f in (:scatter, :lines, :scatterlines, :stairs, :stem, :barplot, :waterfall)
    f! = Symbol(f, '!')
    docstring = """
        $f(A::AbstractDimVector; attributes...)
        
    Plot a 1-dimensional `AbstractDimArray` with `Makie`.

    The X axis will be labelled with the dimension name and and use ticks from its lookup.

    $(_keyword_heading_doc(f))
    $AXISLEGENDKW_DOC     
    """
    @eval begin
        @doc $docstring
        function Makie.$f(A::AbstractDimVector; axislegendkw=(;), attributes...)
            args, merged_attributes = _pointbased1(A; attributes...)
            p = Makie.$f(args...; merged_attributes...)
            axislegend(p.axis; merge=false, unique=false, axislegendkw...)
            return p
        end
        function Makie.$f!(axis, A::AbstractDimVector; axislegendkw=(;), attributes...)
            args, merged_attributes = _pointbased1(A; attributes..., _set_axis_attributes=false)
            return Makie.$f!(axis, args...; merged_attributes...)
        end
    end
end


function Makie.linesegments(A::AbstractDimVector; axislegendkw=(;), attributes...)
    args, merged_attributes = _pointbased1(A; attributes...)
    lines = _interval_lines(A)
    p = Makie.linesegments(lines; merged_attributes...)
    axislegend(p.axis; merge=false, unique=false, axislegendkw...)
    return p
end

function Makie.linesegments!(x, A::AbstractDimVector; attributes...)
    args, merged_attributes = _pointbased1(A; attributes...)
    lines = _interval_lines(A)
    return Makie.linesegments(x, lines; merged_attributes...)
end

function _interval_lines(A::AbstractDimVector) 
    map(intervalbounds(only(dims(A))), A) do bounds, val
        T = promote_type(typeof(first(bounds)), typeof(last(bounds)), typeof(val))
        (T(bounds[1]), T(val)), (T(bounds[2]), T(val))
    end
end

function Makie.plot(A::AbstractDimVector; kw...)
    only(isintervals(A)) ? Makie.linesegments(A; kw...) : Makie.scatter(A; kw...)
end
function Makie.plot!(ax, A::AbstractDimVector; kw...)
    only(isintervals(A)) ? Makie.linesegments!(ax, A; kw...) : Makie.scatter(axis, A; kw...)
end

function _pointbased1(A; _set_axis_attributes=true, attributes...)
    # Array/Dimension manipulation
    A1 = _prepare_for_makie(A)
    lookup_attributes, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, newdims[1] => newdims[1]), A)
    args = Makie.convert_arguments(Makie.PointBased(), A2)
    # Plot attribute generation
    user_attributes = Makie.Attributes(; attributes...)
    axis_attributes = if _set_axis_attributes 
        Attributes(; 
            axis=(; 
                xlabel=string(name(dims(A, 1))), 
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
    if !_set_axis_attributes
        delete!(merged_attributes, :axis)
    end
    return args, merged_attributes
end


# 2d SurfaceLike

for f in (:heatmap, :image, :contour, :contourf, :spy, :surface)
    f! = Symbol(f, '!')
    docstring = """
        $f(A::AbstractDimMatrix; attributes...)
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f`.

    $(_keyword_heading_doc(f))
    $(_xy(f))
    $(_maybe_colorbar_doc(f))
    """
    @eval begin
        @doc $docstring
        function Makie.$f(A::AbstractDimMatrix{T}; colorbarkw=(;), attributes...) where T
            A1, A2, args, merged_attributes = _surface2(A; attributes...)
            p = if $(f == :surface)
                # surface is an LScene so we cant pass attributes
                p = Makie.$f(args...; attributes...)
                # And instead set axisnames manually
                p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
                p
            else
                Makie.$f(args...; merged_attributes...)
            end
            # Add a Colorbar for heatmaps and contourf
            if T isa Real && $(f in (:plot, :heatmap, :contourf)) 
                Colorbar(p.figure[1, 2], p.plot;
                    label=DD.label(A), colorbarkw...
                )
            end
            return p
        end
        function Makie.$f!(axis, A::AbstractDimMatrix; colorbarkw=(;), attributes...)
            _, _, args, _ = _surface2(A, attributes)
            # No ColourBar in the ! in-place versions
            return Makie.$f!(axis, args...; attributes...)
        end
    end
end

function Makie.plot(A::AbstractDimMatrix; kw...)
    if all(isintervals(dims(A)))
        Makie.heatmap(A; kw...)
    elseif any(isintervals(A))
        Makie.linesegments(A; kw...)
    else
        Makie.scatter(A; kw...)
    end
end
function Makie.plot!(ax, A::AbstractDimMatrix; kw...)
    if all(isintervals(A))
        Makie.heatmap!(ax, A; kw...)
    elseif any(isintervals(A))
        Makie.linesegments!(ax, A; kw...)
    else
        Makie.scatter!(ax, A; kw...)
    end
end

function Makie.linesegments(A::AbstractDimMatrix; attributes...)
    A1, A2, args, merged_attributes = _surface2(A; attributes...)
    lines = vec(collect(DimLines(A)))
    p = Makie.linesegments(lines; color=vec(A), merged_attributes...)
    return p
end

function Makie.linesegments!(x, A::AbstractDimMatrix; attributes...)
    A1, A2, args, merged_attributes = _surface2(A; attributes...)
    lines = collect(vec(DimLines(A)))
    return Makie.linesegments(x, lines; colors=vec(A), merged_attributes...)
end

function _surface2(A; x=nothing, y=nothing, attributes...)
    replacements = _keywords2dimpairs(x, y)
    # Array/Dimension manipulation
    A1 = _prepare_for_makie(A; replacements)
    lookup_attributes, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, map(Pair, newdims, newdims)...), A, replacements)
    args = Makie.convert_arguments(Makie.ContinuousSurface(), A2)

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

for f in (:volume, :volumeslices)
    f! = Symbol(f, '!')
    docstring = """
        $f(A::AbstractDimArray{<:Any,3}; attributes...)
        
    Plot a 3-dimensional `AbstractDimArray` with `Makie.$f`.

    $(_keyword_heading_doc(f))
    $(_xy(f))
    $(_z(f))
    """
    @eval begin
        @doc $docstring
        function Makie.$f(A::AbstractDimArray{<:Any,3}; attributes...)
            A1, A2, args, merged_attributes = _volume3(A; attributes...)
            p = Makie.$f(args...; merged_attributes...)
            p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
            return p
        end
        function Makie.$f!(axis, A::AbstractDimArray{<:Any,3}; attributes...)
            _, _, args, _ = _volume3(A; attributes...)
            return Makie.$f!(axis, args...; attributes...)
        end
    end
end

function Makie.plot(A::AbstractDimArray{<:Any,3}; kw...)
    if all(isintervals(dims(A)))
        Makie.volume(A; interpolate=false, kw...)
    elseif count(isintervals(A)) == 2
        Makie.poly(A; kw...)
    elseif count(isintervals(A)) == 1
        Makie.linesegments(A; kw...)
    else
        Makie.scatter(A; kw...)
    end
end
function Makie.plot!(ax, A::AbstractDimArray{<:Any,3}; kw...)
    if all(isintervals(A))
        Makie.volume!(ax, A; interpolate=false, kw...)
    elseif count(isintervals(A)) == 2
        Makie.poly!(ax, A; kw...)
    elseif count(isintervals(A)) == 1
        Makie.linesegments!(ax, A; kw...)
    else
        Makie.scatter!(ax, A; kw...)
    end
end

function Makie.poly(A::AbstractDimArray{<:Any,3}; attributes...)
    A1, A2, args, merged_attributes = _volume3(A; attributes...)
    dps = DimPolygons(A)
    polys = vec(collect(dps))
    # TODO this doesn't plot properly?
    # All polygons plat on the same plane
    p = Makie.poly(polys; color=vec(A2), merged_attributes...)
    p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
    return p
end

function Makie.poly!(ax, A::AbstractDimArray{<:Any,3}; attributes...)
    A1, A2, args, merged_attributes = _volume3(A; attributes...)
    polys = vec(collect(DimPolygons(A2)))
    return Makie.poly(ax, polys; color=vec(A), merged_attributes...)
end

function Makie.linesegments(A::AbstractDimArray{<:Any,3}; attributes...)
    A1, A2, args, merged_attributes = _volume3(A; attributes...)
    lines = vec(collect(DimLines(A)))
    p = Makie.linesegments(lines; color=vec(A), merged_attributes...)
    p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
    return p
end

function Makie.linesegments!(ax, A::AbstractDimArray{<:Any,3}; attributes...)
    A1, A2, args, merged_attributes = _surface2(A; attributes...)
    lines = collect(vec(DimLines(A)))
    p = Makie.linesegments!(ax, lines; colors=vec(A), merged_attributes...)
    p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
    return p
end

function Makie.scatter(A::AbstractDimArray{<:Any,3}; attributes...)
    A1, A2, args, merged_attributes = _volume3(A; attributes...)
    points = vec(collect(DimPoints(A2)))
    p = Makie.scatter(points; color=vec(A), merged_attributes...)
    p.axis.scene[OldAxis][:names, :axisnames] = map(DD.label, DD.dims(A2))
    return p
end


function _volume3(A; x=nothing, y=nothing, z=nothing, attributes...)
    replacements = _keywords2dimpairs(x, y, z)
    # Array/Dimension manipulation
    A1 = _prepare_for_makie(A; replacements)
    _, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, map(Pair, newdims, newdims)...), A, replacements)
    args = Makie.convert_arguments(Makie.VolumeLike(), A2)

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
    series(A::AbstractDimArray{<:Any,2}; attributes...)
    
Plot a 2-dimensional `AbstractDimArray` with `Makie.series`.

$(_labeldim_detection_doc(series))
"""
function Makie.series(A::AbstractDimArray{<:Any,2}; 
    colormap=:Set1_5, color=nothing, axislegendkw=(;), labeldim=nothing, attributes...,
)
    args, merged_attributes = _series(A, attributes, labeldim)
    n = size(last(args), 1)
    p = if isnothing(color)
        if n > 7
            color = resample_cmap(colormap, n) 
            Makie.series(args...; color, colormap, merged_attributes...)
        else
            Makie.series(args...; colormap, merged_attributes...)
        end
    else
        Makie.series(args...; color, colormap, merged_attributes...)
    end
    axislegend(p.axis; merge=true, unique=false, axislegendkw...)
    return p
end
function Makie.series!(axis, A::AbstractDimArray{<:Any,2}; axislegendkw=(;), labeldim=nothing, attributes...)
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
        $f(A::AbstractDimArray{<:Any,2}; attributes...)
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f`.

    $(_labeldim_detection_doc(f))
    """
    @eval begin
        @doc $docstring
        function Makie.$f(A::AbstractDimArray{<:Any,2}; labeldim=nothing, attributes...)
            args, merged_attributes = _boxplotlike(A, attributes, labeldim)
            return Makie.$f(args...; merged_attributes...)
        end
        function Makie.$f!(axis, A::AbstractDimArray{<:Any,2}; labeldim=nothing, attributes...)
            args, _ = _boxplotlike(A, attributes, labeldim)
            return Makie.$f!(axis, args...; attributes...)
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
Makie.plottype(A::AbstractDimArray{<:Any,1}) = Makie.Scatter
Makie.plottype(A::AbstractDimArray{<:Any,2}) = Makie.Heatmap
Makie.plottype(A::AbstractDimArray{<:Any,3}) = Makie.Volume

# Conversions
function Makie.convert_arguments(t::Type{<:Makie.AbstractPlot}, A::AbstractDimArray{<:Any,2})
    A1 = _prepare_for_makie(A)
    xs, ys = map(parent, lookup(A1))
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end
function Makie.convert_arguments(t::Makie.PointBased, A::AbstractDimArray{<:Any,1})
    A = _prepare_for_makie(A)
    xs = parent(lookup(A, 1))
    return Makie.convert_arguments(t, _floatornan(parent(A)))
end
function Makie.convert_arguments(t::Makie.PointBased, A::AbstractDimArray{<:Number,2})
    return Makie.convert_arguments(t, parent(A))
end
function Makie.convert_arguments(t::SurfaceLikeCompat, A::AbstractDimArray{<:Any,2})
    A1 = _prepare_for_makie(A)
    xs, ys = map(parent, lookup(A1))
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end
function Makie.convert_arguments(
    t::Makie.DiscreteSurface, A::AbstractDimArray{<:Any,2}
)
    A1 = _prepare_for_makie(A)
    xs, ys = map(parent, lookup(A1))
    return xs, ys, last(Makie.convert_arguments(t, parent(A1)))
end
function Makie.convert_arguments(t::Makie.VolumeLike, A::AbstractDimArray{<:Any,3}) 
    A1 = _prepare_for_makie(A)
    xs, ys, zs = map(parent, lookup(A1))
    return xs, ys, zs, last(Makie.convert_arguments(t, parent(A1)))
end
# fallbacks with descriptive error messages
function Makie.convert_arguments(t::Makie.ConversionTrait, A::AbstractDimArray{<:Any,N}) where {N}
    @warn "$t not implemented for `AbstractDimArray` with $N dims, falling back to parent array type"
    return Makie.convert_arguments(t, parent(A))
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

function _prepare_for_makie(A; replacements=())
    _permute_xyz(maybeshiftlocus(Center(), A; dims=(XDim, YDim)), replacements) |> _reorder
end

# Permute the data after replacing the dimensions with X/Y/Z
_permute_xyz(A::AbstractDimArray, replacements::Pair) = _permute_xyz(A, (replacements,))
_permute_xyz(A::AbstractDimArray, replacements::Tuple{<:Pair,Vararg{<:Pair}}) =
    _permute_xyz(A, map(p -> basetypeof(key2dim(p[1]))(basetypeof(key2dim(p[2]))()), replacements))
function _permute_xyz(A::AbstractDimArray{<:Any,N}, replacements::Tuple) where N
    xyz_dims = (X(), Y(), Z())[1:N]
    all_replacements = _get_replacement_dims(A, replacements)
    A_replaced_dims = set(A, all_replacements...)
    # Permute to X/Y/Z order
    permutedims(A_replaced_dims, xyz_dims)
end

# Give the data in A2 the names from A1 working backwards from what was replaced earlier
_restore_dim_names(A2, A1, replacements::Pair) = _restore_dim_names(A2, A1, (replacements,)) 
_restore_dim_names(A2, A1, replacements::Tuple{<:Pair,Vararg{<:Pair}}) =
    _restore_dim_names(A2, A1, map(p -> basetypeof(key2dim(p[1]))(basetypeof(key2dim(p[2]))()), replacements))
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

_floatornan(A::AbstractArray{<:Union{Missing,<:Real}}) = _floatornan32.(A)
_floatornan(A::AbstractArray{<:Union{Missing,Float64}}) = _floatornan64.(A)
_floatornan(A) = A
_floatornan32(x) = ismissing(x) ? NaN32 : Float32(x)
_floatornan64(x) = ismissing(x) ? NaN64 : Float64(x)

end
