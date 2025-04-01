const DimSetters = Union{Lookup,LookupSetters,Tuple,Dimension,Symbol}

set(dim::Dimension, x::DimSetters) = _set(Safe(), dim, x)
set(dims::DimTuple, x::DimSetters) = _set(Safe(), dims, x)
set(dims::DimTuple, p::Pair) = _set(Safe(), dims, p)
set(dims::DimTuple, a1::Union{Dimension,Pair}, a2::Union{Dimension,Pair}, args::Union{Dimension,Pair}...) =
    _set(Safe(), dims, a1, a2, args...)

unsafe_set(dim::Dimension, x::DimSetters) = _set(Unsafe(), dim, x)
unsafe_set(dims::DimTuple, x::DimSetters) = _set(Unsafe(), dims, x)
unsafe_set(dims::DimTuple, p::Pair) = _set(Unsafe(), dims, p)
unsafe_set(dims::DimTuple, a1::Union{Dimension,Pair}, a2::Union{Dimension,Pair}, args::Union{Dimension,Pair}...) =
    _set(Unsafe(), dims, a1, a2, args...)

_set(s::Safety, dims::DimTuple, l::LookupSetters) =
    _set(s, dims, map(d -> rebuild(d, l), dims)...)

# Convert pairs to wrapped dims and set
_set(s::Safety, dims::DimTuple, p::Pair, ps::Pair...) =
    _set(s, dims, (p, ps...))
_set(s::Safety, dims::DimTuple, ps::Tuple{Vararg{Pair}}) =
    _set(s, dims, pairs2dims(ps...))
_set(s::Safety, dims::DimTuple, ::Tuple{}) = dims
_set(s::Safety, dims::DimTuple, newdims::Dimension...) =
    _set(s, dims, newdims)
# Set dims with (possibly unsorted) wrapper vals
_set(s::Safety, dims::DimTuple, wrappers::DimTuple) = begin
    # Check the dimension types match
    map(wrappers) do w
        hasdim(dims, w) || _wrongdimserr(dims, w)
    end
    # Missing dims return `nothing` from sortdims
    newdims = map(dims, sortdims(wrappers, dims)) do d, w
        _set(s, d, w)
    end
    # Swaps existing dims with non-nothing new dims
    swapdims(dims, newdims)
end

# Set things wrapped in dims
_set(s::Safety, dim::Dimension, wrapper::Dimension{<:DimSetters}) = begin
    rewrapped = _set(s, dim, basetypeof(wrapper))
    _set(s, rewrapped, val(wrapper))
end
_set(s::Safety, dim::Dimension, l::Union{Lookup,LookupSetters}) = begin
    re = rebuild(dim, _set(s, val(dim), l))
    @show typeof(re) typeof(val(dim))
    re
end
# Set the dim, checking the lookup
_set(s::Safety, dim::Dimension, newdim::Dimension) =
    _set(s, newdim, _set(s, val(dim), val(newdim)))
_set(s::Safety, dim::Dimension, newdim::Dimension{<:Type}) =
    _set(s, dim, val(newdim)())
_set(s::Safety, dim::Dimension, key::Symbol) = _set(s, dim, name2dim(key))
_set(s::Safety, dim::Dimension, x) = rebuild(dim, _set(s, val(dim), x))
_set(s::Safety, dim::Dimension, ::Type{T}) where T = _set(s, dim, T())

# Metadata
_set(s::Safety, dim::Dimension, newmetadata::AllMetadata) =
    rebuild(dim, _set(s, lookup(dim), newmetadata))

_set(::Safety, x::Dimension, ::Nothing) = x
_set(::Safety, ::Nothing, x::Dimension) = x
_set(::Safety, ::Nothing, ::Nothing) = nothing
_set(::Safety, x, ::Nothing) = x
_set(::Safety, ::Nothing, x) = x
# For ambiguity
_set(::Safety, dims::DimTuple, ::Nothing) = dims
_set(::Safety, dims::Lookup, ::Nothing) = dims

@noinline _wrongdimserr(dims, w) =
    throw(ArgumentError("dim $(basetypeof(w))) not in $(map(basetypeof, dims))"))
