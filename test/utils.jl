using DimensionalData, Test
using DimensionalData: reversearray, reverseindex, reorderarray, reorderindex,
                       Forward, Reverse

@testset "reversing methods" begin
    revdima = reversearray(X(10:10:20; mode=Sampled(order=Ordered())))
    @test val(revdima) == 10:10:20
    @test order(revdima) == Ordered(Forward(), Reverse(), Reverse())
    revdimi = reverseindex(X(10:10:20; mode=Sampled(order=Ordered())))
    @test val(revdimi) == 20:-10:10
    @test order(revdimi) == Ordered(Reverse(), Forward(), Reverse())

    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)))

    reva = reversearray(da; dims=Y);
    @test reva == [3 2 1; 6 5 4]
    @test val(dims(reva, X)) == 10:10:20
    @test val(dims(reva, Y)) == 300:-100:100
    @test order(dims(reva, X)) == Ordered(Forward(), Forward(), Forward())
    @test order(dims(reva, Y)) == Ordered(Reverse(), Reverse(), Reverse())

    revi = reverseindex(da; dims=Y)
    @test revi == A
    @test val(dims(revi, X)) == 10:10:20
    @test val(dims(revi, Y)) == 100:100:300
    @test order(dims(revi, X)) == Ordered(Forward(), Forward(), Forward())
    @test order(dims(revi, Y)) == Ordered(Forward(), Forward(), Reverse())

    reoa = reorderarray(da, Reverse())
    @test reoa == [6 5 4; 3 2 1]
    @test val(dims(reoa, X)) == 10:10:20
    @test val(dims(reoa, Y)) == 300:-100:100
    @test order(dims(reoa, X)) == Ordered(Forward(), Reverse(), Reverse())
    @test order(dims(reoa, Y)) == Ordered(Reverse(), Reverse(), Reverse())

    reoi = reorderindex(da, Reverse())
    @test reoi == A 
    @test val(dims(reoi, X)) == 20:-10:10
    @test val(dims(reoi, Y)) == 300:-100:100
    @test order(dims(reoi, X)) == Ordered(Reverse(), Forward(), Reverse())
    @test order(dims(reoi, Y)) == Ordered(Reverse(), Forward(), Forward())

    reoi = reorderindex(da, (Y(Forward()), X(Reverse())))
    @test reoi == A 
    @test val(dims(reoi, X)) == 20:-10:10
    @test val(dims(reoi, Y)) == 100:100:300
    @test order(dims(reoi, X)) == Ordered(Reverse(), Forward(), Reverse())
    @test order(dims(reoi, Y)) == Ordered(Forward(), Forward(), Reverse())

    reor = reorderrelation(da, (Y(Forward()), X(Reverse())));
    @test reor == [4 5 6; 1 2 3]
    @test val(dims(reor, X)) == 10:10:20
    @test val(dims(reor, Y)) == 300:-100:100
    @test order(dims(reor, X)) == Ordered(Forward(), Reverse(), Reverse())
    @test order(dims(reor, Y)) == Ordered(Reverse(), Forward(), Forward())

    # TODO test this more thouroughly
end

@testset "modify" begin
    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)))
    mda = modify(A -> A .> 3, da)
    @test dims(mda) === dims(da)
    @test mda == [false false false; true true true]
    typeof(parent(mda)) == BitArray{2}
    @test_throws ErrorException modify(A -> A[1, :], da)
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
