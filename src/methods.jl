# Array info
for (mod, fname) in ((:Base, :size), (:Base, :axes), (:Base, :firstindex), (:Base, :lastindex))
    @eval begin
        @inline ($mod.$fname)(A::AbstractDimArray, dims::AllDims) =
            ($mod.$fname)(A, dimnum(A, dims))
    end
end

# Reducing methods

# With a function arg version
for (mod, fname) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum), 
                     (:Statistics, :mean))
    _fname = Symbol('_', fname)
    @eval begin
        # Base methods
        ($mod.$fname)(A::AbstractDimArray; dims=:, kw...) =
            ($_fname)(A::AbstractDimArray, dims; kw...)
        ($mod.$fname)(f, A::AbstractDimArray; dims=:, kw...) =
            ($_fname)(f, A::AbstractDimArray, dims; kw...)
        # Local dispatch methods
        # - Return a reduced DimArray
        ($_fname)(A::AbstractDimArray, dims; kw...) =
            rebuild(A, ($mod.$fname)(parent(A); dims=dimnum(A, dims), kw...), reducedims(A, dims))
        ($_fname)(f, A::AbstractDimArray, dims; kw...) =
            rebuild(A, ($mod.$fname)(f, parent(A); dims=dimnum(A, dims), kw...), reducedims(A, dims))
        # - Return a scalar
        ($_fname)(A::AbstractDimArray, dims::Colon; kw...) = 
            ($mod.$fname)(parent(A); kw...)
        ($_fname)(f, A::AbstractDimArray, dims::Colon; kw...) =
            ($mod.$fname)(f, parent(A); dims=dims, kw...)
    end
end

# With no function arg version
for (mod, fname) in ((:Statistics, :std), (:Statistics, :var))
    _fname = Symbol('_', fname)
    @eval begin
        # Base methods
        ($mod.$fname)(A::AbstractDimArray; corrected::Bool=true, mean=nothing, dims=:) =
            ($_fname)(A, corrected, mean, dims)
        # Local dispatch methods
        # - Returns a reduced array
        ($_fname)(A::AbstractDimArray, corrected, mean, dims) =
            rebuild(A, ($mod.$fname)(parent(A); corrected=corrected, mean=mean, dims=dimnum(A, dims)), reducedims(A, dims))
        # - Returns a scalar
        ($_fname)(A::AbstractDimArray, corrected, mean, dims::Colon) =
            ($mod.$fname)(parent(A); corrected=corrected, mean=mean, dims=dimnum(A, dims))
    end
end
for (mod, fname) in ((:Statistics, :median), (:Base, :extrema), (:Base, :any), (:Base, :all))
    _fname = Symbol('_', fname)
    @eval begin
        # Base methods
        ($mod.$fname)(A::AbstractDimArray; dims=:) = ($_fname)(A, dims)
        # Local dispatch methods
        # - Returns a reduced array
        ($_fname)(A::AbstractDimArray, dims) =
            rebuild(A, ($mod.$fname)(parent(A); dims=dimnum(A, dims)), reducedims(A, dims))
        # - Returns a scalar
        ($_fname)(A::AbstractDimArray, dims::Colon) =
            ($mod.$fname)(parent(A); dims=dimnum(A, dims))
    end
end

