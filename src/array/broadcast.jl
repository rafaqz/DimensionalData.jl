import Base.Broadcast: BroadcastStyle, DefaultArrayStyle, Style


# This is a `BroadcastStyle` for AbstractAbstractDimArray's
# It preserves the dimension names.
# `S` should be the `BroadcastStyle` of the wrapped type.
# Copied from NamedDims.jl (thanks @oxinabox).
struct DimensionalStyle{S <: BroadcastStyle} <: AbstractArrayStyle{Any} end
DimensionalStyle(::S) where {S} = DimensionalStyle{S}()
DimensionalStyle(::S, ::Val{N}) where {S,N} = DimensionalStyle(S(Val(N)))
DimensionalStyle(::Val{N}) where N = DimensionalStyle{DefaultArrayStyle{N}}()
function DimensionalStyle(a::BroadcastStyle, b::BroadcastStyle)
    inner_style = BroadcastStyle(a, b)
    # if the inner style is Unknown then so is the outer style
    if inner_style isa Unknown
        return Unknown()
    else
        return DimensionalStyle(inner_style)
    end
end

function BroadcastStyle(::Type{<:AbstractDimArray{T,N,D,A}}) where {T,N,D,A}
    inner_style = typeof(BroadcastStyle(A))
    return DimensionalStyle{inner_style}()
end

BroadcastStyle(::DimensionalStyle, ::Base.Broadcast.Unknown) = Unknown()
BroadcastStyle(::Base.Broadcast.Unknown, ::DimensionalStyle) = Unknown()
BroadcastStyle(::DimensionalStyle{A}, ::DimensionalStyle{B}) where {A, B} = DimensionalStyle(A(), B())
BroadcastStyle(::DimensionalStyle{A}, b::Style) where {A} = DimensionalStyle(A(), b)
BroadcastStyle(a::Style, ::DimensionalStyle{B}) where {B} = DimensionalStyle(a, B())
BroadcastStyle(::DimensionalStyle{A}, b::Style{Tuple}) where {A} = DimensionalStyle(A(), b)
BroadcastStyle(a::Style{Tuple}, ::DimensionalStyle{B}) where {B} = DimensionalStyle(a, B())
# We need to implement copy because if the wrapper array type does not
# support setindex then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{DimensionalStyle{S}}) where S
    _dims = _broadcasted_dims(bc)
    A = _firstdimarray(bc)
    data = copy(_unwrap_broadcasted(bc))
    return if A isa Nothing || _dims isa Nothing || ndims(A) == 0
        data
    elseif data isa AbstractDimArray
        rebuild(A, parent(data), _dims, refdims(A), Symbol(""))
    else
        rebuild(A, data, _dims, refdims(A), Symbol(""))
    end
end

function Base.copyto!(dest::AbstractArray, bc::Broadcasted{DimensionalStyle{S}}) where S
    _dims = comparedims(dims(dest), _broadcasted_dims(bc); ignore_length_one=true, order=true)
    copyto!(dest, _unwrap_broadcasted(bc))
    A = _firstdimarray(bc)
    if A isa Nothing || _dims isa Nothing
        dest
    else
        rebuild(A, dest, _dims, refdims(A))
    end
end
function Base.copyto!(dest::AbstractDimArray, bc::Broadcasted{DimensionalStyle{S}}) where S
    _dims = comparedims(dims(dest), _broadcasted_dims(bc); ignore_length_one=true, order=true)
    copyto!(parent(dest), _unwrap_broadcasted(bc))
    A = _firstdimarray(bc)
    if A isa Nothing || _dims isa Nothing
        dest
    else
        rebuild(A, parent(dest), _dims, refdims(A))
    end
end

# This is needed for GPUs to prevent scalar indexing problems for things like
# d .= 1:10
function Base.copyto!(dest::AbstractDimArray, bc::Broadcasted{Nothing})
    copyto!(parent(dest), bc)
    dest
end

# Needed for things like d .= 0 when on the GPU
function Base.copyto!(dest::AbstractDimArray, bc::Broadcasted{<:Broadcast.AbstractArrayStyle{0}})
    copyto!(parent(dest), bc)
    dest
end


function Base.similar(bc::Broadcast.Broadcasted{DimensionalStyle{S}}, ::Type{T}) where {S,T}
    A = _firstdimarray(bc)
    rebuildsliced(A, similar(_unwrap_broadcasted(bc), T, axes(bc)...), axes(bc), Symbol(""))
end

# Recursively unwraps `AbstractDimArray`s and `DimensionalStyle`s.
# replacing the `AbstractDimArray`s with the wrapped array,
# and `DimensionalStyle` with the wrapped `BroadcastStyle`.
function _unwrap_broadcasted(bc::Broadcasted{DimensionalStyle{S}}) where S
    innerargs = map(_unwrap_broadcasted, bc.args)
    return Broadcasted{S}(bc.f, innerargs)
end
_unwrap_broadcasted(x) = x
_unwrap_broadcasted(nda::AbstractDimArray) = parent(nda)

# Get the first dimensional array in the broadcast
_firstdimarray(x::Broadcasted) = _firstdimarray(x.args)
_firstdimarray(x::Tuple{<:AbstractDimArray,Vararg}) = x[1]
_firstdimarray(ext::Base.Broadcast.Extruded) = _firstdimarray(ext.x)
function _firstdimarray(x::Tuple{<:Broadcasted,Vararg})
    found = _firstdimarray(x[1])
    if found isa Nothing
        _firstdimarray(tail(x))
    else
        found
    end
end
_firstdimarray(x::Tuple) = _firstdimarray(tail(x))
_firstdimarray(x::Tuple{}) = nothing

# Make sure all arrays have the same dims, and return them
_broadcasted_dims(bc::Broadcasted) = _broadcasted_dims(bc.args...)
_broadcasted_dims(a, bs...) =
    comparedims(_broadcasted_dims(a), _broadcasted_dims(bs...); ignore_length_one=true, order=true)
_broadcasted_dims(a::AbstractBasicDimArray) = dims(a)
_broadcasted_dims(a) = nothing
