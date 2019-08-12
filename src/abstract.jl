abstract type AbstractDimensionalArray{T,N,D} <: AbstractArray{T,N} end

abstract type AbstractDimensionalDataset{N,D} end

# Array interface
Base.size(a::AbstractDimensionalArray) = size(parent(a))
Base.IndexStyle(::Type{<:AbstractDimensionalArray}) = IndexLinear()
Base.iterate(a::AbstractDimensionalArray) = iterate(parent(a))
Base.length(a::AbstractDimensionalArray) = length(parent(a))
Base.ndims(a::AbstractDimensionalArray{T,N,D}) where {T,N,D} = N
Base.show(io::IO, a::AbstractDimensionalArray) = begin
    printstyled(io, "\n", label(a), ": "; color=:red)
    show(io, typeof(a))
    show(io, parent(a))
    printstyled(io, "\n\ndims:\n"; color=:magenta)
    show(io, dims(a))
    show(io, refdims(a))
    printstyled(io, "\n\nmetadata:\n"; color=:cyan)
end


# These methods are needed to rebuild the array when normal integer dims are used.

Base.@propagate_inbounds Base.getindex(a::AbstractDimensionalArray, I::Vararg{<:Number}) =
    getindex(parent(a), I...)
Base.@propagate_inbounds Base.getindex(a::AbstractDimensionalArray, I::Vararg{<:Union{AbstractArray,Colon,Number}}) =
    rebuildsliced(a, getindex(parent(a), I...), I)

Base.@propagate_inbounds Base.setindex!(a::AbstractDimensionalArray, x, I...) =
    setindex!(parent(a), x, I...)

Base.@propagate_inbounds Base.view(a::AbstractDimensionalArray, I::Vararg{<:Union{AbstractArray,Colon,Number}}) =
    rebuildsliced(a, view(parent(a), I...), I)

for fname in [:permutedims, :transpose, :adjoint]
    @eval begin
        Base.$fname(a::AbstractDimensionalArray{T,2}) where T =
            rebuild(a, $fname(parent(a)), reverse(dims(a)), refdims(a))
    end
end
Base.permutedims(a::AbstractDimensionalArray{T,N}, perm) where {T,N} = begin
    perm = [dimnum(a, perm)...]
    rebuild(a, permutedims(parent(a), perm), a.dims[perm], refdims(a))
end
Base.convert(::Type{Array{T,N}}, a::AbstractDimensionalArray{T,N}) where {T,N} = 
    convert(Array{T,N}, parent(a))

# Similar
Base.BroadcastStyle(::Type{<:AbstractDimensionalArray}) = Broadcast.ArrayStyle{AbstractDimensionalArray}()
# Need to cover a few type signatures to avoid ambiguity with base
Base.similar(a::AbstractDimensionalArray, ::Type{T}, I::Dims) where {T,N}=
    rebuild(a, similar(parent(a), T, I...), slicedims(a, I)...)
Base.similar(a::AbstractDimensionalArray, ::Type{T},
             I::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo},N}}) where {T,N} =
    rebuildsliced(a, similar(parent(a), T, I...), I)
Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbstractDimensionalArray}}, ::Type{ElType}) where ElType = begin
    da = find_dimensional(bc)
    rebuildsliced(da, similar(Array{ElType}, axes(bc)), axes(bc))
end

find_dimensional(bc::Base.Broadcast.Broadcasted) = find_dimensional(bc.args)
find_dimensional(args::Tuple) = find_dimensional(find_dimensional(args[1]), tail(args))
find_dimensional(x) = x
find_dimensional(a::AbstractDimensionalArray, rest) = a
find_dimensional(::Any, rest) = find_dimensional(rest)




# TODO cov, cor mapslices, eachslice, reverse, sort and sort! need _methods without kwargs in base so
# we can dispatch on dims. Instead we dispatch on array type for now, which means
# these aren't used unless you inherit from AbstractDimensionalArray.

# If that can happen, these can move to dim_methods.jl and work for anything that
# passes AbstractDimension dims

Base.mapslices(f, a::AbstractDimensionalArray; dims=1, kwargs...) = begin
    dimnums = dimnum(a, dims)
    data = mapslices(f, parent(a); dims=dimnums, kwargs...)
    rebuildsliced(a, data, reduceindices(a, dimnums))
end

if VERSION > v"1.1-"
    Base.eachslice(a::AbstractDimensionalArray; dims=1, kwargs...) = begin
        dimnums = dimnum(a, dims)
        slices = eachslice(parent(a); dims=dimnums, kwargs...)
        return Base.Generator(slices) do slice
            rebuildsliced(a, slice, reduceindices(a, dimnums))
        end
    end
end

for fname in (:cor, :cov)
    @eval Statistics.$fname(a::AbstractDimensionalArray{T,2}; dims=1, kwargs...) where T = begin
        dimnums = dimnum(a, dims)
        newdata = Statistics.$fname(parent(a); dims=dimnums, kwargs...)
        newdims, newrefdims = slicedims(a, reduceindices(a, otherdimnums(a, dimnums)))
        println(dims)
        rebuild(a, newdata, (newdims[1], newdims[1]), newrefdims)
    end
end

Base.reverse(a::AbstractDimensionalArray; dims=1) = begin
    dnum = dimnum(a, dims)
    # Reverse the dimension
    newdims = replacedim_n((x, n) -> n == dnum ? basetype(x)(reverse(val(x))) : x, DimensionalData.dims(a), 1)
    # Reverse the data
    newdata = reverse(parent(a); dims=dnum)
    rebuild(a, newdata, newdims, refdims(a))
end

# Sorting will break the dimensions, maybe return a regular array?
# for fname in [:sort, :sort!]
#     @eval begin
#         $fname(a::AbstractDimensionalArray; dims=1, kwargs...) = begin
#             fname(parent(a); dims=dimnum(a, dims), kwargs...)
#         end
#     end
# end
