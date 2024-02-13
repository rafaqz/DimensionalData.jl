using DimensionalData, Test, Dates
using DimensionalData.Lookups, DimensionalData.Dimensions
using .Lookups: shiftlocus, maybeshiftlocus
using DimensionalData: uniquekeys

@testset "reverse" begin
    @testset "dimension" begin
        revdima = reverse(X(Sampled(10:10:20; order=ForwardOrdered(), span=Regular(10))))
        @test index(revdima) == 20:-10:10
        @test order(revdima) === ReverseOrdered()
        @test span(revdima) === Regular(-10)
    end

    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)); name=:test)
    s = DimStack(da)

    rev_y = reverse(da; dims=Y)
    @test rev_y == [3 2 1; 6 5 4]
    @test index(rev_y, X) == 10:10:20
    @test index(rev_y, Y) == 100:100:300
    @test span(rev_y, Y) == Regular(100)
    @test order(rev_y, Y) == ForwardOrdered()
    @test order(rev_y, X) == ForwardOrdered()

    rev = reverse(da; dims=:)
    @test parent(rev) == reverse(parent(da))
    @test all(index(rev, d) == reverse(index(da, d)) for d in (X,Y))
    @test all(span(rev, d) == reverse(span(da, d)) for d in (X,Y))
    @test all(order(rev, d) == reverse(order(da, d)) for d in (X,Y))
    @test rev == reverse(da; dims=(X,Y))


    @testset "NoLookup dim index is not reversed" begin
        da = DimArray(A, (X(), Y()))
        revd = reverse(da)
        @test index(revd) == axes(da)
    end

    @testset "stack" begin
        dimz = (X([:a, :b]), Y(10.0:10.0:30.0))
        da1 = DimArray(A, dimz; name=:one)
        da2 = DimArray(Float32.(2A), dimz; name=:two)
        da3 = DimArray(Int.(3A), dimz; name=:three)

        s = DimStack((da1, da2, da3))
        rev_s = reverse(s; dims=X)
        @test rev_s[:one] == [4 5 6; 1 2 3]
        @test rev_s[:three] == [12 15 18; 3 6 9]
    end
end

@testset "reorder" begin
    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)); name=:test)
    s = DimStack(da)

    reo = reorder(da, ReverseOrdered())
    @test reo == [4 5 6; 1 2 3]
    @test index(reo, X) == 20:-10:10
    @test index(reo, Y) == 300:-100:100
    @test order(reo, X) == ReverseOrdered()
    @test order(reo, Y) == ReverseOrdered()

    reo = reorder(da, X=>ForwardOrdered(), Y=>ReverseOrdered())
    @test reo == A
    @test index(reo, X) == 10:10:20
    @test index(reo, Y) == 300:-100:100
    @test order(reo, X) == ForwardOrdered()
    @test order(reo, Y) == ReverseOrdered()

    reo = reorder(da, X=>ReverseOrdered(), Y=>ForwardOrdered())
    @test reo == [6 5 4; 3 2 1]
    @test index(reo, X) == 20:-10:10
    @test index(reo, Y) == 100:100:300
    @test order(reo, X) == ReverseOrdered()
    @test order(reo, Y) == ForwardOrdered()

    revallis = reverse(da; dims=(X, Y))
    @test index(revallis) == (20:-10:10, 100:100:300)
    @test order(revallis) == (ReverseOrdered(), ForwardOrdered())

    d = reorder(dims(da, Y), ForwardOrdered()) 
    @test order(d) isa ForwardOrdered
    @test index(d) == 100:100:300

    # reorder with dimension lookups
    rev = reverse(da, dims=Y)
    reo = reorder(rev, da)
    @test rev != da
    @test reo == da
    @test dims(reo) == dims(da)
    @test_throws MethodError reorder(rev, :test)
    rev_s = reverse(s, dims=Y)
    reo_s = reorder(rev_s, da)
    @test rev_s != s
    @test reo_s == s
    @test dims(reo_s) == dims(s)


    @testset "reorder handles extra dimensions" begin
        @test reorder(da[X=1], X=>ReverseOrdered(), Y=>ForwardOrdered()) == rev[X=1]
        @test reorder(rev_s[X=1], da) == s[X=1]
    end
end

