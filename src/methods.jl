# Array info
for (m, f) in ((:Base, :size), (:Base, :axes), (:Base, :firstindex), (:Base, :lastindex))
    @eval begin
        @inline $m.$f(A::AbstractDimArray, dims::AllDims) = $m.$f(A, dimnum(A, dims))
    end
end

# Reducing methods

# With a function arg version
for (m, f) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum), 
                     (:Base, :extrema), (:Statistics, :mean))
    _f = Symbol('_', f)
    @eval begin
        # Base methods
        $m.$f(A::AbstractDimArray; dims=:, kw...) = $_f(A::AbstractDimArray, dims; kw...)
        $m.$f(f, A::AbstractDimArray; dims=:, kw...) = $_f(f, A::AbstractDimArray, dims; kw...)
        # Local dispatch methods
        # - Return a reduced DimArray
        $_f(A::AbstractDimArray, dims; kw...) =
            rebuild(A, $m.$f(parent(A); dims=dimnum(A, _astuple(dims)), kw...), reducedims(A, dims))
        $_f(f, A::AbstractDimArray, dims; kw...) =
            rebuild(A, $m.$f(f, parent(A); dims=dimnum(A, _astuple(dims)), kw...), reducedims(A, dims))
        # - Return a scalar
        $_f(A::AbstractDimArray, dims::Colon; kw...) = $m.$f(parent(A); dims, kw...)
        $_f(f, A::AbstractDimArray, dims::Colon; kw...) = $m.$f(f, parent(A); dims, kw...)
    end
end
# With no function arg version
for (m, f) in ((:Statistics, :std), (:Statistics, :var))
    _f = Symbol('_', f)
    @eval begin
        # Base methods
        $m.$f(A::AbstractDimArray; corrected::Bool=true, mean=nothing, dims=:) =
            $_f(A, corrected, mean, dims)
        # Local dispatch methods - Returns a reduced array
        $_f(A::AbstractDimArray, corrected, mean, dims) =
            rebuild(A, $m.$f(parent(A); corrected=corrected, mean=mean, dims=dimnum(A, _astuple(dims))), reducedims(A, dims))
        # - Returns a scalar
        $_f(A::AbstractDimArray, corrected, mean, dims::Colon) =
            $m.$f(parent(A); corrected=corrected, mean=mean, dims=:)
    end
end
for (m, f) in ((:Statistics, :median), (:Base, :any), (:Base, :all))
    _f = Symbol('_', f)
    @eval begin
        # Base methods
        $m.$f(A::AbstractDimArray; dims=:) = $_f(A, dims)
        # Local dispatch methods - Returns a reduced array
        $_f(A::AbstractDimArray, dims) =
            rebuild(A, $m.$f(parent(A); dims=dimnum(A, _astuple(dims))), reducedims(A, dims))
        # - Returns a scalar
        $_f(A::AbstractDimArray, dims::Colon) = $m.$f(parent(A); dims=:)
    end
end

# These are not exported but it makes a lot of things easier using them
function Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractDimArray, dims)
    rebuild(A, Base._mapreduce_dim(f, op, nt, parent(A), dimnum(A, _astuple(dims))), reducedims(A, dims))
end
function Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractDimArray, dims::Colon)
    Base._mapreduce_dim(f, op, nt, parent(A), dims)
end
function Base._mapreduce_dim(f, op, nt, A::AbstractDimArray, dims)
    rebuild(A, Base._mapreduce_dim(f, op, nt, parent(A), dimnum(A, dims)), reducedims(A, dims))
end
@static if VERSION >= v"1.6" 
    function Base._mapreduce_dim(f, op, nt::Base._InitialValue, A::AbstractDimArray, dims)
        rebuild(A, Base._mapreduce_dim(f, op, nt, parent(A), dimnum(A, dims)), reducedims(A, dims))
    end
    function Base._mapreduce_dim(f, op, nt::Base._InitialValue, A::AbstractDimArray, dims::Colon)
        Base._mapreduce_dim(f, op, nt, parent(A), dims)
    end
end

# TODO: Unfortunately Base/accumulate.jl kw methods all force dims to be Integer.
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

function Base.mapslices(f, A::AbstractDimArray; dims=1, kw...)
    dimnums = dimnum(A, _astuple(dims))
    data = mapslices(f, parent(A); dims=dimnums, kw...)
    rebuild(A, data)
end

# This is copied from base as we can't efficiently wrap this function
# through the kw with a rebuild in the generator. Doing it this way
# also makes it faster to use a dim than an integer.
function Base.eachslice(A::AbstractDimArray; dims=1, kw...)
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
    @eval function Statistics.$fname(A::AbstractDimArray{<:Any,2}; dims=1, kw...)
        newdata = Statistics.$fname(parent(A); dims=dimnum(A, dims), kw...)
        removed_idx = dimnum(A, dims)
        newrefdims = $dims(A)[removed_idx]
        newdim = $dims(A)[3 - removed_idx]
        rebuild(A, newdata, (newdim, newdim), (newrefdims,))
    end
end

# Rotations

struct _Rot90 end
struct _Rot180 end
struct _Rot270 end
struct _Rot360 end

Base.rotl90(A::AbstractDimMatrix) = rebuild(A, rotl90(parent(A)), _rot(_Rot90(), dims(A)))
Base.rotl90(A::AbstractDimMatrix, k::Integer) =
    rebuild(A, rotl90(parent(A), k), _rot(_rottype(k), dims(A)))

