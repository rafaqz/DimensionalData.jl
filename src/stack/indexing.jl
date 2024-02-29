# getindex/view/setindex! ======================================================

#### getindex ####

# Symbol key
for f in (:getindex, :view, :dotview)
    @eval Base.@assume_effects :foldable @propagate_inbounds Base.$f(s::AbstractDimStack, key::Symbol) =
        DimArray(data(s)[key], dims(s, layerdims(s, key)), refdims(s), key, layermetadata(s, key))
    @eval Base.@assume_effects :foldable @propagate_inbounds function Base.$f(s::AbstractDimStack, keys::Tuple)
        rebuild_from_arrays(s, NamedTuple{keys}(map(k -> s[k], keys)))
    end
    @eval Base.@assume_effects :foldable @propagate_inbounds function Base.$f(
        s::AbstractDimStack, keys::Union{<:Not{Symbol},<:Not{<:NTuple{<:Any,Symbol}}}
    )
        rebuild_from_arrays(s, layers(s)[keys]) 
    end
end

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::Union{SelectorOrInterval,Extents.Extent})
            Base.$f(s, dims2indices(s, i)...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::Integer)
            if hassamedims(s)
                map(l -> Base.$f(l, i), s)
            else
                Base.$f(s, DimIndices(s)[i])
            end
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::Union{CartesianIndices,CartesianIndex})
            I = to_indices(CartesianIndices(s), (i,))
            Base.$f(s, I...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::Union{AbstractArray,Colon})
            if length(dims(s)) > 1
                if $f == getindex
                    ls = map(A -> vec(DimExtensionArray(A, dims(s))), layers(s))
                    i = i isa Colon ? eachindex(first(ls)) : i
                    map(i) do n
                        map(Base.Fix2(getindex, n), ls)
                    end
                else
                    Base.$f(s, view(DimIndices(s), i))
                end
            elseif length(dims(s)) == 1
                Base.$f(s, rebuild(only(dims(s)), i))
            else 
                checkbounds(s, i)
            end
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i1::SelectorOrStandard, i2, Is::SelectorOrStandard...)
            I = to_indices(CartesianIndices(s), (i1, i2, Is...))
            # Check we have the right number of dimensions
            if length(dims(s)) > length(I)
                throw(BoundsError(dims(s), I))
            elseif length(dims(s)) < length(I)
                # Allow trailing ones
                if all(i -> i isa Integer && i == 1, I[length(dims(s))+1:end])
                    I = I[1:length(dims(s))]
                else
                    throw(BoundsError(dims(s), I))
                end
            end
            # Convert to Dimension wrappers to handle mixed size layers
            Base.$f(s, map(rebuild, dims(s), I)...)
        end
        @propagate_inbounds function Base.$f(
            s::AbstractDimStack, D::DimensionalIndices...; kw...
        )
            $_f(s, _simplify_dim_indices(D..., kw2dims(values(kw))...)...)
        end
        # Ambiguities
        @propagate_inbounds function Base.$f(
            ::AbstractDimStack, 
            ::_DimIndicesAmb,
            ::Union{Tuple{Dimension,Vararg{Dimension}},AbstractArray{<:Dimension},AbstractArray{<:Tuple{Dimension,Vararg{Dimension}}},DimIndices,DimSelectors,Dimension},
            ::_DimIndicesAmb...
        )
            $_f(s, _simplify_dim_indices(D..., kw2dims(values(kw))...)...)
        end
        @propagate_inbounds function Base.$f(
            s::AbstractDimStack, 
            d1::Union{AbstractArray{Union{}}, DimIndices{<:Integer}, DimSelectors{<:Integer}}, 
            D::Vararg{Union{AbstractArray{Union{}}, DimIndices{<:Integer}, DimSelectors{<:Integer}}}
        )
            $_f(s, _simplify_dim_indices(d1, D...))
        end
        @propagate_inbounds function Base.$f(
            s::AbstractDimStack, 
            D::Union{AbstractArray{Union{}},DimIndices{<:Integer},DimSelectors{<:Integer}}
        )
            $_f(s, _simplify_dim_indices(D...))
        end


        @propagate_inbounds function $_f(
            A::AbstractDimStack, a1::Union{Dimension,DimensionIndsArrays}, args::Union{Dimension,DimensionIndsArrays}...
        )
            return merge_and_index(Base.$f, A, (a1, args...))
        end
        # Handle zero-argument getindex, this will error unless all layers are zero dimensional
        @propagate_inbounds function $_f(s::AbstractDimStack)
            map(Base.$f, s)
        end
        @propagate_inbounds function $_f(s::AbstractDimStack, d1::Dimension, ds::Dimension...)
            D = (d1, ds...)
            extradims = otherdims(D, dims(s))
            length(extradims) > 0 && Dimensions._extradimswarn(extradims)
            newlayers = map(layers(s)) do A
                layerdims = dims(D, dims(A))
                I = length(layerdims) > 0 ? layerdims : map(_ -> :, size(A))
                Base.$f(A, I...)
            end
            # Dicide to rewrap as an AbstractDimStack, or return a scalar
            if all(map(v -> v isa AbstractDimArray, newlayers))
                # All arrays, wrap
                rebuildsliced(Base.$f, s, newlayers, (dims2indices(dims(s), D)))
            elseif any(map(v -> v isa AbstractDimArray, newlayers))
                # Some scalars, re-wrap them as zero dimensional arrays
                non_scalar_layers = map(layers(s), newlayers) do l, nl
                    nl isa AbstractDimArray ? nl : rebuild(l, fill(nl), ())
                end
                rebuildsliced(Base.$f, s, non_scalar_layers, (dims2indices(dims(s), D)))
            else
                # All scalars, return as-is
                newlayers
            end
        end
    end
