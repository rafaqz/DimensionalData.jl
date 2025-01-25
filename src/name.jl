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
value for all `AbstractDimArray`s.
"""
struct NoName <: AbstractName end

Base.Symbol(::NoName) = Symbol("")
Base.string(::NoName) = ""

"""
    Name <: AbstractName

    Name(name::Union{Symbol,Name) => Name
    Name(name::NoName) => NoName

Name wrapper. This lets arrays keep symbol names when the array wrapper needs
to be `isbits`, like for use on GPUs. It makes the name a property of the type.
It's not necessary to use in normal use, a symbol is probably easier.
"""
struct Name{X} <: AbstractName end
Name(name::Symbol) = Name{name}()
Name(name::NoName) = NoName()
Name(name::Name) = name

Base.Symbol(::Name{X}) where X = X
Base.string(::Name{X}) where X = string(X)

name(x::Name) = x


Base.convert(::Type{NoName}, s::Symbol) = NoName()
Base.convert(::Type{Symbol}, ::NoName) = Symbol("")
# TODO should we check that X and s match?
Base.convert(::Type{Name{X}}, s::Symbol) where X = Name{X}()
Base.convert(::Type{Name}, s::Symbol) = Name{s}()
Base.convert(::Type{Symbol}, x::Name{X}) where X = X

Base.promote_rule(::Type{NoName}, ::Type{Symbol}) = NoName
Base.promote_rule(::Type{NoName}, ::Type{<:Name}) = NoName
Base.promote_rule(::Type{Symbol}, ::Type{NoName}) = NoName
Base.promote_rule(::Type{<:Name}, ::Type{NoName}) = NoName
Base.promote_rule(::Type{<:Name}, ::Type{Symbol}) = Symbol
Base.promote_rule(::Type{Symbol}, ::Type{<:Name}) = Symbol