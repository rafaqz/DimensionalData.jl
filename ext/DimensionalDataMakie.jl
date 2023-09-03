module DimensionalDataMakie

using DimensionalData, Makie
using DimensionalData.Dimensions, DimensionalData.LookupArrays

const DD = DimensionalData

_paired(args...) = map(x -> x isa Pair ? x : x => x, args)

# 1d plots are scatter by default
for (f1, f2) in _paired(:plot => :scatter, :scatter, :lines, :scatterlines, :stairs, :stem, :barplot, :waterfall)
    f1!, f2! = Symbol(f1, '!'), Symbol(f2, '!')
    docstring = """
        $f1(::AbstractDimArray{<:Any,1})
        
    Plot a 1-dimensional `AbstractDimArray` with `Makie.$f2`.

    The X axis will be labelled with the dimension name and and use ticks from its lookup.
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(A::AbstractDimArray{<:Any,1}; attributes...)
            args, merged_attributes = _pointbased1(A, attributes)
            Makie.$f2(args...; merged_attributes...)
        end
        function Makie.$f1!(axis, A::AbstractDimArray{<:Any,1}; attributes...)
            args, _ = _pointbased1(A, attributes)
            Makie.$f2!(axis, args...; attributes...)
        end
    end
end

function _pointbased1(A, attributes)
    A1 = _prepare_for_makie(A)
    d = DD.dims(A1, 1)
    user_attributes = Makie.Attributes(; attributes...)
    plot_attributes = Makie.Attributes(; 
        axis=(; 
            xlabel=string(name(d)), 
            ylabel=DD.label(A),
            title=DD.refdims_title(A),
        ),
    )
    # Convert categorical to Int
    lookup_attributes, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, d => newdims[1]), A)
    args = Makie.convert_arguments(Makie.PointBased(), A2)
    merged_attributes = merge(user_attributes, plot_attributes, lookup_attributes)

    return args, merged_attributes
end

for (f1, f2) in _paired(:plot => :heatmap, :heatmap, :image, :contour, :contourf, :spy)
    f1!, f2! = Symbol(f1, '!'), Symbol(f2, '!')
    docstring = """
        $f1(::AbstractDimArray{<:Any,2})
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f2`.

    # Keywords
    
    Keywords for `$f1` work as usual.

    - `dims`: A `Pair` or Tuple of Pair of `Dimension` or `Symbol`. Can be used to
        specify dimensions that should be moved to the `X`, `Y` and `Z` dimensions
        of the plot. For example `$f1(A, dims=:a => :X)` will use the `:a` dimension
        as the `X` dimension in the plot.
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(A::AbstractDimArray{<:Any,2}; dims=(), attributes...)
            args, merged_attributes = _surface2(A, attributes, dims)
            p = Makie.$f2(args...; merged_attributes...)
            if $(f1 in (:heatmap, :contourf)) 
                Colorbar(p.figure[1, 2];
                    label=DD.label(A),
                ) 
            end
            p
        end
        function Makie.$f1!(A::AbstractDimArray{<:Any,2}; dims=(), attributes...)
            args, _ = _surface2(A, attributes, dims)
            Makie.$f2!(args...; attributes...)
        end
    end
end

function _surface2(A, attributes, dims)
    A1 = _prepare_for_makie(A, dims)
    lookup_attributes, newdims = _split_attributes(A1)
    A2 = _restore_dim_names(set(A1, map(Pair, newdims, newdims)...), A, dims)

    dx, dy = DD.dims(A2)
    user_attributes = Makie.Attributes(; attributes...)
    dd_attributes = Makie.Attributes(; 
        axis=(; 
            xlabel=DD.label(dx),
            ylabel=DD.label(dy),
            title=DD.refdims_title(A),
        ),
    )
    merged_attributes = merge(user_attributes, dd_attributes, lookup_attributes)
    args = Makie.convert_arguments(Makie.ContinuousSurface(), A2)
    merged_attributes = merge(user_attributes, dd_attributes, lookup_attributes)

    return args, merged_attributes
end

for (f1, f2) in _paired(:plot => :volume, :volume, :volumeslices)
    f1!, f2! = Symbol(f1, '!'), Symbol(f2, '!')
    docstring = """
        $f1(::AbstractDimArray{<:Any,2})
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f2`.

    # Keywords
    
    Keywords for $f1 work as usual.

    - `dims`: A `Pair` or Tuple of Pair of `Dimension` or `Symbol`. Can be used to
        specify dimensions that should be moved to the `X`, `Y` and `Z` dimensions
        of the plot. For example `$f1(A, dims=:a => :X)` will use the `:a` dimension
        as the `X` dimension in the plot.
    """
    @eval begin
        @doc $docstring
        function Makie.$f1(A::AbstractDimArray{<:Any,3}; dims=(), attributes...)
            args, merged_attributes = _volume3(A, attributes, dims)
            Makie.$f2(args...; merged_attributes...)
        end
        function Makie.$f1!(axis, A::AbstractDimArray{<:Any,3}; dims=(), attributes...)
            args, _ = _volume3(A, attributes, dims)
            Makie.$f2!(axis, args...; attributes...)
        end
    end
end

function _volume3(A, attributes, dims)
    A1 = _prepare_for_makie(A, dims)
    dx, dy, dz = DD.dims(A1)
    user_attributes = Makie.Attributes(; attributes...)
    plot_attributes = Makie.Attributes(; 
        # axis=(; cant actually set anything here for LScene)
    )
    _, newdims = _split_attributes(A1)
    merged_attributes = merge(user_attributes, plot_attributes)
    A2 = _restore_dim_names(set(A1, map(Pair, newdims, newdims)...), A, dims)
    args = Makie.convert_arguments(Makie.VolumeLike(), A2)

    return args, merged_attributes
end

"""
    series(::AbstractDimArray{<:Any,2})
    
