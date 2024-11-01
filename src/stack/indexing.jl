# getindex/view/setindex! ======================================================

#### getindex ####
#
function _maybe_extented_layers(s)
    if hassamedims(s)
        values(s)
    else
        map(A -> DimExtensionArray(A, dims(s)), values(s))
    end
end

# Symbol key
for f in (:getindex, :view, :dotview)
    @eval Base.@constprop :aggressive @propagate_inbounds Base.$f(s::AbstractDimStack, key::Symbol) =
        DimArray(data(s)[key], dims(s, layerdims(s)[key]), refdims(s), key, layermetadata(s, key))
    @eval Base.@constprop :aggressive @propagate_inbounds function Base.$f(s::AbstractDimStack, keys::NTuple{<:Any,Symbol})
        rebuild_from_arrays(s, NamedTuple{keys}(map(k -> s[k], keys)))
    end
    @eval Base.@constprop :aggressive @propagate_inbounds function Base.$f(
        s::AbstractDimStack, keys::Union{<:Not{Symbol},<:Not{<:NTuple{<:Any,Symbol}}}
    )
        rebuild_from_arrays(s, layers(s)[keys]) 
    end
end

Base.@assume_effects :effect_free @propagate_inbounds function Base.getindex(s::AbstractVectorDimStack, i::Union{AbstractVector,Colon})
    # Use dimensional indexing
    Base.getindex(s, rebuild(only(dims(s)), i))
end
Base.@assume_effects :effect_free @propagate_inbounds function Base.getindex(
    s::AbstractDimStack{<:Any,T}, i::Union{AbstractArray,Colon}
) where {T}
    ls = _maybe_extented_layers(s)
    inds = to_indices(first(ls), (i,))[1]
    out = similar(inds, T)
    for (i, ind) in enumerate(inds)
        out[i] = T(map(v -> v[ind], ls))
    end
    return out
end
@propagate_inbounds function Base.getindex(s::AbstractDimStack{<:Any,<:Any,N}, i::Integer) where N
    if N == 1 && hassamedims(s)
        # This is a few ns faster when possible
        map(l -> l[i], data(s))
    else
        # Otherwise use dimensional indexing
        s[DimIndices(s)[i]]
    end
end

@propagate_inbounds function Base.view(s::AbstractVectorDimStack, i::Union{AbstractVector{<:Integer},Colon,Integer})
    Base.view(s, DimIndices(s)[i])
end
@propagate_inbounds function Base.view(s::AbstractDimStack, i::Union{AbstractArray{<:Integer},Colon,Integer})
    # Pretend the stack is an AbstractArray so `SubArray` accepts it.
    Base.view(OpaqueArray(s), i)
end

for f in (:getindex, :view, :dotview)
    _dim_f = Symbol(:_dim_, f)
    @eval begin
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i)
            Base.$f(s, to_indices(CartesianIndices(s), Lookups._construct_types(i))...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::Union{SelectorOrInterval,Extents.Extent})
            Base.$f(s, dims2indices(s, i)...)
        end
        @propagate_inbounds function Base.$f(s::AbstractVectorDimStack, i::Union{CartesianIndices,CartesianIndex})
            I = to_indices(CartesianIndices(s), (i,))
            Base.$f(s, I...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::Union{CartesianIndices,CartesianIndex})
            I = to_indices(CartesianIndices(s), (i,))
            Base.$f(s, I...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i1, i2, Is...)
            I = to_indices(CartesianIndices(s), Lookups._construct_types(i1, i2, Is...))
            # Check we have the right number of dimensions
            if length(dims(s)) > length(I)
        @propagate_inbounds function $_dim_f(
            A::AbstractDimStack, a1::Union{Dimension,DimensionIndsArrays}, args::Union{Dimension,DimensionIndsArrays}...
        )
            return merge_and_index(Base.$f, A, (a1, args...))
        end
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
            $_dim_f(s, _simplify_dim_indices(D..., kw2dims(values(kw))...)...)
        end
        # Ambiguities
        @propagate_inbounds function Base.$f(s::DimensionalData.AbstractVectorDimStack, 
            i::Union{AbstractVector{<:DimensionalData.Dimensions.Dimension},
            AbstractVector{<:Tuple{DimensionalData.Dimensions.Dimension, Vararg{DimensionalData.Dimensions.Dimension}}}, 
            DimensionalData.DimIndices{T,1} where T, DimensionalData.DimSelectors{T,1} where T}
        )
            $_dim_f(s, _simplify_dim_indices(i)...)
        end


        @propagate_inbounds function $_dim_f(
            A::AbstractDimStack, a1::Union{Dimension,DimensionIndsArrays}, args::Union{Dimension,DimensionIndsArrays}...
        )
            return merge_and_index(Base.$f, A, (a1, args...))
        end
        # Handle zero-argument getindex, this will error unless all layers are zero dimensional
        @propagate_inbounds function $_dim_f(s::AbstractDimStack)
            map(Base.$f, data(s))
        end
        Base.@assume_effects :foldable @propagate_inbounds function $_dim_f(s::AbstractDimStack{K}, d1::Dimension, ds::Dimension...) where K
            D = (d1, ds...)
            extradims = otherdims(D, dims(s))
            length(extradims) > 0 && Dimensions._extradimswarn(extradims)
            function f(A) 
                layerdims = dims(D, dims(A))
                I = length(layerdims) > 0 ? layerdims : map(_ -> :, size(A))
                Base.$f(A, I...)
            end
            newlayers = map(f, values(s))
            # Decide to rewrap as an AbstractDimStack, or return a scalar
            if any(map(v -> v isa AbstractDimArray, newlayers))
                # Some scalars, re-wrap them as zero dimensional arrays
                non_scalar_layers = map(values(s), newlayers) do l, nl
                    nl isa AbstractDimArray ? nl : rebuild(l, fill(nl), ())
                end
                rebuildsliced(Base.$f, s, NamedTuple{K}(non_scalar_layers), (dims2indices(dims(s), D)))
            else
                # All scalars, return as-is
                NamedTuple{K}(newlayers)
            end 
        end
    end
end


#### setindex ####
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs, I...; kw...) =
    map((A, x) -> setindex!(A, x, I...; kw...), layers(s), xs)
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs::NamedTuple, i::Integer; kw...) =
    hassamedims(s) ? _map_setindex!(s, xs, i; kw...) : _setindex_mixed!(s, xs, i; kw...)
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs::NamedTuple, i::Colon; kw...) =
    hassamedims(s) ? _map_setindex!(s, xs, i; kw...) : _setindex_mixed!(s, xs, i; kw...)
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs::NamedTuple, i::AbstractArray; kw...) =
    hassamedims(s) ? _map_setindex!(s, xs, i; kw...) : _setindex_mixed!(s, xs, i; kw...)

@propagate_inbounds function Base.setindex!(
    s::AbstractDimStack, xs::NamedTuple, I...; kw...
)
    map((A, x) -> setindex!(A, x, I...; kw...), layers(s), xs)
end

_map_setindex!(s, xs, i) = map((A, x) -> setindex!(A, x, i...; kw...), layers(s), xs)

_setindex_mixed!(s::AbstractDimStack, x, i::AbstractArray) =
    map(A -> setindex!(A, x, DimIndices(dims(s))[i]), layers(s))
_setindex_mixed!(s::AbstractDimStack, i::Integer) =
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
