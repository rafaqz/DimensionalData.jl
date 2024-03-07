# Array info
for (m, f) in ((:Base, :size), (:Base, :axes), (:Base, :firstindex), (:Base, :lastindex))
    @eval begin
        @inline $m.$f(A::AbstractBasicDimArray, dims::AllDims) = $m.$f(A, dimnum(A, dims))
    end
end

# Reducing methods

# With a function arg version
for (m, f) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum),
                     (:Base, :extrema), (:Statistics, :mean))
    _f = Symbol('_', f)
    @eval begin
        # Base methods
        @inline $m.$f(A::AbstractDimArray; dims=:, kw...) = $_f(A, dims; kw...)
        @inline $m.$f(f, A::AbstractDimArray; dims=:, kw...) = $_f(f, A, dims; kw...)
        # Local dispatch methods
        # - Return a reduced DimArray
        @inline $_f(A::AbstractDimArray, dims; kw...) =
            rebuild(A, $m.$f(parent(A); dims=dimnum(A, _astuple(dims)), kw...), reducedims(A, dims))
        @inline $_f(f, A::AbstractDimArray, dims; kw...) =
            rebuild(A, $m.$f(f, parent(A); dims=dimnum(A, _astuple(dims)), kw...), reducedims(A, dims))
        # - Return a scalar
        @inline $_f(A::AbstractDimArray, dims::Colon; kw...) = $m.$f(parent(A); dims, kw...)
        @inline $_f(f, A::AbstractDimArray, dims::Colon; kw...) = $m.$f(f, parent(A); dims, kw...)
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
        @inline $_f(A::AbstractDimArray, corrected, mean, dims) =
            rebuild(A, $m.$f(parent(A); corrected=corrected, mean=mean, dims=dimnum(A, _astuple(dims))), reducedims(A, dims))
        # - Returns a scalar
        @inline $_f(A::AbstractDimArray, corrected, mean, dims::Colon) =
            $m.$f(parent(A); corrected=corrected, mean=mean, dims=:)
    end
end
for (m, f) in ((:Statistics, :median), (:Base, :any), (:Base, :all))
    _f = Symbol('_', f)
    @eval begin
        @inline $m.$f(A::AbstractDimArray; dims=:) = $_f(A, dims)
        # Local dispatch methods - Returns a reduced array
        @inline $_f(A::AbstractDimArray, dims) =
            rebuild(A, $m.$f(parent(A); dims=dimnum(A, _astuple(dims))), reducedims(A, dims))
        # - Returns a scalar
        @inline $_f(A::AbstractDimArray, dims::Colon) = $m.$f(parent(A); dims=:)
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
function Base._mapreduce_dim(f, op, nt, A::AbstractDimArray, dims::Colon)
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

@inline _dropinds(A, dims::Tuple) = dims2indices(A, map(d -> rebuild(d, 1), dims))
@inline _dropinds(A, dim::Dimension) = dims2indices(A, rebuild(dim, 1))


# Function application

function Base.map(f, As::AbstractDimArray...)
    comparedims(As...)
    newdata = map(f, map(parent, As)...)
    rebuild(first(As); data=newdata)
end


@inline function Base.mapslices(f, A::AbstractDimArray; dims=1, kw...)
    # Run `mapslices` on the parent array
    dimnums = dimnum(A, _astuple(dims))
    newdata = mapslices(f, parent(A); dims=dimnums, kw...)
    ds = DD.dims(A, _astuple(dims))
    # Run one slice with dimensions to get the transformed dim
    d_inds = map(d -> rebuild(d, 1), otherdims(A, ds))
    example_dims = length(d_inds) > 0 ? DD.dims(f(view(A, d_inds...))) : ()
    replacement_dims = if isnothing(example_dims) || length(example_dims) != length(ds)
        map(d -> rebuild(d, NoLookup()), ds)
    else
        example_dims
    end
    newdims = format(setdims(DD.dims(A), replacement_dims), newdata)

    return rebuild(A, newdata, newdims)
