
"""
    DimensionalStyle{S}
This is a `BroadcastStyle` for AbstractAbstractDimensionalArray's
It preserves the dimension names.
`S` should be the `BroadcastStyle` of the wrapped type.

Copied from NamedDims.jl. Thanks @oxinabox.
"""
struct DimensionalStyle{S <: BroadcastStyle} <: AbstractArrayStyle{Any} end
DimensionalStyle(::S) where {S} = DimensionalStyle{S}()
DimensionalStyle(::S, ::Val{N}) where {S,N} = DimensionalStyle(S(Val(N)))
DimensionalStyle(::Val{N}) where N = DimensionalStyle{DefaultArrayStyle{N}}()
DimensionalStyle(a::BroadcastStyle, b::BroadcastStyle) = begin
    inner_style = BroadcastStyle(a, b)
    # if the inner style is Unknown then so is the outer style
    if inner_style isa Unknown
        return Unknown()
    else
        return DimensionalStyle(inner_style)
    end
end

Base.BroadcastStyle(::Type{<:AbstractDimensionalArray{T,N,D,A}}) where {T,N,D,A} = begin
    inner_style = typeof(BroadcastStyle(A))
    return DimensionalStyle{inner_style}()
end


Base.BroadcastStyle(::DimensionalStyle{A}, ::DimensionalStyle{B}) where {A, B} = DimensionalStyle(A(), B())
Base.BroadcastStyle(::DimensionalStyle{A}, b::BroadcastStyle) where {A, B} = DimensionalStyle(A(), b)
Base.BroadcastStyle(a::A, ::DimensionalStyle{B}) where {A, B} = DimensionalStyle(a, B())
Base.BroadcastStyle(::DimensionalStyle{A}, b::DefaultArrayStyle) where {A} = DimensionalStyle(A(), b)
Base.BroadcastStyle(a::AbstractArrayStyle{M}, ::DimensionalStyle{B}) where {B,M} = DimensionalStyle(a, B())


# We need to implement copy because if the wrapper array type does not support setindex
# then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{DimensionalStyle{S}}) where S
    _dims = _broadcasted_dims(bc)
    A = _firstdimarray(bc)
    data = copy(_unwrap_broadcasted(bc))
    return if A isa Nothing || _dims isa Nothing 
        data 
    else
        rebuild(A, data, _dims)
    end
end

function Base.copyto!(dest::AbstractArray, bc::Broadcasted{DimensionalStyle{S}}) where S
    _dims = comparedims(dims(dest), _broadcasted_dims(bc))
    copyto!(dest, _unwrap_broadcasted(bc))
    A = _firstdimarray(bc)
    return if A isa Nothing || _dims isa Nothing 
        dest 
    else
        rebuild(A, data(dest), _dims)
    end
end

Base.BroadcastStyle(::Type{<:AbDimArray}) = Broadcast.ArrayStyle{AbDimArray}()

# Recursively unwraps `AbstractDimensionalArray`s and `DimensionalStyle`s.
# replacing the `AbstractDimensionalArray`s with the wrapped array,
# and `DimensionalStyle` with the wrapped `BroadcastStyle`.
_unwrap_broadcasted(bc::Broadcasted{DimensionalStyle{S}}) where S = begin
    innerargs = map(_unwrap_broadcasted, bc.args)
    return Broadcasted{S}(bc.f, innerargs)
end
_unwrap_broadcasted(x) = x
_unwrap_broadcasted(nda::AbstractDimensionalArray) = data(nda)

# Get the first dimensional array inthe broadcast
_firstdimarray(x::Broadcasted) = _firstdimarray(x.args)
_firstdimarray(x::Tuple{<:AbDimArray,Vararg}) = x[1] 
_firstdimarray(x::Tuple) = _firstdimarray(tail(x))
_firstdimarray(x::Tuple{}) = nothing

# Make sure all arrays have the same dims, and return them
_broadcasted_dims(bc::Broadcasted) = _broadcasted_dims(bc.args...)
_broadcasted_dims(a, bs...) = comparedims(_broadcasted_dims(a), _broadcasted_dims(bs...))
_broadcasted_dims(a::AbstractDimensionalArray) = dims(a)
_broadcasted_dims(a) = nothing
