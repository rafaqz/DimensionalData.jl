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

end