end

@static if VERSION < v"1.9-alpha1"
    """
        Base.eachslice(A::AbstractDimArray; dims)

    Create a generator that iterates over dimensions `dims` of `A`, returning arrays that
    select all the data from the other dimensions in `A` using views.

    The generator has `size` and `axes` equivalent to those of the provided `dims`.
    """
    function Base.eachslice(A::AbstractDimArray; dims)
        dimtuple = _astuple(dims)
        if !(dimtuple == ())
            all(hasdim(A, dimtuple...)) || throw(DimensionMismatch("A doesn't have all dimensions $dims"))
        end
        _eachslice(A, dimtuple)
    end
else
    @inline function Base.eachslice(A::AbstractDimArray; dims, drop=true)
        dimtuple = _astuple(dims)
        if !(dimtuple == ())
            all(hasdim(A, dimtuple...)) || throw(DimensionMismatch("A doesn't have all dimensions $dims"))
        end
        _eachslice(A, dimtuple, drop)
    end
    Base.@constprop :aggressive function _eachslice(A::AbstractDimArray{T,N}, dims, drop) where {T,N}
        slicedims = Dimensions.dims(A, dims)
        Adims = Dimensions.dims(A)
        if drop
            ax = map(dim -> axes(A, dim), slicedims)
            slicemap = map(Adims) do dim
                hasdim(slicedims, dim) ? dimnum(slicedims, dim) : (:)
            end
            return Slices(A, slicemap, ax)
        else
            ax = map(Adims) do dim
                hasdim(slicedims, dim) ? axes(A, dim) : axes(reducedims(dim, dim), 1)
            end
            slicemap = map(Adims) do dim
                hasdim(slicedims, dim) ? dimnum(A, dim) : (:)
            end
            return Slices(A, slicemap, ax)
        end
    end
end

# works for arrays and for stacks
function _eachslice(x, dims::Tuple)
    slicedims = Dimensions.dims(x, dims)
    return (view(x, d...) for d in DimIndices(slicedims))
end

# These just return the parent for now
function Base.sort(A::AbstractDimVector; kw...)
    newdims = (set(only(dims(A)), NoLookup()),)
    newdata = sort(parent(A), kw...)
    return rebuild(A, newdata, newdims)
end
function Base.sort(A::AbstractDimArray; dims, kw...)
    newdata = sort(parent(A), dims=dimnum(A, dims), kw...)
    replacement_dims = map(DD.dims(A, _astuple(dims))) do d
        set(d, NoLookup())
    end
    newdims = setdims(DD.dims(A), replacement_dims)
    return rebuild(A, newdata, newdims)
end

function Base.sortslices(A::AbstractDimArray; dims, kw...)
    newdata = sortslices(parent(A), dims=dimnum(A, dims), kw...)
    replacement_dims = map(DD.dims(A, _astuple(dims))) do d
        set(d, NoLookup())
    end
    newdims = setdims(DD.dims(A), replacement_dims)
    return rebuild(A, newdata, newdims)
end


Base.cumsum(A::AbstractDimVector) = rebuild(A, Base.cumsum(parent(A)))
Base.cumsum(A::AbstractDimArray; dims) = rebuild(A, cumsum(parent(A); dims=dimnum(A, dims)))
Base.cumsum!(B::AbstractArray, A::AbstractDimVector) = cumsum!(B, parent(A))
Base.cumsum!(B::AbstractArray, A::AbstractDimArray; dims) = cumsum!(B, parent(A); dims=dimnum(A, dims))

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

Base.rotl90(A::AbstractDimMatrix) = rebuild(A, rotl90(parent(A)), _rotdims_90(dims(A)))
function Base.rotl90(A::AbstractDimMatrix, k::Integer)
    rebuild(A, rotl90(parent(A), k), _rotdims_k(dims(A), k))
end

