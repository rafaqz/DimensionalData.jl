using DimensionalData, Test, Unitful
using DimensionalData: Forward, Reverse,
      reversearray, reverseindex, slicebounds, sliceindexmode, identify,
      indexorder, arrayorder, relationorder

@testset "identify IndexMode" begin
    @test identify(SampledIndex(sampling=IntervalSampling()), X, 1:1) ==
        SampledIndex(Ordered(), RegularSpan(1), IntervalSampling(Center()))
    @test identify(SampledIndex(sampling=IntervalSampling()), Ti, 1:2:3) ==
        SampledIndex(Ordered(), RegularSpan(2), IntervalSampling(Start()))

    @test identify(AutoIndex(), X, 1:2:10) ==
        SampledIndex(Ordered(), RegularSpan(2), PointSampling())
    @test identify(AutoIndex(), X, [1, 2, 3, 4, 5]) ==
        SampledIndex(Ordered(), IrregularSpan(), PointSampling())

    @test identify(SampledIndex(), X, 1:2:10) ==
        SampledIndex(Ordered(), RegularSpan(2), PointSampling())
    @test identify(SampledIndex(), X, [1, 2, 3, 4, 5]) ==
        SampledIndex(Ordered(), IrregularSpan(), PointSampling())

    @test identify(SampledIndex(sampling=IntervalSampling()), X, 1:2:10) ==
        SampledIndex(Ordered(), RegularSpan(2), IntervalSampling(Center()))
    @test identify(SampledIndex(sampling=IntervalSampling()), X, [1, 2, 3, 4, 5]) ==
        SampledIndex(Ordered(), IrregularSpan(), IntervalSampling(Center()))

    @test identify(SampledIndex(order=Ordered(Reverse(), Forward(), Forward())), X, 10:-2:1) ==
        SampledIndex(Ordered(Reverse(), Forward(), Forward()), RegularSpan(-2), PointSampling())

    @test identify(AutoIndex(), X, [:a, :b]) == CategoricalIndex()
    @test identify(AutoIndex(), X, ["a", "b"]) == CategoricalIndex()
    @test identify(AutoIndex(), X, ['a', 'b']) == CategoricalIndex()
    @test identify(AutoIndex(), X, [1, 2, 3, 4]) ==
        SampledIndex(span=IrregularSpan())
    @test_broken identify(AutoIndex(AutoOrder()), X, [4, 3, 2, 1]) ==
        SampledIndex(Ordered(Reverse(), Forward(), Forward()), NoLocus())
    @test_broken identify(AutoIndex(AutoOrder()), X, [1, 3, 2, 9]) ==
        SampledIndex(Unordered(Forward(), NoLocus()))

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

    @test order(reverseindex(SampledIndex(order=Ordered(Forward(), Reverse(), Forward())))) ==
        Ordered(Reverse(), Reverse(), Reverse())
        Ordered(Forward(), Forward(), Reverse())
    @test order(reverseindex(SampledIndex(order=Ordered(Forward(), Reverse(), Reverse())))) ==
        Ordered(Reverse(), Reverse(), Forward())
    @test order(reverseindex(CategoricalIndex(order=Ordered(Forward(), Reverse(), Reverse())))) ==
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

    @testset "forwards" begin
        mode = SampledIndex(span=IrregularSpan((10.0, 60.0)), sampling=IntervalSampling(Start()))
        @test bounds(sliceindexmode(mode, index, 3), X()) == (30.0, 40.0)
        @test bounds(sliceindexmode(mode, index, 1:5), X()) == (10.0, 60.0)
        @test bounds(sliceindexmode(mode, index, 2:3), X()) == (20.0, 40.0)
    end
    @testset "reverse" begin
        mode = SampledIndex(order=Ordered(index=Reverse()), span=IrregularSpan(10.0, 60.0),
                           sampling=IntervalSampling(Start()))
        @test bounds(sliceindexmode(mode, index, 1:5), X()) == (10.0, 60.0)
        @test bounds(sliceindexmode(mode, index, 1:3), X()) == (30.0, 60.0)
    end
