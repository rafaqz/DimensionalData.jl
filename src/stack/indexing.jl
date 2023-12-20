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
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i::Int)
            s[CartesianIndices(s)[i]]
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i1::StandardIndices, i2::StandardIndices, is::StandardIndices...)
            I = to_indices(s, (i1, i2, is...))
            D = map(rebuild, dims(s), I)
            return Base.$f(s, D...)
        end
        @propagate_inbounds function Base.$f(s::AbstractDimStack, i1::SelectorOrStandard, i2::SelectorOrStandard, is::StandardIndices...)
            I = (i1, i2, is...)
            D = map(rebuild, dims(s), I)
            return Base.$f(s, D...)
        end
        Base.@assume_effects :effect_free @propagate_inbounds function Base.$f(s::AbstractDimStack{T}, I::Dimension...; kw...) where T
            D = _wrapped_indices(s, I...; kw...)
            newlayers = map(layers(s), layerdims(s)) do A, layerdims
                I_layer = map(val, dims(D, layerdims))
                Base.$f(A, I_layer...)
            end
            if all(map(v -> v isa AbstractDimArray, newlayers))
                rebuildsliced(Base.$f, s, newlayers, (dims2indices(dims(s), (I..., kwdims(values(kw))...))))
            else
                newlayers
            end
        end
    end
end

#### setindex ####
@propagate_inbounds function Base.setindex!(s::AbstractDimStack, v::NamedTuple, i::Union{Int,CartesianIndex})
    s[CartesianIndices(s)[i]]
end
@propagate_inbounds function Base.setindex!(s::AbstractDimStack, v::NamedTuple, i1::Union{Int,CartesianIndex}, i2::Union{Int,CartesianIndex}, is::Union{Int,CartesianIndex}...)
    I = to_indices(s, (i1, i2, is...))
    D = map(rebuild, dims(s), I)
    s[D...] = v
end
Base.@assume_effects :effect_free @propagate_inbounds function Base.setindex!(
    s::AbstractDimStack{<:NamedTuple{K1}}, vals::NamedTuple{K2}, I::Dimension...; 
    kw...
) where {K1,K2}
    all(map(k -> k in K1, K2)) || _keysmismatch(K1, K2)    
    D = _wrapped_indices(s, I...; kw...)
    map(data(s)[K2], layerdims(s)[K2], vals) do A, layerdims, v
        I_layer = map(val, dims(D, layerdims))
        A[I_layer...] = v
    end
end

@inline function _wrapped_indices(x, I...; kw...)
    indexdims = (I..., kwdims(values(kw))...)
    extradims = otherdims(indexdims, dims(x))
    length(extradims) > 0 && Dimensions._extradimswarn(extradims)
    I = dims2indices(x, indexdims)
    D = map(rebuild, dims(x), I)
    return D
end

@noinline _keysmismatch(K1, K2) = throw(ArgumentError("NamedTuple keys $K2 do not mach stack keys $K1"))

# For @views macro to work with keywords
Base.maybeview(A::AbstractDimStack, args...; kw...) = view(A, args...; kw...)
Base.maybeview(A::AbstractDimStack, args::Vararg{Union{Number, Base.AbstractCartesianIndex}}) = view(A, args...)
