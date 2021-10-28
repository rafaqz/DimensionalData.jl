"""
    AbstractName

Abstract supertype for name wrappers.
"""
abstract type AbstractName end

Base.convert(T::Type{<:AbstractString}, name::AbstractName) = convert(T, string(name))

"""
    NoName <: AbstractName

    NoName()

NoName specifies an array is not named, and is the default `name`
value for all `DimArray`s. It can be used in `set` to remove the
array name:

```julia
A = rebuild(A; name=NoName())
```
"""
struct NoName <: AbstractName end

Base.Symbol(::NoName) = Symbol("")
Base.string(::NoName) = ""

"""
    Name <: AbstractName

    Name(name::Union{Symbol,Name) => Name
    Name(name::NoName) => NoName

Name wrapper. This lets arrays keep symbol names when the array wrapp neeeds
to be `isbits, like for use on GPUs. It makes the name a property of the type.
It's not necessary to use in normal use, a symbol is probably easier.
"""
struct Name{X} <: AbstractName end
Name(name::Symbol) = Name{name}()
Name(name::NoName) = NoName()
Name(name::Name) = name

Base.Symbol(::Name{X}) where X = X
Base.string(::Name{X}) where X = string(X)

name(x::Name) = x
name(x) = name(typeof(x))
name(x::Type) = ""
