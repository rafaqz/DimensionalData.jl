
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
        @propagate_inbounds Base.$f(l::Lookup, i::Union{AbstractArray,Colon}) = 
            rebuild(l; data=Base.$f(parent(l), i))
        # span may need its step size or bounds updated
        @propagate_inbounds function Base.$f(l::AbstractSampled, i::AbstractArray)
            i1 = Base.to_indices(l, (i,))[1]
            rebuild(l; data=Base.$f(parent(l), i1), span=slicespan(l, i1))
        end
        # With ordered lookups AbstractArray{Integer} needs to be ordered
        @propagate_inbounds function Base.$f(l::AbstractSampled, i::AbstractArray{<:Integer})
            @boundscheck checkorder(l, i)
            i1 = only(Base.to_indices(l, (i,)))
            rebuild(l; data=Base.$f(parent(l), i1), span=slicespan(l, i1))
        end
        @propagate_inbounds function Base.$f(l::AbstractCategorical, i::AbstractArray{<:Integer})
            @boundscheck checkorder(l, i)
            rebuild(l; data=Base.$f(parent(l), i))
        end
        # Selector gets processed with `selectindices`
        @propagate_inbounds Base.$f(l::Lookup, i::SelectorOrInterval) = 
            Base.$f(l, selectindices(l, i))
        # Everything else we just index the parent and check if the result is an array
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
            Use `@inbounds` to avoid this check inside a specific function, or `DimensionalData.strict_order!(false)` globally.
        """))
    end
end
# Avoid checks for Bool, Bool indexing is ordered
checkorder(l, i::AbstractArray{Bool}) = nothing