end


#### setindex ####
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs, I...; kw...) =
    map((A, x) -> setindex!(A, x, I...; kw...), layers(s), xs)
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs::NamedTuple, i::Integer; kw...) =
    hassamedims(s) ? _map_setindex!(s, xs, i) : _setindex_mixed(s, xs, i)
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs::NamedTuple, i::Colon; kw...) =
    hassamedims(s) ? _map_setindex!(s, xs, i) : _setindex_mixed(s, xs, i)
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs::NamedTuple, i::AbstractArray; kw...) =
    hassamedims(s) ? _map_setindex!(s, xs, i) : _setindex_mixed(s, xs, i)

@propagate_inbounds function Base.setindex!(
    s::AbstractDimStack, xs::NamedTuple, I...; kw...
)
    map((A, x) -> setindex!(A, x, I...; kw...), layers(s), xs)
end
# For ambiguity
# @propagate_inbounds function Base.setindex!(
#     s::AbstractDimStack, xs::NamedTuple, i::Integer
# )
#     setindex!(A, xs, DimIndices(s)[i])
# end

_map_setindex!(s, xs, i) = map((A, x) -> setindex!(A, x, i...; kw...), layers(s), xs)

_setindex_mixed(s::AbstractDimStack, x, i::AbstractArray) =
    map(A -> setindex!(A, x, DimIndices(dims(s))[i]), layers(s))
_setindex_mixed(s::AbstractDimStack, i::Integer) =
    map(A -> setindex!(A, x, DimIndices(dims(s))[i]), layers(s))
function _setindex_mixed!(s::AbstractDimStack, x, i::Colon)
    map(DimIndices(dims(s))) do D
        map(A -> setindex!(A, D), x, layers(s))
    end
end

@noinline _keysmismatch(K1, K2) = throw(ArgumentError("NamedTuple keys $K2 do not mach stack keys $K1"))

# For @views macro to work with keywords
Base.maybeview(A::AbstractDimStack, args...; kw...) = view(A, args...; kw...)

function merge_and_index(f, s::AbstractDimStack, ds)
    ds, inds_arrays = _separate_dims_arrays(_simplify_dim_indices(ds...)...)
    # No arrays here, so abort (dispatch is tricky...)
    length(inds_arrays) == 0 && return f(s, ds...)
    inds = first(inds_arrays)

    V = length(ds) > 0 ? view(s, ds...) : s
    if !(length(dims(first(inds))) == length(dims(V)))
        throw(ArgumentError("When indexing an AbstractDimStack with an Array all dimensions must be used")) 
    end
    mdim = only(mergedims(dims(V),  dims(V)))
    newlayers = map(layers(V)) do l
        l1 = all(hasdim(l, dims(V))) ? l : DimExtension(l, dims(V))
        view(l1, inds)
    end
    return rebuild_from_arrays(s, newlayers)
end
