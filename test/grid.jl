@testset "bounds" begin

end

@testset "sampling" begin

end

@testset "reverse" begin
    @test reverse(Reverse()) == Forward()
    @test reverse(Forward()) == RegularGrid()
    @test reverse(Unordered()) == Unordered()
    @test reverse(Ordered(Forward(), Reverse())) == Ordered(Reverse(), Forward()) 
    @test grid(reverse(AllignedGrid(grid=Ordered(Forward(), Reverse())))) == Ordered(Reverse(), Forward()) 
    @test grid(reverse(RegularGrid(grid=Ordered(Forward(), Reverse())))) == Ordered(Reverse(), Forward()) 
    @test grid(reverse(CategoricalGrid(grid=Ordered(Forward(), Reverse())))) == Ordered(Reverse(), Forward()) 
end
