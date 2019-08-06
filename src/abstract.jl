
abstract type AbstractDimensionalArray{T,N,D} <: AbstractArray{T,N} end

abstract type AbstractDimensionalDataset{N,D} end


# Base methods

Base.size(a::AbstractDimensionalArray) = size(parent(a))
Base.IndexStyle(::Type{<:AbstractDimensionalArray}) = IndexLinear()
Base.iterate(a::AbstractDimensionalArray) = iterate(parent(a))
Base.length(a::AbstractDimensionalArray) = length(parent(a))
Base.ndims(a::AbstractDimensionalArray{T,N,D}) where {T,N,D} = N 


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

Base.permutedims(a::AbstractDimensionalArray{T,2}) where T =  
    rebuild(a, permutedims(parent(a)), reverse(dims(a)), refdims(a))
Base.permutedims(a::AbstractDimensionalArray{T,N}, dims) where {T,N} = begin
    dimnums = [dimnum(a, dims)...]
    rebuild(a, permutedims(parent(a), dimnums), a.dims[dimnums], refdims(a))
end


# General methods

const DimData = Union{AbstractDimensionalArray, AbstractDimensionalDataset}

Base.similar(a::DimData, ::Type{T}) where T = 
    similar(a, T, replacedimval(x -> OneTo(length(x)), dims(a)))
Base.similar(a::DimData, ::Type{T}, I::Tuple{Int64,Vararg{Int64,N}}) where {T,N}= 
    rebuild(a, similar(parent(a), T, I...), slicedims(a, I)...)
Base.similar(a::DimData, ::Type{T}, I::Tuple{Union{Integer, OneTo},Vararg{Union{Integer, OneTo},N}}) where {T,N} = 
    rebuild(a, similar(parent(a), T, I...), slicedims(a, I)...)

label(a::DimData) = string(name(a), " ", getstring(units(a)))

# hasdim(a::DimData, dim::Type) = 

# bounds(a::AbstractDimensionalArray, dims::Vararg{<:AbstractDimensionDim}) = bounds(a, dimnum(a, dims)...)
# bounds(a::AbstractDimensionalArray, args::Vararg{Integer}) = bounds.(Ref(a), args)  
# bounds(a::AbstractDimensionalArray, i::Integer) = bounds(dims(a)[i])
