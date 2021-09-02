using DimensionalData, Test, Dates
using DimensionalData: flip, shiftlocus, maybeshiftlocus

@testset "reverse" begin
    @testset "dimension" begin
        revdima = reverse(ArrayOrder, X(10:10:20; mode=Sampled(order=Ordered(), span=Regular(10))))
        @test val(revdima) == 10:10:20
        @test order(revdima) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
        @test span(revdima) == Regular(10)
        revdimi = reverse(IndexOrder, X(10:10:20; mode=Sampled(order=Ordered(), span=Regular(10))))
        @test val(revdimi) == 20:-10:10
        @test order(revdimi) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
        @test span(revdimi) == Regular(-10)
        # reverse for Dimension means IndexOrder
        revdimi2 = reverse(X(10:10:20; mode=Sampled(order=Ordered(), span=Regular(10))))
        @test revdimi2 == revdimi
    end

    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)); name=:test)
    s = DimStack(da)

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

    revas = reverse(ArrayOrder, s; dims=Y)
    @test reva == [3 2 1; 6 5 4]
    @test val(dims(revas, X)) == 10:10:20
    @test val(dims(revas, Y)) == 300:-100:100
    @test order(dims(revas, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())
    @test order(dims(revas, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    revis = reverse(IndexOrder, s; dims=Y)
    span(reverse(IndexOrder, mode(dims(revis, X))))
    span(dims(revis, X))
    @test revis[:test] == A
    @test val(dims(revis, X)) == 10:10:20
    @test val(dims(revis, Y)) == 100:100:300
    @test order(dims(revis, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())

    @testset "Val index" begin
        dav = DimArray(A, (X(Val((10, 20)); mode=Sampled(order=Ordered())), 
                           Y(Val((300, 200, 100)); mode=Sampled(order=Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())))); name=:test)
        revdav = reverse(IndexOrder, dav; dims=(X, Y))
        @test val(revdav) == (Val((20, 10)), Val((100, 200, 300)))
    end
    @testset "NoIndex dim index is not reversed" begin
        da = DimArray(A, (X(), Y()))
        revda = reverse(da)
        @test index(revda) == axes(da)
        revda2 = reverse(IndexOrder, da; dims=1)
        @test index(revda2) == axes(da)
        revda3 = reverse(ArrayOrder, da; dims=1)
        @test index(revda3) == axes(da)
        revda4 = reverse(Relation, dims(da, X))
        @test index(revda4) == axes(da, X)
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

    reoa = reorder(da, ReverseArray())
    @test reoa == [6 5 4; 3 2 1]
    @test val(dims(reoa, X)) == 10:10:20
    @test val(dims(reoa, Y)) == 300:-100:100
    @test order(dims(reoa, X)) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
    @test order(dims(reoa, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    reoi = reorder(da, (X=ReverseIndex, Y=ReverseIndex))
    @test reoi == A 
    @test val(dims(reoi, X)) == 20:-10:10
    @test val(dims(reoi, Y)) == 300:-100:100
    @test order(dims(reoi, X)) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
    @test order(dims(reoi, Y)) == Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())

    reoi = reorder(da, Y(ForwardIndex); X=ReverseIndex)
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

    revallis = reverse(IndexOrder, da; dims=(X, Y))
    @test index(revallis) == (20:-10:10, 100:100:300)
    @test indexorder(revallis) == (ReverseIndex(), ForwardIndex())
end

@testset "flip" begin
    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)); name=:test)
    fda = flip(IndexOrder, da; dims=(X, Y))
    @test indexorder(fda) == (ReverseIndex(), ForwardIndex())
    fda = flip(Relation, da, Y)
    @test relation(fda, Y) == ReverseRelation()
    @test flip(Relation, NoIndex()) == NoIndex()
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
        @test data(ms) == (da1=[false false false; true true true],
                              da2=[false true  true ; true true true])
        @test typeof(parent(ms[:da2])) == BitArray{2}
    end
    @testset "dimension" begin
        dim = X(10:10:20)
        mdim = modify(x -> 3 .* x, dim)
        @test index(mdim) === 30:30:60
        dim = Y(Val((1,2,3,4,5)))
        mdim = modify(xs -> 2 .* xs, dim)
        @test index(mdim) === (2, 4, 6, 8, 10)
        da = DimArray(A, dimz)
        mda = modify(y -> vec(4 .* y), da, Y)
        @test index(mda, Y) == [1200.0, 800.0, 400.0]
    end
end

@testset "dimwise" begin
    A2 = [1 2 3; 4 5 6]
    B1 = [1, 2, 3]
    da2 = DimArray(A2, (X([20, 30]), Y([:a, :b, :c])))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    dc1 = dimwise(+, db1, db1)
    @test dc1 == [2, 4, 6]
    dc2 = dimwise(+, da2, db1)
    @test dc2 == [2 4 6; 5 7 9]
    dc4 = dimwise(+, da2, db1)

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X, Y, Z))
    db2 = DimArray(A2, (X, Y))
    dc3 = dimwise(+, da3, db2)
    @test dc3 == cat([2 4 6; 8 10 12], [12 14 16; 18 20 22]; dims=3)
    dc3 = dimwise!(+, da3, da3, db2)

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