Base.rotr90(A::AbstractDimMatrix) = rebuild(A, rotr90(parent(A)), _rotdims_270(dims(A)))
function Base.rotr90(A::AbstractDimMatrix, k::Integer)
    rebuild(A, rotr90(parent(A), k), _rotdims_k(dims(A), -k))
end

Base.rot180(A::AbstractDimMatrix) = rebuild(A, rot180(parent(A)), _rotdims_180(dims(A)))

# Not type stable - but we have to lose type stability somewhere when
# dims are being swapped, by an Int value, so it may as well be here
function _rotdims_k(dims, k)
    k = mod(k, 4)
    k == 1 ? _rotdims_90(dims) :
    k == 2 ? _rotdims_180(dims) :
    k == 3 ? _rotdims_270(dims) : dims
end

_rotdims_90((dim_a, dim_b)) = reverse(dim_b), dim_a
_rotdims_180((dim_a, dim_b)) = reverse(dim_a), reverse(dim_b)
_rotdims_270((dim_a, dim_b)) = dim_b, reverse(dim_a)

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
@inline function Base.permutedims(A::AbstractDimArray, perm)
    rebuild(A, permutedims(parent(A), dimnum(A, Tuple(perm))), sortdims(dims(A), Tuple(perm)))
end
@inline function Base.PermutedDimsArray(A::AbstractDimArray{T,N}, perm) where {T,N}
    perm_inds = dimnum(A, Tuple(perm))
    iperm_inds = invperm(perm_inds)
    data = parent(A)
    data_perm = PermutedDimsArray{T,N,perm_inds,iperm_inds,typeof(data)}(data)
    rebuild(A, data_perm, sortdims(dims(A), Tuple(perm)))
end

# Concatenation
Base.cat(A1::AbstractDimArray, As::AbstractDimArray...; dims) = _cat(dims, A1, As...)

function _cat(catdim::Union{Int,Symbol,DimOrDimType}, A1::AbstractDimArray, As::AbstractDimArray...)
    _cat((catdim,), A1, As...)
end
function _cat(catdims::Tuple, A1::AbstractDimArray, As::AbstractDimArray...)
    Xin = (A1, As...)
    newcatdims = map(catdims) do catdim
        # If catdim is already constructed, its the new dimension
        if catdim isa Dimension
            return catdim
        end
        # Otherwise build a new dimension/lookup
        if catdim isa Int
            if hasdim(A1, catdim)
                catdim = basedims(dims(A1, catdim))
            else
                return AnonDim(NoLookup()) # TODO: handle larger dimension extensions, this is half broken
            end
        else
            catdim = basedims(key2dim(catdim))
        end
        # Dimension Types and Symbols
        if all(x -> hasdim(x, catdim), Xin)
            # We concatenate an existing dimension
            newcatdim = if lookup(A1, catdim) isa NoLookup
                rebuild(catdim, NoLookup())
            else
                # vcat the index for the catdim in each of Xin
                joindims = map(A -> dims(A, catdim), Xin)
                if !check_cat_lookups(joindims...)
                    return rebuild(catdim, NoLookup())
                end
                _vcat_dims(joindims...)
            end
        else
            # Concatenate new dims
            if all(map(x -> hasdim(refdims(x), catdim), Xin))
                if catdim isa Dimension && val(catdim) isa AbstractArray && !(lookup(catdim) isa NoLookup{AutoIndex})
                    # Combine the refdims properties with the passed in catdim
                    set(refdims(first(Xin), catdim), catdim)
                else
                    # vcat the refdims
                    _vcat_dims(map(x -> refdims(x, catdim), Xin)...)
                end
            else
                # Use the catdim as the new dimension
                catdim
            end
        end
    end

    inserted_dims = dims(newcatdims, dims(A1))
    appended_dims = otherdims(newcatdims, inserted_dims)

    inserted_dnums = dimnum(A1, inserted_dims)
    appended_dnums = ntuple(i -> i + length(dims(A1)), length(appended_dims))
    cat_dnums = (inserted_dnums..., appended_dnums...)

    # Warn if dims or val do not match, and cat the parent
    if !comparedims(Bool, map(x -> otherdims(x, newcatdims), Xin)...;
        order=true, val=true, warn=" Can't `cat` AbstractDimArray, applying to `parent` object."
    )
        return Base.cat(map(parent, Xin)...; dims=cat_dnums)
    end

    updated_dims = setdims(dims(A1), inserted_dims)
    newdims = (updated_dims..., appended_dims...)
    newrefdims = otherdims(refdims(A1), newcatdims)
    newA = Base.cat(map(parent, Xin)...; dims=cat_dnums)
    return rebuild(A1, newA, format(newdims, newA), newrefdims)
