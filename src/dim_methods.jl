# Dimension reduction methods where dims are an argument
# targeting underscore _methods so we can use dispatch ont the dims arg

import Statistics: _mean, _median, _std, _var
import Base: _sum, _prod, _maximum, _minimum, _mapreduce_dim, _accumulate!
# These are a stop-gap until we can dispatch on dims
import Statistics: cov, cor
import Base: mapslices, eachslice

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

# Adding a broadcast style broke this
for fname in [:std, :var]
    _fname = Symbol('_', fname)
    @eval function ($_fname)(a::AbstractArray{T,N} , corrected::Bool, mean, dims::AllDimensions) where {T,N}
        dimnums = dimnum(a, dims)
        data = ($_fname)(a, corrected, mean, dimnums)
        rebuild(a, data, slicedims(a, reduceindices(a, dimnums))...)
    end
end

# TODO cov, cor mapslices, eachslice, sort and sort! need _methods without kwargs in base so
# we can dispatch on dims. Instead we dispatch on array type for now, which means
# these aren't used unless you inherit from AbstractDimensionalArray.

mapslices(f, a::AbstractDimensionalArray; dims=1, kwargs...) = begin
    dimnums = dimnum(a, dims)
    data = mapslices(f, parent(a); dims=dimnums, kwargs...)
    rebuild(a, data, slicedims(a, reduceindices(a, dimnums))...)
end

if VERSION > v"1.1-"
    eachslice(a::AbstractDimensionalArray; dims=1, kwargs...) = begin
        dimnums = dimnum(a, dims)
        slices = eachslice(parent(a); dims=dimnums, kwargs...)
        return Base.Generator(slices) do slice
            rebuild(a, slice, slicedims(a, reduceindices(a, dimnums))...)
        end
    end
end

# for fname in (:cor, :cov)
#     @eval $fname(a::AbstractDimensionalArray; dims=1, kwargs...) = begin
#         dimnums = dimnum(a, dims)
#         data = Statistics.$fname(parent(a); dims=dimnums, kwargs...)
#         rebuild(a, data, )
#     end
# end

# for fname in [:sort, :sort!]
#     @eval begin
#         $fname(a::AbstractDimensionalArray; dims, kwargs...) = begin
#             dimnums = dimnum(a, dims)
#             data = fname(parent(a); dims=dimnums, kwargs...)
#             rebuild(a, data, )
#         end
#         $fname(a::AbstractDimensionalArray{T,N}; kwargs...) where {T,N} = begin
#             data = fname(parent(a); kwargs...)
#             rebuild(a, data, slicedims())
#         end
#     end
# end


# AbstractArray methods where dims are an argument

# These use AbstractArray instead of AbstractDimensionArray, which means most of
# the interface can be used without inheriting from it.

Base.@propagate_inbounds Base.getindex(a::AbstractArray, dims::Vararg{<:AbstractDimension}) =
    getindex(a, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, rims::Vararg{<:AbstractDimension}) =
    setindex!(a, x, dims2indices(a, dims)...)
Base.@propagate_inbounds Base.view(a::AbstractArray, dims::Vararg{<:AbstractDimension}) =
    view(a, dims2indices(a, dims)...)
Base.similar(a::AbstractArray, ::Type{T}, dims::AllDimensions) where T =
    similar(a, T, dims2indices(a, dims))
Base.to_shape(dims::AllDimensions) = dims # For use in similar()
Base.accumulate(f, A::AbstractArray, dims::AllDimensions) = accumulate(f, A, dimnum(a, dims))
Base.permutedims(a::AbstractArray, dims::AllDimensions) = permutedims(a, [dimnum(a, dims)...])



#= SplitApplyCombine methods?
Should allow groupby using dims lookup to make this worth the dependency
Like group by time/lattitude/height band etc.

SplitApplyCombine.splitdims(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdims(a, dimnum(a, dims))

SplitApplyCombine.splitdimsview(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdimsview(a, dimnum(a, dims))
=#

