basetypeof(x) = basetypeof(typeof(x))
basetypeof(t::Type) = t.name.wrapper
basetypeof(t::UnionAll) = basetypeof(t.body)

# Left pipe operator for cleaning up brackets
f <| x = f(x) 

# This shouldn't be hard coded, but it makes plots tolerable for now
shorten(x::AbstractFloat) = round(x, sigdigits=3)
shorten(x) = x
