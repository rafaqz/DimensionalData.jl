const DimSetters = Union{LookupArraySetters,Type,UnionAll,Dimension,Symbol}

set(dim::Dimension, x::DimSetters) = _set(dim, x)
# Convert args/kw to dims and set
_set(dims_::DimTuple, args::Dimension...; kw...) = _set(dims_, (args..., kwdims(kw)...))
# Convert pairs to wrapped dims and set
_set(dims_::DimTuple, p::Pair, ps::Vararg{Pair}) = _set(dims_, (p, ps...))
_set(dims_::DimTuple, ps::Tuple{Vararg{Pair}}) = _set(dims_, pairdims(ps...))
# Set dims with (possibly unsorted) wrapper vals
_set(dims::DimTuple, wrappers::DimTuple) = begin
    # Check the dimension types match
    map(wrappers) do w
        hasdim(dims, w) || _wrongdimserr(dims, w)
    end
    # Missing dims return `nothing` from sortdims
    newdims = map(_set, dims, sortdims(wrappers, dims))
    # Swaps existing dims with non-nothing new dims
    swapdims(dims, newdims)
end

# Set things wrapped in dims
_set(dim::Dimension, wrapper::Dimension{<:DimSetters}) = _set(dim::Dimension, val(wrapper))
# Set the dim, checking the lookup
_set(dim::Dimension, newdim::Dimension) = _set(newdim, _set(val(dim), val(newdim)))
# Construct types
_set(dim::Dimension, ::Type{T}) where T = _set(dim, T())
_set(dim::Dimension, key::Symbol) = _set(dim, key2dim(key))
_set(dim::Dimension, dt::DimType) = basetypeof(dt)(val(dim))
_set(dim::Dimension, x) = rebuild(dim; val=_set(val(dim), x))
# Set the lookup
# Otherwise pass this on to set fields on the lookup
_set(dim::Dimension, x::LookupArrayTrait) = rebuild(dim, _set(lookup(dim), x))

# Metadata
_set(dim::Dimension, newmetadata::AllMetadata) = rebuild(dim, _set(lookup(dim), newmetadata))

_set(x::Dimension, ::Nothing) = x
_set(::Nothing, x::Dimension) = x
_set(::Nothing, ::Nothing) = nothing
_set(x, ::Nothing) = x
_set(::Nothing, x) = x

@noinline _wrongdimserr(dims, w) = throw(ArgumentError("dim $(basetypeof(w))) not in $(map(basetypeof, dims))"))
