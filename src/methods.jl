# Array info
for (mod, fname) in ((:Base, :size), (:Base, :axes), (:Base, :firstindex), (:Base, :lastindex))
    @eval begin
        @inline ($mod.$fname)(A::AbstractArray, dims::AllDims) =
            ($mod.$fname)(A, dimnum(A, dims))
    end
end

# Reducing methods

for (mod, fname) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum), (:Statistics, :mean))
    _fname = Symbol('_', fname)
    @eval begin
        # Returns a scalar
        @inline ($mod.$fname)(A::AbDimArray) = ($mod.$fname)(data(A))
        # Returns a reduced array
        @inline ($mod.$_fname)(A::AbstractArray, dims::AllDims) =
            rebuild(A, ($mod.$_fname)(data(A), dimnum(A, dims)), reducedims(A, dims))
        @inline ($mod.$_fname)(f, A::AbstractArray, dims::AllDims) =
            rebuild(A, ($mod.$_fname)(f, data(A), dimnum(A, dims)), reducedims(A, dims))
        @inline ($mod.$_fname)(A::AbDimArray, dims::Union{Int,Base.Dims}) =
            rebuild(A, ($mod.$_fname)(data(A), dims), reducedims(A, dims))
        @inline ($mod.$_fname)(f, A::AbDimArray, dims::Union{Int,Base.Dims}) =
            rebuild(A, ($mod.$_fname)(f, data(A), dims), reducedims(A, dims))
    end
end

for (mod, fname) in ((:Statistics, :std), (:Statistics, :var))
    _fname = Symbol('_', fname)
    @eval begin
        # Returns a scalar
        @inline ($mod.$fname)(A::AbDimArray) = ($mod.$fname)(data(A))
        # Returns a reduced array
        @inline ($mod.$_fname)(A::AbstractArray, corrected::Bool, mean, dims::AllDims) =
            rebuild(A, ($mod.$_fname)(A, corrected, mean, dimnum(A, dims)), reducedims(A, dims))
        @inline ($mod.$_fname)(A::AbDimArray, corrected::Bool, mean, dims::Union{Int,Base.Dims}) =
            rebuild(A, ($mod.$_fname)(data(A), corrected, mean, dims), reducedims(A, dims))
    end
end

Statistics.median(A::AbDimArray) = Statistics.median(data(A))
Statistics._median(A::AbstractArray, dims::AllDims) =
    rebuild(A, Statistics._median(data(A), dimnum(A, dims)), reducedims(A, dims))
