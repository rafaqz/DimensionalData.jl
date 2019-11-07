using DimensionalData, Statistics, Test, BenchmarkTools, Unitful, SparseArrays

using DimensionalData: val, basetype, slicedims, dims2indices, formatdims, 
      @dim, reducedims, dimnum, basetype, X, Y, Z, Time, Forward

include("dimension.jl")
include("primitives.jl")
include("array.jl")
include("selector.jl")
include("methods.jl")
include("benchmarks.jl")
