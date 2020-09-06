using DimensionalData, Test, Unitful
using DimensionalData: slicebounds, slicemode

@testset "order" begin
    @test indexorder(Ordered()) == ForwardIndex()
    @test arrayorder(Ordered()) == ForwardArray()
    @test relation(Ordered()) == ForwardRelation()
    @test indexorder(Unordered()) == UnorderedIndex()
    @test arrayorder(Unordered()) == ForwardArray()
    @test relation(Unordered()) == ForwardRelation()
end

@testset "reverse" begin
    @test reverse(ReverseIndex()) == ForwardIndex()
    @test reverse(ForwardIndex()) == ReverseIndex()
    @test reverse(ReverseArray()) == ForwardArray()
    @test reverse(ForwardArray()) == ReverseArray()
    @test reverse(ReverseRelation()) == ForwardRelation()
    @test reverse(ForwardRelation()) == ReverseRelation()
    @test reverse(ArrayOrder, Unordered(ForwardRelation())) ==
        Unordered(ReverseRelation())
    @test reverse(ArrayOrder, Ordered(ForwardIndex(), ReverseArray(), ForwardRelation())) ==
        Ordered(ForwardIndex(), ForwardArray(), ReverseRelation())
    @test reverse(IndexOrder, Unordered(ForwardRelation())) ==
        Unordered(ReverseRelation())
    @test reverse(IndexOrder, Ordered(ForwardIndex(), ReverseArray(), ForwardRelation())) ==
        Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())
    @test order(reverse(IndexOrder, Sampled(order=Ordered(ForwardIndex(), ReverseArray(), ForwardRelation())))) ==
        Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())
        Ordered(ForwardIndex(), ForwardArray(), ReverseRelation())
    @test order(reverse(IndexOrder, Sampled(order=Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())))) ==
        Ordered(ReverseIndex(), ReverseArray(), ForwardRelation())
    @test order(reverse(IndexOrder, Categorical(order=Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())))) ==
        Ordered(ReverseIndex(), ReverseArray(), ForwardRelation())
end

@testset "slicbounds" begin
    index = [10.0, 20.0, 30.0, 40.0, 50.0]
    bound = (10.0, 60.0)
    @test slicebounds(Start(), bounds, index, 2:3) == (20.0, 40.0)
    bound = (0.0, 50.0)
    @test slicebounds(End(), bounds, index, 2:3) == (10.0, 30.0)
    bound = (0.5, 55.0)
    @test slicebounds(Center(), bounds, index, 2:3) == (15.0, 35.0)
end

@testset "slicemode" begin
    ind = [10.0, 20.0, 30.0, 40.0, 50.0]

    @testset "Irregular forwards" begin
        mode_ = Sampled(span=Irregular((10.0, 60.0)), sampling=Intervals(Start()))
        mode_ = Sampled(Ordered(), Irregular((10.0, 60.0)), Intervals(Start()))
        @test bounds(slicemode(mode_, ind, 3), X(ind)) == (30.0, 40.0)
        @test bounds(slicemode(mode_, ind, 1:5), X(ind)) == (10.0, 60.0)
        @test bounds(slicemode(mode_, ind, 2:3), X(ind)) == (20.0, 40.0)
    end

    @testset "Irregular reverse" begin
        mode_ = Sampled(order=Ordered(index=ReverseIndex()), span=Irregular(10.0, 60.0),
                       sampling=Intervals(Start()))
        mode_ = Sampled(Ordered(index=ReverseIndex()), Irregular(10.0, 60.0), Intervals(Start()))
        @test bounds(slicemode(mode_, ind, 1:5), X(ind)) == (10.0, 60.0)
        @test bounds(slicemode(mode_, ind, 1:3), X(ind)) == (30.0, 60.0)
    end

    @testset "Irregular with no bounds" begin
        mode = Sampled(span=Irregular(), sampling=Intervals(Start()))
        mode = Sampled(Ordered(), Irregular(), Intervals(Start()))
        @test bounds(slicemode(mode, ind, 3), X()) == (30.0, 40.0)
        @test bounds(slicemode(mode, ind, 2:4), X()) == (20.0, 50.0)
        # TODO should this be built into `identify` to at least get one bound?
        @test bounds(slicemode(mode, ind, 1:5), X()) == (10.0, nothing)
        mode = Sampled(span=Irregular(), sampling=Intervals(End()))
        mode = Sampled(Ordered(), Irregular(), Intervals(End()))
        @test bounds(slicemode(mode, ind, 3), X()) == (20.0, 30.0)
        @test bounds(slicemode(mode, ind, 2:4), X()) == (10.0, 40.0)
        @test bounds(slicemode(mode, ind, 1:5), X()) == (nothing, 50.0)
        mode = Sampled(span=Irregular(), sampling=Intervals(Center()))
        mode = Sampled(Ordered(), Irregular(), Intervals(Center()))
        @test bounds(slicemode(mode, ind, 3), X()) == (25.0, 35.0)
        @test bounds(slicemode(mode, ind, 2:4), X()) == (15.0, 45.0)
        @test bounds(slicemode(mode, ind, 1:5), X()) == (nothing, nothing)
    end

    @testset "Regular is unchanged" begin
        mode = Sampled(span=Regular(1.0), sampling=Intervals(Start()))
        mode = Sampled(Ordered(), Regular(1.0), Intervals(Start()))
        @test slicemode(mode, ind, 2:3) === mode
    end

    @testset "Points is unchanged" begin
        mode = Sampled(span=Regular(1.0), sampling=Points())
        mode = Sampled(Ordered(), Regular(1.0), Points())
        @test slicemode(mode, ind, 2:3) === mode
    end

