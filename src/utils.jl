basetype(x) = basetype(typeof(x))
basetype(t::Type) = t.name.wrapper
basetype(t::UnionAll) = t

f <| x = f(x) 
Base.:~(f::Type{<:AbstractDimension}, x) = f(x)
Base.:~(f::Type{<:SelectionMode}, x) = f(x) 
