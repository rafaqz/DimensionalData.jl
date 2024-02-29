
for f in (:getindex, :view, :dotview)
    @eval begin
        # Int and CartesianIndex forward to the parent
        @propagate_inbounds Base.$f(l::Lookup, i::Union{Int,CartesianIndex}) =
            Base.$f(parent(l), i)
        # AbstractArray, Colon and CartesianIndices: the lookup is rebuilt around a new parent
        @propagate_inbounds Base.$f(l::Lookup, i::Union{AbstractArray,Colon}) = 
            rebuild(l; data=Base.$f(parent(l), i))
        # Selector gets processed with `selectindices`
        @propagate_inbounds Base.$f(l::Lookup, i::SelectorOrInterval) = Base.$f(l, selectindices(l, i))
        # Everything else (like custom indexing from other packages) passes through to the parent
        @propagate_inbounds Base.$f(l::Lookup, i) = Base.$f(parent(l), i)
    end
end