end

@testset "bounds" begin

    @testset "Intervals" begin
        @testset "Regular bounds are calculated from interval type and span value" begin
            @testset "forward ind" begin
                ind = 10.0:10.0:50.0
                dim = X(ind; mode=Sampled(order=Ordered(), sampling=Intervals(Start()), span=Regular(10.0)))
                @test bounds(dim) == (10.0, 60.0)
                dim = X(ind; mode=Sampled(order=Ordered(), sampling=Intervals(End()), span=Regular(10.0)))
                @test bounds(dim) == (0.0, 50.0)
                dim = X(ind; mode=Sampled(Ordered(), Regular(10.0), Intervals(Start())))
                @test bounds(dim) == (10.0, 60.0)                                        
                dim = X(ind; mode=Sampled(Ordered(), Regular(10.0), Intervals(End())))
                @test bounds(dim) == (0.0, 50.0)                                         
                dim = X(ind; mode=Sampled(Ordered(), Regular(10.0), Intervals(Center())))
                @test bounds(dim) == (5.0, 55.0)
            end
            @testset "reverse ind" begin
                revind = [10.0, 9.0, 8.0, 7.0, 6.0]
                dim = X(revind; mode=Sampled(; order=Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()),
                                                   sampling=Intervals(Start()), span=Regular(-1.0)))
                dim = X(revind; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), Regular(-1.0), Intervals(Start())))
                @test bounds(dim) == (6.0, 11.0)
                dim = X(revind; mode=Sampled(; order=Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()),
                                                   sampling=Intervals(End()), span=Regular(-1.0)))
                dim = X(revind; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), Regular(-1.0), Intervals(End())))
                @test bounds(dim) == (5.0, 10.0)
                dim = X(revind; mode=Sampled(; order=Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()),
                                                   sampling=Intervals(Center()), span=Regular(-1.0)))
                dim = X(revind; mode=Sampled(Ordered(ReverseIndex(),ForwardArray(),ForwardRelation()), Regular(-1.0), Intervals(Center())))
                @test bounds(dim) == (5.5, 10.5)
            end
        end
        @testset "Irregular bounds are whatever is stored in span" begin
            ind = 10.0:10.0:50.0
            dim = X(ind; mode=Sampled(Ordered(), Irregular(0.0, 50000.0), Intervals(Start())))
            @test bounds(dim) == (0.0, 50000.0)
        end
    end

    @testset "Points" begin
        ind = 10:15
        dim = X(ind; mode=Sampled(order=Ordered(), sampling=Points()))
        @test bounds(dim) == (10, 15)
        ind = 15:-1:10
        dim = X(ind; mode=Sampled(order=Ordered(index=ReverseIndex()), sampling=Points()))
        last(dim), first(dim)
        @test bounds(dim) == (10, 15)
        dim = X(ind; mode=Sampled(order=Unordered(), sampling=Points()))
        @test bounds(dim) == (nothing, nothing)
    end

    @testset "Categorical" begin
        ind = [:a, :b, :c, :d]
        dim = X(ind; mode=Categorical(; order=Ordered()))
        @test bounds(dim) == (:a, :d)
        dim = X(ind; mode=Categorical(; order=Ordered(;index=ReverseIndex())))
        @test bounds(dim) == (:d, :a)
        dim = X(ind; mode=Categorical(; order=Unordered()))
        @test bounds(dim) == (nothing, nothing)
    end

end
