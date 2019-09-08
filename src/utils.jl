basetype(x) = basetype(typeof(x))
basetype(t::Type) = t.name.wrapper
basetype(t::UnionAll) = t

f <| x = f(x) 

# This shouldn't be hard coded, but it makes plots tolerable for now
shorten(x::AbstractFloat) = round(x, sigdigits=3)
shorten(x) = x

# Nothing doesn't string
getstring(::Nothing) = ""
getstring(x) = string(x)
