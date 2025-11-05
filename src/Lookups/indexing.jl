
const STRICT_ORDER_CHECKS = Ref(true)
const STRICT_ORDER_DOCS = """
By default indexing with Vector{Int} is required 
to be ordered if lookups are ordered to avoid broken lookups.
`@inbounds` annotations skip this check, but in some cases where 
outputs are not used you may wish to disable it completely.
"""

"""
    strict_order()

Check if strick broadcasting checks are active.

$STRICT_ORDER_DOCS
"""
strict_order() = STRICT_ORDER_CHECKS[]

"""
    strict_order!(x::Bool)

Set global AbstractVector{Int} indexing checks to `strict`, or not, for all `AbstractDimArray`.

$STRICT_ORDER_DOCS
"""
strict_order!(x::Bool) = STRICT_ORDER_CHECKS[] = x


for f in (:getindex, :view, :dotview)
    @eval begin
        # Int and CartesianIndex forward to the parent
        @propagate_inbounds Base.$f(l::Lookup, i::Union{Int,CartesianIndex}) =
            Base.$f(parent(l), i)
        # AbstractArray, Colon and CartesianIndices: the lookup is rebuilt around a new parent
        @propagate_inbounds Base.$f(l::Lookup, i::Union{AbstractVector,Colon}) = 
            rebuild(l; data=Base.$f(parent(l), i))
        @propagate_inbounds function Base.$f(l::Union{Sampled,Categorical}, i::AbstractVector{Int})
            @boundscheck checkorder(l, i)
            # Allow skipping this check with @inbounds
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

function checkorder(l, i)
    if strict_order() && isordered(l)
        issorted(i) || throw(ArgumentError("""
            For `ForwardOrdered` or `ReverseOrdered` lookups, indices of `AbstractVector{Int}` must be in ascending order. 
            Use `@inbounds` to avoid this check locally, and `DimensionalData.strict_order!(false)` globally.
        """))
    end
end
