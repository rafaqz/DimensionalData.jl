import Statistics: _mean, _median, _std, _var
import Base: _sum, _prod, _maximum, _minimum, _mapreduce_dim

for fname in [:sum, :prod, :maximum, :minimum, :mean]
    _fname = Symbol('_', fname)
    @eval begin
        @inline ($_fname)(a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} = begin
            ($_fname)(a, dimnum(a, dims))
        end
        @inline ($_fname)(f, a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} = begin
            ($_fname)(f, a, dimnum(a, dims))
        end
    end
end

@inline _median(a::AbstractArray, dims::AllDimensions) = _median(a, dimnum(a, dims))
@inline _mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDimensions) =
    _mapreduce_dim(f, op, nt, A, dimnum(A, dims))

for fname in [:std, :var]
    _fname = Symbol('_', fname)
    @eval begin
        ($_fname)(a::AbstractArray{T,N} , corrected::Bool, mean, dimz::AllDimensions) where {T,N} = begin
            dimnums = dimnum(a, dimz)
            otherdims = dims(a)[setdiff(collect(1:N), dimnums)] 
            otherindices = dims2indices(a, map(o->basetype(o)(), otherdims), 1)
            newdims, newrefdims = slicedims(a, otherindices)
            newdata = ($_fname)(a, corrected, mean, dimnums)[otherindices...]
            rebuild(a, newdata, newdims, newrefdims)
        end
    end
end

# TODO cov, cor need _cov and _cor methods in base so we can dispatch on dims
