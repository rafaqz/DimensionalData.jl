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
for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds function Base.$f(
            s::AbstractDimStack, i1::Union{Integer,CartesianIndex}, Is::Union{Integer,CartesianIndex}...
        )
            # Convert to Dimension wrappers to handle mixed size layers
            Base.$f(s, DimIndices(s)[i1, Is...]...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i1, Is...)
            I = (i1, Is...)
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
        @propagate_inbounds function Base.$f(s::AbstractDimStack, D::Dimension...; kw...)
            alldims = (D..., kwdims(values(kw))...)
            extradims = otherdims(alldims, dims(s))
            length(extradims) > 0 && Dimensions._extradimswarn(extradims)
            newlayers = map(layers(s)) do A
                layerdims = dims(alldims, dims(A))
                I = length(layerdims) > 0 ? layerdims : map(_ -> :, size(A))
                Base.$f(A, I...)
            end
            if all(map(v -> v isa AbstractDimArray, newlayers))
                rebuildsliced(Base.$f, s, newlayers, (dims2indices(dims(s), alldims)))
            else
                newlayers
            end
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack)
            map($f, s)
        end
    end
end

#### setindex ####
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs, I...; kw...) =
    map((A, x) -> setindex!(A, x, I...; kw...), layers(s), xs)
@propagate_inbounds function Base.setindex!(
    s::AbstractDimStack{<:NamedTuple{K1}}, xs::NamedTuple{K2}, I...; kw...
) where {K1,K2}
    K1 == K2 || _keysmismatch(K1, K2)
    map((A, x) -> setindex!(A, x, I...; kw...), layers(s), xs)
end

@noinline _keysmismatch(K1, K2) = throw(ArgumentError("NamedTuple keys $K2 do not mach stack keys $K1"))

# For @views macro to work with keywords
Base.maybeview(A::AbstractDimStack, args...; kw...) = view(A, args...; kw...)
