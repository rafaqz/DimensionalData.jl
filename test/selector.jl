using DimensionalData, Test, Unitful, Combinatorics, Dates
using DimensionalData: between, at, near, contains, selectindices, hasselection,
    Points, Intervals, Regular, Irregular, Explicit,
    Unordered, ForwardOrdered, ReverseOrdered, Start, Center, End

a = [1 2  3  4
     5 6  7  8
     9 10 11 12]

dims_ = X(Sampled(10:10:20; sampling=Intervals())),
        Y(Sampled(5:7; sampling=Intervals()))
A = DimArray([1 2 3; 4 5 6], dims_)

@testset "selector primitives" begin

    @testset "Regular Intervals with range" begin
        # Order: index, array, relation (array order is irrelevent here, it's just for plotting)
        # Varnames: locusindexorderrelation
        args = Intervals(Start()), NoMetadata()
        startfwd = Sampled(11.0:30.0,      ForwardOrdered(), Regular(1), args...)
        startrev = Sampled(30.0:-1.0:11.0, ReverseOrdered(), Regular(-1), args...)

        @testset "Any at" begin
            @test at(startfwd, At(30)) == 20
            @test at(startrev, At(30)) == 1
            @test at(startfwd, At(29.9; atol=0.2)) == 20
            @test at(startrev, At(29.9; atol=0.2)) == 1
            @test at(startfwd, At(30.1; atol=0.2)) == 20
            @test at(startrev, At(30.1; atol=0.2)) == 1
        end

        @testset "Start between" begin
            @test between(startfwd, Between(11, 14)) === 1:3
            @test between(startrev, Between(11, 14)) === 18:20
            @test between(startfwd, Between(11.1, 13.9)) === 2:2
            @test between(startrev, Between(11.1, 13.9)) === 19:19
            # Input order doesn't matter
            @test between(startfwd, Between(14, 11)) === 1:3
        end

        @testset "Start contains" begin
            @test_throws BoundsError contains(startfwd, Contains(10.9))
            @test_throws BoundsError contains(startrev, Contains(31))
            @test contains(startfwd, Contains(11)) == 1
            @test contains(startfwd, Contains(11.9)) == 1
            @test contains(startfwd, Contains(12.0)) == 2
            @test contains(startfwd, Contains(30.0)) == 20
            @test contains(startfwd, Contains(29.9)) == 19
            @test contains(startrev, Contains(11.9)) == 20
            @test contains(startrev, Contains(12.0)) == 19
            @test contains(startrev, Contains(30.9)) == 1
            @test contains(startrev, Contains(30.0)) == 1
            @test contains(startrev, Contains(29.0)) == 2
        end

        @testset "Start near" begin
            @test bounds(startfwd) == bounds(startrev)
            @test near(startfwd, Near(-100)) == 1
            @test near(startfwd, Near(11.9)) == 1
            @test near(startfwd, Near(12.0)) == 2
            @test near(startfwd, Near(30.0)) == 20
            @test near(startfwd, Near(29.9)) == 19
            @test near(startrev, Near(11.9)) == 20
            @test near(startrev, Near(12.0)) == 19
            @test near(startrev, Near(29.0)) == 2
            @test near(startrev, Near(30.0)) == 1
            @test near(startfwd, Near(100)) == 20
        end

        args = Intervals(Center()), NoMetadata()
        centerfwd = Sampled(11.0:30.0,      ForwardOrdered(), Regular(1), args...)
        centerrev = Sampled(30.0:-1.0:11.0, ReverseOrdered(), Regular(-1), args...)

        @testset "Center between" begin
            @test between(centerfwd, Between(10.5, 14.6)) === 1:4
            @test between(centerfwd, Between(10.6, 14.4)) === 2:3
            @test between(centerrev, Between(10.5, 14.6)) === 17:20
            @test between(centerrev, Between(10.6, 14.4)) === 18:19
            # Input order doesn't matter
            @test between(centerfwd, Between(15, 10)) === 1:4
        end

        @testset "Center contains" begin
            @test_throws BoundsError contains(centerfwd, Contains(10.4))
            @test_throws BoundsError contains(centerfwd, Contains(30.5))
            @test_throws BoundsError contains(centerrev, Contains(10.4))
            @test_throws BoundsError contains(centerrev, Contains(30.5))
            @test contains(centerfwd, Contains(10.5)) == 1
            @test contains(centerfwd, Contains(30.4)) == 20
            @test contains(centerfwd, Contains(29.5)) == 20
            @test contains(centerfwd, Contains(29.4)) == 19
            @test contains(centerrev, Contains(10.5)) == 20
            @test contains(centerrev, Contains(30.4)) == 1
            @test contains(centerrev, Contains(29.5)) == 1
            @test contains(centerrev, Contains(29.4)) == 2
        end

        @testset "Center near" begin
            @test near(centerfwd, Near(10.4)) == 1
            @test near(centerfwd, Near(30.5)) == 20
            @test near(centerrev, Near(10.4)) == 20
            @test near(centerrev, Near(30.5)) == 1
            @test near(centerfwd, Near(10.5)) == 1
            @test near(centerfwd, Near(30.4)) == 20
            @test near(centerfwd, Near(29.5)) == 20
            @test near(centerfwd, Near(29.4)) == 19
            @test near(centerrev, Near(10.5)) == 20
            @test near(centerrev, Near(30.4)) == 1
            @test near(centerrev, Near(29.5)) == 1
            @test near(centerrev, Near(29.4)) == 2
        end

        args = Intervals(End()), NoMetadata()
        endfwd = Sampled(11.0:30.0,      ForwardOrdered(), Regular(1), args...)
        endrev = Sampled(30.0:-1.0:11.0, ReverseOrdered(), Regular(-1), args...)

        @testset "End between" begin
            @test between(endfwd, Between(10.1, 14.9)) === 2:4
            @test between(endrev, Between(10.1, 14.9)) === 17:19
            @test between(endfwd, Between(10, 15)) === 1:5
            @test between(endrev, Between(10, 15)) === 16:20
            # Input order doesn't matter
            @test between(endfwd, Between(15, 10)) === 1:5
        end

        @testset "End contains" begin
            @test_throws BoundsError contains(endfwd, Contains(10))
            @test_throws BoundsError contains(endfwd, Contains(30.1))
            @test_throws BoundsError contains(endrev, Contains(10))
            @test_throws BoundsError contains(endrev, Contains(30.1))
            @test contains(endfwd, Contains(10.1)) == 1
            @test contains(endfwd, Contains(11.0)) == 1
            @test contains(endfwd, Contains(11.1)) == 2
            @test contains(endfwd, Contains(29.0)) == 19
            @test contains(endfwd, Contains(29.1)) == 20
            @test contains(endfwd, Contains(30.0)) == 20
            @test contains(endrev, Contains(10.1)) == 20
            @test contains(endrev, Contains(11.0)) == 20
            @test contains(endrev, Contains(11.1)) == 19
            @test contains(endrev, Contains(29.0)) == 2
            @test contains(endrev, Contains(29.1)) == 1
            @test contains(endrev, Contains(30.0)) == 1
            @test contains(endrev, Contains(11.0)) == 20
            @test contains(endrev, Contains(11.1)) == 19
        end

        @testset "End near" begin
            @test near(endfwd, Near(10)) == 1
            @test near(endfwd, Near(11.0)) == 1
            @test near(endfwd, Near(11.1)) == 2
            @test near(endfwd, Near(29.0)) == 19
            @test near(endfwd, Near(29.1)) == 20
            @test near(endfwd, Near(30.0)) == 20
            @test near(endfwd, Near(31.1)) == 20
            @test near(endrev, Near(10)) == 20
            @test near(endrev, Near(11.0)) == 20
            @test near(endrev, Near(11.1)) == 19
            @test near(endrev, Near(29.0)) == 2
            @test near(endrev, Near(29.1)) == 1
            @test near(endrev, Near(30.0)) == 1
            @test near(endrev, Near(31.1)) == 1
            @test near(endrev, Near(11.0)) == 20
            @test near(endrev, Near(11.1)) == 19
            @test near(endrev, Near(29.0)) == 2
            @test near(endrev, Near(29.1)) == 1
            @test near(endfwd, Near(-100)) == 1
            @test near(endfwd, Near(100)) == 20
        end

    end

    @testset "Regular Intervals with array" begin
        startfwd = Sampled([1, 3, 4, 5], ForwardOrdered(), Regular(1), Intervals(Start()), NoMetadata())
        startrev = Sampled([5, 4, 3, 1], ReverseOrdered(), Regular(-1), Intervals(Start()), NoMetadata())
        @test_throws BoundsError contains(startfwd, Contains(0.9))
        @test contains(startfwd, Contains(1.0)) == 1
        @test contains(startfwd, Contains(1.9)) == 1
        @test_throws ArgumentError contains(startfwd, Contains(2))
        @test_throws ArgumentError contains(startfwd, Contains(2.9))
        @test contains(startfwd, Contains(3)) == 2
        @test contains(startfwd, Contains(5.9)) == 4
        @test_throws BoundsError contains(startfwd, Contains(6))
        @test_throws BoundsError contains(startrev, Contains(0.9))
        @test contains(startrev, Contains(1.0)) == 4
        @test contains(startrev, Contains(1.9)) == 4
        @test_throws ArgumentError contains(startrev, Contains(2))
        @test_throws ArgumentError contains(startrev, Contains(2.9))
        @test contains(startrev, Contains(3)) == 3
        @test contains(startrev, Contains(5.9)) == 1
        @test_throws BoundsError contains(startrev, Contains(6))
    end

    @testset "Irregular Intervals with array" begin
        # Order: index, array, relation (array order is irrelevent here, it's just for plotting)
        # Varnames: locusindexorderrelation
        args = Irregular(1.0, 121.0), Intervals(Start()), NoMetadata()
        startfwd = Sampled((1:10).^2,    ForwardOrdered(), args...)
        startrev = Sampled((10:-1:1).^2, ReverseOrdered(), args...)

        @testset "Any at" begin
            @test at(startfwd, At(25)) == 5
            @test at(startrev, At(25)) == 6
            @test at(startfwd, At(100)) == 10
            @test at(startrev, At(100)) == 1
        end

        @testset "Start between" begin
            @test between(startfwd, Between(9, 36)) === 3:5
            @test between(startrev, Between(9, 36)) === 6:8
            @test between(startfwd, Between(9.1, 35.0)) === 4:4
            @test between(startrev, Between(9.1, 35.9)) === 7:7
            # Input order doesn't matter
            @test between(startfwd, Between(36, 9)) === 3:5
            # Handle searchorted overflow
            @test between(startfwd, Between(-100, 9)) === 1:2
            @test between(startfwd, Between(80, 150)) === 9:10
            @test between(startrev, Between(-100, 9)) === 9:10
            @test between(startrev, Between(80, 150)) === 1:2
        end

        @testset "Start contains" begin
            @test_throws BoundsError contains(startfwd, Contains(0.9))
            @test_throws BoundsError contains(startfwd, Contains(121.1))
            @test contains(startfwd, Contains(1)) == 1
            @test contains(startfwd, Contains(3.9)) == 1
            @test contains(startfwd, Contains(4.0)) == 2
            @test contains(startfwd, Contains(100.0)) == 10
            @test contains(startfwd, Contains(99.9)) == 9
            @test_throws BoundsError contains(startrev, Contains(0.9))
            @test_throws BoundsError contains(startrev, Contains(121.1))
            @test contains(startrev, Contains(3.9)) == 10
            @test contains(startrev, Contains(4.0)) == 9
            @test contains(startrev, Contains(120.9)) == 1
            @test contains(startrev, Contains(100.0)) == 1
            @test contains(startrev, Contains(99.0)) == 2
        end

        args = Irregular(0.5, 111.5), Intervals(Center()), NoMetadata()
        centerfwd = Sampled((1.0:10.0).^2,      ForwardOrdered(), args...)
        centerrev = Sampled((10.0:-1.0:1.0).^2, ReverseOrdered(), args...)

        @testset "Center between" begin
            @test between(centerfwd, Between(6.5, 30.5)) === 3:5
            @test between(centerfwd, Between(6.6, 30.4)) === 4:4
            @test between(centerrev, Between(6.5, 30.5)) === 6:8
            @test between(centerrev, Between(6.6, 30.4)) === 7:7
            # Input order doesn't matter
            @test between(centerfwd, Between(30.5, 6.5)) === 3:5
        end

        @testset "Center contains" begin
            @test_throws BoundsError contains(centerfwd, Contains(0.4))
            @test_throws BoundsError contains(centerfwd, Contains(111.5))
            @test contains(centerfwd, Contains(0.5)) == 1
            @test contains(centerfwd, Contains(111.4)) == 10
            @test contains(centerfwd, Contains(90.5)) == 10
            @test contains(centerfwd, Contains(90.4)) == 9
            @test_throws BoundsError contains(centerrev, Contains(0.4))
            @test_throws BoundsError contains(centerrev, Contains(111.5))
            @test contains(centerrev, Contains(72.5)) == 2
            @test contains(centerrev, Contains(72.4)) == 3
            @test contains(centerrev, Contains(0.5)) == 10
            @test contains(centerrev, Contains(111.4)) == 1
            @test contains(centerrev, Contains(90.5)) == 1
            @test contains(centerrev, Contains(90.4)) == 2
        end

        args = Irregular(0.0, 100.0), Intervals(End()), NoMetadata()
        endfwd = Sampled((1.0:10.0).^2,      ForwardOrdered(), args...)
        endrev = Sampled((10.0:-1.0:1.0).^2, ReverseOrdered(), args...)

        @testset "End between" begin
            @test between(endfwd, Between(4, 25)) === 3:5
            @test between(endrev, Between(4, 25)) === 6:8
            @test between(endfwd, Between(4.1, 24.9)) === 4:4
            @test between(endrev, Between(4.1, 24.9)) === 7:7
            # Input order doesn't matter
            @test between(endfwd, Between(25, 4)) === 3:5
            # Handle searchorted overflow
            @test between(endfwd, Between(-100, 4)) === 1:2
            @test between(endfwd, Between(-100, 4)) === 1:2
            @test between(endfwd, Between(64, 150)) === 9:10
            @test between(endrev, Between(-100, 4)) === 9:10
            @test between(endrev, Between(64, 150)) === 1:2
        end

        @testset "End contains" begin
            @test_throws BoundsError contains(endfwd, Contains(-0.1))
            @test_throws BoundsError contains(endfwd, Contains(100.1))
            @test_throws BoundsError contains(endrev, Contains(-0.1))
            @test_throws BoundsError contains(endrev, Contains(100.1))
            @test contains(endfwd, Contains(0.1)) == 1
            @test contains(endfwd, Contains(1.0)) == 1
            @test contains(endfwd, Contains(1.1)) == 2
            @test contains(endfwd, Contains(81.0)) == 9
            @test contains(endfwd, Contains(81.1)) == 10
            @test contains(endfwd, Contains(100.0)) == 10
            @test contains(endrev, Contains(0.1)) == 10
            @test contains(endrev, Contains(1.0)) == 10
            @test contains(endrev, Contains(1.1)) == 9
            @test contains(endrev, Contains(81.0)) == 2
            @test contains(endrev, Contains(81.1)) == 1
            @test contains(endrev, Contains(100.0)) == 1
        end

    end

    @testset "Points lookup" begin
        fwd = Sampled(5.0:30.0;      order=ForwardOrdered(), sampling=Points())
        rev = Sampled(30.0:-1.0:5.0; order=ReverseOrdered(), sampling=Points())

        @testset "between" begin
            @test between(fwd, Between(10, 15)) === 6:11
            @test between(rev, Between(10, 15)) === 16:21
            # Input order doesn't matter
            @test between(fwd, Between(15, 10)) === 6:11
        end

        @testset "at" begin
            @test at(fwd, At(30)) == 26
            @test at(rev, At(30)) == 1
        end

        @testset "near" begin
            @test near(fwd, Near(50))   == 26
            @test near(fwd, Near(0))    == 1
            @test near(fwd, Near(29.4)) == 25
            @test near(fwd, Near(29.5)) == 26
            @test near(rev, Near(29.4)) == 2
            @test near(rev, Near(30.1)) == 1
            @test_throws ArgumentError near(Sampled((5.0:30.0); order=Unordered(), sampling=Points()), Near(30.1))
        end

        @testset "contains" begin
            @test_throws ArgumentError contains(fwd, Contains(50))
        end

    end