end

function Base.hcat(As::Union{AbstractDimVector,AbstractDimMatrix}...)
    Base.cat(As; dims=2)
    A1 = first(As)
    catdim = if A1 isa AbstractDimVector
        AnonDim()
    else
        joindims = map(last ∘ dims, As)
        check_cat_lookups(joindims...) || return Base.hcat(map(parent, As)...)
        _vcat_dims(joindims...)
    end
    noncatdim = dims(A1, 1)
    # Make sure this is the same dimension for all arrays
    if !comparedims(Bool, map(x -> dims(x, 1), As)...;
        val=true, warn=" Can't `hcat` AbstractDimArray, applying to `parent` object."
    )
        return Base.hcat(map(parent, As)...)
    end
    newdims = (noncatdim, catdim)
    newA = hcat(map(parent, As)...)
    return rebuild(A1, newA, format(newdims, newA))
end

function Base.vcat(As::Union{AbstractDimVector,AbstractDimMatrix}...)
    A1 = first(As)
    firstdims = map(first ∘ dims, As)
    check_cat_lookups(firstdims...) || return Base.vcat(map(parent, As)...)
    newdims = if A1 isa AbstractDimVector
        catdim = _vcat_dims(firstdims...)
        (catdim,)
    else
        # Make sure this is the same dimension for all arrays
        if !comparedims(Bool, map(x -> dims(x, 2), As)...;
            val=true, warn = " Can't `vcat` AbstractDimArray, applying to `parent` object."
        )
            return Base.vcat(map(parent, As)...)
        end
        catdim = _vcat_dims(firstdims...)
        noncatdim = dims(A1, 2)
        (catdim, noncatdim)
    end
    newA = vcat(map(parent, As)...)
    return rebuild(A1, newA, format(newdims, newA))
end

function Base.vcat(d1::Dimension, ds::Dimension...)
    dims = (d1, ds...)
    comparedims(dims...; length=false)
    check_cat_lookups(dims...) || return Base.vcat(map(parent, dims)...)
    return _vcat_dims(d1, ds...)
end

check_cat_lookups(dims::Dimension...) =
    _check_cat_lookups(basetypeof(first(dims)), lookup(dims)...)

# Lookups may need adjustment for `cat`
_check_cat_lookups(D, lookups::Lookup...) = _check_cat_lookup_order(D, lookups...)
_check_cat_lookups(D, l1::NoLookup, lookups::NoLookup...) = true
function _check_cat_lookups(D, l1::AbstractSampled, lookups::AbstractSampled...)
    length(lookups) > 0 || return true
    _check_cat_lookup_order(D, l1, lookups...) || return false
    _check_cat_lookups(D, span(l1), l1, lookups...)
end
function _check_cat_lookups(D, ::Regular, lookups...)
    length(lookups) > 1 || return true
    lastval = last(first(lookups))
    s = step(first(lookups))
    map(Base.tail(lookups)) do l
        if !(span(l) isa Regular)
            _mixed_span_warn(D, Regular, span(l))
            return false
        end
        if !(step(span(l)) == s)
            @warn _cat_warn_string(D, "step sizes $(step(span(l))) and $s do not match")
            return false
        end
        if !(lastval + s ≈ first(l))
            @warn _cat_warn_string(D, "`Regular` lookups do not join with the correct step size: $(lastval) + $s ≈ $(first(l)) should hold")
            return false
        end
        lastval = last(l)
        return true
    end |> all
