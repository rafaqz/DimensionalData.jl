a = [1 2 3; 4 5 6]
da = DimArray(a, (X((143, 145)), Y((-38, -36))))
dimz = dims(da)

@testset "dims2indices" begin
    @test DimensionalData._dims2indices(dimz[1], Y) == Colon()
    @test dims2indices(dimz, (Y(),)) == (Colon(), Colon())
    @test (@ballocated dims2indices($dimz, (Y(),))) == 0
    @test dims2indices(dimz, (Y(1),)) == (Colon(), 1)
    @test (@ballocated dims2indices($dimz, (Y(1),))) == 0
    @test dims2indices(dimz, (Ti(4), X(2))) == (2, Colon())
    @test dims2indices(dimz, (Y(2), X(3:7))) == (3:7, 2)
    @test (@ballocated dims2indices($dimz, (Y(2), X(3:7)))) == 0
    @test dims2indices(dimz, (X(2), Y([1, 3, 4]))) == (2, [1, 3, 4])
    @test dims2indices(da, (X(2), Y([1, 3, 4]))) == (2, [1, 3, 4])
    v = [1, 3, 4]
    @test (@ballocated dims2indices($da, (X(2), Y($v)))) == 0
end

@testset "dims2indices with Transformed" begin
    tdimz = Dim{:trans1}(mode=Transformed(identity, X())), 
            Dim{:trans2}(mode=Transformed(identity, Y())), 
            Z(1:1, NoIndex(), nothing)
    @test dims2indices(tdimz, (X(1), Y(2), Z())) == (1, 2, Colon())
    @test dims2indices(tdimz, (Dim{:trans1}(1), Dim{:trans2}(2), Z())) == (1, 2, Colon())
end