end

@testset "Selectors on Sampled Points" begin
    da = DimArray(a, (Y(Sampled(10:10:30)), Ti(Sampled((1:4)u"s"))))

    @test At(10.0) == At(10.0, nothing, nothing)
    @test At(10.0; atol=0.0, rtol=Base.rtoldefault(Float64)) ==
          At(10.0, 0.0, Base.rtoldefault(Float64))
    Near([10, 20])

    @test Between(10, 20) == Between((10, 20))

    @testset "selectors with dim wrappers" begin
        @test @inferred da[Y(At([10, 30])), Ti(At([1u"s", 4u"s"]))] == [1 4; 9 12]
        @test_throws ArgumentError da[Y(At([9, 30])), Ti(At([1u"s", 4u"s"]))]
        @test @inferred view(da, Y(At(20)), Ti(At((3:4)u"s"))) == [7, 8]
        @test @inferred view(da, Y(Near(17)), Ti(Near([1.5u"s", 3.1u"s"]))) == [6, 7]
        @test @inferred view(da, Y(Between(9, 21)), Ti(At((3:4)u"s"))) == [3 4; 7 8]
    end

    @testset "selectors without dim wrappers" begin
        @test @inferred da[At(20:10:30), At(1u"s")] == [5, 9]
        @test @inferred view(da, Between(9, 31), Near((3:4)u"s")) == [3 4; 7 8; 11 12]
        @test @inferred view(da, Near(22), At([3.0u"s", 4.0u"s"])) == [7, 8]
        @test @inferred view(da, At(20), At((2:3)u"s")) == [6, 7]
        @test @inferred view(da, Near(13), Near([1.3u"s", 3.3u"s"])) == [1, 3]
        # Near works with a tuple input
        @test @inferred view(da, Near([13]), Near([1.3u"s", 3.3u"s"])) == [1 3]
        @test @inferred view(da, Between(11, 20), At((2:3)u"s")) == [6 7]
        # Between also accepts a tuple input
        @test @inferred view(da, Between((11, 20)), Between((2u"s", 3u"s"))) == [6 7]
    end

    @testset "mixed selectors and standard" begin
        selectors = [
            (Between(9, 31), Near((3:4)u"s")),
            (Near(22), At([3.0u"s", 4.0u"s"])),
            (At(20), At((2:3)u"s")),
            (Near(13), Near([1.3u"s", 3.3u"s"])),
            (Near([13]), Near([1.3u"s", 3.3u"s"])),
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
            @test from2d == parent(da)[idx]
            @test !(from2d isa AbstractDimArray)
            from1d = da[Y(At(10))][idx]
            @test from1d == parent(da)[1, :][idx]
            @test from1d isa AbstractDimArray
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
            idx = 3
            from2d = view(da, idx)
            @test from2d == view(parent(da), idx)
            @test from2d isa SubArray
            from1d = view(da[Y(At(10))], idx)
            @test from1d == view(parent(da)[1, :], idx)
            @test from1d isa SubArray
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
            idx = indices[1]
            # 2D case
            da2d = copy(da)
            a2d = copy(parent(da2d))
            replacement = zero(a2d[idx])
            @test setindex!(da2d, replacement, idx) == setindex!(a2d, replacement, idx)
            @test da2d == a2d
            # 1D array
            da1d = da[Y(At(10))]
            a1d = copy(parent(da1d))
            @test setindex!(da1d, replacement, idx) == setindex!(a1d, replacement, idx)
            @test da1d == a1d
        end
    end

    @testset "more Unitful dims" begin
        dimz = Ti(1.0u"s":1.0u"s":3.0u"s"), Y(1u"km":1u"km":4u"km")
        db = DimArray(a, dimz)
        @test db[Y(Between(2u"km", 3.9u"km")), Ti(At(3.0u"s"))] == [10, 11]
    end

    @testset "selectors work in reverse orders" begin
        a = [1 2  3  4
             5 6  7  8
             9 10 11 12]

        @testset "forward index" begin
            da_fff = DimArray(a, (Y(Sampled(10:10:30; order=ForwardOrdered())),
                                  Ti(Sampled((1:4)u"s"; order=ForwardOrdered()))))
            @test da_fff[Y(At(20)), Ti(At((3.0:4.0)u"s"))] == [7, 8]
            @test da_fff[Y(At([20, 30])), Ti(At((3.0:4.0)u"s"))] == [7 8; 11 12]
            @test da_fff[Y(Near(22)), Ti(Near([3.3u"s", 4.3u"s"]))] == [7, 8]
            @test da_fff[Y(Near([22, 42])), Ti(Near([3.3u"s", 4.3u"s"]))] == [7 8; 11 12]
            @test da_fff[Y(Between(20, 30)), Ti(Between(3.0u"s", 4.0u"s"))] == [7 8; 11 12]
        end

        @testset "reverse index" begin
            da_rff = DimArray(a, (Y(Sampled(30:-10:10; order=ReverseOrdered())),
                                  Ti(Sampled((4:-1:1)u"s"; order=ReverseOrdered()))))
            @test da_rff[Y(At(20)), Ti(At((3.0:4.0)u"s"))] == [6, 5]
            @test da_rff[Y(At([20, 30])), Ti(At((3.0:4.0)u"s"))] == [6 5; 2 1]
            @test da_rff[Y(Near(22)), Ti(Near([3.3u"s", 4.3u"s"]))] == [6, 5]
            @test da_rff[Y(Near([22, 42])), Ti(Near([3.3u"s", 4.3u"s"]))] == [6 5; 2 1]
            # Between hasn't reverse the index order
            @test da_rff[Y(Between(20, 30)), Ti(Between(3.0u"s", 4.0u"s"))] == [1 2; 5 6]
        end

    end

    @testset "setindex! with selectors" begin
        c = deepcopy(a)
        dc = DimArray(c, (Y(10:10:30), Ti((1:4)u"s")))
        dc[Near(11), At(3u"s")] = 100
        @test c[1, 3] == 100
        @inferred setindex!(dc, [200, 201, 202], Ti(Near(2.2u"s")), Y(Between(10, 30)))
        @test c[1:3, 2] == [200, 201, 202]
    end

    @testset "Where " begin
        @test val(Where(identity)) == identity
        dimz = Ti((1:1:3)u"s"), Y(10:10:40)
        da = DimArray(a, dimz)
        wda = da[Y(Where(x -> x >= 30)), Ti(Where(x -> x in([2u"s", 3u"s"])))]
        @test parent(wda) == [7 8; 11 12]
        @test index(wda) == ([2u"s", 3u"s"], [30, 40])
    end

end

@testset "Selectors on Sampled Intervals" begin
    da = DimArray(a, (Y(Sampled(10:10:30; sampling=Intervals())),
                      Ti(Sampled((1:4)u"s"; sampling=Intervals()))))

    @testset "with dim wrappers" begin
        @test @inferred da[Y(At([10, 30])), Ti(At([1u"s", 4u"s"]))] == [1 4; 9 12]
        @test_throws ArgumentError da[Y(At([9, 30])), Ti(At([1u"s", 4u"s"]))]
        @test @inferred view(da, Y(At(20)), Ti(At((3:4)u"s"))) == [7, 8]
        @test @inferred view(da, Y(Contains(17)), Ti(Contains([1.9u"s", 3.1u"s"]))) == [5, 7]
        @test @inferred view(da, Y(Between(4, 26)), Ti(At((3:4)u"s"))) == [3 4; 7 8]
    end

    @testset "without dim wrappers" begin
        @test @inferred da[At(20:10:30), At(1u"s")] == [5, 9]
        @test @inferred view(da, Between(4, 36), Near((3:4)u"s")) == [3 4; 7 8; 11 12]
        @test @inferred view(da, Near(22), At([3.0u"s", 4.0u"s"])) == [7, 8]
        @test @inferred view(da, At(20), At((2:3)u"s")) == [6, 7]
        @test @inferred view(da, Near(13), Near([1.3u"s", 3.3u"s"])) == [1, 3]
        @test @inferred view(da, Near([13]), Near([1.3u"s", 3.3u"s"])) == [1 3]
        @test @inferred view(da, Between(11, 26), At((2:3)u"s")) == [6 7]
        # Between also accepts a tuple input
        @test @inferred view(da, Between((11, 26)), Between((2u"s", 4u"s"))) == [6 7]
    end

    @testset "with DateTime index" begin
        @testset "Start locus" begin
            timedim = Ti(Sampled(DateTime(2001):Month(1):DateTime(2001, 12); 
                span=Regular(Month(1)), sampling=Intervals(Start())
            ))
            da = DimArray(1:12, timedim)
            @test @inferred da[Ti(At(DateTime(2001, 3)))] == 3
            @test @inferred da[Near(DateTime(2001, 4, 7))] == 4
            @test @inferred da[Between(DateTime(2001, 4, 7), DateTime(2001, 8, 30))] == [5, 6, 7]
        end
        @testset "End locus" begin
            timedim = Ti(Sampled(DateTime(2001):Month(1):DateTime(2001, 12); 
                span=Regular(Month(1)), sampling=Intervals(End()))
            )
            da = DimArray(1:12, timedim)
            @test @inferred da[Ti(At(DateTime(2001, 3)))] == 3
            @test @inferred da[Near(DateTime(2001, 4, 7))] == 5
            @test @inferred da[Between(DateTime(2001, 4, 7), DateTime(2001, 8, 30))] == [6, 7, 8]
        end
    end

    # @testset "with Val index" begin
    #     valdimz = Ti(Sampled(Val(2.0:2.0:6.0))), 
    #               Y(Sampled(Val(10.0:10.0:40)))
    #     da = DimArray(a, valdimz)
    #     @test @inferred da[Ti=Val(4.0), Y=Val(40.0)] == 8
    #     @test @inferred da[At(2.0), At(20.0)] == 2
    #     @test @inferred da[Near(Val{3.2}()), At(Val{20.0}())] == 6
    #     @test @inferred da[Near(3.2), At(20.0)] == 6
    # end

end

@testset "Selectors on Sampled Explicit Intervals" begin
    span_y = Explicit(vcat((5.0:10.0:25.0)', (15.0:10.0:35.0)'))
    span_ti = Explicit(vcat(((0.5:1.0:3.5)u"s")', ((1.5:1.0:4.5)u"s")'))
    da = DimArray(a, (Y(Sampled(10:10:30; span=span_y, sampling=Intervals())),
                      Ti(Sampled((1:4)u"s"; span=span_ti, sampling=Intervals()))))

    @testset "with dim wrappers" begin
        @test @inferred da[Y(At([10, 30])), Ti(At([1u"s", 4u"s"]))] == [1 4; 9 12]
        @test_throws ArgumentError da[Y(At([9, 30])), Ti(At([1u"s", 4u"s"]))]
        @test @inferred view(da, Y(At(20)), Ti(At((3:4)u"s"))) == [7, 8]
        @test @inferred view(da, Y(Contains(17)), Ti(Contains([1.4u"s", 3.1u"s"]))) == [5, 7]
    end

    @testset "without dim wrappers" begin
        @test @inferred da[At(20:10:30), At(1u"s")] == [5, 9]
        @test @inferred view(da, Between(4, 36), Contains((3:4)u"s")) == [3 4; 7 8; 11 12]
        @test @inferred view(da, Contains(22), At([3.0u"s", 4.0u"s"])) == [7, 8]
        @test @inferred view(da, At(20), At((2:3)u"s")) == [6, 7]
        @test @inferred view(da, Contains(13), Contains([1.3u"s", 3.3u"s"])) == [1, 3]
        @test @inferred view(da, Contains([13]), Contains([1.3u"s", 3.3u"s"])) == [1 3]
        @test @inferred view(da, Between(11, 26), At((2:3)u"s")) == [6 7]
        # Between also accepts a tuple input
        @test @inferred view(da, Between((11, 26)), Between((1.4u"s", 4u"s"))) == [6 7]
    end

    @testset "with DateTime index" begin
        span_ti = Explicit(vcat(
            reshape((DateTime(2001, 1):Month(1):DateTime(2001, 12)), 1, 12),
            reshape((DateTime(2001, 2):Month(1):DateTime(2002, 1)), 1, 12)
        ))
        timedim = Ti(Sampled(DateTime(2001, 1, 15):Month(1):DateTime(2001, 12, 15); 
            span=span_ti, sampling=Intervals(Center())
        ))
        da = DimArray(1:12, timedim)
        @test @inferred da[Ti(At(DateTime(2001, 3, 15)))] == 3
        @test @inferred da[Contains(DateTime(2001, 4, 7))] == 4
        @test @inferred da[Between(DateTime(2001, 4, 7), DateTime(2001, 8, 30))] == [5, 6, 7]
    end

end

@testset "Selectors on Categorical" begin
    a = [1 2  3  4
         5 6  7  8
         9 10 11 12]

    dimz = Ti(Categorical([:one, :two, :three]; order=ForwardOrdered())),
           Y(Categorical([:a, :b, :c, :d]; order=ForwardOrdered()))
    da = DimArray(a, dimz)
    @test @inferred da[Ti(At([:one, :two])), Y(Contains(:b))] == [2, 6]
    @test @inferred da[At(:two), Between(:b, :d)] == [6, 7, 8]
    @test @inferred da[At(:two), At(:b)] == 6
    # Near and contains are just At
    @test @inferred da[Contains([:one, :three]), Near([:b, :c, :d])] == [2 3 4; 10 11 12]

    dimz = Ti(Categorical([:one, :two, :three]; order=Unordered())),
           Y(Categorical([:a, :b, :c, :d]; order=Unordered()))
    da = DimArray(a, dimz)
    @test_throws ArgumentError da[At(:two), Between(:b, :d)] == [6, 7, 8]

    unordered_dimz = Ti(Categorical([:one, :two, :three]; order=Unordered())),
                     Y(Categorical([:a, :b, :c, :d]; order=Unordered()))
    unordered_da = DimArray(a, unordered_dimz)
    unordered_da[Near(:two), Near(:d)]

    a = [1 2  3  4
         5 6  7  8
         9 10 11 12]
end

@testset "Selectors on NoLookup" begin
    dimz = Ti(), Y()
    da = DimArray(a, dimz)
    @test @inferred da[Ti(At([1, 2])), Y(Contains(2))] == [2, 6]
    @test @inferred da[Near(2), Between(2, 4)] == [6, 7, 8]
    @test @inferred da[Contains([1, 3]), Near([2, 3, 4])] == [2 3 4; 10 11 12]
end

@testset "Selectors on TranformedIndex" begin
    using CoordinateTransformations

    m = LinearMap([0.5 0.0; 0.0 0.5])

    dimz = Dim{:trans1}(Transformed(m, X())), 
           Dim{:trans2}(Transformed(m, Y())), Z()
    @test DimensionalData.dimsmatch(dimz[1], X())
    @test DimensionalData.dimsmatch(dimz[2], Y())

    @testset "permutedims works on lookup dimensions" begin
        # @test @inferred sortdims((Y(), Z(), X()), dimz) == (X(), Y(), Z())
    end

    da = DimArray(reshape(a, 3, 4, 1), dimz)

    @testset "Indexing with array dims indexes the array as usual" begin
        da2 = da[1:3, 1:1, 1:1]
        @test @inferred da2[Dim{:trans1}(3), Dim{:trans2}(1), Z(1)] == 9
        # Using selectors works the same as indexing with lookup
        # dims - it applies the transform function.
        # It's not clear this should be allowed or makes sense,
        # but it works anyway because the permutation is correct either way.
        @test @inferred da[Dim{:trans1}(At(6)), Dim{:trans2}(At(2)), Z(1)] == 9
    end

    @testset "Indexing with lookup dims uses the transformation" begin
        @test @inferred da[X(Near(6.1)), Y(Near(8.5)), Z(1)] == 12
        @test @inferred da[X(At(4.0)), Y(At(2.0)), Z(1)] == 5
        @test_throws ArgumentError da[trans1=At(4.0)]
        @test_throws InexactError da[X(At(6.1)), Y(At(8)), Z(1)]
        # Indexing directly with lookup dims also just works, but maybe shouldn't?
        @test @inferred da[X(2), Y(2), Z(1)] == 6
    end

end

@testset "selectindices" begin
    @test selectindices(A[X(1)], Contains(7)) == (3,)
    @test selectindices(dims_, ()) == ()
end

@testset "errors" begin
    @test_throws ArgumentError DimensionalData.selectindices(X(Sampled(1:4, sampling=Points())), Contains(1))
end


@testset "hasselection" begin
    @test hasselection(A, X(At(20)))
    @test hasselection(dims(A, X), X(At(20)))
    @test hasselection(dims(A, X), At(19; atol=2))
    @test hasselection(A, (Y(At(7)),))
    @test hasselection(A, (X(At(10)), Y(At(7))))

    args = Intervals(Start()), NoMetadata()
    startfwd = Ti(Sampled(11.0:30.0,      ForwardOrdered(), Regular(1), args...))
    startrev = Ti(Sampled(30.0:-1.0:11.0, ReverseOrdered(), Regular(-1), args...))

    cases = (startfwd, startrev)
    @test all(map(d -> hasselection(d, At(30.0)), cases))
    @test all(map(d -> !hasselection(d, At(31.0)), cases))
    @test all(map(d -> hasselection(d, Contains(12.8)), cases))
    @test all(map(d -> !hasselection(d, Contains(400.0)), cases))
    @test all(map(d -> hasselection(d, Near(0.0)), cases))
end
