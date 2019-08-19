abstract type AbstractMetadata end

# Dict interface
Base.parent(m::AbstractMetadata) = m.metadata
Base.keys(m::AbstractMetadata) = keys(parent(m))
Base.values(m::AbstractMetadata) = values(parent(m))
Base.getindex(m::AbstractMetadata, I) = getindex(parent(m), I) 
Base.setindex!(m::AbstractMetadata, x, I) = setindex!(parent(m), x, I) 
Base.get(m::AbstractMetadata, key, default) = get(parent(m), key, default) 
