"""
Selection modes define how indexed data will be selected 
when given coordinates, times or other dimension criteria 
that may not match the values at any specific indices.
"""
abstract type SelectionMode{V} end
val(m::SelectionMode) = m.val 

"""
    At()
Selection mode for `select()` that exactly matches the value on the 
passed-in dimensions, or throws an error. For ranges and arrays, every
value must match an existing value - not just the end points. 
To select (inclusively) between exact dimension endpoints, use a 2 tuple.
"""
struct At{V} <: SelectionMode{V}
    val::V
end
At(args...) = At{typeof(args)}(args)
At() = At{Nothing}(nothing)

struct Near{V} <: SelectionMode{V}
    val::V
end
Near(args...) = Near{typeof(args)}(args)
Near() = Near{Nothing}(nothing)

"""
    Between()
Selection mode for `select()`, retreiving values inside a 
2 tuple of bounds passed in with a dimension. Only
available for NTuple{2}.
"""
struct Between{V<:Union{Tuple{Any,Any},Nothing}} <: SelectionMode{V}
    val::V
end
Between() = Between{Nothing}(nothing)
Between(args...) = Between{typeof(args)}(args)
Between(x::Tuple) = Between{typeof(x)}(x)

"""
Allows the X.Near(2) syntax

Should it allow lower and title case, or just title?
Title would be safer for avoiding field clashes and 
does suggest its converted to a constructor. But lower 
is simpler and easier to type.
"""
Base.getproperty(t::Type{T}, x::Symbol) where T <: AbstractDimension = begin
    if x === :At || x === :at
        (args...) -> T(At(args...))
    elseif x === :Near || x === :near
        (args...) -> T(Near(args...))
    elseif x === :Between || x === :between
        (args...) -> T(Between(args...))
    else
        getfield(t, x)
    end
end

select(a, I...) = a[sel2indices(dims(a), permutedims(I, dims(a)))...]
selectview(a, I...) = view(a, sel2indices(dims(a), permutedims(I, dims(a)))...)

sel2indices(dims::AbDimTuple, I) =
    (sel2indices(dims[1], I[1]), sel2indices(tail(dims), tail(I))...)
sel2indices(::Tuple{}, ::Tuple{}) = ()


# Default is At()
sel2indices(dim::AbDim, seldim) = sel2indices(dim::AbDim, val(seldim), At()) 
sel2indices(dims::AbDim, seldim::Nothing, args...) = Colon()
sel2indices(dims::AbDim, seldim::Colon, args...) = Colon()


# TODO: make these efficient

# At
sel2indices(dim::AbDim, seldim::AbDim{<:At}) = 
    sel2indices(dim, val(val(seldim)), At())
sel2indices(dim::AbDim, selval, ::At) = 
    exactorerror(selval, dim)
sel2indices(dim::AbDim, selvals::Tuple, ::At) =
    exactorerror(first(selvals), dim):exactorerror(last(selvals), dim)
sel2indices(dim::AbDim, selvals::AbstractVector, ::At) =
    exactorerror.(selvals, Ref(dim))

# Between
sel2indices(dim::AbDim, seldim::AbDim{<:Between}) = 
    sel2indices(dim, val(val(seldim)), Between())
sel2indices(dim::AbDim, selvals::Tuple, ::Between) =
    searchsortedfirst(val(dim), first(selvals)):searchsortedlast(val(dim), last(selvals))

# Near
sel2indices(dim::AbDim, seldim::AbDim{<:Near}) = 
    sel2indices(dim, val(val(seldim)), Near())
sel2indices(dim::AbDim, selval, ::Near) = 
    near(selval, val(dim))
sel2indices(dim::AbDim, selvals::AbstractVector, ::Near) =
    near.(selvals, Ref(val(dim)))

exactorerror(selval, dim) = begin
    ind = findfirst(x -> x == selval, val(dim))
    ind == nothing ? throw(ArgumentError("$selval not found in $dim")) : ind
end

near(selval, list) = begin
    ind = searchsortedfirst(list, selval)
    if ind <= firstindex(list) 
        ind
    elseif abs(list[ind] - selval) < abs(list[ind-1] - selval)
        ind
    else
        ind - 1
    end
end
