# getindex/view/setindex! ======================================================

#### getindex ####

# Symbol key
for f in (:getindex, :view, :dotview)
    @eval @propagate_inbounds Base.$f(s::AbstractDimStack, key::Symbol) =
        DimArray(data(s)[key], dims(s, layerdims(s, key)), refdims(s), key, layermetadata(s, key))
end
@propagate_inbounds function Base.getindex(s::AbstractDimStack, keys::Tuple)
    rebuild_from_arrays(s, NamedTuple{keys}(map(k -> s[k], keys)))
end

# Array-like indexing
# @propagate_inbounds Base.getindex(s::AbstractDimStack, i::Int, I::Int...) =
#     map(A -> Base.getindex(A, i, I...), data(s))
# @propagate_inbounds function Base.getindex(
#     s::AbstractDimStack, i::Union{Integer,AbstractArray,Colon}
# )
#     if hassamedims(s)
#         if ndims(first(layers(s))) == 1
#             map(A -> getindex(A, i), s)
#         else
#             map(A -> getindex(A, i), layers(s))
#         end
#     else
#         _getindex_mixed(s, xs, i)
#     end
# end
# @propagate_inbounds _getindex_mixed(s::AbstractDimStack, i::AbstractArray) =
#     map(A -> getindex(A, DimIndices(dims(s))[i]), layers(s))
# @propagate_inbounds _getindex_mixed(s::AbstractDimStack, i::Int) =
#     map(A -> getindex(A, DimIndices(dims(s))[i]), layers(s))
# @propagate_inbounds _getindex_mixed(s::AbstractDimStack, i::Colon) =
#     map(A -> getindex(A, i), layers(s))

for f in (:getindex, :view, :dotview)
    _f = Symbol(:_, f)
    @eval begin
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::StandardIndices)
            $f(s, view(DimIndices(s), i))
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i1::SelectorOrStandard, Is::SelectorOrStandard...)
            I = to_indices(CartesianIndices(s), (i1, Is...))
            @show I CartesianIndices(s)
            # Check we have the right number of dimensions
            if length(dims(s)) > length(I)
                throw(BoundsError(dims(s), I))
            elseif length(dims(s)) < length(I)
                # Allow trailing ones
                if all(i -> i isa Integer && i == 1, I[length(dims(s)):end])
                    I = I[1:length(dims)]
                else
                    throw(BoundsError(dims(s), I))
                end
            end
            # Convert to Dimension wrappers to handle mixed size layers
            Base.$f(s, map(rebuild, dims(s), I)...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::AbstractArray)
            # Multidimensional: return vectors of values
            if length(dims(s)) > 1
                Ds = DimIndices(s)[i]
                map(s) do A
                    map(D -> A[D...], Ds)
                end
            else
                map(A -> A[i], s)
            end
        end
        # Handle zero-argument getindex, this will error unless all layers are zero dimensional
        @propagate_inbounds function Base.$f(s::AbstractDimStack)
            map($f, s)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, D::DimensionalIndices...; kw...)
            $_f(s, _simplify_dim_indices(D..., kwdims(values(kw))...)...)
        end
        @propagate_inbounds function $_f(
            A::AbstractDimStack, a1::Union{Dimension,DimensionIndsArrays}, args::Union{Dimension,DimensionIndsArrays}...
        )
            return merge_and_index($f, A, (a1, args...))
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
