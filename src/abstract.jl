
abstract type AbstractDimensionalArray{T,N,D} <: AbstractArray{T,N} end

abstract type AbstractDimensionalDataset{N,D} end


# Base methods

Base.size(a::AbstractDimensionalArray) = size(parent(a))
Base.IndexStyle(::Type{<:AbstractDimensionalArray}) = IndexLinear()
Base.iterate(a::AbstractDimensionalArray) = iterate(parent(a))
Base.length(a::AbstractDimensionalArray) = length(parent(a))
Base.ndims(a::AbstractDimensionalArray{T,N,D}) where {T,N,D} = N 
Base.zero(a::AbstractDimensionalArray) = rebuild(a, zero(parent(a)), dims(a), refdims(a))
Base.one(a::AbstractDimensionalArray) = rebuild(a, one(parent(a)), dims(a), refdims(a))

Base.ndims(a::AbstractDimensionalDataset{N,D}) where {N,D} = N 

# These methods allow wrapping the output with the array type
# and updating the correct dimensions, by adding a method for rebuild()

# Array methods

Base.@propagate_inbounds Base.getindex(a::AbstractDimensionalArray, I::Vararg{<:Number}) = getindex(parent(a), I...)
Base.@propagate_inbounds Base.getindex(a::AbstractDimensionalArray, I::Vararg{<:Union{AbstractArray,Colon,Number}}) = 
    rebuild(a, getindex(parent(a), I...), slicedims(a, I)...)

Base.@propagate_inbounds Base.setindex!(a::AbstractDimensionalArray, x, I...) = setindex!(parent(a), x, I...)

Base.@propagate_inbounds Base.view(a::AbstractDimensionalArray, I::Vararg{<:Union{AbstractArray,Colon,Number}}) = 
    rebuild(a, view(parent(a), I...), slicedims(a, I)...)

for fname in [:permutedims, :transpose, :adjoint]
    @eval begin
        Base.$fname(a::AbstractDimensionalArray{T,2}) where T =  
            rebuild(a, $fname(parent(a)), reverse(dims(a)), refdims(a))
        Base.$fname(a::AbstractDimensionalArray{T,N}, dims) where {T,N} = begin
            dimnums = [dimnum(a, dims)...]
            rebuild(a, $fname(parent(a), dimnums), a.dims[dimnums], refdims(a))
        end
    end
end

Base.similar(a::AbstractDimensionalArray, ::Type{T}) where T = 
    similar(a, T, mapdims(x -> OneTo(length(x)), dims(a)))
Base.similar(a::AbstractDimensionalArray, ::Type{T}, I::Tuple{Int64,Vararg{Int64,N}}) where {T,N}= 
    rebuild(a, similar(parent(a), T, I...), slicedims(a, I)...)
Base.similar(a::AbstractDimensionalArray, ::Type{T}, I::Tuple{Union{Integer, OneTo},Vararg{Union{Integer, OneTo},N}}) where {T,N} = 
    rebuild(a, similar(parent(a), T, I...), slicedims(a, I)...)

# General
label(a) = string(name(a), " ", getstring(units(a)))
