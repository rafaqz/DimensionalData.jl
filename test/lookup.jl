using DimensionalData, Test, Unitful
using DimensionalData: _slicespan, isrev, _bounds,
    ForwardOrdered, ReverseOrdered, Unordered,
    Regular, Irregular, Explicit, Transformed, dims2indices

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
        @test bounds(getindex(m, 3:3)) == (30.0, 40.0)
        @test bounds(getindex(m, 1:5)) == (10.0, 60.0)
        @test bounds(getindex(m, 2:3)) == (20.0, 40.0)
        m = Sampled(ind, ForwardOrdered(), Irregular((0.0, 50.0)), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (20.0, 30.0)
        @test bounds(getindex(m, 1:5)) == (0.0, 50.0)
        @test bounds(getindex(m, 2:3)) == (10.0, 30.0)
        m = Sampled(ind, ForwardOrdered(), Irregular((5.0, 55.0)), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (25.0, 35.0)
        @test bounds(getindex(m, 1:5)) == (5.0, 55.0)
        @test bounds(getindex(m, 2:3)) == (15.0, 35.0)
    end

    @testset "Irregular reverse" begin
        revind = [50.0, 40.0, 30.0, 20.0, 10.0]
        m = Sampled(revind; order=ReverseOrdered(), span=Irregular(0.0, 50.0), sampling=Intervals(Start()))
        @test bounds(getindex(m, 1:5)) == (0.0, 50.0)
        @test bounds(getindex(m, 1:2)) == (30.0, 50.0)
        @test bounds(getindex(m, 2:3)) == (20.0, 40.0)
        m = Sampled(revind, ReverseOrdered(), Irregular(10.0, 60.0), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 1:5)) == (10.0, 60.0)
        @test bounds(getindex(m, 1:2)) == (40.0, 60.0)
        @test bounds(getindex(m, 2:3)) == (30.0, 50.0)
        m = Sampled(revind, ReverseOrdered(), Irregular(0.5, 55.0), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 1:5)) == (0.5, 55.0)
        @test bounds(getindex(m, 1:2)) == (35.0, 55.0)
        @test bounds(getindex(m, 2:3)) == (25.0, 45.0)
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

@testset "bounds" begin

    @testset "Intervals" begin
        @testset "Regular bounds are calculated from interval type and span value" begin
            @testset "forward ind" begin
                ind = 10.0:10.0:50.0
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(Start()), span=Regular(10.0)))
                @test bounds(dim) == (10.0, 60.0)
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(End()), span=Regular(10.0)))
                @test bounds(dim) == (0.0, 50.0)
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Start()), NoMetadata()))
                @test bounds(dim) == (10.0, 60.0)                                        
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(End()), NoMetadata()))
                @test bounds(dim) == (0.0, 50.0)                                         
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Center()), NoMetadata()))
                @test bounds(dim) == (5.0, 55.0)
            end
            @testset "reverse ind" begin
                revind = [10.0, 9.0, 8.0, 7.0, 6.0]
                dim = X(Sampled(revind, ; order=ReverseOrdered(), sampling=Intervals(Start()), span=Regular(-1.0)))
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(Start()), NoMetadata()))
                @test bounds(dim) == (6.0, 11.0)
                dim = X(Sampled(revind, ; order=ReverseOrdered(), sampling=Intervals(End()), span=Regular(-1.0)))
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(End()), NoMetadata()))
                @test bounds(dim) == (5.0, 10.0)
                dim = X(Sampled(revind, ; order=ReverseOrdered(), sampling=Intervals(Center()), span=Regular(-1.0)))
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(Center()), NoMetadata()))
                @test bounds(dim) == (5.5, 10.5)
            end
        end
        @testset "Irregular bounds are whatever is stored in span" begin
            ind = 10.0:10.0:50.0
            dim = X(Sampled(ind, ForwardOrdered(), Irregular(0.0, 50000.0), Intervals(Start()), NoMetadata()))
            @test bounds(dim) == (0.0, 50000.0)
            @test bounds(getindex(dim, 2:3)) == (20.0, 40.0)
        end
        @testset "Explicit bounds are is stored in span matrix" begin
            ind = 10.0:10.0:50.0
            bnds = vcat(ind', (ind .+ 10)')
            dim = X(Sampled(ind, ForwardOrdered(), Explicit(bnds), Intervals(Start()), NoMetadata()))
            @test bounds(dim) == (10.0, 60.0)
            @test bounds(DimensionalData._slicedims(getindex, dim, 2:3)[1][1]) == (20.0, 40.0)
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
    end

    @testset "Categorical" begin
        ind = [:a, :b, :c, :d]
        dim = X(Categorical(ind; order=ForwardOrdered()))
        @test order(dim) == ForwardOrdered()
        @test_throws ErrorException step(dim)
        @test span(dim) == DimensionalData.NoSpan()
        @test sampling(dim) == DimensionalData.NoSampling()
        @test dims(lookup(dim)) === nothing
        @test locus(dim) == Center()
        @test bounds(dim) == (:a, :d)
        dim = X(Categorical(ind; order=ReverseOrdered()))
        @test bounds(dim) == (:d, :a)
        @test order(dim) == ReverseOrdered()
        dim = X(Categorical(ind; order=Unordered()))
        @test bounds(dim) == (nothing, nothing)
        @test order(dim) == Unordered()
    end

end

@testset "dims2indices with Transformed" begin
    tdimz = Dim{:trans1}(Transformed(identity, X())), 
            Dim{:trans2}(Transformed(identity, Y())), 
            Z(NoLookup(1:1))
    @test dims2indices(tdimz, (X(1), Y(2), Z())) == (1, 2, Colon())
    @test dims2indices(tdimz, (Dim{:trans1}(1), Dim{:trans2}(2), Z())) == (1, 2, Colon())
end
