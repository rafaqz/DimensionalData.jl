"""
Selection modes define how indexed data will be selected 
when given coordinates, times or other dimension criteria 
that may not match the values at any specific indices.
"""
abstract type SelectionMode{V} end
val(m::SelectionMode) = m.val 

(::Type{T})(args...) where T <: SelectionMode = T{typeof(args)}(args)
(::Type{T})()  where T <: SelectionMode = T{Nothing}(nothing)

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

"""
Select the nearest index to the contained value
"""
struct Near{V} <: SelectionMode{V}
    val::V
end

"""
    Between()
Retreiving indices located between a 2 tuple of values.
"""
struct Between{V<:Union{Tuple{Any,Any},Nothing}} <: SelectionMode{V}
    val::V
end
Between(x::Tuple) = Between{typeof(x)}(x)

# TODO: make these efficient

# At
sel2indices(dim::AbDim, sel::At) = at(dim, val(sel))
sel2indices(dim::AbDim, sel::At{<:Tuple}) = [at.(Ref(dim), val(sel))...]
sel2indices(dim::AbDim, sel::At{<:AbstractVector}) = at.(Ref(dim), val(sel))
# Near
sel2indices(dim::AbDim, sel::Near) = near(dim, val(sel))
sel2indices(dim::AbDim, sel::Near{<:Tuple}) = [near.(Ref(dim), val(sel))...]
sel2indices(dim::AbDim, sel::Near{<:AbstractVector}) = near.(Ref(dim), val(sel))
# Between
sel2indices(dim::AbDim, sel::Between{<:Tuple}) =
    searchsortedfirst(val(dim), first(val(sel))):searchsortedlast(val(dim), last(val(sel)))

at(dim, selval) = begin
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
