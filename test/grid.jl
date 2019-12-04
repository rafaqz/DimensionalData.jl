using DimensionalData, Test, Unitful
using DimensionalData: X, Y, Z, Time, Forward, Reverse

@testset "sampling" begin

end

@testset "reverse" begin
    @test reverse(Reverse()) == Forward()
    @test reverse(Forward()) == Reverse()
    @test reverse(Unordered()) == Unordered()
    @test reverse(Ordered(Forward(), Reverse())) == Ordered(Forward(), Forward()) 
    @test grid(reverse(AllignedGrid(grid=Ordered(Forward(), Reverse())))) == Ordered(Reverse(), Reverse()) 
    @test grid(reverse(RegularGrid(grid=Ordered(Forward(), Reverse())))) == Ordered(Reverse(), Forward()) 
    @test grid(reverse(CategoricalGrid(grid=Ordered(Forward(), Reverse())))) == Ordered(Reverse(), Forward()) 
end
