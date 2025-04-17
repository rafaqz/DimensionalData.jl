
for f in (:getindex, :view, :dotview)
    @eval begin
        # Int and CartesianIndex forward to the parent
        @propagate_inbounds Base.$f(l::Lookup, i::Union{Int,CartesianIndex}) =
            Base.$f(parent(l), i)
        # AbstractArray, Colon and CartesianIndices: the lookup is rebuilt around a new parent
        @propagate_inbounds Base.$f(l::Lookup, i::Union{AbstractVector,Colon}) = 
            rebuild(l; data=Base.$f(parent(l), i))
        @propagate_inbounds function Base.$f(l::Union{Sampled,Categorical}, i::AbstractVector{Int})
            if isordered(l)
                issorted(i) || throw(ArgumentError("For `ForwardOrdered` or `ReverseOrdered` lookups, indices of `AbstractVector{Int}` must be in ascending order"))
            end
            rebuild(l; data=Base.$f(parent(l), i))
        end
        # Selector gets processed with `selectindices`
        @propagate_inbounds Base.$f(l::Lookup, i::SelectorOrInterval) = Base.$f(l, selectindices(l, i))
        @propagate_inbounds function Base.$f(l::Lookup, i)
            x = Base.$f(parent(l), i)
            x isa AbstractArray ? rebuild(l; data=x) : x
        end
    end
end
