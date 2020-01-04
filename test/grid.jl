using DimensionalData, Test, Unitful
using DimensionalData: X, Y, Z, Time, Forward, Reverse, 
      reversearray, reverseindex, slicebounds, slicegrid, identify, orderof

@testset "identify grid type" begin
    @test identify(RegularGrid(), 1) == RegularGrid()
    @test identify(UnknownGrid(), 1:2:10) == RegularGrid(; step=2, order=Ordered(Forward(), Forward(), Forward()))
    @test identify(UnknownGrid(), 10:-2:1) == RegularGrid(; step=-2, order=Ordered(Reverse(), Forward(), Forward()))
    @test identify(UnknownGrid(), [:a, :b]) == CategoricalGrid()
    @test identify(UnknownGrid(), ["a", "b"]) == CategoricalGrid()
    @test identify(UnknownGrid(), [1, 2, 3, 4]) == AlignedGrid(; order=Ordered(Forward(), Forward(), Forward()))
    @test identify(UnknownGrid(), [4, 3, 2, 1]) == AlignedGrid(; order=Ordered(Reverse(), Forward(), Forward()))
end

@testset "sampling" begin

end

@testset "order" begin
    @test dimorder(Ordered()) == Forward()
    @test arrayorder(Ordered()) == Forward()
    @test relationorder(Ordered()) == Forward()
    @test dimorder(Unordered()) == Unordered()
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

    @test order(reverseindex(AlignedGrid(order=Ordered(Forward(), Reverse(), Forward())))) == 
        Ordered(Reverse(), Reverse(), Reverse()) 
        Ordered(Forward(), Forward(), Reverse()) 
    @test order(reverseindex(RegularGrid(order=Ordered(Forward(), Reverse(), Reverse())))) == 
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

    dim = X(index; grid=RegularGrid(; locus=Start(), step=10.0))
    @test bounds(dim) == (10.0, 60.0)
    dim = X(index; grid=RegularGrid(; locus=End(), step=10.0))
    @test bounds(dim) == (0.0, 50.0)
    dim = X(index; grid=RegularGrid(; locus=Center(), step=10.0))
    @test bounds(dim) == (5.0, 55.0)

    revindex = [10.0, 9.0, 8.0, 7.0, 6.0]
    dim = X(revindex; grid=RegularGrid(; order=orderof(revindex), locus=Start(), step=1.0))
    @test bounds(dim) == (6.0, 11.0)
    dim = X(revindex; grid=RegularGrid(; order=orderof(revindex), locus=End(), step=1.0))
    @test bounds(dim) == (5.0, 11.0)
    dim = X(revindex; grid=RegularGrid(; order=orderof(revindex), locus=Center(), step=1.0))
    @test bounds(dim) == (5.5, 10.5)

    index = [:a, :b, :c, :d]
    dim = X(index; grid=CategoricalGrid(; order=Ordered()))
    @test bounds(dim) == (:a, :d)
    dim = X(index; grid=CategoricalGrid(; order=Ordered(;index=Reverse())))
    @test bounds(dim) == (:d, :a)
    dim = X(index; grid=CategoricalGrid(; order=Unordered()))
    @test_throws ErrorException bounds(dim)
end