end
function _check_cat_lookups(D, ::Explicit, lookups...)
    map(lookups) do l
        span(l) isa Explicit || _mixed_span_warn(D, Explicit, span(l))
    end |> all
end
function _check_cat_lookups(D, ::Irregular, lookups...)
    map(lookups) do l
        span(l) isa Irregular || _mixed_span_warn(D, Irregular, span(l))
    end |> all
end

function _check_cat_lookup_order(D, lookups::Lookup...)
    l1 = first(lookups)
    length(l1) == 0 && return _check_cat_lookup_order(D, Base.tail(lookups)...)
    L = basetypeof(l1)
    x = last(l1)
    if isordered(l1)
        map(Base.tail(lookups)) do lookup
            length(lookup) > 0 || return true
            if isforward(lookup)
                if isreverse(l1)
                    _cat_mixed_ordered_warn(D)
                    return false
                elseif length(lookup) == 0 || first(lookup) > x
                    x = last(lookup)
                    return true
                else
                    x = last(lookup)
                    _cat_lookup_overlap_warn(D, first(lookup), x)
                    return false
                end
            else
                if isforward(l1)
                    _cat_mixed_ordered_warn(D)
                    return false
                elseif length(lookup) == 0 || first(lookup) < x
                    x = last(lookup)
                    return true
                else
                    x = last(lookup)
                    _cat_lookup_overlap_warn(D, first(lookup), x)
                    return false
                end
            end
        end |> all
    else
        intr = intersect(lookups...)
        if length(intr) == 0
            return true
        else
            _cat_lookup_intersect_warn(D, intr)
            return false
        end
    end
end

function _vcat_dims(d1::Dimension, ds::Dimension...)
    dims = (d1, ds...)
    newlookup = _vcat_lookups(lookup(dims)...)
    return rebuild(d1, newlookup)
end

# Lookups may need adjustment for `cat`
function _vcat_lookups(lookups::Lookup...)
    newindex = _vcat_index(lookups...)
    return rebuild(lookups[1]; data=newindex)
end
function _vcat_lookups(lookups::AbstractSampled...)
    newindex = _vcat_index(lookups...)
    newlookup = _vcat_lookups(sampling(first(lookups)), span(first(lookups)), lookups...)
    return rebuild(newlookup; data=newindex)
end
function _vcat_lookups(::Any, ::Regular, lookups...)
    first(lookups)
end
function _vcat_lookups(::Intervals, ::Explicit, lookups...)
    len = mapreduce(+, lookups) do l
        size(val(span(l)), 2)
    end
    combined_span_mat = similar(val(span(first(lookups))), 2, len)
    i = 1
    foreach(lookups) do l
        span_mat = val(span(l))
        l = size(span_mat, 2)
        combined_span_mat[:, i:i+l - 1] .= span_mat
        i += l
    end
    rebuild(first(lookups); span=Explicit(combined_span_mat))
end
function _vcat_lookups(::Intervals, ::Irregular, lookups...)
    allbounds = map(bounds ∘ span, lookups)
    newbounds = minimum(map(first, allbounds)), maximum(map(last, allbounds))
    rebuild(lookups[1]; span=Irregular(newbounds))
end
function _vcat_lookups(::Points, ::Irregular, lookups...)
    rebuild(first(lookups); span=Irregular(nothing, nothing))
end

_vcat_index(A1::NoLookup, A::NoLookup...) = OneTo(mapreduce(length, +, (A1, A...)))
# TODO: handle vcat OffsetArrays?
# Otherwise just vcat. TODO: handle order breaking vcat?
# function _vcat_index(lookup::Lookup, lookups...)
    # _vcat_index(span(lookup), lookup, lookups...)
