@inline Base.getindex(d::Dimension) = val(d)

for f in (:getindex, :view, :dotview)
    @eval begin
        # Int and CartesianIndex forward to the parent array
        @propagate_inbounds function Base.$f(d::Dimension{<:AbstractArray}, i::Union{Int,CartesianIndex})
            Base.$f(val(d), i)
        end
        @propagate_inbounds function Base.$f(d::Dimension{<:AbstractArray}, i::Union{AbstractArray,Colon,CartesianIndices})
            # AbstractArray/Colon return an AbstractArray - so rebuild the dimension
            rebuild(d, Base.$f(val(d), i))
        end
        # Selector gets processed with `selectindices`
        @propagate_inbounds function Base.$f(d::Dimension{<:AbstractArray}, i::SelectorOrInterval)
            Base.$f(d, selectindices(val(d), i))
        end
        @propagate_inbounds function Base.$f(d::Dimension{<:AbstractArray}, i)
            x = Base.$f(parent(d), i)
            x isa AbstractArray ? rebuild(d, x) : x
        end
    end
end

#### dims2indices ####

"""
    dims2indices(dim::Dimension, I) => NTuple{Union{Colon,AbstractArray,Int}}

Convert a `Dimension` or `Selector` `I` to indices of `Int`, `AbstractArray` or `Colon`.
"""
@inline dims2indices(dim::Dimension, I) = _dims2indices(dim, I)
@inline dims2indices(x, I) = dims2indices(dims(x), I)
@inline dims2indices(::Nothing, I) = _dimsnotdefinederror()
@inline dims2indices(::Tuple{}, I) = ()
@inline dims2indices(dims::DimTuple, I) = dims2indices(dims, (I,))
# Standard array indices are simply returned
@inline dims2indices(dims::DimTuple, I::Tuple{Vararg{StandardIndices}}) = I
@inline dims2indices(dims::DimTuple, I::Tuple{<:Extents.Extent}) = dims2indices(dims, _extent_as(Interval, first(I)))
@inline dims2indices(dims::DimTuple, I::Tuple{<:Touches{<:Extents.Extent}}) = dims2indices(dims, _extent_as(Touches, val(first(I))))
@inline dims2indices(dims::DimTuple, I::Tuple{<:Near{<:Extents.Extent}}) = dims2indices(dims, _extent_as(Near, val(first(I))))

@inline dims2indices(dims::DimTuple, I::Tuple{<:CartesianIndex}) = I
@inline dims2indices(dims::DimTuple, sel::Tuple) = 
    Lookups.selectindices(lookup(dims), sel)
@inline dims2indices(dims::DimTuple, ::Tuple{}) = ()
# Otherwise attempt to convert dims to indices
@inline function dims2indices(dims::DimTuple, I::DimTuple)
    extradims = otherdims(I, dims) # extra dims in the query, I
    # Extract "multi dimensional" lookups like MergedLookup or Rasters' GeometryLookup
    multidims = Dimensions.dims(otherdims(dims, I), x -> lookup(x) isa MultiDimensionalLookup && !isempty(Dimensions.dims(x, I)))
    # Warn if any dims from I were not picked up by multidims
    actuallyextradims = otherdims(extradims, x -> any(y -> hasdim(y, x), multidims)) # one way setdiff(extradims, multidims) essentially
    length(actuallyextradims) > 0 && _extradimswarn(actuallyextradims)
    # Run the query for the known one-to-one dimensions
    Isorted = Dimensions.sortdims(I, dims)
    one_to_one_idxs = split_alignments(dims2indices, unalligned_dims2indices, dims, Isorted) 
    # Finally, run the query for the multidimensional dims
    # This is basically doing an Accessors.@set on the full_dim_structure
    # one_to_one_idxs is capable of indexing the whole dataset, but 
    # it doesn't know about the merged lookups.  This keeps all one-to-one
    # things the same but injects the solutions to the merged lookups where
    # available and appropriate.
    return map(dims, one_to_one_idxs) do dim, idx
        # Note that this loop iterates over `dims` so each multidim can only be encountered once
        if hasdim(multidims, dim)
            if !(idx isa Colon)
                error("I should be a Colon but I am not: dimension $(name(dim))\nGot\n$idx")
            end
            dims2indices(dim, Dimensions.dims(I, Dimensions.dims(dim)))
        else
            idx
        end
    end