Plot a 2-dimensional `AbstractDimArray` with `Makie.series`.

At least one dimension should have a `Categorical` `Lookup`, which
will be used to assign categories to the values in the array.
"""
function Makie.series(A::AbstractDimArray{<:Any,2}; attributes...)
    args, merged_attributes = _series(A, attributes)
    p = Makie.series(args...; merged_attributes...)
    axislegend(p.axis)
    p
end
function Makie.series!(axis, A::AbstractDimArray{<:Any,2}; attributes...)
    args, _ = _series(A, attributes)
    Makie.series!(args...; attributes...)
end

function _series(A, attributes)
    categoricaldim = reduce(dims(A); init=nothing) do acc, x
        if isnothing(acc)
            lookup(x) isa AbstractCategorical ? x : nothing
        else
            lookup(acc) isa AbstractCategorical ? acc : x
        end
    end
    isnothing(categoricaldim) && throw(ArgumentError("No dimensions have Categorical lookups"))
    categoricallookup = parent(categoricaldim)
    otherdim = only(otherdims(A, categoricaldim))
    otherlookup = lookup(otherdim)

    user_attributes = Makie.Attributes(; attributes...)
    dd_attributes = Makie.Attributes(; 
        labels=string.(parent(categoricallookup)),
        axis=(; 
            xlabel=DD.label(otherdim),
            ylabel=DD.label(A),
            title=DD.refdims_title(A),
        ),
    )
    merged_attributes = merge(user_attributes, dd_attributes)

    return args, merged_attributes
end

for f in (:boxplot, :rainclouds, :violin)
    f! = Symbol(f, '!')
    docstring = """
        $f(::AbstractDimArray{<:Any,2})
        
    Plot a 2-dimensional `AbstractDimArray` with `Makie.$f`.

    At least one dimension should have a `Categorical` `Lookup`, which
    will be used to assign categories to the values in the array.
    """
    @eval begin
        @doc $docstring
        function Makie.$f(A::AbstractDimArray{<:Any,2}; attributes...)
            args, merged_attributes = _boxplot(A, attributes)
            Makie.$f(args...; merged_attributes...)
        end
        function Makie.$f!(axis, A::AbstractDimArray{<:Any,2}; attributes...)
            args, merged_attributes = _boxplot(A, attributes)
            Makie.$f(axis, args...; merged_attributes...)
        end
    end
end

function _boxplot(A, attributes)
    categoricaldim = reduce(dims(A); init=nothing) do acc, x
        if isnothing(acc)
            lookup(x) isa AbstractCategorical ? x : nothing
        else
            lookup(acc) isa AbstractCategorical ? acc : x
        end
    end
    isnothing(categoricaldim) && throw(ArgumentError("No dimensions have Categorical lookups"))
    categoricallookup = parent(categoricaldim)
    otherdim = only(otherdims(A, categoricaldim))
    categories = broadcast_dims((_, c) -> c, A, DimArray(eachindex(categoricaldim), categoricaldim))

    user_attributes = Makie.Attributes(; attributes...)
    plot_attributes = Makie.Attributes(; 
        axis=(; 
            xlabel=DD.label(categoricaldim),
            xticks=axes(categoricallookup, 1),
            xtickformat=I -> map(string, categoricallookup[map(Int, I)]),
            ylabel=DD.label(A),
        ),
    )
    merged_attributes = merge(user_attributes, plot_attributes)
    args = vec(lookup(otherdim)), parent(A)

    return args, merged_attributes
end

Makie.plottype(A::AbstractDimArray{<:Any,1}) = Makie.Scatter
Makie.plottype(A::AbstractDimArray{<:Any,2}) = Makie.Heatmap
Makie.plottype(A::AbstractDimArray{<:Any,3}) = Makie.Volume

# then, define how they are to be converted to plottable data
function Makie.convert_arguments(t::Makie.PointBased, A::AbstractDimArray{<:Any,1})
    A = _prepare_for_makie(A)
    xs = lookup(A, 1)
    return Makie.convert_arguments(t, parent(xs), parent(A))
end
function Makie.convert_arguments(t::Makie.PointBased, A::AbstractDimArray{<:Number,2})
    return Makie.convert_arguments(t, parent(A))
end
function Makie.convert_arguments(t::Makie.SurfaceLike, A::AbstractDimArray{<:Any,2})
    A1 = _prepare_for_makie(A)
    xs, ys = map(parent, lookup(A1))
    return Makie.convert_arguments(t, xs, ys, parent(A1))
end
function Makie.convert_arguments(
    t::Makie.DiscreteSurface, A::AbstractDimArray{<:Any,2}
)
    A1 = _prepare_for_makie(A)
    # xs, ys = map(_lookup_edges, lookup(A1))
    xs, ys = map(parent, lookup(A1))
    return xs, ys, parent(A1)
end
function Makie.convert_arguments(t::Makie.VolumeLike, A::AbstractDimArray{<:Any,3}) 
    A1 = _prepare_for_makie(A)
    xs, ys, zs = map(parent, lookup(A1))
    return xs, ys, zs, parent(A1)
end
# fallbacks with descriptive error messages
function Makie.convert_arguments(t::Makie.ConversionTrait, A::AbstractDimArray{<:Any,N}) where {N}
    @warn "$t not implemented for `AbstractDimArray` with $N dims, falling back to parent array type"
    return Makie.convert_arguments(t, parent(A))
end

# Calculate the edges 
# function _lookup_edges(l::LookupArray)
#     l = if l isa AbstractSampled 
#         set(l, Intervals())
#     else
#         set(l, Sampled(; sampling=Intervals()))
#     end
#     if l == 1
#         return [bounds(l)...]
#     else
#         ib = intervalbounds(l)
#         if order(l) isa ForwardOrdered
#             edges = first.(ib)
#             push!(edges, last(last(ib)))
#         else
#             edges = last.(ib)
#             push!(edges, first(last(ib)))
#         end
#         return edges
#     end
# end

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
_split_attributes(dim::Dimension) = _split_attributes((dim,))

_prepare_for_makie(A, dims=()) = _permute(A, dims) |> _reorder |> _makie_eltype

_permute(A, replacements::Pair) = _permute(A, (replacements,))
_permute(A, replacements::Tuple{<:Pair,Vararg{<:Pair}}) =
    _permute1(A, map(p -> basetypeof(key2dim(p[1]))(basetypeof(key2dim(p[2]))()), replacements))
function _permute(A::AbstractDimArray{<:Any,N}, replacements::Tuple) where N
    xyz_dims = (X(), Y(), Z())[1:N]
    all_replacements = _get_replacement_dims(A, replacements)
    A_replaced_dims = set(A, all_replacements...)
    # Permute to X/Y/Z order
    permutedims(A_replaced_dims, xyz_dims)
end

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

function _get_replacement_dims(A::AbstractDimArray{<:Any,N}, replacements::Tuple) where N
    xyz_dims = (X(), Y(), Z())[1:N]
    # Make sure destinations are X/Y/Z only
    dest_dims = map(replacements) do d
        d1 = basetypeof(val(d))()
        d1 in xyz_dims || throw(ArgumentError("`dims` destinations must be in $(map(basetypeof, xyz_dims))"))
        d1
    end
    replaced_dims = set(basedims(A), replacements...)
    # Find remaining dims that are not X/Y/Z
    other_source_dims = otherdims(replaced_dims, xyz_dims)
    # Assign dest dims from whatever X/Y/Z remain
    other_dest_dims = otherdims(xyz_dims, replaced_dims)
    # Define the missing replacements
    other_replacements = map(rebuild, other_source_dims, other_dest_dims)
    return (replacements..., other_replacements...)
end

_reorder(A) = reorder(A, DD.ForwardOrdered)
_makie_eltype(A) = _missing_or_float32.(A)

_missing_or_float32(num::Number) = Float32(num)
_mirssing_or_float32(::Missing) = missing

end
