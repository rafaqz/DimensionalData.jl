using DimensionalData, Test, Unitful, Combinatorics
using DimensionalData: Forward, Reverse, Ordered,
      arrayorder, indexorder, relationorder, between, at, near

@testset "selector primitives" begin
    timeforfor = Ti((5:30)u"s"; grid=RegularGrid(order=Ordered(Forward(),Forward(),Forward())))
    timeforrev = Ti((5:30)u"s"; grid=RegularGrid(order=Ordered(Forward(),Forward(),Reverse())))
    timerevfor = Ti((30:-1:5)u"s"; grid=RegularGrid(order=Ordered(Reverse(),Forward(),Forward())))
    timerevrev = Ti((30:-1:5)u"s"; grid=RegularGrid(order=Ordered(Reverse(),Forward(),Reverse())))

    @testset "between" begin
        @test between(timeforfor, Between(10u"s", 15u"s")) === 6:11
        @test between(timeforrev, Between(10u"s", 15u"s")) === 16:1:21
        @test between(timerevfor, Between(10u"s", 15u"s")) === 16:21
        @test between(timerevrev, Between(10u"s", 15u"s")) === 6:1:11
        # Input order doesn't matter
        @test between(timeforfor, Between(15u"s", 10u"s")) === 6:11
    end

    @testset "at" begin
        @test at(timeforfor, At(30u"s"), 30u"s") == 26
        @test at(timerevfor, At(30u"s"), 30u"s") == 1
        @test at(timeforrev, At(30u"s"), 30u"s") == 1
        @test at(timerevrev, At(30u"s"), 30u"s") == 26
    end

    @testset "at" begin
        @test near(timeforfor, Near(29.5u"s"), 29.5u"s") == 26
        @test near(timerevfor, Near(29.5u"s"), 29.5u"s") == 1
        @test near(timeforrev, Near(29.5u"s"), 29.5u"s") == 1
        @test near(timerevrev, Near(29.5u"s"), 29.5u"s") == 26
        @test near(timeforfor, Near(29.4u"s"), 29.4u"s") == 25
        @test near(timerevfor, Near(29.4u"s"), 29.4u"s") == 2
        @test near(timeforrev, Near(29.4u"s"), 29.4u"s") == 2
        @test near(timerevrev, Near(29.4u"s"), 29.4u"s") == 25
    end

end

a = [1 2  3  4
     5 6  7  8
     9 10 11 12]

