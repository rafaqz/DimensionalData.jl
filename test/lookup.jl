using DimensionalData, Test, Unitful
using DimensionalData.LookupArrays, DimensionalData.Dimensions
using DimensionalData.LookupArrays: _slicespan, isrev, _bounds
using DimensionalData.Dimensions: _slicedims

@testset "locus" begin
    @test locus(NoSampling()) == Center()
    @test locus(NoLookup()) == Center()
    @test locus(Categorical()) == Center()
    @test locus(Sampled(; sampling=Points())) == Center()
    @test locus(Sampled(; sampling=Intervals(Center()))) == Center()
    @test locus(Sampled(; sampling=Intervals(Start()))) == Start()
    @test locus(Sampled(; sampling=Intervals(End()))) == End()
end

@testset "equality" begin
    ind = 10:14
    n = NoLookup(ind)
    c = Categorical(ind; order=ForwardOrdered())
    cr = Categorical(reverse(ind); order=ReverseOrdered())
    s = Sampled(ind; order=ForwardOrdered(), sampling=Points(), span=Regular(1))
    si = Sampled(ind; order=ForwardOrdered(), sampling=Intervals(), span=Regular(1))
    sir = Sampled(ind; order=ForwardOrdered(), sampling=Intervals(), span=Irregular())
    sr = Sampled(reverse(ind); order=ReverseOrdered(), sampling=Points(), span=Regular(1))
    @test n == n
    @test c == c
    @test s == s
    @test n != s
    @test n != c
    @test c != s
    @test sr != s
    @test si != s
    @test sir != s
    @test cr != c
end

@testset "isrev" begin
    @test isrev(ForwardOrdered()) == false
    @test isrev(ForwardOrdered()) == false
end

@testset "reverse" begin
    @test reverse(ForwardOrdered()) == ReverseOrdered()
    @test reverse(ReverseOrdered()) == ForwardOrdered()
    @test reverse(Unordered()) == Unordered()
    lu = Sampled(order=ForwardOrdered(), span=Regular(1))
    @test order(reverse(lu)) == ReverseOrdered()
    lu = Categorical(order=ReverseOrdered())
    @test order(reverse(lu)) == ForwardOrdered()
end

