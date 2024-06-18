module DimensionalDataCategoricalArraysExt

import DimensionalData, CategoricalArrays
const DD = DimensionalData
const CAs = CategoricalArrays
CategoricalDimArray = DD.AbstractDimArray{<:Union{Missing, CAs.CategoricalValue}}

# categorical and cut take a dimarray and return a categorical dim array
function CAs.categorical(x::DD.AbstractDimArray; kw...)
    ca = CAs.categorical(Base.parent(x); kw...)
    DD.rebuild(x; data = ca)
end

# Need to define these separately to avoid ambiguity
CAs.cut(x::DD.AbstractDimArray, ng::Integer; kw...) = DD.rebuild(x; data = CAs.cut(Base.parent(x),ng; kw...))
CAs.cut(x::DD.AbstractDimArray, breaks::AbstractVector; kw...) = DD.rebuild(x; data = CAs.cut(Base.parent(x),breaks; kw...))

CAs.recode(x::DD.AbstractDimArray, pairs::Pair...) = CAs.recode(x, nothing, pairs...)
CAs.recode(x::DD.AbstractDimArray, default::Any, pairs::Pair...) = DD.rebuild(x; data = CAs.recode(Base.parent(x),default, pairs...))

# function that mutate in-place
for f in [:levels!, :droplevels!, :fill!, :ordered!]
    @eval function CAs.$f(x::CategoricalDimArray, args...; kw...)
        CAs.$f(Base.parent(x), args...; kw...)
        return x
    end
end

# functions that rebuild the categorical array
for f in [:compress, :decompress]
    @eval CAs.$f(x::CategoricalDimArray, args...; kw...) =
        DD.rebuild(x; data = CAs.$f(Base.parent(x), args...; kw...))
end

# functions that do not mutate
for f in [:levels, :leveltype, :pool, :refs, :isordered]
    @eval CAs.$f(x::CategoricalDimArray, args...; kw...) = CAs.$f(Base.parent(x), args...; kw...)
end

## Recode! methods
# methods without a default - needed to avoid ambiguity
CAs.recode!(dest::DD.AbstractDimArray, src::AbstractArray, pairs::Pair...) = CAs.recode!(dest, src, nothing, pairs...)
CAs.recode!(dest::AbstractArray, src::DD.AbstractDimArray, pairs::Pair...) = CAs.recode!(dest, src, nothing, pairs...)
CAs.recode!(dest::DD.AbstractDimArray, src::CAs.CategoricalArray, pairs::Pair...) = CAs.recode!(dest, src, nothing, pairs...)
CAs.recode!(dest::CAs.CategoricalArray, src::DD.AbstractDimArray, pairs::Pair...) = CAs.recode!(dest, src, nothing, pairs...)
CAs.recode!(dest::DD.AbstractDimArray, src::DD.AbstractDimArray, pairs::Pair...) = CAs.recode!(dest, src, nothing, pairs...)
# methods with a single array
CAs.recode!(a::DD.AbstractDimArray, default::Any, pairs::Pair...) = CAs.recode!(a, a, default, pairs...)
CAs.recode!(a::DD.AbstractDimArray, pairs::Pair...) = CAs.recode!(a, a, nothing, pairs...)

# methods with default
function CAs.recode!(dest::DD.AbstractDimArray, src::AbstractArray, default, pairs::Pair...)
    CAs.recode!(Base.parent(dest), src, default, pairs...)
    return dest
end
function CAs.recode!(dest::AbstractArray, src::DD.AbstractDimArray, default, pairs::Pair...)
    CAs.recode!(dest, Base.parent(src), default, pairs...)
    return dest
end
function CAs.recode!(dest::DD.AbstractDimArray, src::CAs.CategoricalArray, default, pairs::Pair...)
    CAs.recode!(Base.parent(dest), src, default, pairs...)
    return dest
end
function CAs.recode!(dest::CAs.CategoricalArray, src::DD.AbstractDimArray, default, pairs::Pair...)
    CAs.recode!(dest, Base.parent(src), default, pairs...)
    return dest
end
function CAs.recode!(dest::DD.AbstractDimArray, src::DD.AbstractDimArray, default, pairs::Pair...)
    CAs.recode!(Base.parent(dest), Base.parent(src), pairs...)
    return dest
end

end
