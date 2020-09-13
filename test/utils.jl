using DimensionalData, Test

@testset "reversing methods" begin
    revdima = reverse(ArrayOrder, X(10:10:20; mode=Sampled(order=Ordered(), span=Regular(10))))
    @test val(revdima) == 10:10:20
    @test order(revdima) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
    @test span(revdima) == Regular(10)
    revdimi = reverse(IndexOrder, X(10:10:20; mode=Sampled(order=Ordered(), span=Regular(10))))
    @test val(revdimi) == 20:-10:10
    @test order(revdimi) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
    @test span(revdimi) == Regular(-10)

    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)), :test)
    ds = DimDataset(da)

    reva = reverse(ArrayOrder, da; dims=Y)
    @test reva == [3 2 1; 6 5 4]
    @test val(dims(reva, X)) == 10:10:20
    @test val(dims(reva, Y)) == 300:-100:100
    @test order(dims(reva, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())
    @test order(dims(reva, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    revi = reverse(IndexOrder, da; dims=Y)
    @test revi == A
    @test val(dims(revi, X)) == 10:10:20
    @test val(dims(revi, Y)) == 100:100:300
    @test order(dims(revi, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())

    revads = reverse(ArrayOrder, ds; dims=Y)
    @test reva == [3 2 1; 6 5 4]
    @test val(dims(revads, X)) == 10:10:20
    @test val(dims(revads, Y)) == 300:-100:100
    @test order(dims(revads, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())
    @test order(dims(revads, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    revids = reverse(IndexOrder, ds; dims=Y)
    span(reverse(IndexOrder, mode(dims(revids, X))))
    span(dims(revids, X))
    @test revids[:test] == A
    @test val(dims(revids, X)) == 10:10:20
    @test val(dims(revids, Y)) == 100:100:300
    @test order(dims(revids, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())


    reoa = reorder(da, ReverseArray())
    @test reoa == [6 5 4; 3 2 1]
    @test val(dims(reoa, X)) == 10:10:20
    @test val(dims(reoa, Y)) == 300:-100:100
    @test order(dims(reoa, X)) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
    @test order(dims(reoa, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    reoi = reorder(da, X=ReverseIndex, Y=ReverseIndex)
    @test reoi == A 
    @test val(dims(reoi, X)) == 20:-10:10
    @test val(dims(reoi, Y)) == 300:-100:100
    @test order(dims(reoi, X)) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
    @test order(dims(reoi, Y)) == Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())

    reoi = reorder(da, (Y=ForwardIndex, X=ReverseIndex))
    @test reoi == A
    @test val(dims(reoi, X)) == 20:-10:10
    @test val(dims(reoi, Y)) == 100:100:300
    @test order(dims(reoi, X)) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
    @test order(dims(reoi, Y)) == Ordered(ForwardIndex(), ForwardArray(), ReverseRelation())

    reor = reorder(da, X => ReverseRelation, Y => ForwardRelation)
    @test reor == [4 5 6; 1 2 3]
    @test val(dims(reor, X)) == 10:10:20
    @test val(dims(reor, Y)) == 300:-100:100
    @test order(dims(reor, X)) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
    @test order(dims(reor, Y)) == Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())

    # TODO test this more thouroughly
end

@testset "modify" begin
    @testset "array" begin
        A = [1 2 3; 4 5 6]
        da = DimArray(A, (X(10:10:20), Y(300:-100:100)))
        mda = modify(A -> A .> 3, da)
        @test dims(mda) === dims(da)
        @test mda == [false false false; true true true]
        @test typeof(parent(mda)) == BitArray{2}
        @test_throws ErrorException modify(A -> A[1, :], da)
    end

    @testset "dataset" begin
        A = [1 2 3; 4 5 6]
        dimz = (X(10:10:20), Y(300:-100:100))
        da1 = DimArray(A, dimz, :da1)
        da2 = DimArray(2A, dimz, :da2)
        ds = DimDataset(da1, da2)
        mds = modify(A -> A .> 3, ds)
        @test layers(mds) == (da1=[false false false; true true true],
                              da2=[false true  true ; true true true])
        @test typeof(parent(mds[:da2])) == BitArray{2}
    end
end

@testset "dimwise" begin
    A2 = [1 2 3; 4 5 6]
    B1 = [1, 2, 3]
    da2 = DimArray(A2, (X([20, 30]), Y([:a, :b, :c])))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    dc2 = dimwise(+, da2, db1)
    @test dc2 == [2 4 6; 5 7 9]

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X, Y, Z))
    db2 = DimArray(A2, (X, Y))
    dc3 = dimwise(+, da3, db2)
    @test dc3 == cat([2 4 6; 8 10 12], [12 14 16; 18 20 22]; dims=3)

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X([20, 30]), Y([:a, :b, :c]), Z(10:10:20)))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    dc3 = dimwise(+, da3, db1)
    @test dc3 == cat([2 4 6; 5 7 9], [12 14 16; 15 17 19]; dims=3)

    @testset "works with permuted dims" begin
        db2p = permutedims(da2)
        dc3p = dimwise(+, da3, db2p)
        @test dc3p == cat([2 4 6; 8 10 12], [12 14 16; 18 20 22]; dims=3)
    end

end