@testset "shiftlocus" begin
    dim = X(1.0:3.0; mode=Sampled(Ordered(), Regular(1.0), Intervals(Center())))
    @test val(shiftlocus(Start(), dim)) == 0.5:1.0:2.5
    @test val(shiftlocus(End(), dim)) == 1.5:1.0:3.5
    @test val(shiftlocus(Center(), dim)) == 1.0:1.0:3.0
    @test locus(shiftlocus(Start(), dim)) == Start()
    @test locus(shiftlocus(End(), dim)) == End()
    @test locus(shiftlocus(Center(), dim)) == Center()
    dim = X([3, 4, 5]; mode=Sampled(Ordered(), Regular(1), Intervals(Start())))
    @test val(shiftlocus(End(), dim)) == [4, 5, 6]
    @test val(shiftlocus(Center(), dim)) == [3.5, 4.5, 5.5]
    @test val(shiftlocus(Start(), dim)) == [3, 4, 5]
    dim = X([3, 4, 5]; mode=Sampled(Ordered(), Regular(1), Intervals(End())))
    @test val(shiftlocus(End(), dim)) == [3, 4, 5]
    @test val(shiftlocus(Center(), dim)) == [2.5, 3.5, 4.5]
    @test val(shiftlocus(Start(), dim)) == [2, 3, 4]
end

@testset "maybeshiftlocus" begin
    dim = X(1.0:3.0; mode=Sampled(Ordered(), Regular(1.0), Intervals(Center())))
    @test val(maybeshiftlocus(Start(), dim)) == 0.5:1.0:2.5
    dim = X(1.0:3.0; mode=Sampled(Ordered(), Regular(1.0), Points()))
    @test val(maybeshiftlocus(Start(), dim)) == 1.0:3.0
end

@testset "dim2boundsmatrix" begin
    @testset "Regular span" begin
        dim = X(1.0:3.0; mode=Sampled(Ordered(), Regular(1.0), Intervals(Center())))
        @test DimensionalData.dim2boundsmatrix(dim) == [0.5 1.5 2.5 
                                                        1.5 2.5 3.5]
        dim = X(1.0:3.0; mode=Sampled(Ordered(), Regular(1.0), Intervals(Start())))
        @test DimensionalData.dim2boundsmatrix(dim) == [1.0 2.0 3.0 
                                                        2.0 3.0 4.0]
        dim = X(1.0:3.0; mode=Sampled(Ordered(), Regular(1.0), Intervals(End())))
        @test DimensionalData.dim2boundsmatrix(dim) == [0.0 1.0 2.0 
                                                        1.0 2.0 3.0]
        dim = X(3.0:-1:1.0; mode=Sampled(Ordered(index=ReverseIndex()), Regular(1.0), Intervals(Center())))
        @test DimensionalData.dim2boundsmatrix(dim) == [2.5 1.5 0.5 
                                                        3.5 2.5 1.5]
    end
    @testset "Explicit span" begin
        dim = X(1.0:3.0; mode=Sampled(Ordered(), Explicit([0.0 1.0 2.0 
                                                           1.0 2.0 3.0]), Intervals(End())))
        @test DimensionalData.dim2boundsmatrix(dim) == [0.0 1.0 2.0 
                                                        1.0 2.0 3.0]
    end
end
