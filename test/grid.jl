using DimensionalData, Test, Unitful
using DimensionalData: X, Y, Z, Time, Forward, Reverse, 
      reversearray, reverseindex, slicebounds, slicegrid

@testset "sampling" begin

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
    @test order(reversearray(AlignedGrid(order=Ordered(Forward(), Reverse(), Forward())))) == 
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

    dim = X(index; grid=EqualSizedGrid(; locus=Start(), span=10.0))
    @test bounds(dim) == (10.0, 60.0)
    dim = X(index; grid=EqualSizedGrid(; locus=End(), span=10.0))
    @test bounds(dim) == (0.0, 50.0)
    dim = X(index; grid=EqualSizedGrid(; locus=Center(), span=10.0))
    @test bounds(dim) == (5.0, 55.0)

    index = [:a, :b, :c, :d]
    dim = X(index; grid=CategoricalGrid(; order=Ordered()))
    @test bounds(dim) == (:a, :d)
    dim = X(index; grid=CategoricalGrid(; order=Ordered(;index=Reverse())))
    @test bounds(dim) == (:d, :a)
    dim = X(index; grid=CategoricalGrid(; order=Unordered()))
    @test_throws ErrorException bounds(dim)
end
