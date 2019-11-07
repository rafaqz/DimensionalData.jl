"""
Selectors indicate that index values are not indices, but points to 
be selected from the dimension values, such as DateTime objects on a Time dimension.
"""
abstract type Selector{T} end

val(m::Selector) = m.val 

(::Type{T})(args...) where T <: Selector = T{typeof(args)}(args)

"""
    At(x)

Selector that exactly matches the value on the passed-in dimensions, or throws an error. 
For ranges and arrays, every value must match an existing value - not just the end points. 
"""
struct At{T} <: Selector{T}
    val::T
end

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
sel2indices(grid, dim::AbDim, sel::At) = at(dim, val(sel))
sel2indices(grid, dim::AbDim, sel::At{<:Tuple}) = [at.(Ref(dim), val(sel))...]
sel2indices(grid, dim::AbDim, sel::At{<:AbstractVector}) = at.(Ref(dim), val(sel))
sel2indices(grid, dim::AbDim{<:Any,<:AbstractCategoricalGrid}, sel::Near) = 
    throw(ArgumentError("`Near` has no meaning in a `CategoricalGrid`. Use `At`"))
sel2indices(grid, dim::AbDim, sel::Near) = near(dim, val(sel))
sel2indices(grid, dim::AbDim, sel::Near{<:Tuple}) = [near.(Ref(dim), val(sel))...]
sel2indices(grid, dim::AbDim, sel::Near{<:AbstractVector}) = near.(Ref(dim), val(sel))
sel2indices(grid::IndependentGrid{<:Ordered}, dim::AbDim, sel::Between{<:Tuple}) = 
    between(dim, val(sel))
sel2indices(grid::IndependentGrid{Unordered}, dim::AbDim, sel::Between{<:Tuple}) = 
    throw(ArgumentError("`Between` has no meaning with an `Unordered` grid"))

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


at(dim::AbDim, selval) = at(val(dim), selval) 
at(dim, selval) = begin
    # This is not particularly efficient.
    # It should be separated out for unordered categorical 
    # dims and otherwise treated as an ordered list.
    ind = findfirst(x -> x == selval, val(dim))
    ind == nothing ? throw(ArgumentError("$selval not found in $dim")) : ind
end

near(list, selval) = begin
    list = val(list)
    ind = searchsortedfirst(list, selval)
    if ind <= firstindex(list) 
        ind
    elseif abs(list[ind] - selval) < abs(list[ind-1] - selval)
        ind
    else
        ind - 1
    end
end

between(dim::AbDim, sel) = between(indexorder(dim), dim, sel)
between(::Forward, dim::AbDim, sel) = 
    rangeorder(dim, searchsortedfirst(val(dim), first(sel)), searchsortedlast(val(dim), last(sel)))
between(::Reverse, dim::AbDim, sel) = 
    rangeorder(dim, searchsortedlast(val(dim), last(sel); rev=true), 
                    searchsortedfirst(val(dim), first(sel); rev=true))

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

