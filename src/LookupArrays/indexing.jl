
for f in (:getindex, :view, :dotview)
    @eval begin
        # Int and CartesianIndex forward to the parent
        @propagate_inbounds Base.$f(l::LookupArray, i::Union{Int,CartesianIndex}) =
            Base.$f(parent(l), i)
        # AbstractArray and Colon the lookup is rebuilt around a new parent
        @propagate_inbounds Base.$f(l::LookupArray, i::Union{AbstractArray,Colon}) = 
            rebuild(l; data=Base.$f(parent(l), i))
        # Selector gets processed with `selectindices`
        @propagate_inbounds Base.$f(l::LookupArray, i::SelectorOrInterval) = Base.$f(l, selectindices(l, i))
        # Everything else (like custom indexing from other packages) passes through to the parent
        @propagate_inbounds function Base.$f(l::LookupArray, i)
            Base.$f(parent(l), i)
        end
    end
end
