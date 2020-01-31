"""
Selectors indicate that index values are not indices, but points to
be selected from the dimension values, such as DateTime objects on a Time dimension.
"""
abstract type Selector{T} end

val(m::Selector) = m.val

"""
    At(x)

Selector that exactly matches the value on the passed-in dimensions, or throws an error.
For ranges and arrays, every value must match an existing value - not just the end points.
"""
struct At{T,A,R} <: Selector{T}
    val::T
    atol::A
    rtol::R
end
At(val::Union{Number,AbstractArray{<:Number},Tuple{<:Number,Vararg}};
   atol=zero(eltype(val)),
   rtol=(atol > zero(eltype(val)) ? zero(rtol) : Base.rtoldefault(eltype(val)))
  ) = At{typeof.((val, atol, rtol))...}(val, atol, rtol)
At(val; atol=nothing, rtol=nothing) =
    At{typeof.((val, atol, rtol))...}(val, atol, rtol)

atol(sel::At) = sel.atol
rtol(sel::At) = sel.rtol

"""
    Near(x)

Selector that selects the nearest index to its contained value(s)
"""
struct Near{T} <: Selector{T}
    val::T
end

"""
    Between(a, b)

Selector that retreive all indices located between 2 values.
"""
struct Between{T<:Union{Tuple{Any,Any},Nothing}} <: Selector{T}
    val::T
end
Between(args...) = Between{typeof(args)}(args)
Between(x::Tuple) = Between{typeof(x)}(x)

# Get the dims in the same order as the grid
# This would be called after RegularGrid and/or CategoricalGrid
# dimensions are removed
dims2indices(grid::TransformedGrid, dims::Tuple, lookups::Tuple, emptyval) =
    sel2indices(grid, dims, map(val, permutedims(dimz, dims(grid))))

sel2indices(A::AbstractArray, lookup) = sel2indices(dims(A), lookup)
sel2indices(dims::Tuple, lookup) = sel2indices(dims, (lookup,))
sel2indices(dims::Tuple, lookup::Tuple) = sel2indices(map(grid, dims), dims, lookup)
sel2indices(grids, dims::Tuple, lookup::Tuple) =
    (sel2indices(grids[1], dims[1], lookup[1]),
     sel2indices(tail(grids), tail(dims), tail(lookup))...)
    sel2indices(grids::Tuple{}, dims::Tuple{}, lookup::Tuple{}) = ()

# Handling base cases:
sel2indices(grid, dim::AbDim, lookup::StandardIndices) = lookup

# At selector
sel2indices(grid, dim::AbDim, sel::At) = at(dim, sel, val(sel))
sel2indices(grid, dim::AbDim, sel::At{<:Tuple}) =
    [at.(Ref(dim), Ref(sel), val(sel))...]
sel2indices(grid, dim::AbDim, sel::At{<:AbstractVector}) =
    at.(Ref(dim), Ref(sel), val(sel))

# Near selector
sel2indices(grid::T, dim::AbDim, sel::Near) where T<:Union{CategoricalGrid,UnknownGrid,NoGrid} =
    throw(ArgumentError("`Near` has no meaning with `$T`. Use `At`"))
sel2indices(grid::AbstractAlignedGrid, dim::AbDim, sel::Near) =
    near(dim, sel, val(sel))
sel2indices(grid::AbstractAlignedGrid, dim::AbDim, sel::Near{<:Tuple}) =
    [near.(Ref(dim), Ref(sel), val(sel))...]
sel2indices(grid::AbstractAlignedGrid, dim::AbDim, sel::Near{<:AbstractVector}) =
    near.(Ref(dim), Ref(sel), val(sel))

# Between selector
sel2indices(grid, dim::AbDim, sel::Between{<:Tuple}) = between(dim, sel)


# Transformed grid

# We use the transformation from the first TransformedGrid dim.
# In practice the others could be empty.
sel2indices(grids::Tuple{Vararg{<:TransformedGrid}}, dims::AbDimTuple,
            sel::Tuple{Vararg{<:Selector}}) =
    map(to_int, sel, val(dims[1])([map(val, sel)...]))

to_int(::At, x) = convert(Int, x)
to_int(::Near, x) = round(Int, x)

# Do the input values need some kind of scalar conversion?
# what is the scale of these lookup matrices?
# sel2indices(grid::LookupGrid, sel::Tuple{Vararg{At}}) =
    # lookup(grid)[map(val, sel)...]


at(dim::AbDim, sel::At, val) =
    _relate(dim, at(dim, val, atol(sel), rtol(sel)))
at(dim::AbDim, selval, atol::Nothing, rtol::Nothing) = begin
    i = findfirst(x -> x == selval, val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end
at(dim::AbDim, selval, atol, rtol) = begin
    # This is not particularly efficient.
    # It should be separated out for unordered
    # dims and otherwise treated as an ordered list.
    i = findfirst(x -> isapprox(x, selval; atol=atol, rtol=rtol), val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end


near(dim::AbDim, sel::Near, val) =
    _relate(dim, near(indexorder(dim), dim::AbDim, val))
near(::Unordered, dim, selval) =
    throw(ArgumentError("`Near` has no meaning in an `Unordered` grid"))
near(ord, dim, selval) = begin
    index = val(dim)
    i = searchsortedfirst(index, selval; rev=isrev(ord))
    # Make sure index is withing bounds
    if i > lastindex(index)
        lastindex(index)
    elseif i <= firstindex(index)
        firstindex(index)
    # Find nearest index
    elseif _isnearest(ord, selval, index, i)
        i
    else
        i - 1
    end
end

_isnearest(::Forward, selval, index, i) = abs(index[i] - selval) <= abs(index[i-1] - selval)
_isnearest(::Reverse, selval, index, i) = abs(index[i] - selval) < abs(index[i-1] - selval)

between(dim::AbDim, sel::Between) = between(indexorder(dim), dim, val(sel))
between(::Unordered, dim::AbDim, sel) =
    throw(ArgumentError("Cannot use `Between` on an unordered grid"))
between(ord::Reverse, dim::AbDim, sel) = begin
    low, high = _sorttuple(sel)
    a = searchsortedlast(val(dim), high; rev=true)
    b = searchsortedfirst(val(dim), low; rev=true)
    a, b = _bounded(a, dim), _bounded(b, dim)
    _relate(dim, a:b)
end
between(ord::Forward, dim::AbDim, sel) = begin
    low, high = _sorttuple(sel)
    a = searchsortedfirst(val(dim), low)
    b = searchsortedlast(val(dim), high)
    a, b = _bounded(a, dim), _bounded(b, dim)
    _relate(dim, a:b)
end

_bounded(x, dim) = 
    if x > lastindex(dim)
        lastindex(dim)
    elseif x <= firstindex(dim)
        firstindex(dim)
    else
        x
    end


_mayberev(::Forward, (a, b)) = (a, b)
_mayberev(::Reverse, (a, b)) = (b, a)

_sorttuple((a, b)) = a < b ? (a, b) : (b, a)

# Selector indexing without dim wrappers. Must be in the right order!
Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{Union{Selector, StandardIndices}}) =
    getindex(a, sel2indices(a, I)...)
Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, I::Vararg{Selector}) =
    setindex!(a, x, sel2indices(a, I)...)
Base.view(a::AbDimArray, I::Vararg{Union{Selector, StandardIndices}}) =
    view(a, sel2indices(a, I)...)
