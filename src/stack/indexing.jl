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
@propagate_inbounds Base.getindex(s::AbstractDimStack, i::Int, I::Int...) =
    map(A -> Base.getindex(A, i, I...), data(s))
for f in (:getindex, :view, :dotview)
    @eval begin

        @propagate_inbounds function Base.$f(s::AbstractDimStack, I...; kw...)
            indexdims = (I..., kwdims(values(kw))...)
            extradims = otherdims(indexdims, dims(s))
            length(extradims) > 0 && Dimensions._extradimswarn(extradims)
            newlayers = map(layers(s)) do A
                layerdims = dims(indexdims, dims(A))
                Base.$f(A, layerdims...)
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
