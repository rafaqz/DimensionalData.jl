module DimensionalDataAdaptExt

using DimensionalData
using DimensionalData.Dimensions
using DimensionalData.Lookups
import Adapt

const DD = DimensionalData

# Metadata nearly always contains strings, which break GPU compat.
# For now just remove everything, but we could strip all strings
# and replace Dict with NamedTuple.
# This might also be a problem with non-GPU uses of Adapt.jl where keeping
# the metadata is fine.
Adapt.adapt_structure(to, m::Metadata) = NoMetadata()

# Span types
Adapt.adapt_structure(to, s::Span) = s
Adapt.adapt_structure(to, s::Explicit) = Explicit(Adapt.adapt_structure(to, val(s)))

# Lookup types
function Adapt.adapt_structure(to, l::Lookup)
    rebuild(l; data=Adapt.adapt(to, parent(l)))
end

function Adapt.adapt_structure(to, l::AbstractSampled)
    rebuild(l; data=Adapt.adapt(to, parent(l)), metadata=NoMetadata(), span=Adapt.adapt(to, span(l)))
end

function Adapt.adapt_structure(to, l::AbstractCategorical)
    rebuild(l; data=Adapt.adapt(to, parent(l)), metadata=NoMetadata())
end

# Dimension types
Adapt.adapt_structure(to, dim::Dimension) = rebuild(dim; val=Adapt.adapt(to, val(dim)))

# DimArray
function Adapt.adapt_structure(to, A::DD.AbstractDimArray)
    rebuild(A,
        data=Adapt.adapt(to, parent(A)),
        dims=Adapt.adapt(to, dims(A)),
        refdims=Adapt.adapt(to, refdims(A)),
        name=DD.Name(name(A)),
        metadata=Adapt.adapt(to, metadata(A)),
    )
end

# DimStack
Adapt.adapt_structure(to, s::DD.AbstractDimStack) = DD.maplayers(A -> Adapt.adapt(to, A), s)

end # module
