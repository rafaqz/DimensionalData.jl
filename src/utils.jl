basetypeof(x) = basetypeof(typeof(x))
@generated function basetypeof(::Type{T}) where T
    getfield(parentmodule(T), nameof(T))
end

# Left pipe operator for cleaning up brackets
f <| x = f(x) 

# This shouldn't be hard coded, but it makes plots tolerable for now
shorten(x::AbstractFloat) = round(x, sigdigits=3)
shorten(x) = x
