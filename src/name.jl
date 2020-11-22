
abstract type AbstractName end

struct Name{X} <: AbstractName end
Name(name::Symbol) = Name{name}()

Base.Symbol(::Name{X}) where X = X
Base.string(::Name{X}) where X = string(X)

struct NoName <: AbstractName end

Base.Symbol(::NoName) = Symbol("")
Base.string(::NoName) = ""
