using DimensionalData, Test, Unitful, Combinatorics, Dates, IntervalSets, Extents
using DimensionalData.Lookups, DimensionalData.Dimensions
using .Lookups: between, touches, at, near, contains, bounds, SelectorError, cycle_val

a = [1 2  3  4
     5 6  7  8
     9 10 11 12]

dims_ = X(Sampled(10:10:20; sampling=Intervals())),
        Y(Sampled(5:7; sampling=Intervals()))
A = DimArray([1 2 3; 4 5 6], dims_)

@testset "selector primitives" begin

    @testset "Explicit Intervals" begin
        fwdindex = 11.0:30.0
        revindex = 30.0:-1.0:11.0

        args = Intervals(Start()), NoMetadata()
        fwdmatrix = vcat(fwdindex', (fwdindex .+ 1)')
        revmatrix = vcat(revindex', (revindex .+ 1)')
        startfwd = Sampled(fwdindex, ForwardOrdered(), Explicit(fwdmatrix), args...)
        startrev = Sampled(revindex, ReverseOrdered(), Explicit(revmatrix), args...)

        args = Intervals(Center()), NoMetadata()
        fwdmatrix = vcat((fwdindex .- 0.5)', (fwdindex .+ 0.5)')
        revmatrix = vcat((revindex .- 0.5)', (revindex .+ 0.5)')
        centerfwd = Sampled(fwdindex, ForwardOrdered(), Explicit(fwdmatrix), args...)
        centerrev = Sampled(revindex, ReverseOrdered(), Explicit(revmatrix), args...)

        args = Intervals(End()), NoMetadata()
        fwdmatrix = vcat((fwdindex .- 1)', fwdindex')
        revmatrix = vcat((revindex .- 1)', revindex')
        endfwd = Sampled(fwdindex, ForwardOrdered(), Explicit(fwdmatrix), args...)
        endrev = Sampled(revindex, ReverseOrdered(), Explicit(revmatrix), args...)

        @testset "Any at" begin
            @test at(startfwd, At(30)) == 20
            @test at(startrev, At(30)) == 1
            @test at(startfwd, At(29.9; atol=0.2)) == 20
            @test at(startrev, At(29.9; atol=0.2)) == 1
            @test at(startfwd, At(30.1; atol=0.2)) == 20
            @test at(startrev, At(30.1; atol=0.2)) == 1
            @test_throws SelectorError at(startrev, At(0.0; atol=0.2))
            @test at(startrev, At(0.0; atol=0.2); err=Lookups._False()) == nothing
        end

        @testset "Start between" begin
            @test between(startfwd, 0..11.9) === 1:0
            @test between(startfwd, 0..12) === 1:1
            @test between(startfwd, 30..50) === 20:20
            @test between(startfwd, 31..50) === 21:20
            @test between(startrev, 0..11.9) === 21:20
            @test between(startrev, 0..12) === 20:20
            @test between(startrev, 30..50) === 1:1
            @test between(startrev, 30.1..50) === 1:0
            @test between(startfwd, 0..40) === 1:20
            @test between(startrev, 0..40) === 1:20
            # Bounds
            @test between(startfwd, 11.0..31.0) === 1:20
            @test between(startrev, 11.0..31.0) === 1:20
            # Input order doesn't matter with Between
            @test between(startfwd, Between(14, 11)) === 1:3
            @test between(startfwd, Between(0, 11.9)) === 1:0
            # Intervals
            @test between(startfwd, 12.0..15.0) === 2:4
            @test between(startfwd, 12.1..14.9) === 3:3
            @test between(startrev, 12.0..15.0) === 17:19
            @test between(startrev, 12.1..14.9) === 18:18
            @test between(startfwd, Interval{:open,:open}(11.9..15.1)) === 2:4
            @test between(startfwd, Interval{:open,:open}(12.0..15.0)) === 3:3
            @test between(startrev, Interval{:open,:open}(11.9..15.1)) === 17:19
            @test between(startrev, Interval{:open,:open}(12.0..15.0)) === 18:18
            @test between(startfwd, Interval{:open,:closed}(11.9..15.0)) === 2:4
            @test between(startfwd, Interval{:open,:closed}(12.0..14.9)) === 3:3
            @test between(startrev, Interval{:open,:closed}(11.9..15.0)) === 17:19
            @test between(startrev, Interval{:open,:closed}(12.0..14.9)) === 18:18
            @test between(startfwd, Interval{:closed,:open}(12.0..15.1)) === 2:4
            @test between(startfwd, Interval{:closed,:open}(12.1..15.0)) === 3:3
            @test between(startrev, Interval{:closed,:open}(12.0..15.1)) === 17:19
            @test between(startrev, Interval{:closed,:open}(12.1..15.0)) === 18:18
        end

        @testset "Center between" begin
            @test between(centerfwd, 0..11.4) === 1:0
            @test between(centerfwd, 0..11.5) === 1:1
            @test between(centerfwd, 29.5..50.0) === 20:20
            @test between(centerfwd, 29.6..50.0) === 21:20
            @test between(centerrev, 0..11.4) === 21:20
            @test between(centerrev, 0..11.5) === 20:20
            @test between(centerrev, 29.5..50.0) === 1:1
            @test between(centerrev, 29.6..50.0) === 1:0
            @test between(centerfwd, 0..40) === 1:20
            @test between(centerrev, 0..40) === 1:20
            # Bounds
            @test between(centerrev, 10.5..30.5) === 1:20
            @test between(centerrev, 10.5..30.5) === 1:20
            # Input order doesn't matter with Between
            @test between(centerfwd, Between(15, 10)) === 1:4

            @test between(centerfwd, 11.5..14.5) === 2:4
            @test between(centerfwd, 11.6..14.4) === 3:3
            @test between(centerrev, 11.5..14.5) === 17:19
            @test between(centerrev, 11.6..14.4) === 18:18
            @test between(centerfwd, Interval{:open,:open}(11.4..14.6)) === 2:4
            @test between(centerfwd, Interval{:open,:open}(11.5..14.5)) === 3:3
            @test between(centerrev, Interval{:open,:open}(11.4..14.6)) === 17:19
            @test between(centerrev, Interval{:open,:open}(11.5..14.5)) === 18:18
            @test between(centerfwd, Interval{:open,:closed}(11.4..14.5)) === 2:4
            @test between(centerfwd, Interval{:open,:closed}(11.5..14.4)) === 3:3
            @test between(centerrev, Interval{:open,:closed}(11.4..14.5)) === 17:19
            @test between(centerrev, Interval{:open,:closed}(11.5..14.4)) === 18:18
            @test between(centerfwd, Interval{:closed,:open}(11.5..14.6)) === 2:4
            @test between(centerfwd, Interval{:closed,:open}(11.6..14.5)) === 3:3
            @test between(centerrev, Interval{:closed,:open}(11.5..14.6)) === 17:19
            @test between(centerrev, Interval{:closed,:open}(11.6..14.5)) === 18:18
        end

        @testset "End between" begin
            @test between(endfwd, 0.0..10.9) === 1:0
            @test between(endfwd, 0..11) === 1:1
            @test between(endfwd, 29.0..30.0) === 20:20
            @test between(endfwd, 29.1..50.0) === 21:20
            @test between(endrev, 0.0..10.9) === 21:20
            @test between(endrev, 0.0..11.0) === 20:20
            @test between(endrev, 29.0..50.0) === 1:1
            @test between(endrev, 29.1..50.0) === 1:0
            @test between(endfwd, 0..40) === 1:20
            @test between(endrev, 0..40) === 1:20
            # Bounds
            @test between(endfwd, 10.0..30.0) === 1:20
            @test between(endrev, 10.0..30.0) === 1:20
            # Input order doesn't matter with Between
            @test between(endfwd, Between(15, 10)) === 1:5

            @test between(endfwd, 12.0..15.0) === 3:5
            @test between(endfwd, 12.1..14.9) === 4:4
            @test between(endrev, 12.0..15.0) === 16:18
            @test between(endrev, 12.1..14.9) === 17:17
            @test between(endfwd, Interval{:open,:open}(11.9..15.1)) === 3:5
            @test between(endfwd, Interval{:open,:open}(12.0..15.0)) === 4:4
            @test between(endrev, Interval{:open,:open}(11.9..15.1)) === 16:18
            @test between(endrev, Interval{:open,:open}(12.0..15.0)) === 17:17
            @test between(endfwd, Interval{:open,:closed}(11.9..15.0)) === 3:5
            @test between(endfwd, Interval{:open,:closed}(12.0..14.9)) === 4:4
            @test between(endrev, Interval{:open,:closed}(11.9..15.0)) === 16:18
            @test between(endrev, Interval{:open,:closed}(12.0..14.9)) === 17:17
            @test between(endfwd, Interval{:closed,:open}(12.0..15.1)) === 3:5
            @test between(endfwd, Interval{:closed,:open}(12.1..15.0)) === 4:4
            @test between(endrev, Interval{:closed,:open}(12.0..15.1)) === 16:18
            @test between(endrev, Interval{:closed,:open}(12.1..15.0)) === 17:17
        end

        # Essentially as `between` above but with smaller intervals
        @testset "Start touches" begin
            @test touches(startfwd, Touches(0, 10.9)) === 1:0
            @test touches(startfwd, Touches(0, 11)) === 1:1
            @test touches(startfwd, Touches(31, 31)) === 20:20
            @test touches(startfwd, Touches(31, 50)) === 20:20
            @test touches(startfwd, Touches(31.1, 50)) === 21:20
            @test touches(startrev, Touches(0, 10.9)) === 21:20
            @test touches(startrev, Touches(0, 11)) === 20:20
            @test touches(startrev, Touches(31, 50)) === 1:1
            @test touches(startrev, Touches(31.1, 50)) === 1:0
            @test touches(startfwd, Touches(0, 40)) === 1:20
            @test touches(startrev, Touches(0, 40)) === 1:20
            # Bounds
            @test touches(startfwd, Touches(12.0, 30.0)) === 1:20
            @test touches(startrev, Touches(12.0, 30.0)) === 1:20
            # Intervals
            @test touches(startfwd, Touches(13.0, 14.0)) === 2:4
            @test touches(startfwd, Touches(13.1, 13.9)) === 3:3
            @test touches(startrev, Touches(13.0, 14.0)) === 17:19
            @test touches(startrev, Touches(13.1, 13.9)) === 18:18
        end

        @testset "Center touches" begin
            @test touches(centerfwd, Touches(0, 10.4)) === 1:0
            @test touches(centerfwd, Touches(0, 10.5)) === 1:1
            @test touches(centerfwd, Touches(30.0, 30.0)) === 20:20
            @test touches(centerfwd, Touches(30.5, 50.0)) === 20:20
            @test touches(centerfwd, Touches(30.6, 50.0)) === 21:20
            @test touches(centerrev, Touches(0, 10.4)) === 21:20
            @test touches(centerrev, Touches(0, 10.5)) === 20:20
            @test touches(centerrev, Touches(30.5, 50.0)) === 1:1
            @test touches(centerrev, Touches(30.6, 50.0)) === 1:0
            @test touches(centerfwd, Touches(0, 40)) === 1:20
            @test touches(centerrev, Touches(0, 40)) === 1:20
            # Bounds
            @test touches(centerrev, Touches(11.5, 29.5)) === 1:20
            @test touches(centerrev, Touches(11.5, 29.5)) === 1:20

            @test touches(centerfwd, Touches(12.5, 13.5)) === 2:4
            @test touches(centerfwd, Touches(12.6, 13.4)) === 3:3
            @test touches(centerrev, Touches(12.5, 13.5)) === 17:19
            @test touches(centerrev, Touches(12.6, 13.4)) === 18:18
        end

        @testset "End touches" begin
            @test touches(endfwd, Touches(0.0, 9.9)) === 1:0
            @test touches(endfwd, Touches(0, 10)) === 1:1
            @test touches(endfwd, Touches(30.0, 30.0)) === 20:20
            @test touches(endfwd, Touches(30.1, 50.0)) === 21:20
            @test touches(endrev, Touches(0.0, 9.9)) === 21:20
            @test touches(endrev, Touches(0.0, 10.0)) === 20:20
            @test touches(endrev, Touches(30.0, 50.0)) === 1:1
            @test touches(endrev, Touches(30.1, 50.0)) === 1:0
            @test touches(endfwd, Touches(0, 40)) === 1:20
            @test touches(endrev, Touches(0, 40)) === 1:20
            # Bounds
            @test touches(endfwd, Touches(11.0, 29.0)) === 1:20
            @test touches(endrev, Touches(11.0, 29.0)) === 1:20

            @test touches(endfwd, Touches(13.0, 14.0)) === 3:5
            @test touches(endfwd, Touches(13.1, 13.9)) === 4:4
            @test touches(endrev, Touches(13.0, 14.0)) === 16:18
            @test touches(endrev, Touches(13.1, 13.9)) === 17:17
        end

        @testset "Start contains" begin
            @test_throws SelectorError contains(startfwd, Contains(10.9))
            @test_throws SelectorError contains(startfwd, Contains(31))
            @test_throws SelectorError contains(startrev, Contains(31))
            @test_throws SelectorError contains(startrev, Contains(10.9))
            @test contains(startrev, Contains(10.9); err=Lookups._False()) == nothing
            @test contains(startfwd, Contains(11)) == 1
            @test contains(startfwd, Contains(11.9)) == 1
            @test contains(startfwd, Contains(12.0)) == 2
            @test contains(startfwd, Contains(30.0)) == 20
            @test contains(startfwd, Contains(30.9)) == 20
            @test contains(startfwd, Contains(29.9)) == 19
            @test contains(startrev, Contains(11.9)) == 20
            @test contains(startrev, Contains(12.0)) == 19
            @test contains(startrev, Contains(30.0)) == 1
            @test contains(startrev, Contains(30.9)) == 1
            @test contains(startrev, Contains(29.0)) == 2
        end

        @testset "Center contains" begin
            @test_throws SelectorError contains(centerfwd, Contains(10.4))
            @test_throws SelectorError contains(centerfwd, Contains(30.5))
            @test_throws SelectorError contains(centerrev, Contains(10.4))
            @test_throws SelectorError contains(centerrev, Contains(30.5))
            @test contains(centerfwd, Contains(10.5)) == 1
            @test contains(centerfwd, Contains(30.4)) == 20
            @test contains(centerfwd, Contains(29.5)) == 20
            @test contains(centerfwd, Contains(29.4)) == 19
            @test contains(centerrev, Contains(10.5)) == 20
            @test contains(centerrev, Contains(30.4)) == 1
            @test contains(centerrev, Contains(29.5)) == 1
            @test contains(centerrev, Contains(29.4)) == 2
        end

        @testset "End contains" begin
            @test_throws SelectorError contains(endfwd, Contains(10))
            @test_throws SelectorError contains(endfwd, Contains(30.1))
            @test_throws SelectorError contains(endrev, Contains(10))
            @test_throws SelectorError contains(endrev, Contains(30.1))
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

    end

    @testset "Regular Intervals with range" begin
        args = Intervals(Start()), NoMetadata()
        startfwd = Sampled(11.0:30.0,      ForwardOrdered(), Regular(1), args...)
        startrev = Sampled(30.0:-1.0:11.0, ReverseOrdered(), Regular(-1), args...)

        args = Intervals(Center()), NoMetadata()
        centerfwd = Sampled(11.0:30.0,      ForwardOrdered(), Regular(1), args...)
        centerrev = Sampled(30.0:-1.0:11.0, ReverseOrdered(), Regular(-1), args...)

        args = Intervals(End()), NoMetadata()
        endfwd = Sampled(11.0:30.0,      ForwardOrdered(), Regular(1), args...)
        endrev = Sampled(30.0:-1.0:11.0, ReverseOrdered(), Regular(-1), args...)

        @testset "Any at" begin
            @test at(startfwd, At(30)) == 20
            @test at(startrev, At(30)) == 1
            @test at(startfwd, At(29.9; atol=0.2)) == 20
            @test at(startrev, At(29.9; atol=0.2)) == 1
            @test at(startfwd, At(30.1; atol=0.2)) == 20
            @test at(startrev, At(30.1; atol=0.2)) == 1
        end
        @testset "Start between" begin
            @test between(startfwd, 0..11.9) === 1:0
            @test between(startfwd, 0..12) === 1:1
            @test between(startfwd, 30..50) === 20:20
            @test between(startfwd, 31..50) === 21:20
            @test between(startrev, 0..11.9) === 21:20
            @test between(startrev, 0..12) === 20:20
            @test between(startrev, 30..50) === 1:1
            @test between(startrev, 30.1..50) === 1:0
            @test between(startfwd, 0..40) === 1:20
            @test between(startrev, 0..40) === 1:20
            # Bounds
            @test between(startfwd, 11.0..31.0) === 1:20
            @test between(startrev, 11.0..31.0) === 1:20

            @test between(startfwd, 11.1..13.9) === 2:2
            @test between(startfwd, 11.0..14.0) === 1:3
            @test between(startrev, 11.1..13.9) === 19:19
            @test between(startrev, 11.0..14.0) === 18:20
            @test between(startfwd, Interval{:open,:open}(11.0..14.0)) === 2:2
            @test between(startfwd, Interval{:open,:open}(10.9..14.1)) === 1:3
            @test between(startrev, Interval{:open,:open}(11.0..14.0)) === 19:19
            @test between(startrev, Interval{:open,:open}(10.9..14.1)) === 18:20
            @test between(startfwd, Interval{:open,:closed}(11.0..13.9)) === 2:2
            @test between(startfwd, Interval{:open,:closed}(10.9..14.0)) === 1:3
            @test between(startrev, Interval{:open,:closed}(11.0..13.9)) === 19:19
            @test between(startrev, Interval{:open,:closed}(10.9..14.0)) === 18:20
            @test between(startfwd, Interval{:closed,:open}(11.1..13.9)) === 2:2
            @test between(startfwd, Interval{:closed,:open}(11.0..14.1)) === 1:3
            @test between(startrev, Interval{:closed,:open}(11.1..14.0)) === 19:19
            @test between(startrev, Interval{:closed,:open}(11.0..14.1)) === 18:20
        end

        @testset "Center between" begin
            @test between(centerfwd, 0..11.4) === 1:0
            @test between(centerfwd, 0..11.5) === 1:1
            @test between(centerfwd, 29.5..50.0) === 20:20
            @test between(centerfwd, 29.6..50.0) === 21:20
            @test between(centerrev, 0..11.4) === 21:20
            @test between(centerrev, 0..11.5) === 20:20
            @test between(centerrev, 29.5..50.0) === 1:1
            @test between(centerrev, 29.6..50.0) === 1:0
            @test between(centerfwd, 0..40) === 1:20
            @test between(centerrev, 0..40) === 1:20
            # Bounds
            @test between(centerrev, 10.5..30.5) === 1:20
            @test between(centerrev, 10.5..30.5) === 1:20

            @test between(centerfwd, 10.5..14.5) === 1:4
            @test between(centerfwd, 10.6..14.4) === 2:3
            @test between(centerrev, 10.5..14.5) === 17:20
            @test between(centerrev, 10.6..14.4) === 18:19
            @test between(centerfwd, Interval{:open,:open}(10.4..14.6)) === 1:4
            @test between(centerfwd, Interval{:open,:open}(10.5..14.5)) === 2:3
            @test between(centerrev, Interval{:open,:open}(10.4..14.6)) === 17:20
            @test between(centerrev, Interval{:open,:open}(10.6..14.5)) === 18:19
            @test between(centerfwd, Interval{:open,:closed}(10.4..14.6)) === 1:4
            @test between(centerfwd, Interval{:open,:closed}(10.5..14.4)) === 2:3
            @test between(centerrev, Interval{:open,:closed}(10.4..14.6)) === 17:20
            @test between(centerrev, Interval{:open,:closed}(10.5..14.4)) === 18:19
            @test between(centerfwd, Interval{:closed,:open}(10.5..14.6)) === 1:4
            @test between(centerfwd, Interval{:closed,:open}(10.6..14.5)) === 2:3
            @test between(centerrev, Interval{:closed,:open}(10.5..14.6)) === 17:20
            @test between(centerrev, Interval{:closed,:open}(10.6..14.5)) === 18:19
        end

        @testset "End between" begin
            @test between(endfwd, 0.0..10.9) === 1:0
            @test between(endfwd, 0..11) === 1:1
            @test between(endfwd, 29.0..30.0) === 20:20
            @test between(endfwd, 29.1..50.0) === 21:20
            @test between(endrev, 0.0..10.9) === 21:20
            @test between(endrev, 0.0..11.0) === 20:20
            @test between(endrev, 29.0..50.0) === 1:1
            @test between(endrev, 29.1..50.0) === 1:0
            @test between(endfwd, 0..40) === 1:20
            @test between(endrev, 0..40) === 1:20
            # Bounds
            @test between(endfwd, 10.0..30.0) === 1:20
            @test between(endrev, 10.0..30.0) === 1:20

            @test between(endfwd, 10.0..15.0) === 1:5
            @test between(endfwd, 10.1..14.9) === 2:4
            @test between(endrev, 10.0..15.0) === 16:20
            @test between(endrev, 10.1..14.9) === 17:19
            @test between(endfwd, Interval{:open,:open}( 9.9..15.1)) === 1:5
            @test between(endfwd, Interval{:open,:open}(10.0..15.0)) === 2:4
            @test between(endrev, Interval{:open,:open}( 9.9..15.1)) === 16:20
            @test between(endrev, Interval{:open,:open}(10.0..15.0)) === 17:19
            @test between(endfwd, Interval{:open,:closed}( 9.9..15.0)) === 1:5
            @test between(endfwd, Interval{:open,:closed}(10.0..14.9)) === 2:4
            @test between(endrev, Interval{:open,:closed}( 9.9..15.0)) === 16:20
            @test between(endrev, Interval{:open,:closed}(10.0..14.9)) === 17:19
            @test between(endfwd, Interval{:closed,:open}(10.0..15.1)) === 1:5
            @test between(endfwd, Interval{:closed,:open}(10.1..15.0)) === 2:4
            @test between(endrev, Interval{:closed,:open}(10.0..15.1)) === 16:20
            @test between(endrev, Interval{:closed,:open}(10.1..15.0)) === 17:19
        end

        @testset "Start touches" begin
            @test touches(startfwd, Touches(0, 10.9)) === 1:0
            @test touches(startfwd, Touches(0, 11)) === 1:1
            @test touches(startfwd, Touches(31, 50)) === 20:20
            @test touches(startfwd, Touches(31.1, 50)) === 21:20
            @test touches(startrev, Touches(0, 10.9)) === 21:20
            @test touches(startrev, Touches(0, 11)) === 20:20
            @test touches(startrev, Touches(31, 50)) === 1:1
            @test touches(startrev, Touches(31.1, 50)) === 1:0
            @test touches(startfwd, Touches(0, 40)) === 1:20
            @test touches(startrev, Touches(0, 40)) === 1:20
            # Bounds
            @test touches(startfwd, Touches(11.0, 31.0)) === 1:20
            @test touches(startrev, Touches(11.0, 31.0)) === 1:20

            @test touches(startfwd, Touches(12.1, 12.9)) === 2:2
            @test touches(startfwd, Touches(12.0, 13.0)) === 1:3
            @test touches(startrev, Touches(12.1, 12.9)) === 19:19
            @test touches(startrev, Touches(12.0, 13.0)) === 18:20
        end

        @testset "Center touches" begin
            @test touches(centerfwd, Touches(0, 10.4)) === 1:0
            @test touches(centerfwd, Touches(0, 10.5)) === 1:1
            @test touches(centerfwd, Touches(30.5, 50.0)) === 20:20
            @test touches(centerfwd, Touches(30.6, 50.0)) === 21:20
            @test touches(centerrev, Touches(0, 10.4)) === 21:20
            @test touches(centerrev, Touches(0, 10.5)) === 20:20
            @test touches(centerrev, Touches(30.5, 50.0)) === 1:1
            @test touches(centerrev, Touches(30.6, 50.0)) === 1:0
            @test touches(centerfwd, Touches(0, 40)) === 1:20
            @test touches(centerrev, Touches(0, 40)) === 1:20
            # Bounds
            @test touches(centerrev, Touches(11.5, 29.5)) === 1:20
            @test touches(centerrev, Touches(11.5, 29.5)) === 1:20

            @test touches(centerfwd, Touches(11.5, 13.5)) === 1:4
            @test touches(centerfwd, Touches(11.6, 13.4)) === 2:3
            @test touches(centerrev, Touches(11.5, 13.5)) === 17:20
            @test touches(centerrev, Touches(11.6, 13.4)) === 18:19
        end

        @testset "End touches" begin
            @test touches(endfwd, Touches(0.0, 9.9)) === 1:0
            @test touches(endfwd, Touches(0, 10)) === 1:1
            @test touches(endfwd, Touches(30.0, 30.0)) === 20:20
            @test touches(endfwd, Touches(30.1, 50.0)) === 21:20
            @test touches(endrev, Touches(0.0, 9.9)) === 21:20
            @test touches(endrev, Touches(0.0, 10.0)) === 20:20
            @test touches(endrev, Touches(30.0, 50.0)) === 1:1
            @test touches(endrev, Touches(30.1, 50.0)) === 1:0
            @test touches(endfwd, Touches(0, 40)) === 1:20
            @test touches(endrev, Touches(0, 40)) === 1:20
            # Bounds
            @test touches(endfwd, Touches(11.0, 29.0)) === 1:20
            @test touches(endrev, Touches(11.0, 29.0)) === 1:20

            @test touches(endfwd, Touches(11.0, 14.0)) === 1:5
            @test touches(endfwd, Touches(11.1, 13.9)) === 2:4
            @test touches(endrev, Touches(11.0, 14.0)) === 16:20
            @test touches(endrev, Touches(11.1, 13.9)) === 17:19
        end

        @testset "Start contains" begin
            @test_throws SelectorError contains(startfwd, Contains(10.9))
            @test_throws SelectorError contains(startrev, Contains(31))
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

        @testset "Center contains" begin
            @test_throws SelectorError contains(centerfwd, Contains(10.4))
            @test_throws SelectorError contains(centerfwd, Contains(30.5))
            @test_throws SelectorError contains(centerrev, Contains(10.4))
            @test_throws SelectorError contains(centerrev, Contains(30.5))
            @test contains(centerfwd, Contains(10.5)) == 1
            @test contains(centerfwd, Contains(30.4)) == 20
            @test contains(centerfwd, Contains(29.5)) == 20
            @test contains(centerfwd, Contains(29.4)) == 19
            @test contains(centerrev, Contains(10.5)) == 20
            @test contains(centerrev, Contains(30.4)) == 1
            @test contains(centerrev, Contains(29.5)) == 1
            @test contains(centerrev, Contains(29.4)) == 2
        end

        @testset "End contains" begin
            @test_throws SelectorError contains(endfwd, Contains(10))
            @test_throws SelectorError contains(endfwd, Contains(30.1))
            @test_throws SelectorError contains(endrev, Contains(10))
            @test_throws SelectorError contains(endrev, Contains(30.1))
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
        @test_throws SelectorError contains(startfwd, Contains(0.9))
        @test contains(startfwd, Contains(1.0)) == 1
        @test contains(startfwd, Contains(1.9)) == 1
        @test_throws ArgumentError contains(startfwd, Contains(2))
        @test_throws ArgumentError contains(startfwd, Contains(2.9))
        @test contains(startfwd, Contains(3)) == 2
        @test contains(startfwd, Contains(5.9)) == 4
        @test_throws SelectorError contains(startfwd, Contains(6))
        @test_throws SelectorError contains(startrev, Contains(0.9))
        @test contains(startrev, Contains(1.0)) == 4
        @test contains(startrev, Contains(1.9)) == 4
        @test_throws ArgumentError contains(startrev, Contains(2))
        @test_throws ArgumentError contains(startrev, Contains(2.9))
        @test contains(startrev, Contains(3)) == 3
        @test contains(startrev, Contains(5.9)) == 1
        @test_throws SelectorError contains(startrev, Contains(6))
    end

    @testset "Irregular Intervals with array" begin
        # Order: index, array, relation (array order is irrelevent here, it's just for plotting)
        # Varnames: locusindexorderrelation
        args = Irregular(1.0, 121.0), Intervals(Start()), NoMetadata()
        startfwd = Sampled((1.0:10.0).^2,    ForwardOrdered(), args...)
        startrev = Sampled((10.0:-1.0:1.0).^2, ReverseOrdered(), args...)

        args = Irregular(0.5, 111.5), Intervals(Center()), NoMetadata()
        centerfwd = Sampled((1.0:10.0).^2,      ForwardOrdered(), args...)
        centerrev = Sampled((10.0:-1.0:1.0).^2, ReverseOrdered(), args...)

        args = Irregular(0.0, 100.0), Intervals(End()), NoMetadata()
        endfwd = Sampled((1.0:10.0).^2,      ForwardOrdered(), args...)
        endrev = Sampled((10.0:-1.0:1.0).^2, ReverseOrdered(), args...)

        @testset "Any at" begin
            @test at(startfwd, At(25)) == 5
            @test at(startrev, At(25)) == 6
            @test at(startfwd, At(100)) == 10
            @test at(startrev, At(100)) == 1
        end

        @testset "Start between" begin
            # Handle searchorted overflow
            @test between(startfwd, 0..0) === 1:0
            @test between(startfwd, 130..130) === 11:10
            @test between(startrev, 0..0) === 11:10
            @test between(startrev, 130..130) === 1:0
            @test between(startfwd, -100..9) === 1:2
            @test between(startfwd, 80..150) === 9:10
            @test between(startrev, -100..9) === 9:10
            @test between(startrev, 80..150) === 1:2
            @test between(startfwd, -200..200) === 1:10
            @test between(startrev, -200..200) === 1:10
            # Bounds
            @test between(startfwd, 1.0..121.0) === 1:10
            @test between(startrev, 1.0..121.0) === 1:10
            @test between(startfwd, Interval{:open,:open}(1.0..121.0)) === 2:9
            @test between(startrev, Interval{:open,:open}(1.0..121.0)) === 2:9

            @test between(startfwd, 9..36) === 3:5
            @test between(startfwd, 9.1..35.0) === 4:4
            @test between(startrev, 9..36) === 6:8
            @test between(startrev, 9.1..35.9) === 7:7
            @test between(startfwd, Interval{:open,:open}(8.9..36.1)) === 3:5
            @test between(startfwd, Interval{:open,:open}(9.0..36.0)) === 4:4
            @test between(startrev, Interval{:open,:open}(8.9..36.1)) === 6:8
            @test between(startrev, Interval{:open,:open}(9..36)) === 7:7
            @test between(startfwd, Interval{:open,:closed}(8.9..36)) === 3:5
            @test between(startfwd, Interval{:open,:closed}(9.0..35.9)) === 4:4
            @test between(startrev, Interval{:open,:closed}(8.9..36)) === 6:8
            @test between(startrev, Interval{:open,:closed}(9.0..35.9)) === 7:7
            @test between(startfwd, Interval{:closed,:open}(9.0..36.1)) === 3:5
            @test between(startfwd, Interval{:closed,:open}(9.1..36.0)) === 4:4
            @test between(startrev, Interval{:closed,:open}(9.0..36.1)) === 6:8
            @test between(startrev, Interval{:closed,:open}(9.1..36.0)) === 7:7

        end


        @testset "Center between" begin
            # Handle searchorted overflow
            @test between(centerfwd, 0..0) === 1:0
            @test between(centerfwd, 0..0) === 1:0
            @test between(centerfwd, -100..9) === 1:2
            @test between(centerfwd, 70..150) === 9:10
            @test between(centerfwd, 130..130) === 11:10
            @test between(centerrev, 0..0) === 11:10
            @test between(centerrev, -100..9) === 9:10
            @test between(centerrev, 70..150) === 1:2
            @test between(centerrev, 130..130) === 1:0
            @test between(centerfwd, -200..200) === 1:10
            @test between(centerrev, -200..200) === 1:10
            # Bounds
            @test between(centerfwd, 0.5..111.5) === 1:10
            @test between(centerrev, 0.5..111.5) === 1:10
            @test between(centerfwd, Interval{:open,:open}(0.5..111.5)) === 2:9
            @test between(centerrev, Interval{:open,:open}(0.5..111.5)) === 2:9
    

            @test between(centerfwd, 6.5..30.5) === 3:5
            @test between(centerfwd, 6.6..30.4) === 4:4
            @test between(centerrev, 6.5..30.5) === 6:8
            @test between(centerrev, 6.6..30.4) === 7:7
            @test between(centerfwd, Interval{:open,:open}(6.4..30.6)) === 3:5
            @test between(centerfwd, Interval{:open,:open}(6.5..30.5)) === 4:4
            @test between(centerrev, Interval{:open,:open}(6.4..30.6)) === 6:8
            @test between(centerrev, Interval{:open,:open}(6.5..30.5)) === 7:7
            @test between(centerfwd, Interval{:open,:closed}(6.4..30.5)) === 3:5
            @test between(centerfwd, Interval{:open,:closed}(6.5..30.4)) === 4:4
            @test between(centerrev, Interval{:open,:closed}(6.4..30.5)) === 6:8
            @test between(centerrev, Interval{:open,:closed}(6.5..30.4)) === 7:7
            @test between(centerfwd, Interval{:closed,:open}(6.5..30.6)) === 3:5
            @test between(centerfwd, Interval{:closed,:open}(6.6..30.5)) === 4:4
            @test between(centerrev, Interval{:closed,:open}(6.5..30.6)) === 6:8
            @test between(centerrev, Interval{:closed,:open}(6.6..30.5)) === 7:7

        end

        @testset "End between" begin
            # Handle searchorted overflow
            @test between(endfwd, -1 .. -1) === 1:0
            @test between(endfwd, 130..130) === 11:10
            @test between(endrev, -1 .. -1) === 11:10
            @test between(endrev, 130..130) === 1:0
            @test between(endfwd, -100..4) === 1:2
            @test between(endfwd, 64..150) === 9:10
            @test between(endrev, -100..4) === 9:10
            @test between(endrev, 64..150) === 1:2
            @test between(endfwd, -200..200) === 1:10
            @test between(endrev, -200..200) === 1:10
            # Bounds
            @test between(endfwd, 0.0..100.0) === 1:10
            @test between(endrev, 0.0..100.0) === 1:10
            @test between(endfwd, Interval{:open,:open}(0.0..100.0)) === 2:9
            @test between(endrev, Interval{:open,:open}(0.0..100.0)) === 2:9

            @test between(endfwd, 4.0..25.0) === 3:5
            @test between(endrev, 4.0..25.0) === 6:8
            @test between(endfwd, 4.1..24.9) === 4:4
            @test between(endrev, 4.1..24.9) === 7:7
            @test between(endfwd, Interval{:open,:open}(3.9..25.1)) === 3:5
            @test between(endrev, Interval{:open,:open}(3.9..25.1)) === 6:8
            @test between(endfwd, Interval{:open,:open}(4.0..25.0)) === 4:4
            @test between(endrev, Interval{:open,:open}(4.0..25.0)) === 7:7
            @test between(endfwd, Interval{:open,:closed}(3.9..25.0)) === 3:5
            @test between(endrev, Interval{:open,:closed}(3.9..25.0)) === 6:8
            @test between(endfwd, Interval{:open,:closed}(4.0..24.9)) === 4:4
            @test between(endrev, Interval{:open,:closed}(4.0..24.9)) === 7:7
            @test between(endfwd, Interval{:closed,:open}(4.0..25.1)) === 3:5
            @test between(endrev, Interval{:closed,:open}(4.0..25.1)) === 6:8
            @test between(endfwd, Interval{:closed,:open}(4.1..25.0)) === 4:4
            @test between(endrev, Interval{:closed,:open}(4.1..25.0)) === 7:7
        end

        @testset "Start touches" begin
            # Handle searchorted overflow
            @test touches(startfwd, Touches(0, 0)) === 1:0
            @test touches(startfwd, Touches(130, 130)) === 11:10
            @test touches(startrev, Touches(0, 0)) === 11:10
            @test touches(startrev, Touches(130, 130)) === 1:0
            @test touches(startfwd, Touches(-100, 4)) === 1:2
            @test touches(startfwd, Touches(99, 150)) === 9:10
            @test touches(startrev, Touches(-100, 4)) === 9:10
            @test touches(startrev, Touches(99, 150)) === 1:2
            @test touches(startfwd, Touches(-200, 200)) === 1:10
            @test touches(startrev, Touches(-200, 200)) === 1:10
            # Bounds
            @test touches(startfwd, Touches(4.0, 100.0)) === 1:10
            @test touches(startrev, Touches(4.0, 100.0)) === 1:10

            @test touches(startfwd, Touches(16, 25)) === 3:5
            @test touches(startfwd, Touches(16.1, 24.9)) === 4:4
            @test touches(startrev, Touches(16, 25)) === 6:8
            @test touches(startrev, Touches(16.1, 24.9)) === 7:7
        end


        @testset "Center touches" begin
            # Handle searchorted overflow
            @test touches(centerfwd, Touches(0, 0)) === 1:0
            @test touches(centerfwd, Touches(0, 0)) === 1:0
            @test touches(centerfwd, Touches(-100, 3)) === 1:2
            @test touches(centerfwd, Touches(72.6, 150)) === 9:10 # 72.5 ?
            @test touches(centerfwd, Touches(130, 130)) === 11:10
            @test touches(centerrev, Touches(0, 0)) === 11:10
            @test touches(centerrev, Touches(-100, 4)) === 9:10
            @test touches(centerrev, Touches(72.6, 150)) === 1:2
            @test touches(centerrev, Touches(130, 130)) === 1:0
            @test touches(centerfwd, Touches(-200, 200)) === 1:10
            @test touches(centerrev, Touches(-200, 200)) === 1:10
            # Bounds
            @test touches(centerfwd, Touches(2.5, 90.5)) === 1:10
            @test touches(centerrev, Touches(2.5, 90.5)) === 1:10
            @test touches(centerfwd, Touches(2.6, 90.4)) === 2:9
            @test touches(centerrev, Touches(2.6, 90.4)) === 2:9
    
            @test touches(centerfwd, Touches(12.5, 20.5)) === 3:5
            @test touches(centerfwd, Touches(12.6, 20.4)) === 4:4
            @test touches(centerrev, Touches(12.5, 20.5)) === 6:8
            @test touches(centerrev, Touches(12.6, 20.4)) === 7:7
        end

        @testset "End touches" begin
            # Handle searchorted overflow
            @test touches(endfwd, Touches(-1 ,  -1)) === 1:0
            @test touches(endfwd, Touches(130, 130)) === 11:10
            @test touches(endrev, Touches(-1 ,  -1)) === 11:10
            @test touches(endrev, Touches(130, 130)) === 1:0
            @test touches(endfwd, Touches(-100, 1)) === 1:2
            @test touches(endfwd, Touches(81, 150)) === 9:10
            @test touches(endrev, Touches(-100, 1)) === 9:10
            @test touches(endrev, Touches(81, 150)) === 1:2
            @test touches(endfwd, Touches(-200, 200)) === 1:10
            @test touches(endrev, Touches(-200, 200)) === 1:10
            # Bounds
            @test touches(endfwd, Touches(1.0, 81.0)) === 1:10
            @test touches(endrev, Touches(1.0, 81.0)) === 1:10

            @test touches(endfwd, Touches(9.0, 16.0)) === 3:5
            @test touches(endrev, Touches(9.0, 16.0)) === 6:8
            @test touches(endfwd, Touches(9.1, 15.9)) === 4:4
            @test touches(endrev, Touches(9.1, 15.9)) === 7:7
        end

        @testset "Start contains" begin
            @test_throws SelectorError contains(startfwd, Contains(0.9))
            @test_throws SelectorError contains(startfwd, Contains(121.1))
            @test contains(startfwd, Contains(1)) == 1
            @test contains(startfwd, Contains(3.9)) == 1
            @test contains(startfwd, Contains(4.0)) == 2
            @test contains(startfwd, Contains(100.0)) == 10
            @test contains(startfwd, Contains(99.9)) == 9
            @test_throws SelectorError contains(startrev, Contains(0.9))
            @test_throws SelectorError contains(startrev, Contains(121.1))
            @test contains(startrev, Contains(3.9)) == 10
            @test contains(startrev, Contains(4.0)) == 9
            @test contains(startrev, Contains(120.9)) == 1
            @test contains(startrev, Contains(100.0)) == 1
            @test contains(startrev, Contains(99.0)) == 2
        end

        @testset "Center contains" begin
            @test_throws SelectorError contains(centerfwd, Contains(0.4))
            @test_throws SelectorError contains(centerfwd, Contains(111.5))
            @test contains(centerfwd, Contains(0.5)) == 1
            @test contains(centerfwd, Contains(111.4)) == 10
            @test contains(centerfwd, Contains(90.5)) == 10
            @test contains(centerfwd, Contains(90.4)) == 9
            @test_throws SelectorError contains(centerrev, Contains(0.4))
            @test_throws SelectorError contains(centerrev, Contains(111.5))
            @test contains(centerrev, Contains(72.5)) == 2
            @test contains(centerrev, Contains(72.4)) == 3
            @test contains(centerrev, Contains(0.5)) == 10
            @test contains(centerrev, Contains(111.4)) == 1
            @test contains(centerrev, Contains(90.5)) == 1
            @test contains(centerrev, Contains(90.4)) == 2
        end

        @testset "End contains" begin
            @test_throws SelectorError contains(endfwd, Contains(-0.1))
            @test_throws SelectorError contains(endfwd, Contains(100.1))
            @test_throws SelectorError contains(endrev, Contains(-0.1))
            @test_throws SelectorError contains(endrev, Contains(100.1))
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
            @test between(fwd, 0..4.9) === 1:0
            @test between(fwd, 0..5) === 1:1
            @test between(fwd, 30..31) === 26:26
            @test between(fwd, 10..14.9) === 6:10
            @test between(fwd, 10..15) === 6:11
            @test between(rev, 10..14.9) === 17:21
            @test between(rev, 10..15) === 16:21
            @test between(rev, 0..4.9) === 27:26
            @test between(rev, 0..5) === 26:26
            @test between(rev, 30..31) === 1:1

            @test between(fwd, OpenInterval(0..5)) === 1:0
            @test between(fwd, OpenInterval(0..5.1)) === 1:1
            @test between(fwd, OpenInterval(30..31)) === 27:26
            @test between(fwd, OpenInterval(10..15)) === 7:10
            @test between(fwd, OpenInterval(10..15.1)) === 7:11
            @test between(rev, OpenInterval(10..15)) === 17:20
            @test between(rev, OpenInterval(10..15.1)) === 16:20
            @test between(rev, OpenInterval(0..5)) === 27:26
            @test between(rev, OpenInterval(0..5.1)) === 26:26
            @test between(rev, OpenInterval(30..31)) === 1:0

            @test between(fwd, Interval{:open,:closed}(0..4.9)) === 1:0
            @test between(fwd, Interval{:open,:closed}(0..5.0)) === 1:1
            @test between(fwd, Interval{:open,:closed}(30..31)) === 27:26
            @test between(fwd, Interval{:open,:closed}(10..14.9)) === 7:10
            @test between(fwd, Interval{:open,:closed}(10..15.0)) === 7:11
            @test between(rev, Interval{:open,:closed}(10..14.9)) === 17:20
            @test between(rev, Interval{:open,:closed}(10..15.0)) === 16:20
            @test between(rev, Interval{:open,:closed}(0..4.9)) === 27:26
            @test between(rev, Interval{:open,:closed}(0..5.0)) === 26:26
            @test between(rev, Interval{:open,:closed}(30..31)) === 1:0

            @test between(fwd, Interval{:closed,:open}(0..5.0)) === 1:0
            @test between(fwd, Interval{:closed,:open}(0..5.1)) === 1:1
            @test between(fwd, Interval{:closed,:open}(30..31)) === 26:26
            @test between(fwd, Interval{:closed,:open}(10..15)) === 6:10
            @test between(fwd, Interval{:closed,:open}(10..15.1)) === 6:11
            @test between(rev, Interval{:closed,:open}(10..15)) === 17:21
            @test between(rev, Interval{:closed,:open}(10..15.1)) === 16:21
            @test between(rev, Interval{:closed,:open}(0..5.0)) === 27:26
            @test between(rev, Interval{:closed,:open}(0..5.1)) === 26:26
            @test between(rev, Interval{:closed,:open}(30..31)) === 1:1
            
            fwd1 = Sampled(5.0:5.0; order=ForwardOrdered(), sampling=Points())
            rev1 = Sampled(5.0:-1.0:5.0; order=ReverseOrdered(), sampling=Points())
            @test between(fwd1, 5..5) === 1:1
            @test between(rev1, 5..5) === 1:1
            @test between(fwd1, OpenInterval(5..5)) === 1:0
            @test between(rev1, OpenInterval(5..5)) === 1:0
        end

        @testset "at" begin
            @test at(fwd, At(30)) == 26
            @test at(rev, At(30)) == 1
        end

        @testset "contains" begin
            @test contains(fwd, Contains(30)) == 26
            @test contains(rev, Contains(30)) == 1
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

    end

