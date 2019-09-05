abstract type AbstractDimensionalArray{T,N,D} <: AbstractArray{T,N} end

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

rebuildsliced(a, data, I) = rebuild(a, data, slicedims(a, I)...)

# These methods are needed to rebuild the array when normal integer dims are used.

Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{<:Integer}) =
    getindex(parent(a), I...)
Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{<:Union{AbstractArray,Colon,Integer}}) =
    rebuildsliced(a, getindex(parent(a), I...), I)

Base.@propagate_inbounds Base.setindex!(a::AbDimArray, x, I...) =
    setindex!(parent(a), x, I...)

Base.@propagate_inbounds Base.view(a::AbDimArray, I::Vararg{<:Union{AbstractArray,Colon,Integer}}) =
    rebuildsliced(a, view(parent(a), I...), I)

for fname in [:permutedims, :transpose, :adjoint]
    @eval begin
        @inline Base.$fname(a::AbDimArray{T,2}) where T =
            rebuild(a, $fname(parent(a)), reverse(dims(a)), refdims(a))
    end
end

@inline Base.permutedims(a::AbDimArray{T,N}, perm) where {T,N} = 
    rebuild(a, permutedims(parent(a), dimnum(a, perm)), 
            permutedims(dims(a), perm), refdims(a))
            
Base.convert(::Type{Array{T,N}}, a::AbDimArray{T,N}) where {T,N} = 
    convert(Array{T,N}, parent(a))

# Similar
@inline Base.BroadcastStyle(::Type{<:AbDimArray}) = Broadcast.ArrayStyle{AbDimArray}()
# Need to cover a few type signatures to avoid ambiguity with base
@inline Base.similar(a::AbDimArray) where {T,N}=
    rebuild(a, similar(parent(a)), dims(a), refdims(a))
@inline Base.similar(a::AbDimArray, ::Type{T}, I::Dims) where {T,N}=
    rebuild(a, similar(parent(a), T, I...), slicedims(a, I)...)
@inline Base.similar(a::AbDimArray, ::Type{T}, I::Tuple{Union{Integer,OneTo},Vararg{Union{Integer,OneTo},N}}) where {T,N} =
    rebuildsliced(a, similar(parent(a), T, I...), I)
@inline Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbDimArray}}, ::Type{ElType}) where ElType = begin
    da = find_dimensional(bc)
    rebuildsliced(da, similar(Array{ElType}, axes(bc)), axes(bc))
end

@inline find_dimensional(bc::Base.Broadcast.Broadcasted) = find_dimensional(bc.args)
@inline find_dimensional(args::Tuple) = find_dimensional(find_dimensional(args[1]), tail(args))
@inline find_dimensional(x) = x
@inline find_dimensional(a::AbDimArray, rest) = a
@inline find_dimensional(::Any, rest) = find_dimensional(rest)


# TODO cov, cor mapslices, eachslice, reverse, sort and sort! need _methods without kwargs in base so
# we can dispatch on dims. Instead we dispatch on array type for now, which means
# these aren't used unless you inherit from AbDimArray.

# If that can happen, these can move to dim_methods.jl and work for anything that
# passes AbstractDimension dims

Base.mapslices(f, a::AbDimArray; dims=1, kwargs...) = begin
    data = mapslices(f, parent(a); dims=dimnum(a, dims), kwargs...)
    rebuildsliced(a, data, dims2indices(a, reducedims(dims)))
end

# This is copied from base as we can't efficiently wrap this function
# through the kwarg with a rebuild in the generator. Doing it this way 
# wierdly makes it 2x faster to use a dim than an integer.
if VERSION > v"1.1-"
    Base.eachslice(A::AbDimArray; dims=1, kwargs...) = begin
        if dims isa Tuple && length(dims) == 1 
            throw(ArgumentError("only single dimensions are supported"))
        end
        dim = first(dimnum(A, dims))
        dim <= ndims(A) || throw(DimensionMismatch("A doesn't have $dim dimensions"))
        idx1, idx2 = ntuple(d->(:), dim-1), ntuple(d->(:), ndims(A)-dim)
        return (view(A, idx1..., i, idx2...) for i in axes(A, dim))
    end
end

for fname in (:cor, :cov)
    @eval Statistics.$fname(a::AbDimArray{T,2}; dims=1, kwargs...) where T = begin
        newdata = Statistics.$fname(parent(a); dims=dimnum(a, dims), kwargs...)
        I = dims2indices(a, dims, 1)
        newdims, newrefdims = slicedims(a, I)
        rebuild(a, newdata, (newdims[1], newdims[1]), newrefdims)
    end
end

Base.reverse(a::AbDimArray{T,N}; dims=1) where {T,N} = begin
    dnum = dimnum(a, dims)
    # Reverse the dimension. TODO: make this type stable
    newdims = Tuple(map((x, n) -> n == dnum ? basetype(x)(reverse(val(x))) : x, DimensionalData.dims(a), 1:N))
    # Reverse the data
    newdata = reverse(parent(a); dims=dnum)
    rebuild(a, newdata, newdims, refdims(a))
end



"""
A basic DimensionalArray type

Maintains and updates its dimensions through transformations
"""
struct DimensionalArray{T,N,D,R,A<:AbstractArray{T,N}} <: AbstractDimensionalArray{T,N,D}
    data::A
    dims::D
    refdims::R
end
@inline DimensionalArray(a::AbstractArray{T,N}, dims; refdims=()) where {T,N} =
    DimensionalArray(a, formatdims(a, dims), refdims)

# Array interface (AbstractDimensionalArray takes care of everything else)
@inline Base.parent(a::DimensionalArray) = a.data

# DimensionalArray interface
@inline rebuild(a::DimensionalArray, data, dims, refdims) = 
    DimensionalArray(data, dims, refdims)

@inline refdims(a::DimensionalArray) = a.refdims