@testset "modify" begin
    A = [1 2 3; 4 5 6]
    dimz = (X(10:10:20), Y(300:-100:100))
    @testset "array" begin
        da = DimArray(A, dimz)
        mda = modify(A -> A .> 3, da)
        @test dims(mda) === dims(da)
        @test mda == [false false false; true true true]
        @test typeof(parent(mda)) == BitArray{2}
        @test_throws ErrorException modify(A -> A[1, :], da)
    end
    @testset "dataset" begin
        da1 = DimArray(A, dimz; name=:da1)
        da2 = DimArray(2A, dimz; name=:da2)
        s = DimStack(da1, da2)
        ms = modify(A -> A .> 3, s)
        @test parent(ms) == (da1=[false false false; true true true],
                              da2=[false true  true ; true true true])
        @test typeof(parent(ms[:da2])) == BitArray{2}
    end
    @testset "dimension" begin
        dim = X(Sampled(10:10:20))
        mdim = modify(x -> 3 .* x, dim)
        @test index(mdim) == 30:30:60 # in Julia 1.6: typeof(30:30:60)==StepRange ; in Julia 1.7 typeof(30:30:60)==StepRangeLen
        da = DimArray(A, dimz)
        mda = modify(y -> vec(4 .* y), da, Y)
        @test index(mda, Y) == [1200.0, 800.0, 400.0]
    end
end

@testset "broadcast_dims" begin
    A2 = [1 2 3; 4 5 6]
    B1 = [1, 2, 3]
    da2 = DimArray(A2, (X([20, 30]), Y([:a, :b, :c])))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    dc1 = broadcast_dims(+, db1, db1)
    @test dc1 == [2, 4, 6]
    dc2 = broadcast_dims(+, da2, db1)
    @test dc2 == [2 4 6; 5 7 9]
    dc4 = broadcast_dims(+, da2, db1)

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X, Y, Z))
    db2 = DimArray(A2, (X, Y))
    dc3 = broadcast_dims(+, da3, db2)
    @test dc3 == cat([2 4 6; 8 10 12], [12 14 16; 18 20 22]; dims=3)

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X([20, 30]), Y([:a, :b, :c]), Z(10:10:20)))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    dc3 = broadcast_dims(+, da3, db1)
    @test dc3 == cat([2 4 6; 5 7 9], [12 14 16; 15 17 19]; dims=3)

    @testset "works with permuted dims" begin
        db2p = permutedims(da2)
        dc3p = dimwise(+, da3, db2p)
        @test dc3p == cat([2 4 6; 8 10 12], [12 14 16; 18 20 22]; dims=3)
    end

    @test_throws DimensionMismatch broadcast_dims!(+, db1, zeros(Z(3)))
    @test broadcast_dims(+, db1, ones(Z(3))) == [2.0 2.0 2.0; 3.0 3.0 3.0; 4.0 4.0 4.0]

    @testset "works with 0-dimensional arrays" begin
        da4 = DimArray(fill(4), ())
        @test broadcast_dims(+, da4, da4) == DimArray(fill(8), ())
        @test broadcast_dims(*, da4, da3) == parent(da4) .* parent(da3)
        @test dims(broadcast_dims(*, da4, da3)) == dims(da3)
    end

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X([20, 30]), Y([:a, :b, :c]), Z(10:10:20)))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    stack1 = DimStack(da3, db1)
    stack2 = DimStack(da3, db1, dc3)
    @test 
    broadcast_dims(+, stack1, da3, db1)
    == broadcast_dims(+, da3, db1, stack1)
    # Cant mix numvers of stack layers
    @test_throws ArgumentError broadcast_dims(+, stack1, da3, db1, stack2)
end

@testset "shiftlocus" begin
    dim = X(Sampled(1.0:3.0, ForwardOrdered(), Regular(1.0), Intervals(Center()), NoMetadata()))
    @test index(shiftlocus(Start(), dim)) === 0.5:1.0:2.5
    @test index(shiftlocus(End(), dim)) === 1.5:1.0:3.5
    @test index(shiftlocus(Center(), dim)) === 1.0:1.0:3.0
    @test locus(shiftlocus(Start(), dim)) === Start()
    @test locus(shiftlocus(End(), dim)) === End()
    @test locus(shiftlocus(Center(), dim)) === Center()
    dim = X(Sampled([3, 4, 5], ForwardOrdered(), Regular(1), Intervals(Start()), NoMetadata()))
    @test val(shiftlocus(End(), dim)) == [4, 5, 6]
    @test val(shiftlocus(Center(), dim)) == [3.5, 4.5, 5.5]
    @test val(shiftlocus(Start(), dim)) == [3, 4, 5]
    dim = X(Sampled([3, 4, 5], ForwardOrdered(), Regular(1), Intervals(End()), NoMetadata()))
    @test val(shiftlocus(End(), dim)) == [3, 4, 5]
    @test val(shiftlocus(Center(), dim)) == [2.5, 3.5, 4.5]
    @test val(shiftlocus(Start(), dim)) == [2, 3, 4]

    dates = DateTime(2000):Month(1):DateTime(2000, 12)
    ti = Ti(Sampled(dates, ForwardOrdered(), Regular(Month(1)), Intervals(Start()), NoMetadata()))
    @test index(shiftlocus(Center(), ti)) == dates .+ (dates .+ Month(1) .- dates) ./ 2

    bnds = vcat((0.5:2.5)', (1.5:3.5)')
    dim = X(Sampled(1.0:3.0, ForwardOrdered(), Explicit(bnds), Intervals(Center()), NoMetadata()))
    start_dim = shiftlocus(Start(), dim)
    @test index(start_dim) == [0.5, 1.5, 2.5]
    @test locus(start_dim) == Start()
    end_dim = shiftlocus(End(), start_dim)
    @test index(end_dim) == [1.5, 2.5, 3.5]
    @test locus(end_dim) == End()
    center_dim = shiftlocus(Center(), end_dim)
    @test index(center_dim) == index(dim)
    @test locus(center_dim) == Center()
