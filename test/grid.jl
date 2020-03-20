using DimensionalData, Test, Unitful
using DimensionalData: Forward, Reverse,
      reversearray, reverseindex, slicebounds, slicegrid, identify,
      indexorder, arrayorder, relationorder

@testset "identify grid type" begin
    @test identify(SampledGrid(sampling=IntervalSampling()), X, 1:1) ==
        SampledGrid(Ordered(), RegularSpan(1), IntervalSampling(Center()))
    @test identify(SampledGrid(sampling=IntervalSampling()), Ti, 1:2:3) ==
        SampledGrid(Ordered(), RegularSpan(2), IntervalSampling(Start()))

    @test identify(UnknownGrid(), X, 1:2:10) ==
        SampledGrid(Ordered(), RegularSpan(2), PointSampling())
    @test identify(UnknownGrid(), X, [1, 2, 3, 4, 5]) ==
        SampledGrid(Ordered(), IrregularSpan(), PointSampling())

    @test identify(SampledGrid(), X, 1:2:10) ==
        SampledGrid(Ordered(), RegularSpan(2), PointSampling())
    @test identify(SampledGrid(), X, [1, 2, 3, 4, 5]) ==
        SampledGrid(Ordered(), IrregularSpan(), PointSampling())

    @test identify(SampledGrid(sampling=IntervalSampling()), X, 1:2:10) ==
        SampledGrid(Ordered(), RegularSpan(2), IntervalSampling(Center()))
    @test identify(SampledGrid(sampling=IntervalSampling()), X, [1, 2, 3, 4, 5]) ==
        SampledGrid(Ordered(), IrregularSpan(), IntervalSampling(Center()))

    @test identify(SampledGrid(order=Ordered(Reverse(), Forward(), Forward())), X, 10:-2:1) ==
        SampledGrid(Ordered(Reverse(), Forward(), Forward()), RegularSpan(-2), PointSampling())

    @test identify(UnknownGrid(), X, [:a, :b]) == CategoricalGrid()
    @test identify(UnknownGrid(), X, ["a", "b"]) == CategoricalGrid()
    @test identify(UnknownGrid(), X, ['a', 'b']) == CategoricalGrid()
    @test identify(UnknownGrid(), X, [1, 2, 3, 4]) ==
        SampledGrid(span=IrregularSpan())
    @test_broken identify(UnknownGrid(AutoOrder()), X, [4, 3, 2, 1]) ==
        SampledGrid(Ordered(Reverse(), Forward(), Forward()), NoLocus())
    @test_broken identify(UnknownGrid(AutoOrder()), X, [1, 3, 2, 9]) ==
        SampledGrid(Unordered(Forward(), NoLocus()))
end

@testset "order" begin
    @test indexorder(Ordered()) == Forward()
    @test arrayorder(Ordered()) == Forward()
    @test relationorder(Ordered()) == Forward()
    @test indexorder(Unordered()) == Unordered()
    @test arrayorder(Unordered()) == Unordered()
    @test relationorder(Unordered()) == Forward()
end

@testset "reverse" begin
    @test reverse(Reverse()) == Forward()
    @test reverse(Forward()) == Reverse()

    @test reversearray(Unordered(Forward())) ==
        Unordered(Reverse())
    @test reversearray(Ordered(Forward(), Reverse(), Forward())) ==
        Ordered(Forward(), Forward(), Reverse())

    @test reverseindex(Unordered(Forward())) ==
        Unordered(Reverse())
    @test reverseindex(Ordered(Forward(), Reverse(), Forward())) ==
        Ordered(Reverse(), Reverse(), Reverse())

    @test order(reverseindex(SampledGrid(order=Ordered(Forward(), Reverse(), Forward())))) ==
        Ordered(Reverse(), Reverse(), Reverse())
        Ordered(Forward(), Forward(), Reverse())
    @test order(reverseindex(SampledGrid(order=Ordered(Forward(), Reverse(), Reverse())))) ==
        Ordered(Reverse(), Reverse(), Forward())
    @test order(reverseindex(CategoricalGrid(order=Ordered(Forward(), Reverse(), Reverse())))) ==
        Ordered(Reverse(), Reverse(), Forward())
end

