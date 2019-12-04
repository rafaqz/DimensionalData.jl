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

# At selector
sel2indices(grid, dim::AbDim, sel::At) = at(dim, sel)
sel2indices(grid, dim::AbDim, sel::At{<:Tuple}) =
    [at.(Ref(dim), val(sel), atol(sel), rtol(sel))...]
sel2indices(grid, dim::AbDim, sel::At{<:AbstractVector}) =
    at.(Ref(dim), val(sel), atol(sel), rtol(sel))

# Near selector
sel2indices(grid::T, dim::AbDim, sel::Near) where T<:Union{CategoricalGrid,UnknownGrid} =
    throw(ArgumentError("`Near` has no meaning in a `$T`. Use `At`"))
sel2indices(grid::AbstractAllignedGrid, dim::AbDim, sel::Near) =
    near(dim, val(sel))
sel2indices(grid::AbstractAllignedGrid, dim::AbDim, sel::Near{<:Tuple}) =
    [near.(Ref(dim), val(sel))...]
sel2indices(grid::AbstractAllignedGrid, dim::AbDim, sel::Near{<:AbstractVector}) =
    near.(Ref(dim), val(sel))

# Between selector
sel2indices(grid, dim::AbDim, sel::Between{<:Tuple}) = between(dim, val(sel))


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
sel2indices(grid::LookupGrid, sel::Tuple{Vararg{At}}) =
    lookup(grid)[map(val, sel)...]


at(dim::AbDim, sel::At) = at(dim, val(sel), atol(sel), rtol(sel))
at(dim::AbDim, selval, atol::Nothing, rtol::Nothing) = begin
    ind = findfirst(x -> x == selval, val(dim))
    ind == nothing ? throw(ArgumentError("$selval not found in $dim")) : ind
end
at(dim::AbDim, selval, atol, rtol) = begin
    # This is not particularly efficient.
    # It should be separated out for unordered
    # dims and otherwise treated as an ordered list.
    ind = findfirst(x -> isapprox(x, selval; atol=atol, rtol=rtol), val(dim))
    ind == nothing ? throw(ArgumentError("$selval not found in $dim")) : ind
end


near(dim::AbDim, selval) = 
    near(indexorder(dim), dim::AbDim, selval)
near(indexorder::Unordered, dim, selval) =
    throw(ArgumentError("`Near` has no meaning in an `Unordered` grid"))
near(indexorder, dim, selval) = begin
    index = val(dim)
    i = searchsortedfirst(index, selval; rev=isrev(indexorder))
    if i > lastindex(index)
        lastindex(index)
    elseif i <= firstindex(index)
        firstindex(index)
    elseif abs(index[i] - selval) < abs(index[i-1] - selval)
        i
    else
        i - 1
    end
end

between(dim::AbDim, sel) = between(indexorder(dim), dim, sel)
between(::Unordered, dim::AbDim, sel) =
    throw(ArgumentError("Cannot use `Between` on an unordered dimension"))
between(::Forward, dim::AbDim, sel) =
    rangeorder(dim, searchsortedfirst(val(dim), first(sel)), searchsortedlast(val(dim), last(sel)))
between(::Reverse, dim::AbDim, sel) =
    rangeorder(dim, searchsortedfirst(val(dim), last(sel); rev=true),
                    searchsortedlast(val(dim), first(sel); rev=true))

rangeorder(dim::AbDim, lower, upper) = rangeorder(arrayorder(dim), dim, lower, upper)
rangeorder(::Forward, dim::AbDim, lower, upper) = lower:upper
rangeorder(::Reverse, dim::AbDim, lower, upper) = length(val(dim)) - upper + 1:length(val(dim)) - lower + 1


# Selector indexing without dim wrappers. Must be in the right order!
Base.@propagate_inbounds Base.getindex(a::AbstractArray, I::Vararg{Selector}) =
    getindex(a, sel2indices(a, I)...)
Base.@propagate_inbounds Base.setindex!(a::AbstractArray, x, I::Vararg{Selector}) =
    setindex!(a, x, sel2indices(a, I)...)
Base.view(a::AbstractArray, I::Vararg{Selector}) =
    view(a, sel2indices(a, I)...)

