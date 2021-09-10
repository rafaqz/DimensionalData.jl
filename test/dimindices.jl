using DimensionalData, Test

A = zeros(X(4.0:7.0), Y(10.0:12.0))
di = DimIndices(A)

ci = CartesianIndices(A)
@test val.(collect(di)) == Tuple.(collect(ci))

di[4, 3] == (X(4), Y(3))
@test di[X(1)] == [(Y(1),), (Y(2),), (Y(3),)]
@test map(ds -> A[ds...] + 2, di) == fill(2.0, 4, 3)
@test map(ds -> A[ds...], di[X(At(7.0))]) == [fill(0.0, 4) for i in 1:3]
@test_throws ArgumentError DimIndices(zeros(2, 2))

@test size(di) == (4, 3)
@test di[4, 3] == (X(4), Y(3))
@test di[X(1)] == [(X(1), Y(1),), (X(1), Y(2),), (X(1), Y(3),)]
@test map(ds -> A[ds...] + 2, di) == fill(2.0, 4, 3)
@test map(ds -> A[ds...], di[X(At(7.0))]) == [0.0 for i in 1:3]
@test_throws ArgumentError DimIndices(zeros(2, 2))
@test_throws ArgumentError DimIndices(nothing)

@test collect(DimIndices(X(1.0:2.0))) == [(X(1),), (X(2),)]

dk = DimKeys(A)
@test size(dk) == (4, 3)
@test dk[4, 3] == (X(At(7.0; atol=eps(Float64))), Y(At(12.0, atol=eps(Float64))))
@test dk[X(1)] ==  dk[X(At(4.0))] ==
    [(X(At(4.0; atol=eps(Float64))), Y(At(10.0; atol=eps(Float64))),),
     (X(At(4.0; atol=eps(Float64))), Y(At(11.0; atol=eps(Float64))),),
     (X(At(4.0; atol=eps(Float64))), Y(At(12.0; atol=eps(Float64))),)]
@test broadcast(ds -> A[ds...] + 2, dk) == fill(2.0, 4, 3)
@test broadcast(ds -> A[ds...], dk[X(At(7.0))]) == [0.0 for i in 1:3]
@test_throws ArgumentError DimKeys(zeros(2, 2))
@test_throws ArgumentError DimKeys(nothing)

@test collect(DimKeys(X(1.0:2.0))) ==
    [(X(At(1.0; atol=eps(Float64))),), (X(At(2.0; atol=eps(Float64))),)]

@testset "atol" begin
    dka = DimKeys(A; atol=0.3)
    # Mess up the lookups a little...
    B = zeros(X(4.25:1:7.27), Y(9.95:1:12.27))
    @test dka[4, 3] == (X(At(7.0; atol=0.3)), Y(At(12.0, atol=0.3)))
    @test broadcast(ds -> B[ds...] + 2, dka) == fill(2.0, 4, 3)
    @test broadcast(ds -> B[ds...], dka[X(At(7.0))]) == [0.0 for i in 1:3]
    @test_throws ArgumentError broadcast(ds -> B[ds...] + 2, dk) == fill(2.0, 4, 3)
    @test_throws ArgumentError DimKeys(zeros(2, 2))
    @test_throws ArgumentError DimKeys(nothing)
end


@testset "mixed atol" begin
    dka2 = DimKeys(A; atol=(0.1, 0.2))
    # Mess up the lookups again
    C = zeros(X(4.05:7.05), Y(10.15:12.15))
    @test dka2[4, 3] == (X(At(7.0; atol=0.1)), Y(At(12.0, atol=0.2)))
    @test collect(dka2[X(1)]) == [(X(At(4.0; atol=0.1)), Y(At(10.0; atol=0.2)),),
                                 (X(At(4.0; atol=0.1)), Y(At(11.0; atol=0.2)),),
                                 (X(At(4.0; atol=0.1)), Y(At(12.0; atol=0.2)),)]
    @test broadcast(ds -> C[ds...] + 2, dka2) == fill(2.0, 4, 3)
    @test broadcast(ds -> C[ds...], dka2[X(At(7.0))]) == [0.0 for i in 1:3]
    # without atol it errors
    @test_throws ArgumentError broadcast(ds -> C[ds...] + 2, dk) == fill(2.0, 4, 3)
    # no dims errors
    @test_throws ArgumentError DimKeys(zeros(2, 2))
    @test_throws ArgumentError DimKeys(nothing)
    # Only Y can handle errors > 0.1
    D = zeros(X(4.15:7.15), Y(10.15:12.15))
    @test_throws ArgumentError broadcast(ds -> D[ds...] + 2, dka2) == fill(2.0, 4, 3)
end