@testset "slice bounds" begin
    index = [10.0, 20.0, 30.0, 40.0, 50.0]
    bound = (10.0, 60.0)
    @test slicebounds(Start(), bounds, index, 2:3) == (20.0, 40.0)
    bound = (0.0, 50.0)
    @test slicebounds(End(), bounds, index, 2:3) == (10.0, 30.0)
    bound = (0.5, 55.0)
    @test slicebounds(Center(), bounds, index, 2:3) == (15.0, 35.0)
    grid = SampledGrid(span=IrregularSpan((10.0, 60.0)), sampling=IntervalSampling(Start()))
    @test bounds(slicegrid(grid, index, 3), X()) == (30.0, 40.0)
    @test bounds(slicegrid(grid, index, 1:5), X()) == (10.0, 60.0)
    @test bounds(slicegrid(grid, index, 2:3), X()) == (20.0, 40.0)
    grid = SampledGrid(; order=Ordered(;relation=Reverse()), span=IrregularSpan(10.0, 60.0),
                       sampling=IntervalSampling(Start()))
    @test bounds(slicegrid(grid, index, 1:5), X()) == (10.0, 60.0)
    @test bounds(slicegrid(grid, index, 1:3), X()) == (30.0, 60.0)
end

@testset "IntervalSampling bounds" begin
    index = [10.0, 20.0, 30.0, 40.0, 50.0]

    @testset "forward relationship" begin
        dim = X(index; grid=SampledGrid(; sampling=IntervalSampling(Start()), span=RegularSpan(10.0)))
        @test bounds(dim) == (10.0, 60.0)
        dim = X(index; grid=SampledGrid(sampling=IntervalSampling(End()), span=RegularSpan(10.0)))
        @test bounds(dim) == (0.0, 50.0)
        dim = X(index; grid=SampledGrid(sampling=IntervalSampling(Center()), span=RegularSpan(10.0)))
        @test bounds(dim) == (5.0, 55.0)
    end

    @testset "reverse relationship" begin
        dim = X(index; grid=SampledGrid(; order=Ordered(Forward(),Forward(),Reverse()),
                                        sampling=IntervalSampling(Start()), span=RegularSpan(10.0)))
        @test bounds(dim) == (0.0, 50.0)
        dim = X(index; grid=SampledGrid(; order=Ordered(Forward(),Forward(),Reverse()),
                                        sampling=IntervalSampling(End()), span=RegularSpan(10.0)))
        @test bounds(dim) == (10.0, 60.0)
        dim = X(index; grid=SampledGrid(; order=Ordered(Forward(),Forward(),Reverse()),
                                        sampling=IntervalSampling(Center()), span=RegularSpan(10.0)))
        @test bounds(dim) == (5.0, 55.0)
    end

    revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
    @testset "reverse index forward relationship" begin
        dim = X(revindex; grid=SampledGrid(; order=Ordered(Reverse(),Forward(),Forward()),
                                           sampling=IntervalSampling(Start()), span=RegularSpan(-1.0)))
        @test bounds(dim) == (5.0, 10.0)
        dim = X(revindex; grid=SampledGrid(; order=Ordered(Reverse(),Forward(),Forward()),
                                           sampling=IntervalSampling(End()), span=RegularSpan(-1.0)))
        @test bounds(dim) == (6.0, 11.0)
        dim = X(revindex; grid=SampledGrid(; order=Ordered(Reverse(),Forward(),Forward()),
                                           sampling=IntervalSampling(Center()), span=RegularSpan(-1.0)))
        @test bounds(dim) == (5.5, 10.5)
    end

    @testset "reverse index reverse relationship" begin
        revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
        dim = X(revindex; grid=SampledGrid(; order=Ordered(Reverse(),Forward(),Reverse()),
                                           sampling=IntervalSampling(Start()), span=RegularSpan(-1.0)))
        @test bounds(dim) == (6.0, 11.0)
        dim = X(revindex; grid=SampledGrid(; order=Ordered(Reverse(),Forward(),Reverse()),
                                           sampling=IntervalSampling(End()), span=RegularSpan(-1.0)))
        @test bounds(dim) == (5.0, 10.0)
        dim = X(revindex; grid=SampledGrid(; order=Ordered(Reverse(),Forward(),Reverse()),
                                           sampling=IntervalSampling(Center()), span=RegularSpan(-1.0)))
        @test bounds(dim) == (5.5, 10.5)
    end

    index = [:a, :b, :c, :d]
    dim = X(index; grid=CategoricalGrid(; order=Ordered()))
    @test bounds(dim) == (:a, :d)
    dim = X(index; grid=CategoricalGrid(; order=Ordered(;index=Reverse())))
    @test bounds(dim) == (:d, :a)
    dim = X(index; grid=CategoricalGrid(; order=Unordered()))
    @test_throws ErrorException bounds(dim)

end

