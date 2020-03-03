"""
Selectors indicate that index values are not indices, but points to
be selected from the dimension values, such as DateTime objects on a Time dimension.
"""
abstract type Selector{T} end

const SelectorOrStandard = Union{Selector, StandardIndices}

val(m::Selector) = m.val
rebuild(sel::Selector, val) = basetypeof(sel)(val) 


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
    In(x)

Selector that selects the interval the value falls in.
"""
struct In{T} <: Selector{T}
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
sel2indices(grid, dim::Dimension, lookup::StandardIndices) = lookup

# At selector
sel2indices(grid, dim::Dimension, sel::At{<:AbstractVector}) =
    map(v -> at(dim, rebuild(sel, v)), val(sel))
sel2indices(grid, dim::Dimension, sel::At) = at(dim, sel)

# Near selector
sel2indices(grid::T, dim::Dimension, sel::Near) where T =
    throw(ArgumentError("`Near` has no meaning with `$T`. Use `At`"))
sel2indices(grid::PointGrid, dim::Dimension, sel::Near{<:AbstractVector}) =
    map(v -> sel2indices(grid, dim, Near(v)), val(sel))
sel2indices(grid::PointGrid, dim::Dimension, sel::Near) = 
    near(dim, val(sel))

# In selector
sel2indices(grid::T, dim::Dimension, sel::In) where T =
    throw(ArgumentError("`In` has no meaning with `$T`. Use `At`"))
sel2indices(grid::CategoricalGrid, dim::Dimension, sel::In) = 
    sel2indices(grid, dim, At(val(sel))) 
sel2indices(grid::IntervalGrid, dim::Dimension, sel::In{<:AbstractVector}) =
    map(v -> sel2indices(grid, dim, In(v)), val(sel))
sel2indices(grid::IntervalGrid, dim::Dimension, sel::In) = 
    _in(dim, val(sel))

# Between selector
sel2indices(grid, dim::Dimension, sel::Between{<:Tuple}) =
    between(dim, sel)


# Transformed grid

# We use the transformation from the first TransformedGrid dim.
# In practice the others could be empty.
sel2indices(grids::Tuple{Vararg{<:TransformedGrid}}, dims::DimTuple,
            sel::Tuple{Vararg{<:Selector}}) =
    map(to_int, sel, val(dims[1])([map(val, sel)...]))

to_int(::At, x) = convert(Int, x)
to_int(::Near, x) = round(Int, x)

# Do the input values need some kind of scalar conversion?
# what is the scale of these lookup matrices?
# sel2indices(grid::LookupGrid, sel::Tuple{Vararg{At}}) =
    # lookup(grid)[map(val, sel)...]
    


at(dim::Dimension, sel::At) =
    _maybereorder(at(dim, val(sel), atol(sel), rtol(sel)), dim)
at(dim, selval, atol::Nothing, rtol::Nothing) = begin
    i = findfirst(x -> x == selval, val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end
at(dim, selval, atol, rtol) = begin
    # This is not particularly efficient.  # It should be separated out for unordered
    # dims and otherwise treated as an ordered list.
    i = findfirst(x -> isapprox(x, selval; atol=atol, rtol=rtol), val(dim))
    i == nothing && throw(ArgumentError("$selval not found in $dim"))
    return i
end

near(dim::Dimension, selval) =
    _fix(near(indexorder(dim), grid(dim), dim, selval), dim)
near(::Unordered, grid, dim, selval) =
    throw(ArgumentError("`Near` has no meaning in an `Unordered` grid"))
near(ord::Order, grid, dim, selval) = begin
    i = _bounded(searchsortedfirst(val(dim), selval; rev=isrev(ord)), dim)
    if isrev(ord)
        if i >= lastindex(dim)
            lastindex(dim)
        else
            abs(dim[i] - selval) <= abs(dim[i + 1] - selval) ? i : i + 1
        end
    else
        if i <= firstindex(dim)
            firstindex(dim)
        else
            abs(dim[i] - selval) <= abs(dim[i - 1] - selval) ? i : i - 1
        end
    end
end

_in(dim::Dimension, selval) =
    _maybereorder(_in(indexorder(dim), grid(dim), dim, selval), dim)

_in(ord::Unordered, grid, dim, selval) =
    throw(ArgumentError("`In` has no meaning in an `Unordered` grid"))
_in(ord::Order, grid::IntervalGrid, dim, selval) =
    _in(locus(grid), ord, grid, dim, selval)

_in(::Start, ord::Order, grid, dim, selval) = begin
    i = searchsortedlast(val(dim), selval; rev=isrev(ord))
    checkbounds(val(dim), i)
    i
end
_in(::End, ord::Order, grid, dim, selval) = begin
    i = searchsortedfirst(val(dim), selval; rev=isrev(ord))
    checkbounds(val(dim), i)
    i
end
_in(::Center, ord::Order, grid::IntervalGrid, dim, selval) = begin
    i = searchsortedlast(val(dim), selval; rev=isrev(ord))
    checkbounds(val(dim), i)
    if isrev(ord)
        if i == firstindex(dim)
            firstindex(dim)
        else
            (dim[i] + dim[i - 1]) / 2 <= selval ? i - 1 : i
        end
    else
        if i == lastindex(dim) 
            lastindex(dim)
        else
            (dim[i] + dim[i + 1]) / 2 <= selval ? i + 1 : i
        end
    end
end



between(dim::Dimension, sel) = between(indexorder(dim), dim, val(sel))
between(::Unordered, dim::Dimension, sel) =
    throw(ArgumentError("Cannot use `Between` on an unordered grid"))
between(ord::Reverse, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel)
    a = searchsortedlast(val(dim), high; rev=true)
    b = searchsortedfirst(val(dim), low; rev=true)
    a, b = _bounded(a, dim), _bounded(b, dim)
    relate(dim, a:b)
end
between(ord::Forward, dim::Dimension, sel) = begin
    low, high = _sorttuple(sel)
    a = searchsortedfirst(val(dim), low)
    b = searchsortedlast(val(dim), high)
    a, b = _bounded(a, dim), _bounded(b, dim)
    relate(dim, a:b)
end

_fix(i::Int, dim::Dimension) = _maybereorder(_bounded(i, dim), dim)

_bounded(i::Int, dim::Dimension) =
    if i > lastindex(dim)
        lastindex(dim)
    elseif i <= firstindex(dim)
        firstindex(dim)
    else
        i
    end


_maybereorder(i::Int, dim::Dimension) = 
    maybeflip(relationorder(dim), dim, i)

_sorttuple((a, b)) = a < b ? (a, b) : (b, a)

# Selector indexing without dim wrappers. Must be in the right order!
Base.@propagate_inbounds Base.getindex(a::AbDimArray, I::Vararg{SelectorOrStandard}) =
    getindex(a, sel2indices(a, I)...)
Base.@propagate_inbounds Base.setindex!(a::AbDimArray, x, I::Vararg{SelectorOrStandard}) =
    setindex!(a, x, sel2indices(a, I)...)
Base.view(a::AbDimArray, I::Vararg{SelectorOrStandard}) =
    view(a, sel2indices(a, I)...)
