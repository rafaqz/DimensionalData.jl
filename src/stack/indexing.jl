# getindex/view/setindex! ======================================================

#### getindex ####

# Symbol key
@propagate_inbounds Base.getindex(s::AbstractDimStack, key::Symbol) =
    DimArray(data(s)[key], dims(s, layerdims(s, key)), refdims(s), key, layermetadata(s, key))

# Array-like indexing
@propagate_inbounds Base.getindex(s::AbstractDimStack, i::Int, I::Int...) =
    map(A -> Base.getindex(A, i, I...), data(s))
for f in (:getindex, :view, :dotview)
    @eval begin
        @propagate_inbounds function Base.$f(s::AbstractDimStack, I...; kw...)
            newlayers = map(A -> Base.$f(A, I...; kw...), layers(s))
            if all(map(v -> v isa AbstractDimArray, newlayers))
                rebuildsliced(Base.$f, s, newlayers, (dims2indices(dims(s), (I..., _kwdims(values(kw))...))))
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
