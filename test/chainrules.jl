using Test
using DimensionalData
using ChainRulesCore

@testset "chainrules.jl" begin

    @testset "ProjectTo" begin
        data = rand(3)
        A = DimArray(data, (:a,); name=:title, refdims=(), metadata=Dict(:info=>"data"))
        p = ProjectTo(A)
        @test p(data) == A

        @test p(NoTangent()) == NoTangent()

        data = rand(3, 4)
        A = DimArray(data, (:a, :b))
        p = ProjectTo(A)
        @test p(data) == A

        @test p(NoTangent()) == NoTangent()
    end

    @testset "parent rrule" begin
        data = rand(3)
        A = DimArray(data, (:a,))
        y, pb = rrule(parent, A)
        @test y === parent(A)
        # raw array tangent
        ȳ = rand(3)
        _, Ā = pb(ȳ)
        @test Ā == DimArray(ȳ, dims(A))
        # DimArray tangent
        ȳ2 = DimArray(rand(3), dims(A))
        _, Ā2 = pb(ȳ2)
        @test Ā2 == DimArray(parent(ȳ2), dims(A))
        # Zero tangent
        _, Āz = pb(NoTangent())
        @test Āz === NoTangent()

        data = rand(3, 4)
        A = DimArray(data, (:a, :b))
        y, pb = rrule(parent, A)
        @test y === parent(A)
        ȳ = rand(3, 4)
        _, Ā = pb(ȳ)
        @test Ā == DimArray(ȳ, dims(A))
        ȳ2 = DimArray(rand(3, 4), dims(A))
        _, Ā2 = pb(ȳ2)
        @test Ā2 == DimArray(parent(ȳ2), dims(A))
        _, Āz = pb(NoTangent())
        @test Āz === NoTangent()
    end
    @testset "getindex rrule with selectors" begin
        A = DimArray(rand(3, 4), (Y([:a, :b, :c]), X(1:4)))
        
        # Test At selector
        y, pb = rrule(getindex, A; Y=At(:b))
        @test size(y) == (4,)  # Only X dimension remains
        
        ȳ = ones(4)
        _, grad = pb(ȳ)
        @test size(grad) == size(A)
        @test all(grad[1, :] .== 0)
        @test all(grad[2, :] .== 1)  # Y=:b 
        @test all(grad[3, :] .== 0)
        
        # Test multiple selectors
        y2, pb2 = rrule(getindex, A; Y=At(:b), X=At(2))
        @test y2 isa Number
        
        ȳ2 = 1.0
        _, grad2 = pb2(ȳ2)
        @test grad2[2, 2] == 1  # Y=:b, X=2
        @test sum(grad2) == 1   # Only one element should be 1
    end

end