# These are not exported but it makes a lot of things easier using them
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractDimArray, dims) =
    rebuild(A, Base._mapreduce_dim(f, op, nt, parent(A), dimnum(A, dims)), reducedims(A, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractDimArray, dims::Colon) =
    Base._mapreduce_dim(f, op, nt, parent(A), dims)

# TODO: Unfortunately Base/accumulate.jl kwargs methods all force dims to be Integer.
# accumulate wont work unless that is relaxed, or we copy half of the file here.
# Base._accumulate!(op, B, A, dims::AllDims, init::Union{Nothing, Some}) =
    # Base._accumulate!(op, B, A, dimnum(A, dims), init)

# Dimension dropping

function Base.dropdims(A::AbstractDimArray; dims)
    dims = DD.dims(A, dims)
    data = Base.dropdims(parent(A); dims=dimnum(A, dims))
    rebuildsliced(A, data, _dropinds(A, dims))
end

@inline _dropinds(A, dims::DimTuple) = dims2indices(A, map(d -> basetypeof(d)(1), dims))
@inline _dropinds(A, dim::Dimension) = dims2indices(A, basetypeof(dim)(1))



# Function application

@inline Base.map(f, A::AbstractDimArray) = rebuild(A, map(f, parent(A)))

function Base.mapslices(f, A::AbstractDimArray; dims=1, kwargs...)
    dimnums = dimnum(A, dims)
    _data = mapslices(f, parent(A); dims=dimnums, kwargs...)
    rebuild(A, _data, reducedims(A, DimensionalData.dims(A, dimnums)))
end

# This is copied from base as we can't efficiently wrap this function
# through the kwarg with a rebuild in the generator. Doing it this way
# also makes it faster to use a dim than an integer.
function Base.eachslice(A::AbstractDimArray; dims=1, kwargs...)
    if dims isa Tuple && length(dims) != 1
        throw(ArgumentError("only single dimensions are supported"))
    end
    dim = first(dimnum(A, dims))
    dim <= ndims(A) || throw(DimensionMismatch("A doesn't have $dim dimensions"))
    idx1, idx2 = ntuple(d->(:), dim-1), ntuple(d->(:), ndims(A)-dim)
    return (view(A, idx1..., i, idx2...) for i in axes(A, dim))
end


# Duplicated dims

for fname in (:cor, :cov)
    @eval Statistics.$fname(A::AbstractDimArray{T,2}; dims=1, kwargs...) where T = begin
        newdata = Statistics.$fname(parent(A); dims=dimnum(A, dims), kwargs...)
        removed_idx = dimnum(A, dims)
        newrefdims = $dims(A)[removed_idx]
        newdims = $dims(A)[3 - removed_idx]
        rebuild(A, newdata, (newdims, newdims), (newrefdims,))
    end
end


# Rotations

struct Rot90 end
struct Rot180 end
struct Rot270 end
struct Rot360 end

# Not type stable - but we have to lose type stability somewhere when
# dims are being swapped, by an Int value, so it may as well be here
function rottype(k)
    k = mod(k, 4)
    if k == 1
        Rot90()
    elseif k == 2
        Rot180()
    elseif k == 3
        Rot270()
    else
        Rot360()
    end
end

Base.rotl90(A::AbstractDimMatrix) =
    rebuild(A, rotl90(parent(A)), rotdims(Rot90(), dims(A)))
Base.rotl90(A::AbstractDimMatrix, k::Integer) =
    rebuild(A, rotl90(parent(A), k), rotdims(rottype(k), dims(A)))

Base.rotr90(A::AbstractDimMatrix) =
    rebuild(A, rotr90(parent(A)), rotdims(Rot270(), dims(A)))
Base.rotr90(A::AbstractDimMatrix, k::Integer) =
    rebuild(A, rotr90(parent(A), k), rotdims(rottype(-k), dims(A)))

Base.rot180(A::AbstractDimMatrix) =
    rebuild(A, rot180(parent(A)), rotdims(Rot180(), dims(A)))

rotdims(::Rot90, (dima, dimb)) = (flip(Relation, dimb), dima)
rotdims(::Rot180, dims) = map(d -> flip(Relation, d), dims)
rotdims(::Rot270, (dima, dimb)) = (dimb, flip(Relation, dima))
rotdims(::Rot360, dims) = dims


# Dimension reordering

for (pkg, fname) in [(:Base, :permutedims), (:Base, :adjoint),
                     (:Base, :transpose), (:LinearAlgebra, :Transpose)]
    @eval begin
        @inline $pkg.$fname(A::AbstractDimArray{T,2}) where T =
            rebuild(A, $pkg.$fname(parent(A)), reverse(dims(A)))
        @inline $pkg.$fname(A::AbstractDimArray{T,1}) where T =
            rebuild(A, $pkg.$fname(parent(A)), (AnonDim(Base.OneTo(1)), dims(A)...))
    end
end

for fname in [:permutedims, :PermutedDimsArray]
    @eval begin
        @inline Base.$fname(A::AbstractDimArray{T,N}, perm) where {T,N} =
            rebuild(A, $fname(parent(A), dimnum(A, perm)), sortdims(dims(A), perm))
    end
end


# Concatenation

Base._cat(catdims::Union{Int,Base.Dims}, Xin::AbstractDimArray...) =
    Base._cat(dims(first(Xin), catdims), Xin...)
function Base._cat(catdims::AllDims, Xin::AbstractDimArray...)
    A1 = first(Xin)
    comparedims(Xin...)
    if all(hasdim(A1, catdims))
        # Concatenate an existing dim
        dnum = dimnum(A1, catdims)
        # cat the catdim, ignore others
        newdims = Tuple(_catifcatdim(catdims, ds) for ds in zip(map(dims, Xin)...))
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
    newA = Base._cat(dnum, map(data, Xin)...)
    rebuild(A1, newA, formatdims(newA, newdims))
end

_catifcatdim(catdims::Tuple, ds) =
    any(map(cd -> basetypeof(cd) <: basetypeof(ds[1]), catdims)) ? vcat(ds...) : ds[1]
_catifcatdim(catdim, ds) = basetypeof(catdim) <: basetypeof(ds[1]) ? vcat(ds...) : ds[1]

Base.vcat(dims::Dimension...) = begin
    newmode = _vcat_modes(mode(dims)...)
    rebuild(dims[1], _vcat_index(newmode, index(dims)...), newmode)
end

# IndexModes may need adjustment for `cat`
_vcat_modes(modes::IndexMode...) = first(modes)
_vcat_modes(modes::AbstractSampled...) =
    _vcat_modes(sampling(first(modes)), span(first(modes)), modes...)
_vcat_modes(::Any, ::Regular, modes...) = begin
    _step = step(first(modes))
    map(modes) do mode
        step(span(mode)) == _step || error("Step sizes $(step(span(mode))) and $_step do not match ")
    end
    first(modes)
end
_vcat_modes(::Intervals, ::Irregular, modes...) = begin
    allbounds = map(bounds ∘ span, modes)
    @show allbounds
    newbounds = minimum(map(first, allbounds)), maximum(map(last, allbounds))
    @show newbounds
    rebuild(modes[1]; span=Irregular(newbounds))
end
_vcat_modes(::Points, ::Irregular, modes...) = first(modes)

# Index vcat depends on mode:
# NoIndex is always just Base.OneTo(length)
# TODO: handle vcat OffsetArrays?
_vcat_index(mode::NoIndex, A...) = Base.OneTo(sum(map(length, A)))
# Otherwise just vcat. TODO: handle order breaking vcat?
_vcat_index(mode::IndexMode, A...) = vcat(A...)




Base.inv(A::AbstractDimArray{T,2}) where T =
    rebuild(A, inv(parent(A)), reverse(map(d -> flip(IndexOrder, d), dims(A))))

# Index breaking

# TODO: change the index and traits of the reduced dimension
# and return a DimArray.
Base.unique(A::AbstractDimArray; dims::Union{DimOrDimType,Colon}=:) =
    unique(parent(A); dims=dimnum(A, dims))
Base.unique(A::AbstractDimArray{<:Any,1}) = unique(parent(A))