# end
function _vcat_index(lookup1::Lookup, lookups::Lookup...)
    shifted = map((lookup1, lookups...)) do l
        parent(maybeshiftlocus(locus(lookup1), l))
    end
    return reduce(vcat, shifted)
end

@noinline _cat_mixed_ordered_warn(D) = @warn _cat_warn_string(D, "`Ordered` lookups are mixed `ForwardOrdered` and `ReverseOrdered`")
@noinline _cat_lookup_overlap_warn(D, x1, x2) = @warn _cat_warn_string(D, "`Ordered` lookups are misaligned at $x2 and $x1")
@noinline _cat_lookup_intersect_warn(D, intr) = @warn _cat_warn_string(D, "`Unorderd` lookups share values: $intr")

@noinline _mixed_span_error(D, S, span) = throw(DimensionMismatch(_span_string(D, S, span)))
@noinline function _mixed_span_warn(D, S, span)
    @warn _span_string(D, S, span)
    return false
end
_span_string(D, S, span) = _cat_warn_string(D, "not all lookups have `$S` spans. Found $(basetypeof(span))")
_cat_warn_string(D, message) = """
`cat` cannot concatenate `Dimension`s, falling back to `parent` type:
$message on dimension $D.

To fix for `AbstractDimArray`, pass new lookup values as `cat(As...; dims=$D(newlookupvals))` keyword or `dims=$D()` for empty `NoLookup`.
"""

function Base._typed_stack(::Colon, ::Type{T}, ::Type{S}, A, Aax=_iterator_axes(A)) where {T,S<:AbstractDimArray}
    origdims = map(dims, A)
    _A = parent.(A)
    t = eltype(_A)
    _A = Base._typed_stack(:, T, t, A)

    if !comparedims(Bool, origdims...;
        order=true, val=true, warn=" Can't `stack` AbstractDimArray, applying to `parent` object."
    )
        return _A
    else
        DimArray(_A, (first(origdims)..., AnonDim()))
    end
end

function Base._dim_stack(newdim::Integer, ::Type{T}, ::Type{S}, A) where {T,S<:AbstractDimArray}
    origdims = dims.(A)
    _A = parent.(A)
    t = eltype(_A)
    _A = Base._dim_stack(newdim, T, t, A)

    if !comparedims(Bool, origdims...;
        order=true, val=true, warn=" Can't `stack` AbstractDimArray, applying to `parent` object."
    )
        return _A
    end

    newdims = first(origdims)
    newdims = ntuple(length(newdims) + 1) do d
        if d == newdim
            AnonDim()
        else # Return the old dimension, shifted across once if it comes after the new dim
            newdims[d-(d>newdim)]
        end
    end
    DimArray(_A, newdims)
end

