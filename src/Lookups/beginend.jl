struct LazyMath{T,F}
    f::F
end
LazyMath{T}(f::F) where {T,F} = LazyMath{T,F}(f)
Base.show(io::IO, l::LazyMath{T}) where T = print(io, _print_f(T, l.f))

const BeginEndRangeVals = Union{Begin,End,LazyMath,Int}

# Ranges
abstract type AbstractBeginEndRange <: Function end
struct BeginEndRange{A<:BeginEndRangeVals,B<:BeginEndRangeVals} <: AbstractBeginEndRange
    start::A
    stop::B
end
struct BeginEndStepRange{A<:BeginEndRangeVals,B<:BeginEndRangeVals} <: AbstractBeginEndRange
    start::A
    step::Int
    stop::B
end

Base.first(r::AbstractBeginEndRange) = r.start
Base.last(r::AbstractBeginEndRange) = r.stop
Base.step(r::BeginEndStepRange) = r.step

(::Colon)(a::Int, b::Union{Begin,End,Type{Begin},Type{End},LazyMath}) = BeginEndRange(a, _x(b))
(::Colon)(a::Union{Begin,End,Type{Begin},Type{End},LazyMath}, b::Int) = BeginEndRange(_x(a), b)
(::Colon)(a::Union{Begin,End,Type{Begin},Type{End},LazyMath}, b::Union{Begin,End,Type{Begin},Type{End},LazyMath}) = 
    BeginEndRange(_x(a), _x(b))

(::Colon)(a::Union{Int,LazyMath}, step::Int, b::Union{Type{Begin},Type{End}}) = BeginEndStepRange(a, step, _x(b))
(::Colon)(a::Union{Type{Begin},Type{End}}, step::Int, b::Union{Int,LazyMath}) = BeginEndStepRange(_x(a), step, b)
(::Colon)(a::Union{Type{Begin},Type{End}}, step::Int, b::Union{Type{Begin},Type{End}}) = 
    BeginEndStepRange(_x(a), step, _x(b))

_x(T::Type) = T()
_x(x) = x

Base.to_indices(A, inds, (r, args...)::Tuple{BeginEndRange,Vararg}) =
    (_to_index(inds[1], r.start):_to_index(inds[1], r.stop), to_indices(A, Base.tail(inds), args)...)
Base.to_indices(A, inds, (r, args...)::Tuple{BeginEndStepRange,Vararg}) =
    (_to_index(inds[1], r.start):r.step:_to_index(inds[1], r.stop), to_indices(A, Base.tail(inds), args)...)
Base.to_indices(A, inds, (r, args...)::Tuple{<:Union{Begin,End,<:LazyMath},Vararg}) =
    (_to_index(inds[1], r), to_indices(A, Base.tail(inds), args)...)

_to_index(inds, a::Int) = a
_to_index(inds, ::Begin) = first(inds)
_to_index(inds, ::End) = last(inds)
_to_index(inds, l::LazyMath{End}) = l.f(last(inds))
_to_index(inds, l::LazyMath{Begin}) = l.f(first(inds))

Base.checkindex(::Type{Bool}, inds::AbstractUnitRange, ber::AbstractBeginEndRange) =
    Base.checkindex(Bool, inds, _to_index(inds, first(ber)):_to_index(inds, last(ber)))

for f in (:+, :-, :*, :÷, :|, :&, :max, :min)
    @eval Base.$f(::Type{T}, i::Int) where T <: Union{Begin,End} = LazyMath{T}(Base.Fix2($f, i))
    @eval Base.$f(i::Int, ::Type{T}) where T <: Union{Begin,End} = LazyMath{T}(Base.Fix1($f, i))
    @eval Base.$f(::T, i::Int) where T <: Union{Begin,End} = LazyMath{T}(Base.Fix2($f, i))
    @eval Base.$f(i::Int, ::T) where T <: Union{Begin,End} = LazyMath{T}(Base.Fix1($f, i))
    @eval Base.$f(x::LazyMath{T}, i::Int) where T = LazyMath{T}(Base.Fix2($f, i) ∘ x.f)
    @eval Base.$f(i::Int, x::LazyMath{T}) where T = LazyMath{T}(Base.Fix1($f, i) ∘ x.f)
end


Base.show(io::IO, ::MIME"text/plain", r::AbstractBeginEndRange) = show(io, r)
function Base.show(io::IO, r::BeginEndRange)  
    _show(io, first(r))
    print(io, ':')
    _show(io, last(r))
end
function Base.show(io::IO, r::BeginEndStepRange)  
    _show(io, first(r))
    print(io, ':')
    show(io, step(r))
    print(io, ':')
    _show(io, last(r))
end

_show(io, x::Union{Begin,End}) = show(io, typeof(x))
_show(io, x) = show(io, x)
# Here we recursively print `Fix1` and `Fix2` either left or right 
# to recreate the function
_print_f(T, f) = string(T, _pf(f))
_print_f(T, f::Base.ComposedFunction) = _print_f(_print_f(T, f.inner), f.outer)
_print_f(T, f::Base.Fix1) = string('(', f.x, _print_f(f.f, T), ')')
_print_f(T, f::Base.Fix2) = string('(', _print_f(T, f.f), f.x, ')')

_print_f(T, f::Base.Fix1{F}) where F<:Union{typeof(max), typeof(min)} = string(f.f, '(', f.x, ", " ,T, ')')
_print_f(T, f::Base.Fix2{F}) where F<:Union{typeof(max), typeof(min)} = string(f.f, '(', T, ", " ,f.x, ')')

_pf(::typeof(div)) = "÷"
_pf(f) = string(f)

for T in (UnitRange, AbstractUnitRange, StepRange, StepRangeLen, LinRange, Lookup)
    for f in (:getindex, :view, :dotview)
        @eval Base.$f(A::$T, i::AbstractBeginEndRange) = Base.$f(A, to_indices(A, (i,))...)
        @eval Base.$f(A::$T, i::Union{Type{Begin},Type{End},Begin,End,LazyMath}) = 
            Base.$f(A, to_indices(A, _construct_types(i))...) 
    end
end

# These methods let us use Begin End end as types without constructing them.
@inline _construct_types(::Type{Begin}, I...) = (Begin(), _construct_types(I...)...)
@inline _construct_types(::Type{End}, I...) = (End(), _construct_types(I...)...)
@inline _construct_types(i, I...) = (i, _construct_types(I...)...)
@inline _construct_types() = ()
