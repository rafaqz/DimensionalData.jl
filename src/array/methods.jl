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

@inline _dropinds(A, dims::DimTuple) = dims2indices(A, map(d -> rebuild(d, 1), dims))
@inline _dropinds(A, dim::Dimension) = dims2indices(A, rebuild(dim, 1))


# Function application

function Base.map(f, As::AbstractDimArray...)
    comparedims(As...)
    newdata = map(f, map(parent, As)...)
    rebuild(first(As); data=newdata)
end

function Base.mapslices(f, A::AbstractDimArray; dims=1, kw...)
    dimnums = dimnum(A, _astuple(dims))
    data = mapslices(f, parent(A); dims=dimnums, kw...)
    rebuild(A, data)
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
        all(hasdim(A, dimtuple...)) || throw(DimensionMismatch("A doesn't have all dimensions $dims"))
        _eachslice(A, dimtuple)
    end
else
    @inline function Base.eachslice(A::AbstractDimArray; dims, drop=true)
        dimtuple = _astuple(dims)
        all(hasdim(A, dimtuple...)) || throw(DimensionMismatch("A doesn't have all dimensions $dims"))
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
        # Int
        if catdim isa Dimension 
            return catdim
        end
        if catdim isa Int 
            if hasdim(A1, catdim)
                catdim = basedims(dims(A1, catdim))
            else
                return AnonDim(NoLookup())
            end
        else
            catdim = basedims(key2dim(catdim))
        end
        # Dimension
        # Dimension Types and Symbols
        if all(x -> hasdim(x, catdim), Xin)
            # We concatenate an existing dimension
            newcatdim = if lookup(A1, catdim) isa NoLookup
                rebuild(catdim, NoLookup())
            else
                # vcat the index for the catdim in each of Xin
                allcatdims = map(x -> dims(x, catdim), Xin)
                reduce(vcat, allcatdims)
            end
        else
            # Concatenate new dims
            if all(map(x -> hasdim(refdims(x), catdim), Xin))
                samedims = map(A -> dims(A, catdim), Xin)
                check_cat_lookups(samedims...) || return nothing
                if catdim isa Dimension && val(catdim) isa AbstractArray && !(lookup(catdim) isa NoLookup{AutoIndex})
                    # Combine the refdims properties with the passed in catdim
                    set(refdims(first(Xin), catdim), catdim)
                else
                    # vcat the refdims 
                    reduce(vcat, map(x -> refdims(x, catdim), Xin))
                end
            else
                # Use the catdim as the new dimension
                catdim
            end
        end
    end
    any(map(isnothing, newcatdims)) && return Base.cat(map(parent, Xin)...; dims=cat_dnums)

    inserted_dims = dims(newcatdims, dims(A1))
    appended_dims = otherdims(newcatdims, inserted_dims)

    inserted_dnums = dimnum(A1, inserted_dims)
    appended_dnums = ntuple(i -> i + length(dims(A1)), length(appended_dims))
    cat_dnums = (inserted_dnums..., appended_dnums...)
    # Warn if dims or val do not match, and cat the parent
    if !comparedims(Bool, map(x -> otherdims(x, newcatdims), Xin)...; order=true, val=true, warn=true)
        return Base.cat(map(parent, Xin)...; dims=cat_dnums)
    end

    updated_dims = setdims(dims(A1), inserted_dims)
    newdims = (updated_dims..., appended_dims...)
    newrefdims = otherdims(refdims(A1), newcatdims)
    newA = Base.cat(map(parent, Xin)...; dims=cat_dnums)
    return rebuild(A1, newA, format(newdims, newA), newrefdims)
end

function Base.hcat(As::Union{AbstractDimVector,AbstractDimMatrix}...)
    A1 = first(As)
    catdim = if A1 isa AbstractDimVector
        AnonDim()
    else
        vcat(map(last ∘ dims, As)...)
    end
    noncatdim = dims(A1, 1)
    # Make sure this is the same dimension for all arrays
    if !comparedims(Bool, map(x -> dims(x, 1), As)...; val=true, warn=true)
        return Base.cat(map(parent, Xin)...; dims=cat_dnums)
    end
    newdims = (noncatdim, catdim)
    newA = hcat(map(parent, As)...)
    return rebuild(A1, newA, format(newdims, newA))
