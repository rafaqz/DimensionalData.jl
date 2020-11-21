
abstract type AbstractName end

struct NoName <: AbstractName end
struct Name{X} <: AbstractName end

Base.string(::Name{X}) where X = string(X)
Base.string(::NoName) = ""
Base.Symbol(::Name{X}) where X = X
Base.Symbol(::NoName) = Symbol("")
