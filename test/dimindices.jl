using DimensionalData, Test
using DimensionalData.LookupArrays, DimensionalData.Dimensions

A = zeros(X(4.0:7.0), Y(10.0:12.0))

@testset "DimIndices" begin
    di = DimIndices(A)
    ci = CartesianIndices(A)
    @test val.(collect(di)) == Tuple.(collect(ci))
    @test A[di] == view(A, di) == A
    @test di[4, 3] == (X(4), Y(3))
    @test di[2] == (X(2), Y(1))
    @test di[X(1)] == [(X(1), Y(1),), (X(1), Y(2),), (X(1), Y(3),)]
    @test map(ds -> A[ds...] + 2, di) == fill(2.0, 4, 3)
    @test_throws ArgumentError DimIndices(zeros(2, 2))
    @test_throws ArgumentError DimIndices(nothing)
    @test size(di) == (4, 3)
    # Array of indices
    @test collect(DimIndices(X(1:2))) == [(X(1),), (X(2),)]
    @test A[di[:]] == vec(A)
    @test A[di[2:5]] == A[2:5]
    @test A[reverse(di[2:5])] == A[5:-1:2]
    @test A[di[2:4, 1:2]] == A[2:4, 1:2]
    A1 = zeros(X(4.0:7.0), Ti(3), Y(10.0:12.0))
    # TODO lock down what this should be exactly
    @test size(A1[di[2:5]]) == (3, 4) 
    @test size(A1[di[2:4, 1:2], Ti=1]) == (3, 2)
    @test A1[di] isa DimArray{Float64,3}
    @test A1[X=1][di] isa DimArray{Float64,2}
    @test A1[X=1, Y=1][di] isa DimArray{Float64,1}
    # Indexing with no matching dims is like [] (?)
    @test view(A1, X=1, Y=1, Ti=1)[di] == 0.0

    # Convert to vector of DimTuple
    @test A1[di[:]] isa DimArray{Float64,2}
    @test size(A1[di[:]]) == (3, 12)
    @test A1[X=1][di[:]] isa DimArray{Float64,2}
    @test A1[di[:]] isa DimArray{Float64,2}
    @test A1[X=1][di[:]] isa DimArray{Float64,2}
    @test A1[X=1, Y=1][di[:]] isa DimArray{Float64,1}
    # Indexing with no matching dims is like [] (?)
    @test view(A1, X=1, Y=1, Ti=1)[di[:]] == 0.0
end

@testset "DimPoints" begin
    dp = DimPoints(A)
    @test dp[4, 3] == (7.0, 12.0)
    @test dp[:, 3] == [(4.0, 12.0), (5.0, 12.0), (6.0, 12.0), (7.0, 12.0)]
    @test dp[2] == (5.0, 10.0)
    @test dp[X(1)] == [(4.0, 10.0), (4.0, 11.0), (4.0, 12.0)]
    @test size(dp) == (4, 3)
    @test_throws ArgumentError DimPoints(zeros(2, 2))
    @test_throws ArgumentError DimPoints(nothing)
    # Vector
    @test collect(DimPoints(X(1.0:2.0))) == [(1.0,), (2.0,)]
end