end

check_cat_lookups(dims::Dimension...) = _check_cat_lookups(basetypeof(first(dims)), lookup(dims)...)

# LookupArrays may need adjustment for `cat`
_check_cat_lookups(D, lookups::LookupArray...) = _check_cat_lookup_order(D, lookups...)
_check_cat_lookups(D, lookups::AbstractSampled...) =
    _check_cat_lookups(D, span(first(lookups)), lookups...)
function _check_cat_lookups(D, ::Regular, lookups...)
    _check_cat_lookup_order(D, lookups...) || return false
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

function _check_cat_lookup_order(D, lookups::LookupArray...)
    l1 = first(lookups)
    L = basetypeof(l1)
    x = last(l1)
    if order(l1) isa Ordered 
        map(lookups) do lookup
            if order(lookup) isa ForwardOrdered
                if length(lookup) == 0 || first(lookup) > x
                    x = last(lookup)
                    return true
                else
                    x = last(lookup)
                    _cat_lookup_overlap_warn(D, first(lookup), x)
                    return false
                end
            else
                if length(lookup) == 0 || first(lookup) < x 
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

function Base.vcat(As::Union{AbstractDimVector,AbstractDimMatrix}...)
    A1 = first(As)
    catdim = vcat(map(first ∘ dims, As)...)
    newdims = if A1 isa AbstractDimVector
        (catdim,)
    else
        noncatdim = dims(A1, 2)
        # Make sure this is the same dimension for all arrays
        if !comparedims(Bool, map(x -> dims(x, 1), As)...; val=true, warn=true)
            return Base.cat(map(parent, Xin)...; dims=cat_dnums)
        end
        (catdim, noncatdim)
    end
    newA = vcat(map(parent, As)...)
    return rebuild(A1, newA, format(newdims, newA))
end

function Base.vcat(d1::Dimension, ds::Dimension...)
    comparedims(d1, ds...; length=false)
    newlookup = _vcat_lookups(lookup((d1, ds...))...)
    rebuild(d1, newlookup)
end

# LookupArrays may need adjustment for `cat`
function _vcat_lookups(lookups::LookupArray...)
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
# function _vcat_index(lookup::LookupArray, lookups...) 
    # _vcat_index(span(lookup), lookup, lookups...) 
# end
function _vcat_index(lookup1::LookupArray, lookups::LookupArray...)
    xl = length(lookup1) > 0 ? last(lookup1) : nothing
    shifted = map((lookup1, lookups...)) do l
        parent(maybeshiftlocus(locus(lookup1), l))
    end
    return reduce(vcat, shifted)
end

@noinline _cat_lookup_overlap_warn(D, x1, x2) = @warn _cat_warn_string(D, "`Ordered` lookups overlap at $x2 and $x1")
@noinline _cat_lookup_intersect_warn(D, intr) = @warn _cat_warn_string(D, "`Unorderd` lookups share values: $intr")

@noinline _mixed_span_error(D, S, span) = throw(DimensionMismatch(_span_string(T, span)))
@noinline function _mixed_span_warn(D, S, span) 
    @warn _span_string(D, S, span)
    return false
end
_span_string(D, S, span) = _cat_warn_string(D, "not all lookups have `$S` spans. Found $(basetypeof(span))")
_cat_warn_string(D, message) = "`cat` cannot retain named dimensions: $message on dimension $D. \nTo fix, pass a constructed $D with new lookup values as `dims` keyword or $D() for NoLookup."


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

function Base.reverse(A::AbstractDimArray; dims=1)
    newdims = _reverse(DD.dims(A, dims))
    newdata = reverse(parent(A); dims=dimnum(A, dims))
    # Use setdims here because newdims is not all the dims
    setdims(rebuild(A, newdata), newdims)
end

_reverse(dims::Tuple) = map(d -> reverse(d), dims)
_reverse(dim::Dimension) = reverse(dim)

# Dimension
Base.reverse(dim::Dimension) = rebuild(dim, reverse(lookup(dim)))

Base.dataids(A::AbstractDimArray) = Base.dataids(parent(A)) 