end

@testset "IntervalSampling bounds" begin
    @testset "RegularSpan" begin
        @testset "forward index" begin
            index = 10.0:10.0:50.0
            dim = X(index; indexmode=SampledIndex(; sampling=IntervalSampling(Start()), span=RegularSpan(10.0)))
            @test bounds(dim) == (10.0, 60.0)
            dim = X(index; indexmode=SampledIndex(sampling=IntervalSampling(End()), span=RegularSpan(10.0)))
            @test bounds(dim) == (0.0, 50.0)
            dim = X(index; indexmode=SampledIndex(sampling=IntervalSampling(Center()), span=RegularSpan(10.0)))
            @test bounds(dim) == (5.0, 55.0)
        end
        @testset "reverse index" begin
            revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
            dim = X(revindex; indexmode=SampledIndex(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=IntervalSampling(Start()), span=RegularSpan(-1.0)))
            @test bounds(dim) == (6.0, 11.0)
            dim = X(revindex; indexmode=SampledIndex(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=IntervalSampling(End()), span=RegularSpan(-1.0)))
            @test bounds(dim) == (5.0, 10.0)
            dim = X(revindex; indexmode=SampledIndex(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=IntervalSampling(Center()), span=RegularSpan(-1.0)))
            @test bounds(dim) == (5.5, 10.5)
        end
    end
    @testset "RegularSpan" begin
        @testset "forward index" begin
            index = 10.0:10.0:50.0
            dim = X(index; indexmode=SampledIndex(; sampling=IntervalSampling(Start()), span=RegularSpan(10.0)))
            @test bounds(dim) == (10.0, 60.0)
            dim = X(index; indexmode=SampledIndex(sampling=IntervalSampling(End()), span=RegularSpan(10.0)))
            @test bounds(dim) == (0.0, 50.0)
            dim = X(index; indexmode=SampledIndex(sampling=IntervalSampling(Center()), span=RegularSpan(10.0)))
            @test bounds(dim) == (5.0, 55.0)
        end
        @testset "reverse index" begin
            revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
            dim = X(revindex; indexmode=SampledIndex(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=IntervalSampling(Start()), span=RegularSpan(-1.0)))
            @test bounds(dim) == (6.0, 11.0)
            dim = X(revindex; indexmode=SampledIndex(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=IntervalSampling(End()), span=RegularSpan(-1.0)))
            @test bounds(dim) == (5.0, 10.0)
            dim = X(revindex; indexmode=SampledIndex(; order=Ordered(Reverse(),Forward(),Forward()),
                                               sampling=IntervalSampling(Center()), span=RegularSpan(-1.0)))
            @test bounds(dim) == (5.5, 10.5)
        end
    end
end

@testset "PointSampling bounds" begin
    index = 10:15
    dim = X(index; indexmode=SampledIndex(order=Ordered(), sampling=PointSampling()))
    @test bounds(dim) == (10, 15)
    index = 15:-1:10
    dim = X(index; indexmode=SampledIndex(order=Ordered(index=Reverse()), sampling=PointSampling()))
    last(dim), first(dim)
    @test bounds(dim) == (10, 15)
    dim = X(index; indexmode=SampledIndex(order=Unordered(), sampling=PointSampling()))
    @test_throws ErrorException bounds(dim)
end

@testset "CategoricalIndex bounds" begin
    index = [:a, :b, :c, :d]
    dim = X(index; indexmode=CategoricalIndex(; order=Ordered()))
    @test bounds(dim) == (:a, :d)
    dim = X(index; indexmode=CategoricalIndex(; order=Ordered(;index=Reverse())))
    @test bounds(dim) == (:d, :a)
    dim = X(index; indexmode=CategoricalIndex(; order=Unordered()))
    @test_throws ErrorException bounds(dim)
end