@testset "getindex" begin
    ind = [10.0, 20.0, 30.0, 40.0, 50.0]

    @testset "Irregular forwards" begin
        m = Sampled(ind, order=ForwardOrdered(), span=Irregular((10.0, 60.0)), sampling=Intervals(Start()))
        mr = Sampled(ind, order=ForwardOrdered(), span=Regular(10.0), sampling=Intervals(Start()))
        @test bounds(getindex(m, 3:3)) == (30.0, 40.0)
        @test bounds(getindex(m, 1:5)) == (10.0, 60.0)
        @test bounds(getindex(m, 2:3)) == (20.0, 40.0)
        m = Sampled(ind, ForwardOrdered(), Irregular((0.0, 50.0)), Intervals(End()), NoMetadata())
        mr = Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (20.0, 30.0)
        @test bounds(getindex(m, 1:5)) == (0.0, 50.0)
        @test bounds(getindex(m, 2:3)) == (10.0, 30.0)
        m = Sampled(ind, ForwardOrdered(), Irregular((5.0, 55.0)), Intervals(Center()), NoMetadata())
        mr = Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == bounds(getindex(mr, 3:3)) == (25.0, 35.0)
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (5.0, 55.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (15.0, 35.0)
    end

    @testset "Irregular reverse" begin
        revind = [50.0, 40.0, 30.0, 20.0, 10.0]
        m = Sampled(revind; order=ReverseOrdered(), span=Irregular(10.0, 60.0), sampling=Intervals(Start()))
        mr = Sampled(revind; order=ReverseOrdered(), span=Regular(-10.0), sampling=Intervals(Start()))
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (10.0, 60.0)
        @test bounds(getindex(m, 1:2)) == bounds(getindex(mr, 1:2)) == (40.0, 60.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (30.0, 50.0)
        m = Sampled(revind, ReverseOrdered(), Irregular(0.0, 50.0), Intervals(End()), NoMetadata())
        mr = Sampled(revind, ReverseOrdered(), Regular(-10.0), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (0.0, 50.0)
        @test bounds(getindex(m, 1:2)) == bounds(getindex(mr, 1:2)) == (30.0, 50.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (20.0, 40.0)
        m = Sampled(revind, ReverseOrdered(), Irregular(5.0, 55.0), Intervals(Center()), NoMetadata())
        mr = Sampled(revind, ReverseOrdered(), Regular(-10.0), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (5.0, 55.0)
        @test bounds(getindex(m, 1:2)) == bounds(getindex(mr, 1:2)) == (35.0, 55.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (25.0, 45.0)
    end

    @testset "Irregular with no bounds" begin
        m = Sampled(ind, ForwardOrdered(), Irregular(nothing, nothing), Intervals(Start()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (30.0, 40.0)
        @test bounds(getindex(m, 2:4)) == (20.0, 50.0)
        # TODO should this be built into `identify` to at least get one bound?
        @test bounds(getindex(m, 1:5)) == (10.0, nothing)
        m = Sampled(ind, ForwardOrdered(), Irregular(nothing, nothing), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (20.0, 30.0)
        @test bounds(getindex(m, 2:4)) == (10.0, 40.0)
        @test bounds(getindex(m, 1:5)) == (nothing, 50.0)
        m = Sampled(ind, ForwardOrdered(), Irregular(nothing, nothing), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (25.0, 35.0)
        @test bounds(getindex(m, 2:4)) == (15.0, 45.0)
        @test bounds(getindex(m, 1:5)) == (nothing, nothing)
    end

end

@testset "bounds and intervalbounds" begin
    @testset "Intervals" begin
        @testset "Regular bounds are calculated from interval type and span value" begin
            @testset "forward ind" begin
                ind = 10.0:10.0:50.0
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(Start()), span=Regular(10.0)))
                @test bounds(dim) == (10.0, 60.0)
                @test intervalbounds(dim, 2) == (20.0, 30.0)
                @test intervalbounds(dim) == [
                    (10.0, 20.0)
                    (20.0, 30.0)
                    (30.0, 40.0)
                    (40.0, 50.0)
                    (50.0, 60.0)
                ]
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(End()), span=Regular(10.0)))
                @test bounds(dim) == (0.0, 50.0)
                @test intervalbounds(dim, 2) == (10.0, 20.0)
                @test intervalbounds(dim) == [
                    (0.0, 10.0)
                    (10.0, 20.0)
                    (20.0, 30.0)
                    (30.0, 40.0)
                    (40.0, 50.0)
                ]
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(Center()), span=Regular(10.0)))
                @test bounds(dim) == (5.0, 55.0)
                @test intervalbounds(dim, 2) == (15.0, 25.0)
                @test intervalbounds(dim) == [
                    (5.0, 15.0)
                    (15.0, 25.0)
                    (25.0, 35.0)
                    (35.0, 45.0)
                    (45.0, 55.0)
                ]
                # Test non keyword constructors too
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Start()), NoMetadata()))
                @test bounds(dim) == (10.0, 60.0)                                        
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(End()), NoMetadata()))
                @test bounds(dim) == (0.0, 50.0)                                         
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Center()), NoMetadata()))
                @test bounds(dim) == (5.0, 55.0)
            end
            @testset "reverse ind" begin
                revind = [10.0, 9.0, 8.0, 7.0, 6.0]
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(Start()), NoMetadata()))
                @test bounds(dim) == (6.0, 11.0)
                @test intervalbounds(dim, 2) == (9.0, 10.0)
                @test intervalbounds(dim) == [
                    (10.0, 11.0)
                    (9.0, 10.0)
                    (8.0, 9.0)
                    (7.0, 8.0)
                    (6.0, 7.0)
                ]
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(End()), NoMetadata()))
                @test bounds(dim) == (5.0, 10.0)
                @test intervalbounds(dim, 2) == (8.0, 9.0)
                @test intervalbounds(dim) == [
                    (9.0, 10.0)
                    (8.0, 9.0)
                    (7.0, 8.0)
                    (6.0, 7.0)
                    (5.0, 6.0)
                ]
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(Center()), NoMetadata()))
                @test bounds(dim) == (5.5, 10.5)
                @test intervalbounds(dim, 2) == (8.5, 9.5)
                @test intervalbounds(dim) == [
                    (9.5, 10.5)
                    (8.5, 9.5)
                    (7.5, 8.5)
                    (6.5, 7.5)
                    (5.5, 6.5)
                ]
            end
        end
        @testset "Irregular bounds are whatever is stored in span" begin
            ind = 10.0:10.0:50.0
            dim = X(Sampled(ind, ForwardOrdered(), Irregular(10.0, 50000.0), Intervals(Start()), NoMetadata()))
            @test bounds(dim) == (10.0, 50000.0)
            @test bounds(getindex(dim, 2:3)) == (20.0, 40.0)
            @test intervalbounds(dim) == [
                (10.0, 20.0)
                (20.0, 30.0)
                (30.0, 40.0)
                (40.0, 50.0)
                (50.0, 50000.0)
            ]
        end
        @testset "Explicit bounds are is stored in span matrix" begin
            ind = 10.0:10.0:50.0
            bnds = vcat(ind', (20.0:10.0:60.0)')
            dim = X(Sampled(ind, ForwardOrdered(), Explicit(bnds), Intervals(Start()), NoMetadata()))
            @test bounds(dim) == (10.0, 60.0)
            @test bounds(_slicedims(getindex, dim, 2:3)[1][1]) == (20.0, 40.0)
            @test intervalbounds(dim) == [
                (10.0, 20.0)
                (20.0, 30.0)
                (30.0, 40.0)
                (40.0, 50.0)
                (50.0, 60.0)
            ]
        end
    end

    @testset "Points" begin
        ind = 10:15
        dim = X(Sampled(ind; order=ForwardOrdered(), sampling=Points()))
        @test bounds(dim) == (10, 15)
        ind = 15:-1:10
        dim = X(Sampled(ind; order=ReverseOrdered(), sampling=Points()))
        last(dim), first(dim)
        @test bounds(dim) == (10, 15)
        dim = X(Sampled(ind; order=Unordered(), sampling=Points()))
        @test bounds(dim) == (nothing, nothing)
        @test_throws ErrorException intervalbounds(dim)
    end

    @testset "Categorical" begin
        ind = [:a, :b, :c, :d]
        dim = X(Categorical(ind; order=ForwardOrdered()))
        @test order(dim) == ForwardOrdered()
        @test_throws ErrorException step(dim)
        @test span(dim) == NoSpan()
        @test sampling(dim) == NoSampling()
        @test dims(lookup(dim)) === nothing
        @test locus(dim) == Center()
        @test bounds(dim) == (:a, :d)
        dim = X(Categorical(ind; order=ReverseOrdered()))
        @test bounds(dim) == (:d, :a)
        @test order(dim) == ReverseOrdered()
        dim = X(Categorical(ind; order=Unordered()))
        @test bounds(dim) == (nothing, nothing)
        @test order(dim) == Unordered()
        @test_throws ErrorException intervalbounds(dim)
    end

    @testset "Cyclic" begin
        ind = -180.0:1:179.0
        l = Cyclic(index; cycle=360.0, order=ForwardOrdered(), span=Regular(1.0), sampling=Intervals(Start()))
        dim = X(l)
        @test order(dim) == ForwardOrdered()
        @test step(dim) == 1.0
        @test span(dim) == Regular(1.0)
        @test sampling(dim) == Intervals(Start())
        @test locus(dim) == Start()
        @test bounds(dim) == (-Inf, Inf)
        # Indexing with AbstractArray returns Sampled
        for f in (getindex, view, Base.dotview)
            @test f(l, 1:10) isa Sampled
        end
        # TODO clarify intervalbounds - we cant return the whole set to typemax, so we return onecycle?
        # @test intervalbounds(dim) 
        dim = X(Cyclic(index; cycle=360.0, order=ReverseOrdered(), span=Regular(1.0), sampling=Intervals(Start())))
        @test bounds(dim) == (typemin(Float64), typemax(Float64))
        @test order(dim) == ReverseOrdered()
        @test bounds(dim) == (-Inf, Inf)
        @test_throws ArgumentError Cyclic(ind; cycle=360, order=Unordered())
    end

end

@testset "dims2indices with Transformed" begin
    tdimz = Dim{:trans1}(Transformed(identity, X())), 
            Dim{:trans2}(Transformed(identity, Y())), 
            Z(NoLookup(1:1))
    @test dims2indices(tdimz, (X(1), Y(2), Z())) == (1, 2, Colon())
    @test dims2indices(tdimz, (Dim{:trans1}(1), Dim{:trans2}(2), Z())) == (1, 2, Colon())
end