@testset "Selectors on IndependentGrid" begin
    da = DimensionalArray(a, (Y((10, 30)), Ti((1:4)u"s")))

    @test At(10.0) == At(10.0, 0.0, Base.rtoldefault(eltype(10.0)))
    x = [10.0, 20.0]
    @test At(x) === At(x, 0.0, Base.rtoldefault(eltype(10.0)))
    @test At((10.0, 20.0)) === At((10.0, 20.0), 0.0, Base.rtoldefault(eltype(10.0)))

    Near([10, 20])

    @test Between(10, 20) == Between((10, 20))

    @testset "selectors with dim wrappers" begin
        @test da[Y<|At([10, 30]), Ti<|At([1u"s", 4u"s"])] == [1 4; 9 12]
        @test_throws ArgumentError da[Y<|At([9, 30]), Ti<|At([1u"s", 4u"s"])]
        @test view(da, Y<|At(20), Ti<|At((3:4)u"s")) == [7, 8]
        @test view(da, Y<|Near(17), Ti<|Near([1.5u"s", 3.1u"s"])) == [6, 7]
        @test view(da, Y<|Between(9, 21), Ti<|At((3:4)u"s")) == [3 4; 7 8]
    end

    @testset "selectors without dim wrappers" begin
        @test da[At(20:10:30), At(1u"s")] == [5, 9]
        @test view(da, Between(9, 31), Near((3:4)u"s")) == [3 4; 7 8; 11 12]
        @test view(da, Near(22), At([3.0u"s", 4.0u"s"])) == [7, 8]
        @test view(da, At(20), At((2:3)u"s")) == [6, 7]
        @test view(da, Near<|13, Near<|[1.3u"s", 3.3u"s"]) == [1, 3]
        # Near works with a tuple input
        @test view(da, Near<|(13,), Near<|[1.3u"s", 3.3u"s"]) == [1 3]
        @test view(da, Between(11, 20), At((2:3)u"s")) == [6 7]
        # Between also accepts a tuple input
        @test view(da, Between((11, 20)), Between((2u"s", 3u"s"))) == [6 7]
    end

    @testset "mixed selectors and standard" begin
        selectors = [
            (Between(9, 31), Near((3:4)u"s")),
            (Near(22), At([3.0u"s", 4.0u"s"])),
            (At(20), At((2:3)u"s")),
            (Near<|13, Near<|[1.3u"s", 3.3u"s"]),
            (Near<|(13,), Near<|[1.3u"s", 3.3u"s"]),
            (Between(11, 20), At((2:3)u"s"))
        ]
        positions =  [
            (1:3, [3, 4]),
            (2, [3, 4]),
            (2, [2, 3]),
            (1, [1, 3]),
            ([1], [1, 3]),
            (2:2, [2, 3])
        ]
        for (selector, pos) in zip(selectors, positions)
            pairs = collect(zip(selector, pos))
            cases = [(i, j) for i in pairs[1], j in pairs[2]]
            for (case1, case2) in combinations(cases, 2)
                @test da[case1...] == da[case2...]
                @test view(da, case1...) == view(da, case2...)
                dac1, dac2 = copy(da), copy(da)
                sample = da[case1...]
                replacement  = sample isa Integer ? 100 : rand(Int, size(sample))
                # Test return value
                @test setindex!(dac1, replacement, case1...) == setindex!(dac2, replacement, case2...)
                # Test mutation
                @test dac1 == dac2
            end
        end
    end

    @testset "single-arity standard index" begin
        indices = [
            1:3,
            [1, 2, 4],
            4:-2:1,
        ]
        for idx in indices
            from2d = da[idx]
            @test from2d == data(da)[idx]
            @test !(from2d isa AbstractDimensionalArray)

            from1d = da[Y <| At(10)][idx]
            @test from1d == data(da)[1, :][idx]
            @test from1d isa AbstractDimensionalArray
        end
    end

    @testset "single-arity views" begin
        indices = [
            3,
            1:3,
            [1, 2, 4],
            4:-2:1,
        ]
        for idx in indices
            from2d = view(da, idx)
            @test from2d == view(data(da), idx)
            @test !(parent(from2d) isa AbstractDimensionalArray)

            from1d = view(da[Y <| At(10)], idx)
            @test from1d == view(data(da)[1, :], idx)
            @test parent(from1d) isa AbstractDimensionalArray
        end
    end

    @testset "single-arity setindex!" begin
        indices = [
            3,
            1:3,
            [1, 2, 4],
            4:-2:1,
        ]
        for idx in indices
            # 2D case
            da2d = copy(da)
            a2d = copy(data(da2d))
            replacement = zero(a2d[idx])
            @test setindex!(da2d, replacement, idx) == setindex!(a2d, replacement, idx)
            @test da2d == a2d
            # 1D array
            da1d = da[Y <| At(10)]
            a1d = copy(data(da1d))
            @test setindex!(da1d, replacement, idx) == setindex!(a1d, replacement, idx)
            @test da1d == a1d
        end
    end

    @testset "more Unitful dims" begin
        dimz = Ti<|1.0u"s":1.0u"s":3.0u"s", Y<|(1u"km", 4u"km")
        db = DimensionalArray(a, dimz)
        @test db[Y<|Between(2u"km", 3.9u"km"), Ti<|At<|3.0u"s"] == [10, 11]
    end

    @testset "selectors work in reverse orders" begin
        a = [1 2  3  4
             5 6  7  8
             9 10 11 12]

        @testset "forward index with reverse relation" begin
            da_ffr = DimensionalArray(a, (Y(10:10:30; grid=RegularGrid(order=Ordered(Forward(), Forward(), Reverse()))),
                                         Ti((1:1:4)u"s"; grid=RegularGrid(order=Ordered(Forward(), Forward(), Reverse())))))
            @test indexorder(dims(da_ffr, Ti)) == Forward()
            @test arrayorder(dims(da_ffr, Ti)) == Forward()
            @test relationorder(dims(da_ffr, Ti)) == Reverse()
            @test da_ffr[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [6, 5]
            @test da_ffr[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [6 5; 2 1]
            @test da_ffr[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [6, 5]
            @test da_ffr[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [6 5; 2 1]
            # Between hasn't reverse the index order
            @test da_ffr[Y<|Between(19, 35), Ti<|Between(3.0u"s", 4.0u"s")] == [1 2; 5 6] 
        end
        @testset "reverse index with forward relation" begin
            da_rff = DimensionalArray(a, (Y(30:-10:10; grid=RegularGrid(order=Ordered(Reverse(), Forward(), Forward()))),
                                         Ti((4:-1:1)u"s"; grid=RegularGrid(order=Ordered(Reverse(), Forward(), Forward())))))
            @test da_rff[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [6, 5]
            @test da_rff[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [6 5; 2 1]
            @test da_rff[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [6, 5]
            @test da_rff[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [6 5; 2 1]
            # Between hasn't reverse the index order
            @test da_rff[Y<|Between(20, 30), Ti<|Between(3.0u"s", 4.0u"s")] == [1 2; 5 6] 
        end

        @testset "forward index with forward relation" begin
            da_fff = DimensionalArray(a, (Y(10:10:30; grid=RegularGrid(order=Ordered(Forward(), Forward(), Forward()))),
                                         Ti((1:4)u"s"; grid=RegularGrid(order=Ordered(Forward(), Forward(), Forward())))))
            @test da_fff[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [7, 8]
            @test da_fff[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [7 8; 11 12]
            @test da_fff[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [7, 8]
            @test da_fff[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [7 8; 11 12]
            @test da_fff[Y<|Between(20, 30), Ti<|Between(3.0u"s", 4.0u"s")] == [7 8; 11 12] 
        end
        @testset "reverse index with reverse relation" begin
            da_rfr = DimensionalArray(a, (Y(30:-10:10; grid=RegularGrid(order=Ordered(Reverse(), Forward(), Reverse()))),
                                         Ti((4:-1:1)u"s"; grid=RegularGrid(order=Ordered(Reverse(), Forward(), Reverse())))))
            @test da_rfr[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [7, 8]
            @test da_rfr[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [7 8; 11 12]
            @test da_rfr[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [7, 8]
            @test da_rfr[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [7 8; 11 12]
            @test da_rfr[Y<|Between(20, 30), Ti<|Between(3.0u"s", 4.0u"s")] == [7 8; 11 12] 
        end

    end


    @testset "setindex! with selectors" begin
        c = deepcopy(a)
        dc = DimensionalArray(c, (Y((10, 30)), Ti((1:4)u"s")))
        dc[Near(11), At(3u"s")] = 100
        @test c[1, 3] == 100
        dc[Ti<|Near(2.2u"s"), Y<|Between(10, 30)] = [200, 201, 202]
        @test c[1:3, 2] == [200, 201, 202]
    end

end


@testset "CategoricalGrid" begin
    dimz = Ti([:one, :two, :three]; grid=CategoricalGrid()),
           Y([:a, :b, :c, :d]; grid=CategoricalGrid())
    da = DimensionalArray(a, dimz)
    @test da[Ti<|At([:one, :two]), Y<|At(:b)] == [2, 6]
    @test da[At([:one, :three]), At([:b, :c, :d])] == [2 3 4; 10 11 12]
    @test da[At(:two), Between(:b, :d)] == [6, 7, 8]
    # Near doesn't make sense for categories
    @test_throws ArgumentError da[Near(:two), At([:b, :c, :d])]
end

@testset "TranformedGrid " begin
    using CoordinateTransformations

    m = LinearMap([0.5 0.0; 0.0 0.5])

    dimz = Dim{:trans1}(m; grid=TransformedGrid(X())),
           Dim{:trans2}(m, grid=TransformedGrid(Y()))

    @testset "permutedims works on grid dimensions" begin
        @test permutedims((Y(), X()), dimz) == (X(), Y())
    end

    da = DimensionalArray(a, dimz)

    @testset "Indexing with array dims indexes the array as usual" begin
        @test da[Dim{:trans1}(3), Dim{:trans2}(1)] == 9
        # Using selectors works the same as indexing with grid
        # dims - it applies the transform function.
        # It's not clear this should be allowed or makes sense,
        # but it works anyway because the permutation is correct either way.
        @test da[Dim{:trans1}(At(6)), Dim{:trans2}(At(2))] == 9
    end

    @testset "Indexing with grid dims uses the transformation" begin
        @test da[X(Near(6.1)), Y(Near(8.5))] == 12
        @test da[X(At(4.0)), Y(At(2.0))] == 5
        @test_throws InexactError da[X(At(6.1)), Y(At(8))]
        # Indexing directly with grid dims also just works, but maybe shouldn't?
        @test da[X(2), Y(2)] == 6
    end
end
