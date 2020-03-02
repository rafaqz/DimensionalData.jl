using DimensionalData, Test, Unitful
using DimensionalData: Forward, Reverse, 
      reversearray, reverseindex, slicebounds, slicegrid, identify,
      indexorder, arrayorder, relationorder

@testset "identify grid type" begin
    @test identify(RegularGrid(), X, 1:1) == RegularGrid(;locus=Center(), step=1) 
    @test identify(RegularGrid(), Ti, 1:1) == RegularGrid(;locus=Start(), step=1)
    @test identify(UnknownGrid(), X, 1:2:10) == PointGrid(order=Ordered(Forward(), Forward(), Forward()))
    @test identify(UnknownGrid(), X, 10:-2:1) == PointGrid(order=Ordered(Reverse(), Forward(), Forward()))
    @test identify(UnknownGrid(), X, [:a, :b]) == CategoricalGrid()
    @test identify(UnknownGrid(), X, ["a", "b"]) == CategoricalGrid()
    @test identify(UnknownGrid(), X, [1, 2, 3, 4]) == PointGrid(; order=Ordered(Forward(), Forward(), Forward()))
    @test identify(UnknownGrid(), X, [4, 3, 2, 1]) == PointGrid(; order=Ordered(Reverse(), Forward(), Forward()))
    @test identify(UnknownGrid(), X, [1, 3, 2, 9]) == PointGrid(; order=Unordered(Forward()))
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

    @test order(reverseindex(PointGrid(order=Ordered(Forward(), Reverse(), Forward())))) == 
        Ordered(Reverse(), Reverse(), Reverse()) 
        Ordered(Forward(), Forward(), Reverse()) 
    @test order(reverseindex(PointGrid(order=Ordered(Forward(), Reverse(), Reverse())))) == 
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
    grid = BoundedGrid(; locus=Start(), bounds=(10.0, 60.0))
    @test bounds(slicegrid(grid, index, 3)) == (30.0, 40.0)
    @test bounds(slicegrid(grid, index, 1:5)) == (10.0, 60.0)
    @test bounds(slicegrid(grid, index, 2:3)) == (20.0, 40.0)
    grid = BoundedGrid(; locus=Start(), order=Ordered(;relation=Reverse()), bounds=(10.0, 60.0))
    @test bounds(slicegrid(grid, index, 1:5)) == (10.0, 60.0)
    @test bounds(slicegrid(grid, index, 1:3)) == (30.0, 60.0)
end

@testset "RegularGrid bounds" begin
    index = [10.0, 20.0, 30.0, 40.0, 50.0]

    @testset "forward relationship" begin
        dim = X(index; grid=RegularGrid(; locus=Start(), step=10.0))
        @test bounds(dim) == (10.0, 60.0)
        dim = X(index; grid=RegularGrid(; locus=End(), step=10.0))
        @test bounds(dim) == (0.0, 50.0)
        dim = X(index; grid=RegularGrid(; locus=Center(), step=10.0))
        @test bounds(dim) == (5.0, 55.0)
    end

    @testset "reverse relationship" begin
        dim = X(index; grid=RegularGrid(; order=Ordered(Forward(),Forward(),Reverse()), locus=Start(), step=10.0))
        @test bounds(dim) == (0.0, 50.0)
        dim = X(index; grid=RegularGrid(; order=Ordered(Forward(),Forward(),Reverse()), locus=End(), step=10.0))
        @test bounds(dim) == (10.0, 60.0)
        dim = X(index; grid=RegularGrid(; order=Ordered(Forward(),Forward(),Reverse()), locus=Center(), step=10.0))
        @test bounds(dim) == (5.0, 55.0)
    end

    revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
    @testset "reverse index forward relationship" begin
        dim = X(revindex; grid=RegularGrid(; order=Ordered(Reverse(),Forward(),Forward()), locus=Start(), step=-1.0))
        @test bounds(dim) == (5.0, 10.0)
        dim = X(revindex; grid=RegularGrid(; order=Ordered(Reverse(),Forward(),Forward()), locus=End(), step=-1.0))
        @test bounds(dim) == (6.0, 11.0)
        dim = X(revindex; grid=RegularGrid(; order=Ordered(Reverse(),Forward(),Forward()), locus=Center(), step=-1.0))
        @test bounds(dim) == (5.5, 10.5)
    end

    @testset "reverse index reverse relationship" begin
        revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
        dim = X(revindex; grid=RegularGrid(; order=Ordered(Reverse(),Forward(),Reverse()), locus=Start(), step=-1.0))
        @test bounds(dim) == (6.0, 11.0)
        dim = X(revindex; grid=RegularGrid(; order=Ordered(Reverse(),Forward(),Reverse()), locus=End(), step=-1.0))
        @test bounds(dim) == (5.0, 10.0)
        dim = X(revindex; grid=RegularGrid(; order=Ordered(Reverse(),Forward(),Reverse()), locus=Center(), step=-1.0))
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

