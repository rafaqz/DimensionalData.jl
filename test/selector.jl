using DimensionalData, Test, Unitful, Combinatorics
using DimensionalData: between, at, near, contains

a = [1 2  3  4
     5 6  7  8
     9 10 11 12]

dims_ = X(10:10:20; mode=Sampled(sampling=Intervals())),
        Y(5:7; mode=Sampled(sampling=Intervals()))
A = DimArray([1 2 3; 4 5 6], dims_)


@testset "selector primitives" begin

    @testset "Regular Intervals with range" begin
        # Order: index, array, relation (array order is irrelevent here, it's just for plotting)
        # Varnames: locusindexorderrelation

        startfwdfwd = Ti(11.0:30.0;      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ForwardRelation()), Regular(1), Intervals(Start())))
        startfwdrev = Ti(11.0:30.0;      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ReverseRelation()), Regular(1), Intervals(Start())))
        startrevfwd = Ti(30.0:-1.0:11.0; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), Regular(-1), Intervals(Start())))
        startrevrev = Ti(30.0:-1.0:11.0; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ReverseRelation()), Regular(-1), Intervals(Start())))

        @testset "Any at" begin
            @test at(startfwdfwd, At(30)) == 20
            @test at(startrevfwd, At(30)) == 1
            @test at(startfwdrev, At(30)) == 1
            @test at(startrevrev, At(30)) == 20
        end

        @testset "Start between" begin
            @test between(startfwdfwd, Between(11, 14)) === 1:3
            @test between(startfwdrev, Between(11, 14)) === 18:1:20
            @test between(startrevfwd, Between(11, 14)) === 18:20
            @test between(startrevrev, Between(11, 14)) === 1:1:3
            @test between(startfwdfwd, Between(11.1, 13.9)) === 2:2
            @test between(startfwdrev, Between(11.1, 13.9)) === 19:1:19
            @test between(startrevfwd, Between(11.1, 13.9)) === 19:19
            @test between(startrevrev, Between(11.1, 13.9)) === 2:1:2
            # Input order doesn't matter
            @test between(startfwdfwd, Between(14, 11)) === 1:3
        end

        @testset "Start contains" begin
            @test_throws BoundsError contains(startfwdfwd, Contains(10.9))
            @test_throws BoundsError contains(startfwdfwd, Contains(31))
            @test_throws BoundsError contains(startrevfwd, Contains(10.9))
            @test_throws BoundsError contains(startrevfwd, Contains(31))
            @test contains(startfwdfwd, Contains(11)) == 1
            @test contains(startfwdfwd, Contains(11.9)) == 1
            @test contains(startfwdfwd, Contains(12.0)) == 2
            @test contains(startfwdfwd, Contains(30.0)) == 20
            @test contains(startfwdfwd, Contains(29.9)) == 19
            @test contains(startrevfwd, Contains(11.9)) == 20
            @test contains(startrevfwd, Contains(12.0)) == 19
            @test contains(startrevfwd, Contains(30.9)) == 1
            @test contains(startrevfwd, Contains(30.0)) == 1
            @test contains(startrevfwd, Contains(29.0)) == 2
            @test contains(startfwdrev, Contains(11.9)) == 20
            @test contains(startfwdrev, Contains(12.0)) == 19
            @test contains(startfwdrev, Contains(30.0)) == 1
            @test contains(startfwdrev, Contains(29.9)) == 2
            @test contains(startrevrev, Contains(11.9)) == 1
            @test contains(startrevrev, Contains(12.0)) == 2
            @test contains(startrevrev, Contains(29.9)) == 19
            @test contains(startrevrev, Contains(30.0)) == 20
        end

        @testset "Start near" begin
            @test bounds(startfwdfwd) == bounds(startfwdrev) == bounds(startrevrev) == bounds(startrevfwd)
            @test near(startfwdfwd, Near(-100)) == 1
            @test near(startfwdfwd, Near(11.9)) == 1
            @test near(startfwdfwd, Near(12.0)) == 2
            @test near(startfwdfwd, Near(30.0)) == 20
            @test near(startfwdfwd, Near(29.9)) == 19
            @test near(startfwdrev, Near(11.9)) == 20
            @test near(startfwdrev, Near(12.0)) == 19
            @test near(startfwdrev, Near(29.9)) == 2
            @test near(startfwdrev, Near(30.0)) == 1
            @test near(startrevfwd, Near(11.9)) == 20
            @test near(startrevfwd, Near(12.0)) == 19
            @test near(startrevfwd, Near(29.0)) == 2
            @test near(startrevfwd, Near(30.0)) == 1
            @test near(startrevrev, Near(11.9)) == 1
            @test near(startrevrev, Near(12.0)) == 2
            @test near(startrevrev, Near(29.9)) == 19
            @test near(startrevrev, Near(30.0)) == 20
            @test near(startfwdfwd, Near(100)) == 20
        end

        centerfwdfwd = Ti((11.0:30.0);      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ForwardRelation()), Regular(1), Intervals(Center())))
        centerfwdrev = Ti((11.0:30.0);      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ReverseRelation()), Regular(1), Intervals(Center())))
        centerrevfwd = Ti((30.0:-1.0:11.0); mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), Regular(-1), Intervals(Center())))
        centerrevrev = Ti((30.0:-1.0:11.0); mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ReverseRelation()), Regular(-1), Intervals(Center())))

        @testset "Center between" begin
            @test between(centerfwdfwd, Between(10.5, 14.6)) === 1:4
            @test between(centerfwdrev, Between(10.5, 14.6)) === 17:1:20
            @test between(centerrevfwd, Between(10.5, 14.6)) === 17:20
            @test between(centerrevrev, Between(10.5, 14.6)) === 1:1:4
            @test between(centerfwdfwd, Between(10.6, 14.4)) === 2:3
            @test between(centerfwdrev, Between(10.6, 14.4)) === 18:1:19
            @test between(centerrevfwd, Between(10.6, 14.4)) === 18:19
            @test between(centerrevrev, Between(10.6, 14.4)) === 2:1:3
            # Input order doesn't matter
            @test between(centerfwdfwd, Between(15, 10)) === 1:4
        end

        @testset "Center contains" begin
            @test_throws BoundsError contains(centerfwdfwd, Contains(10.4))
            @test_throws BoundsError contains(centerfwdfwd, Contains(30.5))
            @test_throws BoundsError contains(centerrevfwd, Contains(10.4))
            @test_throws BoundsError contains(centerrevfwd, Contains(30.5))
            @test contains(centerfwdfwd, Contains(10.5)) == 1
            @test contains(centerfwdfwd, Contains(30.4)) == 20
            @test contains(centerfwdfwd, Contains(29.5)) == 20
            @test contains(centerfwdfwd, Contains(29.4)) == 19
            @test contains(centerrevfwd, Contains(10.5)) == 20
            @test contains(centerrevfwd, Contains(30.4)) == 1
            @test contains(centerrevfwd, Contains(29.5)) == 1
            @test contains(centerrevfwd, Contains(29.4)) == 2
            @test contains(centerfwdrev, Contains(29.5)) == 1
            @test contains(centerfwdrev, Contains(29.4)) == 2
            @test contains(centerrevrev, Contains(29.5)) == 20
            @test contains(centerrevrev, Contains(29.4)) == 19
        end

        @testset "Center near" begin
            @test near(centerfwdfwd, Near(10.4)) == 1
            @test near(centerfwdfwd, Near(30.5)) == 20
            @test near(centerrevfwd, Near(10.4)) == 20
            @test near(centerrevfwd, Near(30.5)) == 1
            @test near(centerfwdfwd, Near(10.5)) == 1
            @test near(centerfwdfwd, Near(30.4)) == 20
            @test near(centerfwdfwd, Near(29.5)) == 20
            @test near(centerfwdfwd, Near(29.4)) == 19
            @test near(centerrevfwd, Near(10.5)) == 20
            @test near(centerrevfwd, Near(30.4)) == 1
            @test near(centerrevfwd, Near(29.5)) == 1
            @test near(centerrevfwd, Near(29.4)) == 2
            @test near(centerfwdrev, Near(29.5)) == 1
            @test near(centerfwdrev, Near(29.4)) == 2
            @test near(centerrevrev, Near(29.5)) == 20
            @test near(centerrevrev, Near(29.4)) == 19
        end

        endfwdfwd = Ti((11.0:30.0);      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ForwardRelation()), Regular(1), Intervals(End())))
        endfwdrev = Ti((11.0:30.0);      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ReverseRelation()), Regular(1), Intervals(End())))
        endrevfwd = Ti((30.0:-1.0:11.0); mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), Regular(-1), Intervals(End())))
        endrevrev = Ti((30.0:-1.0:11.0); mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ReverseRelation()), Regular(-1), Intervals(End())))

        @testset "End between" begin
            @test between(endfwdfwd, Between(10.1, 14.9)) === 2:4
            @test between(endfwdrev, Between(10.1, 14.9)) === 17:1:19
            @test between(endrevfwd, Between(10.1, 14.9)) === 17:19
            @test between(endrevrev, Between(10.1, 14.9)) === 2:1:4
            @test between(endfwdfwd, Between(10, 15)) === 1:5
            @test between(endfwdrev, Between(10, 15)) === 16:1:20
            @test between(endrevfwd, Between(10, 15)) === 16:20
            @test between(endrevrev, Between(10, 15)) === 1:1:5
            # Input order doesn't matter
            @test between(endfwdfwd, Between(15, 10)) === 1:5
        end

        @testset "End contains" begin
            @test_throws BoundsError contains(endfwdfwd, Contains(10))
            @test_throws BoundsError contains(endfwdfwd, Contains(30.1))
            @test_throws BoundsError contains(endrevfwd, Contains(10))
            @test_throws BoundsError contains(endrevfwd, Contains(30.1))
            @test contains(endfwdfwd, Contains(10.1)) == 1
            @test contains(endfwdfwd, Contains(11.0)) == 1
            @test contains(endfwdfwd, Contains(11.1)) == 2
            @test contains(endfwdfwd, Contains(29.0)) == 19
            @test contains(endfwdfwd, Contains(29.1)) == 20
            @test contains(endfwdfwd, Contains(30.0)) == 20
            @test contains(endrevfwd, Contains(10.1)) == 20
            @test contains(endrevfwd, Contains(11.0)) == 20
            @test contains(endrevfwd, Contains(11.1)) == 19
            @test contains(endrevfwd, Contains(29.0)) == 2
            @test contains(endrevfwd, Contains(29.1)) == 1
            @test contains(endrevfwd, Contains(30.0)) == 1
            @test contains(endrevrev, Contains(11.0)) == 1
            @test contains(endrevrev, Contains(11.1)) == 2
            @test contains(endrevrev, Contains(29.0)) == 19
            @test contains(endrevrev, Contains(29.1)) == 20
            @test contains(endrevfwd, Contains(11.0)) == 20
            @test contains(endrevfwd, Contains(11.1)) == 19
            @test contains(endrevfwd, Contains(29.0)) == 2
            @test contains(endrevfwd, Contains(29.1)) == 1
        end

        @testset "End near" begin
            @test near(endfwdfwd, Near(10)) == 1
            @test near(endfwdfwd, Near(11.0)) == 1
            @test near(endfwdfwd, Near(11.1)) == 2
            @test near(endfwdfwd, Near(29.0)) == 19
            @test near(endfwdfwd, Near(29.1)) == 20
            @test near(endfwdfwd, Near(30.0)) == 20
            @test near(endfwdfwd, Near(31.1)) == 20
            @test near(endrevfwd, Near(10)) == 20
            @test near(endrevfwd, Near(11.0)) == 20
            @test near(endrevfwd, Near(11.1)) == 19
            @test near(endrevfwd, Near(29.0)) == 2
            @test near(endrevfwd, Near(29.1)) == 1
            @test near(endrevfwd, Near(30.0)) == 1
            @test near(endrevfwd, Near(31.1)) == 1
            @test near(endrevrev, Near(11.0)) == 1
            @test near(endrevrev, Near(11.1)) == 2
            @test near(endrevrev, Near(29.0)) == 19
            @test near(endrevrev, Near(29.1)) == 20
            @test near(endrevfwd, Near(11.0)) == 20
            @test near(endrevfwd, Near(11.1)) == 19
            @test near(endrevfwd, Near(29.0)) == 2
            @test near(endrevfwd, Near(29.1)) == 1
            @test near(endfwdfwd, Near(-100)) == 1
            @test near(endfwdfwd, Near(100)) == 20
        end

    end

    @testset "Regular Intervals with array" begin
        startfwd = Ti([1, 3, 4, 5]; mode=Sampled(Ordered(index=ForwardIndex()), Regular(1), Intervals(Start())))
        startrev = Ti([5, 4, 3, 1]; mode=Sampled(Ordered(index=ReverseIndex()), Regular(-1), Intervals(Start())))
        @test_throws BoundsError contains(startfwd, Contains(0.9))
        @test contains(startfwd, Contains(1.0)) == 1
        @test contains(startfwd, Contains(1.9)) == 1
        @test_throws ErrorException contains(startfwd, Contains(2))
        @test_throws ErrorException contains(startfwd, Contains(2.9))
        @test contains(startfwd, Contains(3)) == 2
        @test contains(startfwd, Contains(5.9)) == 4
        @test_throws BoundsError contains(startfwd, Contains(6))
        @test_throws BoundsError contains(startrev, Contains(0.9))
        @test contains(startrev, Contains(1.0)) == 4
        @test contains(startrev, Contains(1.9)) == 4
        @test_throws ErrorException contains(startrev, Contains(2))
        @test_throws ErrorException contains(startrev, Contains(2.9))
        @test contains(startrev, Contains(3)) == 3
        @test contains(startrev, Contains(5.9)) == 1
        @test_throws BoundsError contains(startrev, Contains(6))
    end

    @testset "Irregular Intervals with array" begin
        # Order: index, array, relation (array order is irrelevent here, it's just for plotting)
        # Varnames: locusindexorderrelation
        args = Irregular(1.0, 121.0), Intervals(Start())
        startfwdfwd = Ti((1:10).^2;    mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ForwardRelation()), args...))
        startfwdrev = Ti((1:10).^2;    mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ReverseRelation()), args...))
        startrevfwd = Ti((10:-1:1).^2; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), args...))
        startrevrev = Ti((10:-1:1).^2; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ReverseRelation()), args...))

        @testset "Any at" begin
            @test at(startfwdfwd, At(25)) == 5
            @test at(startfwdrev, At(25)) == 6
            @test at(startrevfwd, At(25)) == 6
            @test at(startrevrev, At(25)) == 5
            @test at(startfwdfwd, At(100)) == 10
            @test at(startfwdrev, At(100)) == 1
            @test at(startrevfwd, At(100)) == 1
            @test at(startrevrev, At(100)) == 10
        end

        @testset "Start between" begin
            @test between(startfwdfwd, Between(9, 36)) === 3:5
            @test between(startfwdrev, Between(9, 36)) === 6:1:8
            @test between(startrevfwd, Between(9, 36)) === 6:8
            @test between(startrevrev, Between(9, 36)) === 3:1:5
            @test between(startfwdfwd, Between(9.1, 35.0)) === 4:4
            @test between(startfwdrev, Between(9.1, 35.9)) === 7:1:7
            @test between(startrevfwd, Between(9.1, 35.9)) === 7:7
            @test between(startrevrev, Between(9.1, 35.9)) === 4:1:4
            # Input order doesn't matter
            @test between(startfwdfwd, Between(36, 9)) === 3:5
            # Handle searchorted overflow
            @test between(startfwdfwd, Between(-100, 9)) === 1:2
            @test between(startfwdfwd, Between(80, 150)) === 9:10
            @test between(startfwdrev, Between(-100, 9)) === 9:1:10
            @test between(startfwdrev, Between(80, 150)) === 1:1:2
            @test between(startrevfwd, Between(-100, 9)) === 9:10
            @test between(startrevfwd, Between(80, 150)) === 1:2
            @test between(startrevrev, Between(-100, 9)) === 1:1:2
            @test between(startrevrev, Between(80, 150)) === 9:1:10
        end

        @testset "Start contains" begin
            @test_throws BoundsError contains(startfwdfwd, Contains(0.9))
            @test_throws BoundsError contains(startfwdfwd, Contains(121.1))
            @test_throws BoundsError contains(startfwdrev, Contains(0.9))
            @test_throws BoundsError contains(startfwdrev, Contains(121.1))
            @test contains(startfwdfwd, Contains(1)) == 1
            @test contains(startfwdfwd, Contains(3.9)) == 1
            @test contains(startfwdfwd, Contains(4.0)) == 2
            @test contains(startfwdfwd, Contains(100.0)) == 10
            @test contains(startfwdfwd, Contains(99.9)) == 9
            @test contains(startfwdrev, Contains(3.9)) == 10
            @test contains(startfwdrev, Contains(4.0)) == 9
            @test contains(startfwdrev, Contains(100.0)) == 1
            @test contains(startfwdrev, Contains(99.9)) == 2
            @test_throws BoundsError contains(startrevrev, Contains(0.9))
            @test_throws BoundsError contains(startrevrev, Contains(121.1))
            @test_throws BoundsError contains(startrevfwd, Contains(0.9))
            @test_throws BoundsError contains(startrevfwd, Contains(121.1))
            @test contains(startrevfwd, Contains(3.9)) == 10
            @test contains(startrevfwd, Contains(4.0)) == 9
            @test contains(startrevfwd, Contains(120.9)) == 1
            @test contains(startrevfwd, Contains(100.0)) == 1
            @test contains(startrevfwd, Contains(99.0)) == 2
            @test contains(startrevrev, Contains(3.9)) == 1
            @test contains(startrevrev, Contains(4.0)) == 2
            @test contains(startrevrev, Contains(100.0)) == 10
            @test contains(startrevrev, Contains(99.9)) == 9
        end

        args = Irregular(0.5, 111.5), Intervals(Center())
        centerfwdfwd =Ti((1.0:10.0).^2;      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ForwardRelation()), args...))
        centerfwdrev =Ti((1.0:10.0).^2;      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ReverseRelation()), args...))
        centerrevfwd =Ti((10.0:-1.0:1.0).^2; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), args...))
        centerrevrev =Ti((10.0:-1.0:1.0).^2; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ReverseRelation()), args...))

        @testset "Center between" begin
            @test between(centerfwdfwd, Between(6.5, 30.5)) === 3:5
            @test between(centerfwdfwd, Between(6.6, 30.4)) === 4:4
            @test between(centerfwdrev, Between(6.5, 30.5)) === 6:1:8
            @test between(centerfwdrev, Between(6.6, 30.4)) === 7:1:7
            @test between(centerrevfwd, Between(6.5, 30.5)) === 6:8
            @test between(centerrevfwd, Between(6.6, 30.4)) === 7:7
            @test between(centerrevrev, Between(6.5, 30.5)) === 3:1:5
            @test between(centerrevrev, Between(6.6, 30.4)) === 4:1:4
            # Input order doesn't matter
            @test between(centerfwdfwd, Between(30.5, 6.5)) === 3:5
        end

        @testset "Center contains" begin
            @test_throws BoundsError contains(centerfwdfwd, Contains(0.4))
            @test_throws BoundsError contains(centerfwdfwd, Contains(111.5))
            @test contains(centerfwdfwd, Contains(0.5)) == 1
            @test contains(centerfwdfwd, Contains(111.4)) == 10
            @test contains(centerfwdfwd, Contains(90.5)) == 10
            @test contains(centerfwdfwd, Contains(90.4)) == 9
            @test contains(centerfwdrev, Contains(90.6)) == 1
            @test contains(centerfwdrev, Contains(90.5)) == 1
            @test contains(centerfwdrev, Contains(90.4)) == 2
            @test contains(centerfwdrev, Contains(72.5)) == 2
            @test contains(centerfwdrev, Contains(72.4)) == 3
            @test_throws BoundsError contains(centerrevfwd, Contains(0.4))
            @test_throws BoundsError contains(centerrevfwd, Contains(111.5))
            @test contains(centerrevfwd, Contains(72.5)) == 2
            @test contains(centerrevfwd, Contains(72.4)) == 3
            @test contains(centerrevfwd, Contains(0.5)) == 10
            @test contains(centerrevfwd, Contains(111.4)) == 1
            @test contains(centerrevfwd, Contains(90.5)) == 1
            @test contains(centerrevfwd, Contains(90.4)) == 2
            @test contains(centerrevrev, Contains(90.5)) == 10
            @test contains(centerrevrev, Contains(90.4)) == 9
        end

        args = Irregular(0.0, 100.0), Intervals(End())
        endfwdfwd = Ti((1.0:10.0).^2;      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ForwardRelation()), args...))
        endfwdrev = Ti((1.0:10.0).^2;      mode=Sampled(Ordered(ForwardIndex(),ForwardArray(),ReverseRelation()), args...))
        endrevfwd = Ti((10.0:-1.0:1.0).^2; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), args...))
        endrevrev = Ti((10.0:-1.0:1.0).^2; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ReverseRelation()), args...))

        @testset "End between" begin
            @test between(endfwdfwd, Between(4, 25)) === 3:5
            @test between(endfwdrev, Between(4, 25)) === 6:1:8
            @test between(endrevfwd, Between(4, 25)) === 6:8
            @test between(endrevrev, Between(4, 25)) === 3:1:5
            @test between(endfwdfwd, Between(4.1, 24.9)) === 4:4
            @test between(endfwdrev, Between(4.1, 24.9)) === 7:1:7
            @test between(endrevfwd, Between(4.1, 24.9)) === 7:7
            @test between(endrevrev, Between(4.1, 24.9)) === 4:1:4
            # Input order doesn't matter
            @test between(endfwdfwd, Between(25, 4)) === 3:5
            # Handle searchorted overflow
            @test between(endfwdfwd, Between(-100, 4)) === 1:2
            @test between(endfwdfwd, Between(-100, 4)) === 1:2
            @test between(endfwdfwd, Between(64, 150)) === 9:10
            @test between(endfwdrev, Between(-100, 4)) === 9:1:10
            @test between(endfwdrev, Between(64, 150)) === 1:1:2
            @test between(endrevfwd, Between(-100, 4)) === 9:10
            @test between(endrevfwd, Between(64, 150)) === 1:2
            @test between(endrevrev, Between(-100, 4)) === 1:1:2
            @test between(endrevrev, Between(64, 150)) === 9:1:10
        end

        @testset "End contains" begin
            @test_throws BoundsError contains(endfwdfwd, Contains(-0.1))
            @test_throws BoundsError contains(endfwdfwd, Contains(100.1))
            @test_throws BoundsError contains(endrevfwd, Contains(-0.1))
            @test_throws BoundsError contains(endrevfwd, Contains(100.1))
            @test contains(endfwdfwd, Contains(0.1)) == 1
            @test contains(endfwdfwd, Contains(1.0)) == 1
            @test contains(endfwdfwd, Contains(1.1)) == 2
            @test contains(endfwdfwd, Contains(81.0)) == 9
            @test contains(endfwdfwd, Contains(81.1)) == 10
            @test contains(endfwdfwd, Contains(100.0)) == 10
            @test contains(endrevfwd, Contains(0.1)) == 10
            @test contains(endrevfwd, Contains(1.0)) == 10
            @test contains(endrevfwd, Contains(1.1)) == 9
            @test contains(endrevfwd, Contains(81.0)) == 2
            @test contains(endrevfwd, Contains(81.1)) == 1
            @test contains(endrevfwd, Contains(100.0)) == 1
            @test contains(endrevrev, Contains(1.0)) == 1
            @test contains(endrevrev, Contains(1.1)) == 2
            @test contains(endrevrev, Contains(81.0)) == 9
            @test contains(endrevrev, Contains(81.1)) == 10
            @test contains(endrevfwd, Contains(1.0)) == 10
            @test contains(endrevfwd, Contains(1.1)) == 9
            @test contains(endrevfwd, Contains(81.0)) == 2
            @test contains(endrevfwd, Contains(81.1)) == 1
        end

    end

    @testset "Points mode" begin

        fwdfwd = Ti((5.0:30.0);      mode=Sampled(order=Ordered(ForwardIndex(),ForwardArray(),ForwardRelation()), sampling=Points()))
        fwdrev = Ti((5.0:30.0);      mode=Sampled(order=Ordered(ForwardIndex(),ForwardArray(),ReverseRelation()), sampling=Points()))
        revfwd = Ti((30.0:-1.0:5.0); mode=Sampled(order=Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), sampling=Points()))
        revrev = Ti((30.0:-1.0:5.0); mode=Sampled(order=Ordered(ReverseIndex(),ForwardArray(),ReverseRelation()), sampling=Points()))

        @testset "between" begin
            @test between(fwdfwd, Between(10, 15)) === 6:11
            @test between(fwdrev, Between(10, 15)) === 16:1:21
            @test between(revfwd, Between(10, 15)) === 16:21
            @test between(revrev, Between(10, 15)) === 6:1:11
            # Input order doesn't matter
            @test between(fwdfwd, Between(15, 10)) === 6:11
        end

        @testset "at" begin
            @test at(fwdfwd, At(30)) == 26
            @test at(revfwd, At(30)) == 1
            @test at(fwdrev, At(30)) == 1
            @test at(revrev, At(30)) == 26
        end

        @testset "near" begin
            @test near(fwdfwd, Near(50))   == 26
            @test near(fwdfwd, Near(0))    == 1
            @test near(fwdfwd, Near(29.4)) == 25
            @test near(fwdfwd, Near(29.5)) == 26
            @test near(revfwd, Near(29.4)) == 2
            @test near(revfwd, Near(30.1)) == 1
            @test near(fwdrev, Near(29.4)) == 2
            @test near(fwdrev, Near(29.5)) == 1
            @test near(revrev, Near(29.4)) == 25
            @test near(revrev, Near(30.1)) == 26
        end

        @testset "near" begin
            @test_throws ArgumentError contains(fwdfwd, Contains(50))
        end

    end