"""
    Base.stack(A::AbstractVector{<:AbstractDimArray}; dims=Pair(ndims(A[1])+1, AnonDim()))

Stack arrays along a new axis while preserving the dimensional information of other axes.

The optional keyword argument `dims` has the following behavior:
- `dims isa Integer`: The dimension of the new axis is an `AnonDim` at position `dims`
- `dims isa Dimension`: The new axis is at `ndims(A[1])+1` and has a dimension of `dims`.
- `dims isa Pair{Integer, Dimension}`: The new axis is at `first(dims)` and has a dimension
  of `last(dims)`.

If `dims` contains a `Dimension`, that `Dimension` must have the same length as A.

# Examples
```julia-repl
julia> da = DimArray([1 2 3; 4 5 6], (X(10:10:20), Y(300:-100:100)));
julia> db = DimArray([6 5 4; 3 2 1], (X(10:10:20), Y(300:-100:100)));

# Stack along a new dimension `Z`
julia> dc = stack([da, db], dims=3=>Z(1:2))
╭─────────────────────────╮
│ 2×3×2 DimArray{Int64,3} │
├─────────────────────────┴──────────────────────────────── dims ┐
  ↓ X Sampled{Int64} 10:10:20 ForwardOrdered Regular Points,
  → Y Sampled{Int64} 300:-100:100 ReverseOrdered Regular Points,
  ↗ Z 1:2
└────────────────────────────────────────────────────────────────┘

julia> dims(dc, 3) == Z(1:2)
true
julia> parent(dc) == stack(map(parent, [da, db]), dims=3)
true
```
"""
function Base.stack(A::AbstractVector{<:AbstractDimArray}; dims=Pair(ndims(A[1])+1, AnonDim()))
    if dims isa Integer
        dims = dims => AnonDim()
    elseif dims isa Dimension
        dims = ndims(A[1])+1 => dims
    end

    B = Base._stack(first(dims), A)

    if B isa AbstractDimArray
        newdims = ntuple(ndims(B)) do d
            if d == first(dims) # Use the new provided dimension
                last(dims)
            else
                DimensionalData.dims(B, d)
            end
        end
        B = rebuild(B; dims=format(newdims, B))
    end
    return B
end

function Base.inv(A::AbstractDimArray{T,2}) where T
    newdata = inv(parent(A))
    newdims = reverse(dims(A))
    rebuild(A, newdata, newdims)
end

# Index breaking

# TODO: change the index and traits of the reduced dimension and return a DimArray.
Base.unique(A::AbstractDimArray; dims::Union{DimOrDimType,Int,Colon}=:) = _unique(A, dims)
Base.unique(A::AbstractDimArray{<:Any,1}) = unique(parent(A))

_unique(A::AbstractDimArray, dims) = unique(parent(A); dims=dimnum(A, dims))
_unique(A::AbstractDimArray, dims::Colon) = unique(parent(A); dims=:)

Base.diff(A::AbstractDimVector; dims=1) = _diff(A, dimnum(A, dims))
Base.diff(A::AbstractDimArray; dims) = _diff(A, dimnum(A, dims))

@inline function _diff(A::AbstractDimArray{<:Any,N}, dims::Integer) where {N}
    r = axes(A)
    # Copied from Base.diff
    r0 = ntuple(i -> i == dims ? UnitRange(1, last(r[i]) - 1) : UnitRange(r[i]), N)
    rebuildsliced(A, diff(parent(A); dims=dimnum(A, dims)), r0)
end

# Forward `replace` to parent objects
function Base._replace!(new::Base.Callable, res::AbstractDimArray, A::AbstractDimArray, count::Int)
    Base._replace!(new, parent(res), parent(A), count)
    return res
end

Base.reverse(A::AbstractDimArray; dims=:) = _reverse(A, dims)

function _reverse(A::AbstractDimArray, ::Colon)
    newdims = _reverse(DD.dims(A))
    newdata = reverse(parent(A))
    # Use setdims here because newdims is not all the dims
    setdims(rebuild(A, newdata), newdims)
end
function _reverse(A::AbstractDimArray, dims)
    newdims = _reverse(DD.dims(A, dims))
    newdata = reverse(parent(A); dims=dimnum(A, dims))
    # Use setdims here because newdims is not all the dims
    setdims(rebuild(A, newdata), newdims)
end
_reverse(dims::Tuple{Vararg{Dimension}}) = map(d -> reverse(d), dims)
_reverse(dim::Dimension) = reverse(dim)

# Dimension
Base.reverse(dim::Dimension) = rebuild(dim, reverse(lookup(dim)))

Base.dataids(A::AbstractDimArray) = Base.dataids(parent(A))

# We need to override copy_similar because our `similar` doesn't work with size changes
# Fixed in Base in https://github.com/JuliaLang/julia/pull/53210
LinearAlgebra.copy_similar(A::AbstractDimArray, ::Type{T}) where {T} = copyto!(similar(A, T), A)
