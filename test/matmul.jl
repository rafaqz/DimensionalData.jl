using DimensionalData, Statistics, Test, Unitful, SparseArrays, Dates, LinearAlgebra

using DimensionalData: AnonDim
using Combinatorics: combinations

@testset "*" begin
    timespan = DateTime(2001):Month(1):DateTime(2001,12)
    A1 = DimArray(rand(12), (Ti(timespan),))
    A2 = DimArray(rand(12, 1), (Ti(timespan), X(10:10:10)))

    @test length.(dims(A1)) == size(A1)
    @test dims(parent(A1) * permutedims(A1)) isa Tuple{<:AnonDim,<:Ti}
    @test parent(A1) * permutedims(A1) == parent(A1) * permutedims(parent(A1))
    @test dims(permutedims(A1) * parent(A1)) isa Tuple{<:AnonDim}
    @test permutedims(A1) * parent(A1) == permutedims(parent(A1)) * parent(A1)

    @test length.(dims(permutedims(A1) * parent(A1))) == size(permutedims(parent(A1)) * parent(A1))
    @test length.(dims(permutedims(A1) * A1)) == size(permutedims(parent(A1)) * parent(A1))
    @test length.(dims(permutedims(parent(A1)) * A1)) == size(permutedims(parent(A1)) * parent(A1))

    @test length.(dims(parent(A1) * permutedims(A1))) == size(parent(A1) * permutedims(parent(A1)))
    @test length.(dims(A1 * permutedims(A1))) == size(parent(A1) * permutedims(parent(A1)))
    @test length.(dims(A1 * permutedims(parent(A1)))) == size(parent(A1) * permutedims(parent(A1)))

    @test length.(dims(A2)) == size(A2)
    @test length.(dims(A2')) == size(A2')

    sze1 = (12, 12)
    @test size(parent(A2) * parent(A2)') == sze1
    @test length.(dims(A2 * A2')) == sze1
    @test length.(dims(parent(A2) * A2')) == sze1
    @test length.(dims(A2 * parent(A2'))) == sze1
    sze2 = (1, 1)
    @test size(parent(A2') * parent(A2)) == sze2
    @test length.(dims(A2' * A2)) == sze2
    @test length.(dims(parent(A2') * A2)) == sze2
    @test length.(dims(A2' * parent(A2))) == sze2

    B1 = DimArray(rand(12, 6), (Ti(timespan), X(1:6)))
    B2 = DimArray(rand(8, 12), (Y(1:8), Ti(timespan)))
    b1 = DimArray(rand(12), Ti(timespan))

    # Test dimension propagation
    @test (B2 * B1) == (parent(B2) * parent(B1))
    @test dims(B2 * B1) isa Tuple{<:Y, <:X}
    @test length.(dims(B2 * B1)) == (8, 6)

    # Test where results have an empty dim
    true_result = (parent(b1)' * parent(B1))
    flip = adjoint
    for flip in (adjoint, transpose, permutedims)
        result = flip(b1) * B1
        @test result ≈ true_result
        # Permute dims is not exactly transpose
        @test dims(result) isa Tuple{<:AnonDim, <:X}
        @test length.(dims(result)) == (1, 6)
    end

    # Test flipped * flipped
    for (flip1, flip2) in combinations((adjoint, transpose, permutedims), 2)
        result = flip1(B1) * flip2(B2)
        @test result == flip1(parent(B1)) * flip2(parent(B2))
        @test dims(result) isa Tuple{<:X, <:Y}
        @test size(result) == (6, 8)
    end

    @testset "strictness" begin
        B2c = DimArray(rand(8, 12), (Y('a':'h'), Ti(1.0:12.0)))
        DimensionalData.strict_matmul!(false)
        @test !DimensionalData.strict_matmul()
        @test_nowarn B2c * b1
        DimensionalData.strict_matmul!(true)
        @test DimensionalData.strict_matmul()
        @test_throws DimensionMismatch B2c * b1
    end
end

@testset "some matmul ambiguity methods" begin
    special_types = (Adjoint, Transpose, Diagonal, Symmetric, Tridiagonal, SymTridiagonal, BitArray,)

    @testset "DimMatrix" begin
        da = DimArray(ones(5,5), (:a, :b))
        @testset "$T" for T in special_types
            x = T(ones(5,5))
            @test dims(x * da) isa Tuple{<:AnonDim, Dim{:b}}
            @test dims(da * x) isa Tuple{Dim{:a}, <:AnonDim}
            @test typeof(x * da) <: DimArray
            @test typeof(da * x) <: DimArray
            @test parent(da' * x) == parent(da)' * x
            @test parent(x * da) == x * parent(da) 
        end
    end

    @testset "DimVector" begin
        dv = DimArray(ones(5), :vec)
        @testset "$T" for T in special_types
            x = T(ones(5,5))
            @test dims(x * dv) isa Tuple{<:AnonDim}
            @test dims(dv' * x) isa Tuple{<:AnonDim,<:AnonDim}
            @test typeof(x * dv) <: DimArray
            @test typeof(dv' * x) <: DimArray
            @test parent(dv' * x) == parent(dv)' * x
            @test parent(x * dv) == x * parent(dv) 
        end
        @testset "$T" for T in (Adjoint, Transpose)
            x = T(1:5)
            @test x * dv === 15.0
            @test typeof(dv * x) <: DimArray
            @test dims(dv * x) isa Tuple{<:Dim{:vec},AnonDim}
            @test dv * x == vcat(x, x, x, x, x)
        end

    end

end

struct ArrayMulWrapper{T,N} <: AbstractArray{T,N}
    data::AbstractDimArray{T,N}
end
VecOrMatMulWrapper{T} = Union{ArrayMulWrapper{T,1},ArrayMulWrapper{T,2}}
Base.size(x::ArrayMulWrapper) = size(x.data)
Base.axes(x::ArrayMulWrapper) = axes(x.data)
Base.getindex(x::ArrayMulWrapper, i::Int) = x.data[i]
Base.getindex(x::ArrayMulWrapper, I::Vararg{Int, N}) where {N} = x.data[I...]
Base.:*(A::VecOrMatMulWrapper, B::VecOrMat) = A.data * B
Base.:*(A::VecOrMat, B::VecOrMatMulWrapper) = A * B.data

@testset "DimArrays constructed with DimUnitRange axes" begin
    x = X(0f0:2f0)
    y = Y(5.0:7.0)
    z = Z(['a', 'b'])
    t = Ti([:c])

    @testset for ((Adims, Bdims), Cdims) in [
        ((x, y), (y, z)) => (x, z),
        ((x, y), (y,)) => (x,),
        ((x,), (t, z)) => (x, z),
    ]
        A = rand(Adims...)
        B = rand(Bdims...)
        C = ArrayMulWrapper(A) * B
        @test C isa DimArray
        @test C ≈ A * B
        @test Dimensions.comparedims(Bool, C, Cdims)
        C2 = A * ArrayMulWrapper(B)
        @test C2 isa DimArray
        @test C ≈ A * B
        @test Dimensions.comparedims(Bool, C2, Cdims)
    end

    yalt = Y(3.0:5.0)
    @test length(yalt) == length(y)
    @testset for (Adims, Bdims) in [
        ((x, y), (yalt, z)),
        ((x, y), (yalt,)),
    ]
        A = rand(Adims...)
        B = rand(Bdims...)
        @test_throws DimensionMismatch ArrayMulWrapper(A) * B
        @test_throws DimensionMismatch A * ArrayMulWrapper(B)
    end
end
