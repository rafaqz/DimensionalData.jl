abstract type AbstractDimensionalArray{T,N,D<:Tuple} <: AbstractArray{T,N} end

const AbDimArray = AbstractDimensionalArray

dims(a::AbDimArray) = a.dims
label(a::AbDimArray) = ""

# Array interface
Base.size(a::AbDimArray) = size(parent(a))
Base.iterate(a::AbDimArray, args...) = iterate(parent(a), args...)
Base.show(io::IO, a::AbDimArray) = begin
    printstyled(io, "\n", label(a), ": "; color=:red)
    show(io, typeof(a))
    show(io, parent(a))
    printstyled(io, "\n\ndims:\n"; color=:magenta)
    show(io, dims(a))
    show(io, refdims(a))
    printstyled(io, "\n\nmetadata:\n"; color=:cyan)
end

Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{<:Integer}) =
    getindex(parent(a), I...)
Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{<:Union{AbstractArray,Colon,Integer}}) =
    rebuildsliced(a, getindex(parent(a), I...), I)

Base.@propagate_inbounds Base.view(a::AbDimArray, I::Vararg{<:Union{AbstractArray,Colon,Integer}}) =
    rebuildsliced(a, view(parent(a), I...), I)
            
Base.convert(::Type{Array{T,N}}, a::AbDimArray{T,N}) where {T,N} = 
    convert(Array{T,N}, parent(a))

# Similar. TODO this need a rethink. How do we know what the new dims are?
Base.BroadcastStyle(::Type{<:AbDimArray}) = Broadcast.ArrayStyle{AbDimArray}()
# Need to cover a few type signatures to avoid ambiguity with base
Base.similar(a::AbDimArray, ::Type{T}, I::Vararg{<:Integer}) where T =
    rebuildsliced(a, similar(parent(a), T, I...), I)
Base.similar(a::AbDimArray, ::Type{T}) where T = rebuild(a, similar(parent(a), T))
Base.similar(a::AbDimArray) = rebuild(a, similar(parent(a)))
Base.similar(a::AbDimArray, ::Type{T}, I::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo},N}}) where {T,N} =
    rebuildsliced(a, similar(parent(a), T, I...), I)
Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbDimArray}}, ::Type{ElType}) where ElType =
    rebuildsliced(find_dimensional(bc), similar(Array{ElType}, axes(bc)), axes(bc))

@inline find_dimensional(bc::Base.Broadcast.Broadcasted) = find_dimensional(bc.args)
@inline find_dimensional(ext::Base.Broadcast.Extruded) = find_dimensional(ext.x)
@inline find_dimensional(args::Tuple{}) = error("dimensional array not found")
@inline find_dimensional(args::Tuple) = find_dimensional(find_dimensional(args[1]), tail(args))
@inline find_dimensional(x) = x
@inline find_dimensional(a::AbDimArray, rest) = a
@inline find_dimensional(::Any, rest) = find_dimensional(rest)


"""
A basic DimensionalArray type

Maintains and updates its dimensions through transformations
"""
struct DimensionalArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N}} <: AbstractDimensionalArray{T,N,D}
    data::A
    dims::D
    refdims::R
end
DimensionalArray(a::AbstractArray, dims; refdims=()) = 
    DimensionalArray(a, formatdims(a, dims), refdims)

# Getters
refdims(a::DimensionalArray) = a.refdims

# DimensionalArray interface
@inline rebuild(a::DimensionalArray, data, dims, refdims) = 
    DimensionalArray(data, dims, refdims)

# Array interface (AbstractDimensionalArray takes care of everything else)
Base.parent(a::DimensionalArray) = a.data

Base.@propagate_inbounds Base.setindex!(a::DimensionalArray, x, I::Vararg{<:Union{AbstractArray,Colon,Real}}) =
    setindex!(parent(a), x, I...)