end


@testset "Selectors on Sampled" begin
    da = DimArray(a, (Y((10, 30); mode=Sampled()),
                              Ti((1:4)u"s"; mode=Sampled())))

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
            (Near<|13, Near<|[1.3u"s", 3.3u"s"]),
            (Near<|[13], Near<|[1.3u"s", 3.3u"s"]),
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
            from2d = view(da, idx)
            @test from2d == view(parent(da), idx)
            @test from2d isa SubArray
            from1d = view(da[Y(At(10))], idx)
            @test from1d == view(parent(da)[1, :], idx)
            @test from1d isa AbstractDimArray
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
        dimz = Ti(1.0u"s":1.0u"s":3.0u"s"; mode=Sampled()),
               Y((1u"km", 4u"km"); mode=Sampled())
        db = DimArray(a, dimz)
        @test db[Y<|Between(2u"km", 3.9u"km"), Ti<|At<|3.0u"s"] == [10, 11]
    end

    @testset "selectors work in reverse orders" begin
        a = [1 2  3  4
             5 6  7  8
             9 10 11 12]

        @testset "forward index with reverse relation" begin
            da_ffr = DimArray(a, (Y(10:10:30; mode=Sampled(order=Ordered(ForwardIndex(), ForwardArray(), ReverseRelation()))),
                                         Ti((1:1:4)u"s"; mode=Sampled(order=Ordered(ForwardIndex(), ForwardArray(), ReverseRelation())))))
            @test indexorder(dims(da_ffr, Ti)) == ForwardIndex()
            @test arrayorder(dims(da_ffr, Ti)) == ForwardArray()
            @test relation(dims(da_ffr, Ti)) == ReverseRelation()
            @test da_ffr[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [6, 5]
            @test da_ffr[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [6 5; 2 1]
            @test da_ffr[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [6, 5]
            @test da_ffr[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [6 5; 2 1]
            # Between hasn't reverse the index order
            @test da_ffr[Y<|Between(19, 35), Ti<|Between(3.0u"s", 4.0u"s")] == [1 2; 5 6]
        end

        @testset "reverse index with forward relation" begin
            da_rff = DimArray(a, (Y(30:-10:10; mode=Sampled(order=Ordered(ReverseIndex(), ForwardArray(), ForwardRelation()))),
                                         Ti((4:-1:1)u"s"; mode=Sampled(order=Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())))))
            @test da_rff[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [6, 5]
            @test da_rff[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [6 5; 2 1]
            @test da_rff[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [6, 5]
            @test da_rff[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [6 5; 2 1]
            # Between hasn't reverse the index order
            @test da_rff[Y<|Between(20, 30), Ti<|Between(3.0u"s", 4.0u"s")] == [1 2; 5 6]
        end

        @testset "forward index with forward relation" begin
            da_fff = DimArray(a, (Y(10:10:30; mode=Sampled(order=Ordered(ForwardIndex(), ForwardArray(), ForwardRelation()))),
                                         Ti((1:4)u"s"; mode=Sampled(order=Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())))))
            @test da_fff[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [7, 8]
            @test da_fff[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [7 8; 11 12]
            @test da_fff[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [7, 8]
            @test da_fff[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [7 8; 11 12]
            @test da_fff[Y<|Between(20, 30), Ti<|Between(3.0u"s", 4.0u"s")] == [7 8; 11 12]
        end

        @testset "reverse index with reverse relation" begin
            da_rfr = DimArray(a, (Y(30:-10:10; mode=Sampled(order=Ordered(ReverseIndex(), ForwardArray(), ReverseRelation()))),
                                         Ti((4:-1:1)u"s"; mode=Sampled(order=Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())))))
            @test da_rfr[Y<|At(20), Ti<|At((3.0:4.0)u"s")] == [7, 8]
            @test da_rfr[Y<|At([20, 30]), Ti<|At((3.0:4.0)u"s")] == [7 8; 11 12]
            @test da_rfr[Y<|Near(22), Ti<|Near([3.3u"s", 4.3u"s"])] == [7, 8]
            @test da_rfr[Y<|Near([22, 42]), Ti<|Near([3.3u"s", 4.3u"s"])] == [7 8; 11 12]
            @test da_rfr[Y<|Between(20, 30), Ti<|Between(3.0u"s", 4.0u"s")] == [7 8; 11 12]
        end

    end

    @testset "setindex! with selectors" begin
        c = deepcopy(a)
        dc = DimArray(c, (Y((10, 30)), Ti((1:4)u"s")))
        dc[Near(11), At(3u"s")] = 100
        @test c[1, 3] == 100
        @inferred setindex!(dc, [200, 201, 202], Ti<|Near(2.2u"s"), Y<|Between(10, 30))
        @test c[1:3, 2] == [200, 201, 202]
    end

end

@testset "Selectors on Sampled and Intervals" begin
    da = DimArray(a, (Y((10, 30); mode=Sampled(sampling=Intervals())),
                              Ti((1:4)u"s"; mode=Sampled(sampling=Intervals()))))

    @testset "selectors with dim wrappers" begin
        @test @inferred da[Y(At([10, 30])), Ti(At([1u"s", 4u"s"]))] == [1 4; 9 12]
        @test_throws ArgumentError da[Y(At([9, 30])), Ti(At([1u"s", 4u"s"]))]
        @test @inferred view(da, Y(At(20)), Ti(At((3:4)u"s"))) == [7, 8]
        @test @inferred view(da, Y(Contains(17)), Ti(Contains([1.9u"s", 3.1u"s"]))) == [5, 7]
        @test @inferred view(da, Y(Between(4, 26)), Ti(At((3:4)u"s"))) == [3 4; 7 8]
    end

    @testset "selectors without dim wrappers" begin
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

end


@testset "Selectors on NoIndex" begin
    dimz = Ti(), Y()
    da = DimArray(a, dimz)
    @test @inferred da[Ti(At([1, 2])), Y(Contains(2))] == [2, 6]
    @test @inferred da[Near(2), Between(2, 4)] == [6, 7, 8]
    @test @inferred da[Contains([1, 3]), Near([2, 3, 4])] == [2 3 4; 10 11 12]
end

@testset "Selectors on Categorical" begin
    a = [1 2  3  4
         5 6  7  8
         9 10 11 12]

    dimz = Ti([:one, :two, :three]; mode=Categorical(Ordered())),
        Y([:a, :b, :c, :d]; mode=Categorical(Ordered()))
    da = DimArray(a, dimz)
    @test @inferred da[Ti(At([:one, :two])), Y(Contains(:b))] == [2, 6]
    @test @inferred da[At(:two), Between(:b, :d)] == [6, 7, 8]
    @test @inferred da[:two, :b] == 6
    # Near and contains are just At
    @test @inferred da[Contains([:one, :three]), Near([:b, :c, :d])] == [2 3 4; 10 11 12]

    dimz = Ti([:one, :two, :three]; mode=Categorical(Unordered())),
        Y([:a, :b, :c, :d]; mode=Categorical(Unordered()))
    da = DimArray(a, dimz)
    @test_throws ArgumentError da[At(:two), Between(:b, :d)] == [6, 7, 8]

    a = [1 2  3  4
         5 6  7  8
         9 10 11 12]

    valdimz = Ti(Val((2.4, 2.5, 2.6)); mode=Categorical(Ordered())),
        Y(Val((:a, :b, :c, :d)); mode=Categorical(Ordered()))
    da = DimArray(a, valdimz)
    @test @inferred da[Val(2.5), Val(:c)] == 7
    @test @inferred da[2.4, :a] == 1
end

@testset "Where " begin
    dimz = Ti((1:1:3)u"s"), Y(10:10:40)
    da = DimArray(a, dimz)
    wda = da[Y(Where(x -> x >= 30)), Ti(Where(x -> x in([2u"s", 3u"s"])))]
    @test parent(wda) == [7 8; 11 12]
    @test index(wda) == ([2u"s", 3u"s"], [30, 40])
end

@testset "TranformedIndex" begin
    using CoordinateTransformations

    m = LinearMap([0.5 0.0; 0.0 0.5])

    dimz = Dim{:trans1}(mode=Transformed(m, X)),
           Dim{:trans2}(mode=Transformed(m, Y)),
           Z()

    @testset "permutedims works on mode dimensions" begin
        DimensionalData.modetype(typeof(dimz[1]))
        @test @inferred sortdims((Y(), Z(), X()), dimz) == (X(), Y(), Z())
    end

    da = DimArray(reshape(a, 3, 4, 1), dimz)

    @testset "Indexing with array dims indexes the array as usual" begin
        @test @inferred da[Dim{:trans1}(3), Dim{:trans2}(1), Z(1)] == 9
        # Using selectors works the same as indexing with mode
        # dims - it applies the transform function.
        # It's not clear this should be allowed or makes sense,
        # but it works anyway because the permutation is correct either way.
        @test @inferred da[Dim{:trans1}(At(6)), Dim{:trans2}(At(2)), Z(1)] == 9
    end

    @testset "Indexing with mode dims uses the transformation" begin
        @test @inferred da[X(Near(6.1)), Y(Near(8.5)), Z(1)] == 12
        @test @inferred da[X(At(4.0)), Y(At(2.0)), Z(1)] == 5
        @test_throws InexactError da[X(At(6.1)), Y(At(8)), Z(1)]
        # Indexing directly with mode dims also just works, but maybe shouldn't?
        @test @inferred da[X(2), Y(2), Z(1)] == 6
    end

end
