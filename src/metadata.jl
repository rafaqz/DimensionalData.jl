abstract type AbstractMetadata end

Base.parent(m::AbstractMetadata) = m.metadata
Base.keys(m::AbstractMetadata) = keys(parent(m))
Base.values(m::AbstractMetadata) = values(parent(m))
Base.getindex(m::AbstractMetadata, I) = getindex(parent(m), I) 
Base.setindex!(m::AbstractMetadata, x, I) = setindex!(parent(m), x, I) 