end
@inline dims2indices(dims::Tuple{}, ::Tuple{}) = ()

@inline function unalligned_dims2indices(dims::DimTuple, sel::Tuple)
    map(sel) do s
        s isa Union{Selector,Interval} && _unalligned_all_selector_error(dims)
        isnothing(s) ? Colon() : s
    end
end
@inline function unalligned_dims2indices(dims::DimTuple, sel::Tuple{Selector,Vararg{Selector}})
    Lookups.select_unalligned_indices(lookup(dims), sel)
end

# Run fa on each aligned dimension d[n] and indices i[n], 
# and fu on grouped unaligned dimensions and I.
# The result is the updated dimensions, but in the original order
split_alignments(fa, fu, dims::Tuple, I::Tuple) = 
    split_alignments(fa, fu, val(dims), dims, I)
@generated function split_alignments(
    fa, fu, lookups::Tuple, dims::Tuple, I::Tuple
)
    # We separate out Aligned and Unaligned lookups as
    # Unaligned must be selected in groups e.g. X and Y together.
    unalligned = Expr(:tuple)
    uaI = Expr(:tuple)
    alligned = Expr(:tuple)
    dimmerge = Expr(:tuple)
    a_count = ua_count = 0
    for (i, lkup) in enumerate(lookups.parameters)
        if lkup <: Unaligned
            ua_count += 1
            push!(unalligned.args, :(dims[$i]))
            push!(uaI.args, :(I[$i]))
            push!(dimmerge.args, :(uadims[$ua_count]))
        else
            a_count += 1
            push!(alligned.args, :(fa(dims[$i], I[$i])))
            # Update the merged tuple
            push!(dimmerge.args, :(adims[$a_count]))
        end
    end

    if length(unalligned.args) > 1
        # Output the `dimmerge` tuple, which will
        # combine uadimsand adims in the right order
        quote
             adims = $alligned
             # Unaligned dims have to be run together as a set
             uadims = fu($unalligned, map(_unwrapdim, $uaI))
             $dimmerge
        end
    else
        alligned
    end
end


_unalligned_all_selector_error(dims) =
    throw(ArgumentError("Unalligned dims: use selectors for all $(join(map(name, dims), ", ")) dims, or none of them"))

_unwrapdim(dim::Dimension) = val(dim)
_unwrapdim(x) = x

# Single dim methods
# Simply unwrap dimensions
@inline _dims2indices(dim::Dimension, seldim::Dimension) = _dims2indices(dim, val(seldim))
# A Dimension type always means Colon(), as if it was constructed with the default value.
@inline _dims2indices(dim::Dimension, ::Type{<:Dimension}) = Colon()
# Nothing means nothing was passed for this dimension
@inline _dims2indices(dim::Dimension, i::AbstractBeginEndRange) = i
@inline _dims2indices(dim::Dimension, i::Union{LU.Begin,LU.End,Type{LU.Begin},Type{LU.End},LU.LazyMath}) = 
    to_indices(parent(dim), LU._construct_types(i))[1]
@inline _dims2indices(dim::Dimension, ::Nothing) = Colon()
@inline _dims2indices(dim::Dimension, x) = Lookups.selectindices(val(dim), x)

function _extent_as(::Type{Lookups.Interval}, extent::Extents.Extent{Keys}) where Keys
    map(map(name2dim, Keys), values(extent)) do k, v
        rebuild(k, Lookups.Interval(v...))
    end    
end
function _extent_as(::Type{T}, extent::Extents.Extent{Keys}) where {T,Keys}
    map(map(name2dim, Keys), values(extent)) do k, v
        rebuild(k, T(v))
    end    
end
