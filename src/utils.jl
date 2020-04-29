basetypeof(x) = basetypeof(typeof(x))
@generated function basetypeof(::Type{T}) where T
    getfield(parentmodule(T), nameof(T))
end

# Left pipe operator for cleaning up brackets
f <| x = f(x)
