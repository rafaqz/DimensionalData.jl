using DimensionalData, Test, Unitful
using DimensionalData.LookupArrays, DimensionalData.Dimensions
using Statistics: mean

dim = Coord([(1.0,1.0,1.0), (1.0,2.0,2.0), (3.0,4.0,4.0), (1.0,3.0,4.0)], (X(), Y(), Z()))
da = DimArray(0.1:0.1:0.4, dim)
da2 = DimArray((0.1:0.1:0.4) * (1:1:3)', (dim, Ti(1u"s":1u"s":3u"s")); metadata=Dict())

@testset "regular indexing" begin
    @test da[Coord()] == da[Coord(:)] == da
    @test da[Coord([1, 2])] == [0.1, 0.2]
    @test da[Coord(4)] == 0.4
    @test da2[Coord(4), Ti(3)] ≈ 1.2
end

@testset "merged selector indexing" begin
    @test da[Coord(:, :, :)] == [0.1, 0.2, 0.3, 0.4]
    @test da[Coord(Between(1, 5), :, At(4.0))] == [0.3, 0.4]
    @test da[Coord(:, Between(1, 2), :)] == [0.1, 0.2]
    @test da2[Ti(At(1u"s")), Coord(:, Between(1, 2), :)] == [0.1, 0.2]
    @test da2[Ti(At(2u"s")), Coord(:, Where(>=(3)), :)] == [0.6, 0.8]
    @test_throws ArgumentError da[var=1, Coord(:, Near(1), :)] 
end

@testset "merged dimension indexing" begin
    @test da[Coord(Z(At(1.0)), Y(Between(1, 3)))] == [0.1]
end

@test index(da[Coord(:, Between(1, 2), :)], Coord) == [(1.0,1.0,1.0), (1.0,2.0,2.0)]

@test bounds(da) == (((1.0, 3.0), (1.0, 4.0), (1.0, 4.0)),)

@testset "merged named reduction" begin
    m = mean(da2; dims = Coord)
    @test size(m) == (1,3)
    @test length(dims(m, Coord)) == 1
    @test dims(m, Coord).val == DimensionalData.NoLookup(Base.OneTo(1))
    pure_mean = mean(da2.data; dims = 1)
    @test vec(pure_mean) == vec(m.data)
end

@testset "merged indexing with intervals" begin
    @test da[Coord(Z(At(1.0)), Y(1..3))] == [0.1]
    @test da2[Ti(At(1u"s")), Coord(X(At(1.0)), Y(At(3.0)), Z(At(4.0)))] == 0.4
end

@testset "custom merged names" begin
    A = (1:2) * (1:40)'
    merged = Dim{:mymerged}(Dimensions.MergedLookup(map(Tuple, vec(CartesianIndices((1:10, 1:4)))), (Dim{:draw}(), Dim{:chain}())))
    da = DimArray(A, (Dim{:var}(1:2), merged))
    @test da[var=2, mymerged=(Dim{:draw}(At(8)), Dim{:chain}(At(4)))] == 76
    @test da[var=1, mymerged=(draw=At(8), chain=At(1))] == 8 
end

@testset "show merged" begin
    sprint(show, dim)
    sp = sprint(show, MIME"text/plain"(), dim)
    @test occursin("Coord", sp)
    sp = sprint(show, MIME"text/plain"(), da)
    @test occursin("Coord", sp)
    @test occursin("X", sp)
    @test occursin("Y", sp)
    @test occursin("Z", sp)
end

@testset "unmerge" begin
    a = DimArray(rand(32, 32, 3), (X,Y,Dim{:band}))
    merged = mergedims(a, (X, Y) => :geometry)
    unmerged = unmergedims(merged, dims(a))
    perm_unmerged = unmergedims(permutedims(merged, (2,1)), dims(a))
    
    # Test Merge
    @test hasdim(merged, Dim{:band})
    @test hasdim(merged, Dim{:geometry})
    @test !hasdim(merged, X)
    @test !hasdim(merged, Y)
    @test size(merged) == (3, 32 * 32)

    # Test Unmerge
    @test hasdim(unmerged, X)
    @test hasdim(unmerged, Y)
    @test hasdim(unmerged, Dim{:band})
    @test !hasdim(unmerged, Dim{:geometry})
    @test dims(unmerged) == dims(a)
    @test size(unmerged) == size(a)
    @test all(a .== unmerged)
    @test all(a .== perm_unmerged)
end
