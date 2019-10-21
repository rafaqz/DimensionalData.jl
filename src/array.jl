abstract type AbstractDimensionalArray{T,N,D<:Tuple} <: AbstractArray{T,N} end

const AbDimArray = AbstractDimensionalArray

const StandardIndices = Union{AbstractArray,Colon,Integer}

# Interface methods ############################################################

dims(A::AbDimArray) = A.dims
label(A::AbDimArray) = ""


# Array interface methods ######################################################

Base.size(A::AbDimArray) = size(parent(A))
Base.iterate(A::AbDimArray, args...) = iterate(parent(A), args...)
Base.show(io::IO, A::AbDimArray) = begin
    printstyled(io, "\n", label(A), ": "; color=:red)
    show(io, typeof(A))
    show(io, parent(A))
    printstyled(io, "\n\ndims:\n"; color=:magenta)
    show(io, dims(A))
    show(io, refdims(A))
    printstyled(io, "\n\nmetadata:\n"; color=:cyan)
end

Base.@propagate_inbounds Base.getindex(A::AbDimArray, I::Vararg{<:Integer}) =
    getindex(parent(A), I...)
Base.@propagate_inbounds Base.getindex(A::AbDimArray, I::Vararg{<:StandardIndices}) =
    rebuildsliced(A, getindex(parent(A), I...), I)

Base.@propagate_inbounds Base.view(A::AbDimArray, I::Vararg{<:StandardIndices}) =
    rebuildsliced(A, view(parent(A), I...), I)
            
Base.convert(::Type{Array{T,N}}, A::AbDimArray{T,N}) where {T,N} = 
    convert(Array{T,N}, parent(A))

Base.copy(A::AbDimArray) = rebuild(A, copy(parent(A)))
Base.copy!(dst::AbDimArray, src::AbDimArray) = copy!(parent(src), parent(dst))
Base.copy!(dst::AbDimArray, src::AbstractArray) = copy!(parent(src), dst)

Base.BroadcastStyle(::Type{<:AbDimArray}) = Broadcast.ArrayStyle{AbDimArray}()

Base.similar(A::AbDimArray) = rebuild(A, similar(parent(A)))
Base.similar(A::AbDimArray, ::Type{T}) where T = rebuild(A, similar(parent(A), T))
Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbDimArray}}, ::Type{ElType}) where ElType = begin
    A = find_dimensional(bc)
    # TODO How do we know what the new dims are?
    rebuildsliced(A, similar(Array{ElType}, axes(bc)), axes(bc))
end

# Need to cover a few type signatures to avoid ambiguity with base
# Don't remove these even though they look redundant
Base.similar(A::AbDimArray, ::Type{T}, I::Vararg{<:Integer}) where T =
    rebuildsliced(A, similar(parent(A), T, I...), I)
Base.similar(A::AbDimArray, ::Type{T}, ::Tuple{Int,Vararg{Int}}) where T = 
    rebuild(A, similar(parent(A), T))
Base.similar(A::AbDimArray, ::Type{T}, I::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo},N}}) where {T,N} =
    rebuildsliced(A, similar(parent(A), T, I...), I)

@inline find_dimensional(bc::Base.Broadcast.Broadcasted) = find_dimensional(bc.args)
@inline find_dimensional(ext::Base.Broadcast.Extruded) = find_dimensional(ext.x)
@inline find_dimensional(args::Tuple{}) = error("dimensional array not found")
@inline find_dimensional(args::Tuple) = find_dimensional(find_dimensional(args[1]), tail(args))
@inline find_dimensional(x) = x
@inline find_dimensional(A::AbDimArray, rest) = A
@inline find_dimensional(::Any, rest) = find_dimensional(rest)


# Concrete implementation ######################################################

"""
A basic DimensionalArray type

Maintains and updates its dimensions through transformations
"""
struct DimensionalArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N}} <: AbstractDimensionalArray{T,N,D}
    data::A
    dims::D
    refdims::R
end
DimensionalArray(A::AbstractArray, dims; refdims=()) = 
    DimensionalArray(A, formatdims(A, dims), refdims)

# Getters
refdims(A::DimensionalArray) = A.refdims

# DimensionalArray interface
@inline rebuild(A::DimensionalArray, data, dims, refdims) = 
    DimensionalArray(data, dims, refdims)

# Array interface (AbstractDimensionalArray takes care of everything else)
Base.parent(A::DimensionalArray) = A.data

Base.@propagate_inbounds Base.setindex!(A::DimensionalArray, x, I::Vararg{StandardIndices}) =
    setindex!(parent(A), x, I...)