end

@testset "Selectors on Sampled Points" begin
    da = DimArray(a, (Y(Sampled(10:10:30)), Ti(Sampled((1:4)u"s"))))

    @test At(10.0) == At(10.0, nothing, nothing)
    @test At(10.0; atol=0.0) ==
          At(10.0, 0.0)
    Near([10, 20])

    @test Between(10, 20) == Between((10, 20))

    @testset "selectors with dim wrappers" begin
        @test @inferred da[Y(At([10, 30])), Ti(At([1u"s", 4u"s"]))] == [1 4; 9 12]
        @test_throws SelectorError da[Y(At([9, 30])), Ti(At([1u"s", 4u"s"]))]
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
        locuss =  [
            (1:3, [3, 4]),
            (2, [3, 4]),
            (2, [2, 3]),
            (1, [1, 3]),
            ([1], [1, 3]),
            (2:2, [2, 3])
        ]
        for (selector, pos) in zip(selectors, locuss)
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
            @test from1d isa DimArray
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

    @testset "All" begin
        dimz = X(10.0:20:200.0), Ti(1u"s":5u"s":100u"s")
        A = DimArray((1:10) * (1:20)', dimz)
        aA = A[X=All(At(10.0), At(50.0)), Ti=All(1u"s"..10u"s", 90u"s"..100u"s")]
        @test parent(aA) == 
            [1  2  19  20
             3  6  57  60]
    end

    @testset "Not " begin
        dimz = X(1.0:2:10.0), Ti(1u"s":5u"s":11u"s")
        A = DimArray((1:5) * (1:3)', dimz)
        A1 = A[X=Not(Near(5.1)), Ti=Not(1u"s" .. 10u"s")]
        A2 = A[Ti=Not(At(1u"s"))]
        A3 = A[X=Not(At([1.0,3.0]))]
        @test lookup(A2, :Ti) == [6u"s", 11u"s"]
        @test lookup(A3, :X) == [5.0,7.0,9.0]
        @test A1 == permutedims([3 6 12 15]) 
        @test lookup(A1, Ti) == [11u"s"]
        @test lookup(A1, X) == [1.0, 3.0, 7.0, 9.0]
    end

end

@testset "Selectors on Sampled Intervals" begin
    da = DimArray(a, (Y(Sampled(10:10:30; sampling=Intervals())),
                      Ti(Sampled((1:4)u"s"; sampling=Intervals()))))

    @testset "Extent indexing" begin
        # These should be the same because da is the maximum size
        # we can index with `Touches`
        @test da[Near(Extents.extent(da))] == da[Touches(Extents.extent(da))] == da[Extents.extent(da)] == da
        rda = reverse(da; dims=Y)
        @test rda[Near(Extents.extent(rda))] == rda[Touches(Extents.extent(rda))] == rda[Extents.extent(rda)] == rda
    end

    @testset "with dim wrappers" begin
        @test @inferred da[Y(At([10, 30])), Ti(At([1u"s", 4u"s"]))] == [1 4; 9 12]
        @test_throws SelectorError da[Y(At([9, 30])), Ti(At([1u"s", 4u"s"]))]
        @test @inferred view(da, Y(At(20)), Ti(At((3:4)u"s"))) == [7, 8]
        @test @inferred view(da, Y(Contains(17)), Ti(Contains([1.9u"s", 3.1u"s"]))) == [5, 7]
        @test @inferred view(da, Y(Between(4, 26)), Ti(At((3:4)u"s"))) == [3 4; 7 8]
        @test @inferred view(da, Y(Touches(4, 26)), Ti(At((3:4)u"s"))) == [3 4; 7 8; 11 12]
    end

    @testset "without dim wrappers" begin
        @test @inferred da[At(20:10:30), At(1u"s")] == [5, 9]
        @test @inferred view(da, Between(4, 36), Near((3:4)u"s")) == [3 4; 7 8; 11 12]
        @test @inferred view(da, Near(22), At([3.0u"s", 4.0u"s"])) == [7, 8]
        @test @inferred view(da, At(20), At((2:3)u"s")) == [6, 7]
        @test @inferred view(da, Near(13), Near([1.3u"s", 3.3u"s"])) == [1, 3]
        @test @inferred view(da, Near([13]), Near([1.3u"s", 3.3u"s"])) == [1 3]
        @test @inferred view(da, Between(11, 26), At((2:3)u"s")) == [6 7]
        @test @inferred view(da, Touches(11, 26), At((2:3)u"s")) == [2 3; 6 7; 10 11]
        # Between also accepts a tuple input
        @test @inferred view(da, Between((11, 26)), Between((2u"s", 4u"s"))) == [6 7]
    end

    @testset "out of bounds" begin
        @test size(view(da, Between(0, 4), At((2:3)u"s"))) == (0, 2)
        @test view(da, Between(0, 4), At((2:3)u"s")) isa DimArray{Int64,2}
        @test size(view(da, Between(40, 45), At((2:3)u"s"))) == (0, 2)
        @test view(da, Between(40, 45), At((2:3)u"s")) isa DimArray{Int64,2}
    end

    @testset "with DateTime lookup" begin
        @testset "Start locus" begin
            timedim = Ti(Sampled(DateTime(2001):Month(1):DateTime(2001, 12); 
                span=Regular(Month(1)), sampling=Intervals(Start())
            ))
            da = DimArray(1:12, timedim)
            @test @inferred da[Ti(At(DateTime(2001, 3)))] == 3
            @test @inferred da[Ti(At(Date(2001, 3)))] == 3
            @test @inferred da[Near(DateTime(2001, 4, 7))] == 4
            @test @inferred da[Near(Date(2001, 4, 7))] == 4
            @test @inferred da[DateTime(2001, 4, 7) .. DateTime(2001, 8, 30)] == [5, 6, 7]
            @test @inferred da[Date(2001, 4, 7) .. Date(2001, 8, 30)] == [5, 6, 7]

            @test_throws SelectorError da[Ti(At(Date(2001, 3, 4); atol=Day(2)))]
            @test @inferred da[Ti(At(Date(2001, 3, 4); atol=Day(3)))] == 3
            @test @inferred da[Ti(At(DateTime(2001, 3, 4); atol=Day(3)))] == 3
        end
        @testset "End locus" begin
            timedim = Ti(Sampled(DateTime(2001):Month(1):DateTime(2001, 12); 
                span=Regular(Month(1)), sampling=Intervals(End()))
            )
            da = DimArray(1:12, timedim)
            @test @inferred da[Ti(At(DateTime(2001, 3)))] == 3
            @test @inferred da[Ti(At(Date(2001, 3)))] == 3
            @test @inferred da[Near(DateTime(2001, 4, 7))] == 5
            @test @inferred da[Near(Date(2001, 4, 7))] == 5
            @test @inferred da[DateTime(2001, 4, 7) .. DateTime(2001, 8, 30)] == [6, 7, 8]
            @test @inferred da[Date(2001, 4, 7) .. Date(2001, 8, 30)] == [6, 7, 8]

            timedim = Ti(Sampled(Date(2001):Month(1):Date(2001, 12); 
                span=Regular(Month(1)), sampling=Intervals(End()))
            )
            da = DimArray(1:12, timedim)
            @test @inferred da[Ti(At(DateTime(2001, 3)))] == 3
            @test @inferred da[Ti(At(Date(2001, 3)))] == 3
            @test @inferred da[Near(DateTime(2001, 4, 7))] == 5
            @test @inferred da[Near(Date(2001, 4, 7))] == 5
            @test @inferred da[DateTime(2001, 4, 7) .. DateTime(2001, 8, 30)] == [6, 7, 8]
            @test @inferred da[Date(2001, 4, 7) .. Date(2001, 8, 30)] == [6, 7, 8]
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
        @test_throws SelectorError da[Y(At([9, 30])), Ti(At([1u"s", 4u"s"]))]
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
        @test @inferred view(da, Touches(11, 26), At((2:3)u"s")) == [2 3; 6 7; 10 11]
        # Between also accepts a tuple input
        @test @inferred view(da, Between((11, 26)), Between((1.4u"s", 4u"s"))) == [6 7]
    end

    @testset "with DateTime lookup" begin
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

@testset "Selectors on Tranformed lookup" begin
    using CoordinateTransformations

    m = LinearMap([0.5 0.0; 0.0 0.5])
    dimz = X(Transformed(m)), Y(Transformed(m)), Z()
    da = DimArray(reshape(a, 3, 4, 1), dimz)
    view(da, :, :, 1)

    @testset "AutoDim attachs the dimension to " begin
        Lookups.dim(lookup(da, X))
    end

    @testset "Indexing with array dims indexes the array as usual" begin
        da2 = da[1:3, 1:1, 1:1];
        @test @inferred da2[X(3), Y(1), Z(1)] == 9
    end

    @testset "Indexing with lookup dims uses the transformation" begin
        @test @inferred da[X(Near(6.1)), Y(Near(8.5)), Z(1)] == 12
        @test @inferred da[X(At(4.0)), Y(At(2.0)), Z(1)] == 5
        @test_throws ArgumentError da[X=At(4.0)]
        @test_throws InexactError da[X(At(6.1)), Y(At(8)), Z(1)]
        # Indexing directly with lookup dims also just works, but maybe shouldn't?
        @test @inferred da[X(2), Y(2), Z(1)] == 6
    end
end

@testset "Cyclic lookup" begin
    lookups = (
        day=Cyclic(DateTime(2001):Day(1):DateTime(2002, 12, 31); cycle=Year(1), order=ForwardOrdered(), span=Regular(Day(1)), sampling=Intervals(Start())),
        week=Cyclic(DateTime(2001):Week(1):DateTime(2002, 12, 31); cycle=Year(1), order=ForwardOrdered(), span=Regular(Week(1)), sampling=Intervals(Start())),
        month=Cyclic(DateTime(2001):Month(1):DateTime(2002, 12, 31); cycle=Year(1), order=ForwardOrdered(), span=Regular(Month(1)), sampling=Intervals(Start())),
        month_month=Cyclic(DateTime(2001):Month(1):DateTime(2002, 1, 31); cycle=Month(1), order=ForwardOrdered(), span=Regular(Month(1)), sampling=Intervals(Start())),
    )

    for l in lookups 
        # Test exact cycles
        @test at(l, At(DateTime(1))) == 1
        @test at(l, At(DateTime(1999))) == 1
        @test at(l, At(DateTime(2000))) == 1
        @test at(l, At(DateTime(2001))) == 1
        @test at(l, At(DateTime(4000))) == 1
        @test near(l, Near(DateTime(1))) == 1
        @test near(l, Near(DateTime(1999))) == 1
        @test near(l, Near(DateTime(2000))) == 1
        @test near(l, Near(DateTime(2001))) == 1
        @test near(l, Near(DateTime(4000))) == 1
        @test contains(l, Contains(DateTime(1))) == 1
        @test contains(l, Contains(DateTime(1999))) == 1
        @test contains(l, Contains(DateTime(2000))) == 1
        @test contains(l, Contains(DateTime(2001))) == 1
        @test contains(l, Contains(DateTime(4000))) == 1
    end

    l = lookups.month
    @test at(l, At(DateTime(1, 12))) == 12
    @test at(l, At(DateTime(1999, 12))) == 12
    @test at(l, At(DateTime(2000, 12))) == 12
    @test at(l, At(DateTime(2001, 12))) == 12
    @test at(l, At(DateTime(3000, 12))) == 12
    l = lookups.day
    @test at(l, At(DateTime(1, 12, 31))) == 365 
    @test at(l, At(DateTime(1999, 12, 31))) == 365
    # This is kinda wrong, as there are 366 days in 2000
    # But our l has 365. Leap years would be handled
    # properly with a four year cycle
    @test at(l, At(DateTime(2000, 12, 31))) == 365
    @test at(l, At(DateTime(2001, 12, 31))) == 365
    @test at(l, At(DateTime(3000, 12, 31))) == 365

    @testset "Leap years are correct with four year cycles" begin
        l = Cyclic(DateTime(2000):Day(1):DateTime(2003, 12, 31); cycle=Year(4), order=ForwardOrdered(), span=Regular(Day(1)), sampling=Intervals(Start()))
        @test at(l, At(DateTime(1, 12, 31))) == findfirst(==(DateTime(2001, 12, 31)), l)
        @test at(l, At(DateTime(1999, 12, 31))) == findfirst(==(DateTime(1999 + 4, 12, 31)), l)
        @test at(l, At(DateTime(2000, 12, 31))) == 366 == findfirst(==(DateTime(2000, 12, 31)), l)
        @test at(l, At(DateTime(2007, 12, 31))) == findfirst(==(DateTime(2007 - 4, 12, 31)), l)
        @test at(l, At(DateTime(3000, 12, 31))) == 366 == findfirst(==(DateTime(3000 - 250 * 4, 12, 31)), l)
    end

    @testset "Cycling works with floats too" begin
        l = Cyclic(-180.0:1:179.0; cycle=360.0, order=ForwardOrdered(), span=Regular(1.0), sampling=Intervals(Start()))
        @test contains(l, Contains(360)) == 181
        @test contains(l, Contains(-360)) == 181
        @test contains(l, Contains(180)) == 1
    end
end

@testset "NoLookup" begin
    l = NoLookup(1:100)
    @test_throws SelectorError selectindices(l, At(0))
    @test_throws SelectorError selectindices(l, At(200))
    @test selectindices(l, At(50)) == 50
    @test selectindices(l, At(50.1; atol=0.3)) == 50
    @test selectindices(l, Near(200.1)) == 100
    @test selectindices(l, Near(-200.1)) == 1
    @test selectindices(l, Contains(20)) == 20
    @test_throws SelectorError selectindices(l, Contains(20.1))
    @test selectindices(l, Contains(20.1); err=Lookups._False()) === nothing
    @test_throws SelectorError selectindices(l, Contains(0)) 
    @test_throws SelectorError selectindices(l, Contains(200)) 
    @test selectindices(l, 20.1..40) == 21:40
end

@testset "selectindices" begin
    @test selectindices(A[X(1)], Contains(7)) == (3,)
    @test selectindices(A, (At(10), Contains(7))) == (1, 3)
    @test selectindices(dims_, ()) == ()
    @test selectindices((), ()) == ()
    @test selectindices(A, (At(90), Contains(7)); err=Lookups._False()) == nothing
    @test selectindices(A[X(1)], Contains(10); err=Lookups._False()) == nothing
end

@testset "selectindices with Tuple" begin
    @test selectindices(lookup(A, Y), At(6, 7)) == 2:3
    @test_throws SelectorError selectindices(lookup(A, Y), At(5.3, 8))
    @test selectindices(lookup(A, Y), At(5.1, 7.1; atol=0.1)) == 1:3
    @test selectindices(lookup(A, Y), Near(5.3, 8)) == 1:3
    @test selectindices(lookup(A, Y), Contains(4.7, 6.1)) == 1:2
    @test_throws SelectorError selectindices(lookup(A, Y), Contains(5.3, 8)) == 1:3
end

@testset "hasselection" begin
    @test hasselection(A, X(At(20)))
    @test hasselection(dims(A, X), X(At(20)))
    @test hasselection(dims(A, X), At(19; atol=2))
    @test hasselection(A, (Y(At(7)),))
    @test hasselection(A, (X(At(10)), Y(At(7))))
    @test_throws ArgumentError hasselection(dims(A), At(20))
    
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

@testset "ArrayLookup selectors" begin
    # Generate a warped matrix
    y = -100:100
    x = -200:200
    xs = [x + 0.01y^3 for x in x, y in y]
    ys = [y + 10cos(x/40) for x in x, y in y]
    # Define x and y lookup dimensions
    using NearestNeighbors
    xdim = X(ArrayLookup(xs))
    ydim = Y(ArrayLookup(ys))
    A = rand(xdim, ydim)
    l = lookup(A, X)
    l.dims
    xval = xs[end-10]
    yval = ys[end-10]
    @test A[Y=At(yval; atol=0.001), X=At(xval; atol=0.001)] ==
        A[Y=Near(yval), X=Near(xval)] ==
        A[Y=At(yval; atol=0.001), X=Near(xval)] ==
        A[Y=Near(yval), X=At(xval; atol=0.001)] ==
        A[X=At(xval; atol=0.001), Y=Near(yval)] ==
        A[end-10]
    xval = xs[end-10] + 0.0005
    yval = ys[end-10] + 0.0005
    @test A[Y=At(yval; atol=0.001), X=At(xval; atol=0.001)] ==
        A[Y=Near(yval), X=Near(xval)] ==
        A[Y=At(yval; atol=0.001), X=Near(xval)] ==
        A[Y=Near(yval), X=At(xval; atol=0.001)] ==
        A[end-10]
end