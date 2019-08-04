# Base methods

# We handle getindex() and view() called with AbstractGeoDim args,
# for any AbstractGeoArray.
#
# Dims are put in order with missing dims filled with Colon().
# Concrete types can mostly ignore Dims, except args... for view()
# and getindex() must have specific types to avoid abimguity.

Base.@propagate_inbounds Base.getindex(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) = getindex(a, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.getindex(a::AbstractGeoArray, I::Vararg{<:Number}) = getindex(parent(a), I...)
Base.@propagate_inbounds Base.getindex(a::AbstractGeoArray) = getindex(parent(a))
Base.@propagate_inbounds Base.getindex(a::AbstractGeoArray, I::Vararg{<:Union{AbstractArray,Colon,Number}}) = begin
    data = getindex(parent(a), I...)
    newdims, newrefdims = slicedim(a, I)
    rebuild(a, data, newdims, (refdims(a)..., newrefdims...))
end

Base.@propagate_inbounds Base.setindex!(a::AbstractGeoArray, x, dims::Vararg{<:AbstractGeoDim}) = setindex!(a, x, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.setindex!(a::AbstractGeoArray, x, I...) = setindex!(parent(a), x, I...)

Base.@propagate_inbounds Base.view(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) = view(a, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.view(a::AbstractGeoArray, I::Vararg{<:Union{AbstractArray,Colon,Number}}) = begin
    v = view(parent(a), I...) 
    newdims, newrefdims = slicedim(a, I)
    rebuild(a, v, newdims, (refdims(a)..., newrefdims...))
end


Base.similar(a::AbstractGeoArray, ::Type{T}) where T = 
    similar(a, T, replacedimval(x -> OneTo(length(x)), dims(a)))
Base.similar(a::AbstractGeoArray, ::Type{T}, dims::GeoDims) where T = 
    similar(a, T, dims2indices(a, dims))
Base.similar(a::AbstractGeoArray, ::Type{T}, I::Tuple{Int64,Vararg{Int64,N}}) where {T,N}= begin
    newdata = similar(parent(a), T, I...)
    newdims, newrefdims = slicedim(a, I)
    rebuild(a, newdata, newdims, (refdims(wa)..., newrefdims...,))
end
Base.similar(a::AbstractGeoArray, ::Type{T}, I::Tuple{Union{Integer, OneTo},Vararg{Union{Integer, OneTo},N}}) where {T,N} = begin
    newdata = similar(parent(a), T, I...)
    newdims, newrefdims = slicedim(a, I)
    rebuild(a, newdata, newdims, (refdims(a)..., newrefdims...,))
end

Base.accumulate(f, A::AbstractGeoArray, dims::Tuple{<:AbstractGeoDim, Vararg}) =
    accumulate(f, A, dimnum(a, dims))

Base.permutedims(a::AbstractGeoArray{T,2}) where T =  
    rebuild(a, permutedims(parent(a)), reverse(dims(a)), refdims(a))
Base.permutedims(a::AbstractGeoArray, dims::GeoDims) = permutedims(a, dimnum(a, dims))
Base.permutedims(a::AbstractGeoArray{T,N}, dims) where {T,N} = begin
    dimnums = [dimnum(a, dims)...]
    rebuild(a, permutedims(parent(a), dimnums), a.dims[dimnums], refdims(a))
end

Base.size(a::AbstractGeoArray) = size(parent(a))
Base.IndexStyle(::Type{<:AbstractGeoArray}) = IndexLinear()
Base.iterate(a::AbstractGeoArray) = iterate(parent(a))
Base.length(a::AbstractGeoArray) = length(parent(a))


# Statistics methods
import Statistics: _mean, _median, _std, _var
import Base: _sum, _prod, _maximum, _minimum, _mapreduce_dim

@inline others(a, d, n) = begin
    axes = setdiff(collect(1:n), dimnum(a, d))
    otherdims = dims(a)[axes] 
    otherindices = dims2indices(a, map(o->basetype(o)(), otherdims), 1)
    otherdims, otherindices
end

for fname in [:sum, :prod, :maximum, :minimum, :mean]
    _fname = Symbol('_', fname)
    @eval begin
        @inline ($_fname)(a::AbstractGeoArray{T,N}, dims::GeoDims) where {T,N} = begin
            ($_fname)(a, dimnum(a, dims))
        end
        @inline ($_fname)(f, a::AbstractGeoArray{T,N}, dims::GeoDims) where {T,N} = begin
            ($_fname)(f, a, dimnum(a, dims))
        end
    end
end

@inline _median(a::AbstractGeoArray, dims::GeoDims) = _median(a, dimnum(a, dims))
@inline _mapreduce_dim(f, op, nt, A::AbstractArray, dims::GeoDims) =
    _mapreduce_dim(f, op, nt, A, dimnum(dims))


for fname in [:std, :var]
    _fname = Symbol('_', fname)
    @eval begin
        ($_fname)(a::AbstractGeoArray{T,N} , corrected::Bool, mean, dims::GeoDims) where {T,N} = begin
            otherdims, otherindices = others(a, dims, N)
            newdims, newrefdims = slicedim(a, otherindices)
            newdata = ($_fname)(a, corrected, mean, dimnum(a, dims))[otherindices...]
            rebuild(a, newdata, newdims, newrefdims)
        end
    end
end

# TODO cov, cor need _cov and _cor methods in base so we can dispatch on dims

# GeoDataBase methods

# FIXME

abstract type AbstractSelectionMode end

struct Nearest <: AbstractSelectionMode end
struct Contained <: AbstractSelectionMode end
struct Exact <: AbstractSelectionMode end
struct Interpolated <: AbstractSelectionMode end


extract(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}; mode=Nearest()) =
    extract(a, dims2indices(dimtype(a), dims)...; mode=mode)

dimname(a::AbstractGeoArray) = dimname.(dimtype(a).parameters)

dimtype(a::AbstractGeoArray{T,N,D}) where {T,N,D} = D

# hasdim(a::AbstractGeoArray, dim::Type) = dim in dimtype(a).parameters

sortdims(a::AbstractGeoArray, dims::Tuple) = sortdims(dimtype(a), dims)

slicedim(a::AbstractGeoArray, I::Tuple) = slicedim(dims(a), I)

dims2indices(a::AbstractGeoArray, dims::Tuple, args...) = dims2indices(dimtype(a), dims, args...)

dimnum(a::AbstractGeoArray, dims) = dimnum(dimtype(a), dims)

bounds(a::AbstractGeoArray, dims::Vararg{<:AbstractGeoDim}) = bounds(a, dimnum(a, dims)...)
bounds(a::AbstractGeoArray, args::Vararg{Integer}) = bounds.(Ref(a), args)  
bounds(a::AbstractGeoArray, i::Integer) = bounds(dims(a)[i])

(::Type{T})(a::AbstractGeoArray) where T<:AbstractGeoDim = T(dims(a)[dimnum(a, T())])
