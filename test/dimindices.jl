using DimensionalData, Test, Dates
using DimensionalData.LookupArrays, DimensionalData.Dimensions

A = zeros(X(4.0:7.0), Y(10.0:12.0))

@testset "DimIndices" begin
    di = @inferred DimIndices(A)
    ci = CartesianIndices(A)
    @test @inferred val.(collect(di)) == Tuple.(collect(ci))
    @test A[di] == view(A, di) == A
    @test @inferred di[4, 3] == (X(4), Y(3))
    @test @inferred di[2] == (X(2), Y(1))
    @test @inferred di[X(1)] == [(X(1), Y(1),), (X(1), Y(2),), (X(1), Y(3),)]
    @test map(ds -> A[ds...] + 2, di) == fill(2.0, 4, 3)
    @test_throws ArgumentError DimIndices(zeros(2, 2))
    @test_throws ArgumentError DimIndices(nothing)
    @test size(di) == (4, 3)
    # Array of indices
    @test @inferred collect(DimIndices(X(1:2))) == [(X(1),), (X(2),)]
    @test @inferred A[di[:]] == vec(A)
    @test @inferred A[di[2:5]] == A[2:5]
    @test @inferred A[reverse(di[2:5])] == A[5:-1:2]
    @test @inferred A[di[2:4, 1:2]] == A[2:4, 1:2]
    A1 = zeros(X(4.0:7.0), Ti(3), Y(10.0:12.0))
    @test @inferred size(A1[di[2:5]]) == (3, 4) 
    @test @inferred size(A1[di[2:4, 1:2], Ti=1]) == (3, 2)
    @test @inferred A1[di] isa DimArray{Float64,3}
    @test @inferred A1[X=1][di] isa DimArray{Float64,2}
    @test @inferred A1[X=1, Y=1][di] isa DimArray{Float64,1}
    # Indexing with no matching dims is like [] (?)
    @test @inferred view(A1, X=1, Y=1, Ti=1)[di] == 0.0

    # Convert to vector of DimTuple
    @test @inferred A1[di[:]] isa DimArray{Float64,2}
    @test @inferred size(A1[di[:]]) == (3, 12)
    @test @inferred A1[X=1][di[:]] isa DimArray{Float64,2}
    @test @inferred A1[di[:]] isa DimArray{Float64,2}
    @test @inferred A1[X=1][di[:]] isa DimArray{Float64,2}
    @test @inferred A1[X=1, Y=1][di[:]] isa DimArray{Float64,1}
    # Indexing with no matching dims is like [] (?)
    @test @inferred view(A1, X=1, Y=1, Ti=1)[di[:]] == 0.0
end

@testset "DimPoints" begin
    dp = @inferred DimPoints(A)
    @test @inferred dp[4, 3] == (7.0, 12.0)
    @test @inferred dp[:, 3] == [(4.0, 12.0), (5.0, 12.0), (6.0, 12.0), (7.0, 12.0)]
    @test @inferred dp[2] == (5.0, 10.0)
    @test @inferred dp[X(1)] == [(4.0, 10.0), (4.0, 11.0), (4.0, 12.0)]
    @test size(dp) == (4, 3)
    @test_throws ArgumentError DimPoints(zeros(2, 2))
    @test_throws ArgumentError DimPoints(nothing)
    # Vector
    @test @inferred DimPoints(X(1.0:2.0)) == [(1.0,), (2.0,)]
end

