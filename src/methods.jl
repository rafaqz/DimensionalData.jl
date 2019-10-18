
for (mod, fname) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum), (:Statistics, :mean))
    _fname = Symbol('_', fname)
    @eval begin
        @inline ($mod.$fname)(A::AbDimArray) = ($mod.$fname)(parent(A))
        @inline ($mod.$_fname)(A::AbstractArray, dims::AllDimensions) =
            rebuild(A, ($mod.$_fname)(parent(A), dimnum(A, dims)), reducedims(A, dims))
        @inline ($mod.$_fname)(f, A::AbstractArray, dims::AllDimensions) =
            rebuild(A, ($mod.$_fname)(f, parent(A), dimnum(A, dims)), reducedims(A, dims))
        @inline ($mod.$_fname)(A::AbDimArray, dims::Union{Int,Base.Dims}) =
            rebuild(A, ($mod.$_fname)(parent(A), dims), reducedims(A, dims))
        @inline ($mod.$_fname)(f, A::AbDimArray, dims::Union{Int,Base.Dims}) =
            rebuild(A, ($mod.$_fname)(f, parent(A), dims), reducedims(A, dims))
    end
end

for fname in (:std, :var)
    _fname = Symbol('_', fname)
    @eval begin
        @inline (Statistics.$fname)(A::AbDimArray) = (Statistics.$fname)(parent(A))
        @inline (Statistics.$_fname)(A::AbstractArray, corrected::Bool, mean, dims::AllDimensions) =
            rebuild(A, (Statistics.$_fname)(A, corrected, mean, dimnum(A, dims)), reducedims(A, dims))
        @inline (Statistics.$_fname)(A::AbDimArray, corrected::Bool, mean, dims::Union{Int,Base.Dims}) =
            rebuild(A, (Statistics.$_fname)(parent(A), corrected, mean, dims), reducedims(A, dims))
    end
end

Statistics.median(A::AbDimArray) = Statistics.median(parent(A))
Statistics._median(A::AbstractArray, dims::AllDimensions) =
    rebuild(A, Statistics._median(parent(A), dimnum(A, dims)), reducedims(A, dims))
Statistics._median(A::AbDimArray, dims::Union{Int,Base.Dims}) =
    rebuild(A, Statistics._median(parent(A), dims), reducedims(A, dims))

Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDimensions) =
    rebuild(A, Base._mapreduce_dim(f, op, nt, parent(A), dimnum(A, dims)), reducedims(A, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbDimArray, dims::Union{Int,Base.Dims}) =
    rebuild(A, Base._mapreduce_dim(f, op, nt, parent(A), dimnum(A, dims)), reducedims(A, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbDimArray, dims::Colon) =
    Base._mapreduce_dim(f, op, nt, parent(A), dims)
# Unfortunately Base/accumulate.jl kwargs methods all force dims to be Integer.
# accumulate wont work unless that is relaxed, or we copy half of the file here.
Base._accumulate!(op, B, A, dims::AllDimensions, init::Union{Nothing, Some}) =
    Base._accumulate!(op, B, A, dimnum(A, dims), init)

Base._dropdims(A::AbstractArray, dim::Union{AbDim,Type{<:AbDim}}) = 
    rebuildsliced(A, Base._dropdims(A, dimnum(A, dim)), dims2indices(A, basetype(dim)(1)))
Base._dropdims(A::AbstractArray, dims::AbDimTuple) = 
    rebuildsliced(A, Base._dropdims(A, dimnum(A, dims)), 
                  dims2indices(A, Tuple((basetype(d)(1) for d in dims))))


@inline Base.map(f, A::AbDimArray) = rebuild(A, map(f, parent(A)), dims(A))

# TODO cov, cor mapslices, eachslice, reverse, sort and sort! need _methods without kwargs in base so
# we can dispatch on dims. Instead we dispatch on array type for now, which means
# these aren't usefull unless you inherit from AbDimArray.

Base.mapslices(f, A::AbDimArray; dims=1, kwargs...) = begin
    dimnums = dimnum(A, dims)
    data = mapslices(f, parent(A); dims=dimnums, kwargs...)
    rebuild(A, data, reducedims(A, DimensionalData.dims(A, dimnums)))
end

# This is copied from base as we can't efficiently wrap this function
# through the kwarg with a rebuild in the generator. Doing it this way 
# wierdly makes it faster to use a dim than an integer.
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
    @eval Statistics.$fname(A::AbDimArray{T,2}; dims=1, kwargs...) where T = begin
        newdata = Statistics.$fname(parent(A); dims=dimnum(A, dims), kwargs...)
        I = dims2indices(A, dims, 1)
        newdims, newrefdims = slicedims(A, I)
        rebuild(A, newdata, (newdims[1], newdims[1]), newrefdims)
    end
end

@inline Base.reverse(A::AbDimArray{T,N}; dims=1) where {T,N} = begin
    dnum = dimnum(A, dims)
    # Reverse the dimension. TODO: make this type stable
    newdims = revdims(DimensionalData.dims(A), dnum)
    # Reverse the data
    newdata = reverse(parent(A); dims=dnum)
    rebuild(A, newdata, newdims, refdims(A))
end

# TODO change order after reverse
@inline revdims(dimstorev::Tuple, dnum) = begin
    dim = dimstorev[end]
    if length(dimstorev) == dnum 
        dim = rebuild(dim, reverse(val(dim)))
    end
    (revdims(Base.front(dimstorev), dnum)..., dim) 
end
@inline revdims(dims::Tuple{}, i) = ()

for (pkg, fname) in [(:Base, :permutedims), (:Base, :adjoint), 
                     (:Base, :transpose), (:LinearAlgebra, :Transpose)]
    @eval begin
        @inline $pkg.$fname(A::AbDimArray{T,2}) where T =
            rebuild(A, $fname(parent(A)), reverse(dims(A)), refdims(A))
    end
end

for fname in [:permutedims, :PermutedDimsArray]
    @eval begin
        @inline Base.$fname(A::AbDimArray{T,N}, perm) where {T,N} = 
            rebuild(A, $fname(parent(A), dimnum(A, perm)), permutedims(dims(A), perm))
    end
end