Statistics._median(A::AbDimArray, dims::Union{Int,Base.Dims}) =
    rebuild(A, Statistics._median(data(A), dims), reducedims(A, dims))

Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDims) =
    rebuild(A, Base._mapreduce_dim(f, op, nt, data(A), dimnum(A, dims)), reducedims(A, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbDimArray, dims::Union{Int,Base.Dims}) =
    rebuild(A, Base._mapreduce_dim(f, op, nt, data(A), dimnum(A, dims)), reducedims(A, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbDimArray, dims::Colon) =
    Base._mapreduce_dim(f, op, nt, data(A), dims)

# TODO: Unfortunately Base/accumulate.jl kwargs methods all force dims to be Integer.
# accumulate wont work unless that is relaxed, or we copy half of the file here.
# Base._accumulate!(op, B, A, dims::AllDims, init::Union{Nothing, Some}) =
    # Base._accumulate!(op, B, A, dimnum(A, dims), init)

Base._extrema_dims(f, A::AbstractArray, dims::AllDims) = begin
    dnums = dimnum(A, dims)
    rebuild(A, Base._extrema_dims(f, data(A), dnums), reducedims(A, dnums))
end


# Dimension dropping
Base._dropdims(A::AbstractArray, dim::DimOrDimType) =
    rebuildsliced(A, Base._dropdims(data(A), dimnum(A, dim)),
                  dims2indices(A, basetypeof(dim)(1)))
Base._dropdims(A::AbstractArray, dims::DimTuple) =
    rebuildsliced(A, Base._dropdims(data(A), dimnum(A, dims)),
                  dims2indices(A, Tuple((basetypeof(d)(1) for d in dims))))


# Function application

@inline Base.map(f, A::AbDimArray) = rebuild(A, map(f, data(A)))

Base.mapslices(f, A::AbDimArray; dims=1, kwargs...) = begin
    dimnums = dimnum(A, dims)
    _data = mapslices(f, data(A); dims=dimnums, kwargs...)
    rebuild(A, _data, reducedims(A, DimensionalData.dims(A, dimnums)))
end

# This is copied from base as we can't efficiently wrap this function
# through the kwarg with a rebuild in the generator. Doing it this way
# also makes it faster to use a dim than an integer.
if VERSION > v"1.1-"
    Base.eachslice(A::AbDimArray; dims=1, kwargs...) = begin
        if dims isa Tuple && length(dims) != 1
            throw(ArgumentError("only single dimensions are supported"))
        end
        dim = first(dimnum(A, dims))
        dim <= ndims(A) || throw(DimensionMismatch("A doesn't have $dim dimensions"))
        idx1, idx2 = ntuple(d->(:), dim-1), ntuple(d->(:), ndims(A)-dim)
        return (view(A, idx1..., i, idx2...) for i in axes(A, dim))
    end
end

# Duplicated dims

for fname in (:cor, :cov)
    @eval Statistics.$fname(A::AbDimArray{T,2}; dims=1, kwargs...) where T = begin
        newdata = Statistics.$fname(data(A); dims=dimnum(A, dims), kwargs...)
        removed_idx = dimnum(A, dims)
        newrefdims = $dims(A)[removed_idx]
        newdims = $dims(A)[3 - removed_idx]
        rebuild(A, newdata, (newdims, newdims), (newrefdims,))
    end
end

const AA = AbstractArray
const ADA = AbstractDimensionalArray

Base.:*(A::ADA{<:Any,2}, B::AA{<:Any,1}) = rebuild(A, data(A) * B, dims(A, (1,)))
Base.:*(A::ADA{<:Any,1}, B::AA{<:Any,2}) = rebuild(A, data(A) * B, dims(A, (1, 1)))
Base.:*(A::ADA{<:Any,2}, B::AA{<:Any,2}) = rebuild(A, data(A) * B, dims(A, (1, 1)))
Base.:*(A::AA{<:Any,1}, B::ADA{<:Any,2}) = rebuild(B, A * data(B), dims(B, (2, 2)))
Base.:*(A::AA{<:Any,2}, B::ADA{<:Any,1}) = rebuild(B, A * data(B), (AnonDim(Base.OneTo(1)),))
Base.:*(A::AA{<:Any,2}, B::ADA{<:Any,2}) = rebuild(B, A * data(B), dims(B, (2, 2)))

Base.:*(A::ADA{<:Any,1}, B::ADA{<:Any,2}) = begin
    comparedims(dims(A, 1), dims(B, 2))
    rebuild(A, data(A) * data(B), dims(A, (1, 1)))
end
Base.:*(A::AbDimArray{<:Any,2}, B::AbDimArray{<:Any,1}) = begin
    comparedims(dims(A, 2), dims(B, 1))
    rebuild(A, data(A) * data(B), dims(A, (1,)))
end
Base.:*(A::ADA{<:Any,2}, B::ADA{<:Any,2}) = begin
    comparedims(dims(A, 2), dims(B, 1))
    rebuild(A, data(A) * data(B), (dims(A, 1), dims(B, 2)))
end

# Reverse.
Base.reverse(A::AbDimArray{T,N}; dims=1) where {T,N} =
    reversearray(A; dims=dims)
Base.reverse(dim::Dimension) = reverseindex(dim)

# Dimension reordering

for (pkg, fname) in [(:Base, :permutedims), (:Base, :adjoint),
                     (:Base, :transpose), (:LinearAlgebra, :Transpose)]
    @eval begin
        @inline $pkg.$fname(A::AbDimArray{T,2}) where T =
            rebuild(A, $pkg.$fname(data(A)), reverse(dims(A)))
        @inline $pkg.$fname(A::AbDimArray{T,1}) where T =
            rebuild(A, $pkg.$fname(data(A)), (AnonDim(Base.OneTo(1)), dims(A)...))
    end
end

for fname in [:permutedims, :PermutedDimsArray]
    @eval begin
        @inline Base.$fname(A::AbDimArray{T,N}, perm) where {T,N} =
            rebuild(A, $fname(data(A), dimnum(A, perm)), permutedims(dims(A), perm))
    end
end


# Concatenation

Base._cat(catdims::Union{Int,Base.Dims}, As::AbDimArray...) =
    Base._cat(dims(first(As), catdims), As...)
Base._cat(catdims::AllDims, As::AbstractArray...) = begin
    A1 = first(As)
    comparedims(As...)
    if all(hasdim(A1, catdims))
        # Concatenate an existing dim
        dnum = dimnum(A1, catdims)
        # cat the catdim, ignore others
        newdims = Tuple(_catifcatdim(catdims, ds) for ds in zip(map(dims, As)...))
    else
        # Concatenate a new dim
        add_dims = if (catdims isa Tuple)
            Tuple(d for d in catdims if !hasdim(A1, d))
        else
            (catdims,)
        end
        dnum = ndims(A1) + length(add_dims)
        newdims = (dims(A1)..., add_dims...)
    end
    newA = Base._cat(dnum, map(data, As)...)
    rebuild(A1, newA, formatdims(newA, newdims))
end

_catifcatdim(catdims::Tuple, ds) =
    any(map(cd -> basetypeof(cd) <: basetypeof(ds[1]), catdims)) ? vcat(ds...) : ds[1]
_catifcatdim(catdim, ds) = basetypeof(catdim) <: basetypeof(ds[1]) ? vcat(ds...) : ds[1]

Base.vcat(dims::Dimension...) =
    rebuild(dims[1], vcat(map(val, dims)...), vcat(map(mode, dims)...))

Base.vcat(modes::IndexMode...) = first(modes)
Base.vcat(modes::AbstractSampled...) =
    _vcat_modes(sampling(first(modes)), span(first(modes)), modes...)

_vcat_modes(::Any, ::Regular, modes...) = begin
    _step = step(first(modes))
    map(modes) do mode
        step(span(mode)) == _step || error("Step sizes $(step(span(mode))) and $_step do not match ")
    end
    first(modes)
end
_vcat_modes(::Intervals, ::Irregular, modes...) = begin
    bounds = bounds(modes[1])[1], bounds(modes[end])[end]
    rebuild(modes[1]; span=Irregular(sortbounds(indexorder(modes[1]), bounds)))
end
_vcat_modes(::Points, ::Irregular, modes...) = first(modes)


# Index breaking

# TODO: change the index and traits of the reduced dimension
# and return a DimensionalArray.
Base.unique(A::AbDimArray{<:Any,1}) = unique(data(A))
Base.unique(A::AbDimArray; dims::DimOrDimType) =
    unique(data(A); dims=dimnum(A, dims))


# TODO cov, cor mapslices, eachslice, reverse, sort and sort! need _methods without kwargs in base so
# we can dispatch on dims. Instead we dispatch on array type for now, which means
# these aren't usefull unless you inherit from AbDimArray.
