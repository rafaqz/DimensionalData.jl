import Statistics: _mean, _median, _std, _var, cov, cor
import Base: _sum, _prod, _maximum, _minimum, _mapreduce_dim, _accumulate!

for fname in [:sum, :prod, :maximum, :minimum, :mean]
    _fname = Symbol('_', fname)
    @eval begin
        ($_fname)(a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} =
            ($_fname)(a, dimnum(a, dims))
        ($_fname)(f, a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} = 
            ($_fname)(f, a, dimnum(a, dims))
    end
end

_median(a::AbstractArray, dims::AllDimensions) = _median(a, dimnum(a, dims))
_mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDimensions) =
    _mapreduce_dim(f, op, nt, A, dimnum(A, dims))
_accumulate!(op, B, A, dims::AllDimensions, init::Union{Nothing, Some}) =
    _accumulate!(op, B, A, dimnum(A, dims), init)

# These need to be wrapped afterwards
for fname in [:std, :var]
    _fname = Symbol('_', fname)
    @eval function ($_fname)(a::AbstractArray{T,N} , corrected::Bool, mean, dimz::AllDimensions) where {T,N}
        dimnums = dimnum(a, dimz)
        otherdims = dims(a)[setdiff(collect(1:N), dimnums)] 
        otherindices = dims2indices(a, map(o->basetype(o)(), otherdims), 1)
        data = ($_fname)(a, corrected, mean, dimnums)[otherindices...]
        rebuild(a, data, slicedims(a, otherindices)...)
    end
end

# TODO cov, cor mapslices, eachslice, sort and sort! need _methods with kwargs in base so 
# we can dispatch on dims. Instead we dispatch on array type for now, which means
# these aren't used unless you inherit from AbstractDimensionalArray.

# for fname in [:sort, :sort!]
#     @eval begin
#         $fname(a::AbstractDimensionalArray; dims, kwargs...) = begin
#             dimnums = dimnum(a, dims)
#             data = fname(parent(a); dims=dimnums, kwargs...)
#             rebuild(a, data, )
#         end
#         $fname(a::AbstractDimensionalArray{L, T, 1}; kwargs...) where {L, T} = begin
#             data = fname(parent(a); kwargs...)
#             rebuild(a, data, )
#         end
#     end
# end

mapslices(f, a::AbstractDimensionalArray; dims, kwargs...) = 
    mapslices(f, parent(a); dims=dimnum(a, dims), kwargs...)

# if VERSION > v"1.1-"
#     function Base.eachslice(a::AbstractDimensionalArray{L}; dims, kwargs...) where L
#         dimnums = dimnum(a, dims)
#         slices = eachslice(parent(a); dims=dimnums, kwargs...)
#         return Base.Generator(slices) do slice
#             rebuild(a, slice, slicedims(a, dimsnums)...)
#         end
#     end
# end

# for fun in (:cor, :cov)
#     @eval $fname(a::AbstractDimensionalArray{L,T,2}; dims=1, kwargs...) where {L,T} = begin
#         dimnums = dimnum(a, dims)
#         data = Statistics.$fun(parent(a); dims=dimnums, kwargs...)
#         rebuild(a, data, slicedims(a, ))
#     end
# end

