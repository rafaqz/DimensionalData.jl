
# Methods where dims are an argument. This is an experimental approach
# that might need to change.
# targeting underscore _methods so we can use dispatch on the dims arg

# TODO hanbdle rebuild in the array dispatch, the dimensions are probably wrong in some cases. 
for (mod, fname) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum), (:Statistics, :mean))
    _fname = Symbol('_', fname)
    @eval begin
        @inline ($mod.$_fname)(a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} =
            ($mod.$_fname)(a, dimnum(a, dims))
        @inline ($mod.$_fname)(f, a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} =
            ($mod.$_fname)(f, a, dimnum(a, dims))
    end
end

for fname in (:std, :var)
    _fname = Symbol('_', fname)
    @eval begin
        @inline (Statistics.$_fname)(a::AbstractArray, corrected::Bool, mean, dims::AllDimensions) =
            (Statistics.$_fname)(a, corrected, mean, dimnum(a, dims))
    end
end

Statistics._median(a::AbstractArray, dims::AllDimensions) =
    Statistics._median(a, dimnum(a, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDimensions) =
    Base._mapreduce_dim(f, op, nt, A, dimnum(A, dims))
# Unfortunately Base/accumulate.jl kwargs methods all force dims to be Integer.
# accumulate wont work unless that is relaxed, or we copy half of the file here.
Base._accumulate!(op, B, A, dims::AllDimensions, init::Union{Nothing, Some}) =
    Base._accumulate!(op, B, A, dimnum(A, dims), init)

Base._dropdims(a::AbstractArray, dim::Union{AbDim,Type{<:AbDim}}) = 
    rebuildsliced(a, Base._dropdims(a, dimnum(a, dim)), dims2indices(a, basetype(dim)(1)))
Base._dropdims(a::AbstractArray, dims::AbDimTuple) = 
    rebuildsliced(a, Base._dropdims(a, dimnum(a, dims)), 
                  dims2indices(a, Tuple((basetype(d)(1) for d in dims))))



# TODO cov, cor mapslices, eachslice, reverse, sort and sort! need _methods without kwargs in base so
# we can dispatch on dims. Instead we dispatch on array type for now, which means
# these aren't usefull unless you inherit from AbDimArray.

Base.mapslices(f, a::AbDimArray; dims=1, kwargs...) = begin
    dimnums = dimnum(a, dims)
    data = mapslices(f, parent(a); dims=dimnums, kwargs...)
    rebuildsliced(a, data, dims2indices(a, reducedims(DimensionalData.dims(a, dimnums))))
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

@inline Base.reverse(a::AbDimArray{T,N}; dims=1) where {T,N} = begin
    dnum = dimnum(a, dims)
    # Reverse the dimension. TODO: make this type stable
    newdims = revdims(DimensionalData.dims(a), dnum)
    # Reverse the data
    newdata = reverse(parent(a); dims=dnum)
    rebuild(a, newdata, newdims, refdims(a))
end

@inline revdims(dimstorev::Tuple, dnum) = begin
    dim = dimstorev[end]
    if length(dimstorev) == dnum 
        dim = rebuild(dim, reverse(val(dim)))
    end
    (revdims(Base.front(dimstorev), dnum)..., dim) 
end
@inline revdims(dims::Tuple{}, i) = ()

for fname in [:permutedims, :transpose, :adjoint]
    @eval begin
        @inline Base.$fname(a::AbDimArray{T,2}) where T =
            rebuild(a, $fname(parent(a)), reverse(dims(a)), refdims(a))
    end
end

Base.permutedims(a::AbDimArray{T,N}, perm) where {T,N} = 
    rebuild(a, permutedims(parent(a), dimnum(a, perm)), permutedims(dims(a), perm))