end

@testset "maybeshiftlocus" begin
    dim = X(Sampled(1.0:3.0, ForwardOrdered(), Regular(1.0), Intervals(Center()), NoMetadata()))
    @test val(maybeshiftlocus(Start(), dim)) == 0.5:1.0:2.5
    dim = X(Sampled(1.0:3.0, ForwardOrdered(), Regular(1.0), Points(), NoMetadata()))
    @test val(maybeshiftlocus(Start(), dim)) == 1.0:3.0
end

@testset "dim2boundsmatrix" begin
    @testset "Regular span" begin
        dim = X(Sampled(1.0:3.0, ForwardOrdered(), Regular(1.0), Intervals(Center()), NoMetadata()))
        @test Dimensions.dim2boundsmatrix(dim) == [0.5 1.5 2.5
                                                   1.5 2.5 3.5]
        dim = X(Sampled(1.0:3.0, ForwardOrdered(), Regular(1.0), Intervals(Start()), NoMetadata()))
        @test Dimensions.dim2boundsmatrix(dim) == [1.0 2.0 3.0
                                                   2.0 3.0 4.0]
        dim = X(Sampled(3.0:-1:1.0, ReverseOrdered(), Regular(-1.0), Intervals(End()), NoMetadata()))
        @test Dimensions.dim2boundsmatrix(dim) == [2.0 1.0 0.0
                                                   3.0 2.0 1.0]
        dim = X(Sampled(LinRange(3.0, 1.0, 3), ReverseOrdered(), Regular(-1.0), Intervals(Center()), NoMetadata()))
        @test Dimensions.dim2boundsmatrix(dim) == [2.5 1.5 0.5
                                                   3.5 2.5 1.5]
        rnge = LinRange(59.95, -40.05, 1001)
        dim = X(Sampled(rnge; order=ReverseOrdered(), span=Regular(step(rnge)), sampling=Intervals(Center())))
        @test Dimensions.selectindices(dim, Contains(7.35)) == 527
        mat = Dimensions.dim2boundsmatrix(dim) 
        dim = X(Sampled(rnge; order=ReverseOrdered(), span=Explicit(mat), sampling=Intervals(Center())))
        @test Dimensions.selectindices(dim, Contains(7.35)) == 527
    end
    @testset "Explicit span" begin
        dim = X(Sampled(1.0:3.0, ForwardOrdered(),
                Explicit([0.0 1.0 2.0; 1.0 2.0 3.0]), Intervals(End()), NoMetadata()))
        @test Dimensions.dim2boundsmatrix(dim) == [0.0 1.0 2.0
                                                   1.0 2.0 3.0]
    end
end

@testset "uniquekeys" begin
    da1 = rand(X(2), Y(2); name=:name1)
    da2 = rand(X(2), Y(2); name=:name1)
    da3 = rand(X(2), Y(2); name=:name2)
    @test uniquekeys([da1, da2, da3]) == [:layer1, :layer2, :name2] # Should we keep thoe original name?
    @test uniquekeys((da1, da2, da3)) == (:layer1, :layer2, :name2) # Should we keep thoe original name?
    @test uniquekeys([:name1, :name1, :name2]) == [:layer1, :layer2, :name2] # Should we keep thoe original name?
    @test uniquekeys((:name1, :name1, :name2)) == (:layer1, :layer2, :name2) 
    @test uniquekeys(Symbol[]) == Symbol[]
    @test uniquekeys(()) == ()
end