Base.rotr90(A::AbstractDimMatrix) = rebuild(A, rotr90(parent(A)), _rot(_Rot270(), dims(A)))
Base.rotr90(A::AbstractDimMatrix, k::Integer) =
    rebuild(A, rotr90(parent(A), k), _rot(_rottype(-k), dims(A)))

Base.rot180(A::AbstractDimMatrix) = rebuild(A, rot180(parent(A)), _rot(_Rot180(), dims(A)))

# Not type stable - but we have to lose type stability somewhere when
# dims are being swapped, by an Int value, so it may as well be here
function _rottype(k)
    k = mod(k, 4)
    if k == 1
        _Rot90()
    elseif k == 2
        _Rot180()
    elseif k == 3
        _Rot270()
    else
        _Rot360()
    end
end

_rot(::_Rot90, (dima, dimb)) = (flip(Relation, dimb), dima)
_rot(::_Rot180, dims) = map(d -> flip(Relation, d), dims)
_rot(::_Rot270, (dima, dimb)) = (dimb, flip(Relation, dima))
_rot(::_Rot360, dims) = dims

# Dimension reordering

for (pkg, fname) in [(:Base, :permutedims), (:Base, :adjoint),
                     (:Base, :transpose), (:LinearAlgebra, :Transpose)]
    @eval begin
        @inline $pkg.$fname(A::AbstractDimArray{<:Any,2}) =
            rebuild(A, $pkg.$fname(parent(A)), reverse(dims(A)))
        @inline $pkg.$fname(A::AbstractDimArray{<:Any,1}) =
            rebuild(A, $pkg.$fname(parent(A)), (AnonDim(Base.OneTo(1)), dims(A)...))
    end
end
for fname in [:permutedims, :PermutedDimsArray]
    @eval begin
        @inline function Base.$fname(A::AbstractDimArray, perm)
            rebuild(A, $fname(parent(A), dimnum(A, Tuple(perm))), sortdims(dims(A), Tuple(perm)))
        end
    end
end

# Concatenation
function Base._cat(catdims::Union{Int,Base.Dims}, Xin::AbstractDimArray...)
    Base._cat(dims(first(Xin), catdims), Xin...)
end
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

function _catifcatdim(catdims::Tuple, dims)
    anydimsmatch = any(map(d -> basetypeof(d) <: basetypeof(dims[1]), catdims)) 
    anydimsmatch ? vcat(dims...) : dims[1]
end
function _catifcatdim(catdim, dims) 
    basetypeof(catdim) <: basetypeof(dims[1]) ? vcat(dims...) : dims[1]
end

function Base.vcat(dims::Dimension...)
    newmode = _vcat_modes(mode(dims)...)
    rebuild(dims[1], _vcat_index(newmode, index(dims)...), newmode)
end

# IndexModes may need adjustment for `cat`
_vcat_modes(modes::IndexMode...) = first(modes)
function _vcat_modes(modes::AbstractSampled...)
    _vcat_modes(sampling(first(modes)), span(first(modes)), modes...)
end
function _vcat_modes(::Any, ::Regular, modes...)
    _step = step(first(modes))
    map(modes) do mode
        step(span(mode)) == _step || error("Step sizes $(step(span(mode))) and $_step do not match ")
    end
    first(modes)
end
function _vcat_modes(::Intervals, ::Irregular, modes...)
    allbounds = map(bounds ∘ span, modes)
    newbounds = minimum(map(first, allbounds)), maximum(map(last, allbounds))
    rebuild(modes[1]; span=Irregular(newbounds))
end
_vcat_modes(::Points, ::Irregular, modes...) = 
    rebuild(first(modes); span=Irregular(nothing, nothing))

# Index vcat depends on mode: NoIndex is always Colon()
_vcat_index(mode::NoIndex, A...) = OneTo(sum(map(length, A)))
# TODO: handle vcat OffsetArrays?
# Otherwise just vcat. TODO: handle order breaking vcat?
_vcat_index(mode::IndexMode, A...) = vcat(A...)


Base.inv(A::AbstractDimArray{T,2}) where T =
    rebuild(A, inv(parent(A)), reverse(map(d -> flip(IndexOrder, d), dims(A))))

# Index breaking

# TODO: change the index and traits of the reduced dimension and return a DimArray.
Base.unique(A::AbstractDimArray; dims::Union{DimOrDimType,Colon}=:) = _unique(A, dims)
Base.unique(A::AbstractDimArray{<:Any,1}) = unique(parent(A))

_unique(A::AbstractDimArray, dims::DimOrDimType) =
    unique(parent(A); dims=dimnum(A, dims))
_unique(A::AbstractDimArray, dims::Colon) = unique(parent(A); dims=:)

Base.diff(A::AbstractDimVector; dims=1) = _diff(A, dimnum(A, dims))
Base.diff(A::AbstractDimArray; dims) = _diff(A, dimnum(A, dims))

@inline function _diff(A::AbstractDimArray{<:Any,N}, dims::Integer) where {N}
    r = axes(A)
    # Copied from Base.diff
    r0 = ntuple(i -> i == dims ? UnitRange(1, last(r[i]) - 1) : UnitRange(r[i]), N)
    rebuildsliced(A, diff(parent(A); dims=dimnum(A, dims)), r0)
end