@testset "DimSelectors" begin
    ds = @inferred DimSelectors(A)
    # The selected array is not identical because 
    # the lookups will be vectors and Irregular, 
    # rather than Regular ranges
    @test parent(A[DimSelectors(A)]) == parent(view(A, DimSelectors(A))) == A
    @test index(A[DimSelectors(A)], 1) == index(view(A, DimSelectors(A)), 1) == index(A, 1)
    @test size(ds) == (4, 3)
    @test @inferred ds[4, 3] == (X(At(7.0; atol=eps(Float64))), Y(At(12.0, atol=eps(Float64))))
    @test @inferred ds[2] == (X(At(5.0; atol=eps(Float64))), Y(At(10.0, atol=eps(Float64))))
    @test ds[X(1)] == ds[X(At(4.0))] ==
        [(X(At(4.0; atol=eps(Float64))), Y(At(10.0; atol=eps(Float64))),),
         (X(At(4.0; atol=eps(Float64))), Y(At(11.0; atol=eps(Float64))),),
         (X(At(4.0; atol=eps(Float64))), Y(At(12.0; atol=eps(Float64))),)]
    @test broadcast(ds -> A[ds...] + 2, ds) == fill(2.0, 4, 3)
    @test broadcast(ds -> A[ds...], ds[X(At(7.0))]) == [0.0 for i in 1:3]
    @test_throws ArgumentError DimSelectors(zeros(2, 2))
    @test_throws ArgumentError DimSelectors(nothing)

    @test @inferred DimSelectors(X(1.0:2.0)) ==
        [(X(At(1.0; atol=eps(Float64))),), (X(At(2.0; atol=eps(Float64))),)]

    @testset "atol" begin
        dsa = @inferred DimSelectors(A; atol=0.3)
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
        dsa2 = @inferred DimSelectors(A; atol=(0.1, 0.2))
        # Mess up the lookups again
        C = zeros(X(4.05:7.05), Y(10.15:12.15))
        @test @inferred dsa2[4, 3] == (X(At(7.0; atol=0.1)), Y(At(12.0, atol=0.2)))
        @test collect(dsa2[X(1)]) == [(X(At(4.0; atol=0.1)), Y(At(10.0; atol=0.2)),),
                                     (X(At(4.0; atol=0.1)), Y(At(11.0; atol=0.2)),),
                                     (X(At(4.0; atol=0.1)), Y(At(12.0; atol=0.2)),)]
        @test @inferred broadcast(ds -> C[ds...] + 2, dsa2) == fill(2.0, 4, 3)
        @test @inferred broadcast(ds -> C[ds...], dsa2[X(At(7.0))]) == [0.0 for i in 1:3]
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
        dsa2 = @inferred DimSelectors(A; selectors=(Near(), At()), atol=0.2)
        # Mess up the lookups again
        C = zeros(X(4.05:7.05), Y(10.15:12.15))
        @test dsa2[4, 3] == (X(Near(7.0)), Y(At(12.0, atol=0.2)))
        @test collect(dsa2[X(1)]) == [(X(Near(4.0)), Y(At(10.0; atol=0.2)),),
                                     (X(Near(4.0)), Y(At(11.0; atol=0.2)),),
                                     (X(Near(4.0)), Y(At(12.0; atol=0.2)),)]
        @test @inferred broadcast(ds -> C[ds...] + 2, dsa2) == fill(2.0, 4, 3)
        @test @inferred broadcast(ds -> C[ds...], dsa2[X(At(7.0))]) == [0.0 for i in 1:3]
        # without atol it errors
        @test_throws ArgumentError broadcast(ds -> C[ds...] + 2, ds) == fill(2.0, 4, 3)
        # no dims errors
        @test_throws ArgumentError DimSelectors(zeros(2, 2))
        @test_throws ArgumentError DimSelectors(nothing)
        D = zeros(X(4.15:7.15), Y(10.15:12.15))
        # This works with `Near`
        @test @inferred broadcast(ds -> D[ds...] + 2, dsa2) == fill(2.0, 4, 3)
    end
end

@testset "DimExtensionArray" begin
    A = DimArray(((1:4) * (1:3)'), (X(4.0:7.0), Y(10.0:12.0)); name=:foo)
    ex = DimensionalData.DimExtensionArray(A, (dims(A)..., Z(1:10), Ti(DateTime(2000):Month(1):DateTime(2000, 12); sampling=Intervals(Start()))))
    @test isintervals(dims(ex, Ti))
    @test ispoints(dims(ex, (X, Y, Z)))
    @test DimArray(ex) isa DimArray{Int,4,<:Tuple{<:X,<:Y,<:Z,<:Ti},<:Tuple,Array{Int,4}}
    @test @inferred DimArray(ex[X=1, Y=1]) isa DimArray{Int,2,<:Tuple{<:Z,<:Ti},<:Tuple,Array{Int,2}}
    @test @inferred all(DimArray(ex[X=4, Y=2]) .=== A[X=4, Y=2])
    @test @inferred ex[Z=At(10), Ti=At(DateTime(2000))] == A
    @test @inferred vec(ex) == mapreduce(_ -> vec(A), vcat, 1:prod(size(ex[X=1, Y=1])))
    ex1 = DimensionalData.DimExtensionArray(A, (Z(1:10), dims(A)..., Ti(DateTime(2000):Month(1):DateTime(2000, 12); sampling=Intervals(Start()))))
    @test vec(ex1) == mapreduce(_ -> mapreduce(i -> map(_ -> A[i], 1:size(ex1, Z)), vcat, 1:prod((size(ex1, X), size(ex1, Y)))), vcat, 1:size(ex1, Ti))
end


@testset "DimSlices" begin
    A = DimArray(((1:4) * (1:3)'), (X(4.0:7.0), Y(10.0:12.0)); name=:foo)
    axisdims = map(DD.dims(s, dimtuple)) do d
        rebuild(d, axes(lookup(d), 1))
    end
    ex = DimensionalData.DimSlices(A, )

    DimSlices(s; dims=axisdims, drop)
    @test isintervals(dims(ex, Ti))
    @test ispoints(dims(ex, (X, Y, Z)))
    @test DimArray(ex) isa DimArray{Int,4,<:Tuple{<:X,<:Y,<:Z,<:Ti},<:Tuple,Array{Int,4}}
    @test @inferred DimArray(ex[X=1, Y=1]) isa DimArray{Int,2,<:Tuple{<:Z,<:Ti},<:Tuple,Array{Int,2}}
    @test @inferred all(DimArray(ex[X=4, Y=2]) .=== A[X=4, Y=2])
    @test @inferred ex[Z=At(10), Ti=At(DateTime(2000))] == A
    @test @inferred vec(ex) == mapreduce(_ -> vec(A), vcat, 1:prod(size(ex[X=1, Y=1])))
    ex1 = DimensionalData.DimExtensionArray(A, (Z(1:10), dims(A)..., Ti(DateTime(2000):Month(1):DateTime(2000, 12); sampling=Intervals(Start()))))
    @test vec(ex1) == mapreduce(_ -> mapreduce(i -> map(_ -> A[i], 1:size(ex1, Z)), vcat, 1:prod((size(ex1, X), size(ex1, Y)))), vcat, 1:size(ex1, Ti))
end

