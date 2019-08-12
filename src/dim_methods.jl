# Dimension reduction methods where dims are an argument
# targeting underscore _methods so we can use dispatch ont the dims arg

for (mod, fname) in ((:Base, :sum), (:Base, :prod), (:Base, :maximum), (:Base, :minimum), (:Statistics, :mean))
    _fname = Symbol('_', fname)
    @eval begin
        ($mod.$_fname)(a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} =
            ($mod.$_fname)(a, dimnum(a, dims))
        ($mod.$_fname)(f, a::AbstractArray{T,N}, dims::AllDimensions) where {T,N} =
            ($mod._fname)(f, a, dimnum(a, dims))
    end
end

for fname in (:std, :var)
    _fname = Symbol('_', fname)
    @eval function (Statistics.$_fname)(a::AbstractArray{T,N} , corrected::Bool, mean, dims::AllDimensions) where {T,N}
        dimnums = dimnum(a, dims)
        (Statistics.$_fname)(a, corrected, mean, dimnums)
    end
end

Statistics._median(a::AbstractArray, dims::AllDimensions) = 
    Base._median(a, dimnum(a, dims))
Base._mapreduce_dim(f, op, nt::NamedTuple{(),<:Tuple}, A::AbstractArray, dims::AllDimensions) =
    Base._mapreduce_dim(f, op, nt, A, dimnum(A, dims))
# Unfortunately Base/accumulate.jl kwargs methods all force dims to be Integer.
# accumulate wont work unless that is relaxed, or we copy half of the file here.
Base._accumulate!(op, B, A, dims::AllDimensions, init::Union{Nothing, Some}) =
    Base._accumulate!(op, B, A, dimnum(A, dims), init)


#= SplitApplyCombine methods?
Should allow groupby using dims lookup to make this worth the dependency
Like group by time/lattitude/height band etc.

SplitApplyCombine.splitdims(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdims(a, dimnum(a, dims))

SplitApplyCombine.splitdimsview(a::AbstractArray, dims::AllDimensions) =
    SplitApplyCombine.splitdimsview(a, dimnum(a, dims))
=#