@testset "DimSelectors" begin
    ds = DimSelectors(A)
    # The selected array is not identical because 
    # the lookups will be vectors and Irregular, 
    # rather than Regular ranges
    @test parent(A[DimSelectors(A)]) == parent(view(A, DimSelectors(A))) == A
    @test index(A[DimSelectors(A)], 1) == index(view(A, DimSelectors(A)), 1) == index(A, 1)
    @test size(ds) == (4, 3)
    @test ds[4, 3] == (X(At(7.0; atol=eps(Float64))), Y(At(12.0, atol=eps(Float64))))
    @test ds[2] == (X(At(5.0; atol=eps(Float64))), Y(At(10.0, atol=eps(Float64))))
    @test ds[X(1)] ==  ds[X(At(4.0))] ==
        [(X(At(4.0; atol=eps(Float64))), Y(At(10.0; atol=eps(Float64))),),
         (X(At(4.0; atol=eps(Float64))), Y(At(11.0; atol=eps(Float64))),),
         (X(At(4.0; atol=eps(Float64))), Y(At(12.0; atol=eps(Float64))),)]
    @test broadcast(ds -> A[ds...] + 2, ds) == fill(2.0, 4, 3)
    @test broadcast(ds -> A[ds...], ds[X(At(7.0))]) == [0.0 for i in 1:3]
    @test_throws ArgumentError DimSelectors(zeros(2, 2))
    @test_throws ArgumentError DimSelectors(nothing)

    @test collect(DimSelectors(X(1.0:2.0))) ==
        [(X(At(1.0; atol=eps(Float64))),), (X(At(2.0; atol=eps(Float64))),)]

    @testset "atol" begin
        dsa = DimSelectors(A; atol=0.3)
        # Mess up the lookups a little...
        B = zeros(X(4.25:1:7.27), Y(9.95:1:12.27))
        @test dsa[4, 3] == (X(At(7.0; atol=0.3)), Y(At(12.0, atol=0.3)))
        @test broadcast(ds -> B[ds...] + 2, dsa) == fill(2.0, 4, 3)
        @test broadcast(ds -> B[ds...], dsa[X(At(7.0))]) == [0.0 for i in 1:3]
        @test_throws ArgumentError broadcast(ds -> B[ds...] + 2, ds) == fill(2.0, 4, 3)
        @test_throws ArgumentError DimSelectors(zeros(2, 2))
        @test_throws ArgumentError DimSelectors(nothing)
    end

    @testset "mixed atol" begin
        dsa2 = DimSelectors(A; atol=(0.1, 0.2))
        # Mess up the lookups again
        C = zeros(X(4.05:7.05), Y(10.15:12.15))
        @test dsa2[4, 3] == (X(At(7.0; atol=0.1)), Y(At(12.0, atol=0.2)))
        @test collect(dsa2[X(1)]) == [(X(At(4.0; atol=0.1)), Y(At(10.0; atol=0.2)),),
                                     (X(At(4.0; atol=0.1)), Y(At(11.0; atol=0.2)),),
                                     (X(At(4.0; atol=0.1)), Y(At(12.0; atol=0.2)),)]
        @test broadcast(ds -> C[ds...] + 2, dsa2) == fill(2.0, 4, 3)
        @test broadcast(ds -> C[ds...], dsa2[X(At(7.0))]) == [0.0 for i in 1:3]
        # without atol it errors
        @test_throws ArgumentError broadcast(ds -> C[ds...] + 2, ds) == fill(2.0, 4, 3)
        # no dims errors
        @test_throws ArgumentError DimSelectors(zeros(2, 2))
        @test_throws ArgumentError DimSelectors(nothing)
        # Only Y can handle errors > 0.1
        D = zeros(X(4.15:7.15), Y(10.15:12.15))
        @test_throws ArgumentError broadcast(ds -> D[ds...] + 2, dsa2) == fill(2.0, 4, 3)
    end

    @testset "mixed selectors" begin
        dsa2 = DimSelectors(A; selectors=(Near, At), atol=0.2)
        # Mess up the lookups again
        C = zeros(X(4.05:7.05), Y(10.15:12.15))
        @test dsa2[4, 3] == (X(Near(7.0)), Y(At(12.0, atol=0.2)))
        @test collect(dsa2[X(1)]) == [(X(Near(4.0)), Y(At(10.0; atol=0.2)),),
                                     (X(Near(4.0)), Y(At(11.0; atol=0.2)),),
                                     (X(Near(4.0)), Y(At(12.0; atol=0.2)),)]
        @test broadcast(ds -> C[ds...] + 2, dsa2) == fill(2.0, 4, 3)
        @test broadcast(ds -> C[ds...], dsa2[X(At(7.0))]) == [0.0 for i in 1:3]
        # without atol it errors
        @test_throws ArgumentError broadcast(ds -> C[ds...] + 2, ds) == fill(2.0, 4, 3)
        # no dims errors
        @test_throws ArgumentError DimSelectors(zeros(2, 2))
        @test_throws ArgumentError DimSelectors(nothing)
        D = zeros(X(4.15:7.15), Y(10.15:12.15))
        # This works with `Near`
        @test broadcast(ds -> D[ds...] + 2, dsa2) == fill(2.0, 4, 3)
    end
end
