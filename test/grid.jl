using DimensionalData, Test, Unitful
using DimensionalData: X, Y, Z, Time, Forward, Reverse, reversearray, reverseindex

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

    @test order(reverseindex(AllignedGrid(order=Ordered(Forward(), Reverse(), Forward())))) == 
        Ordered(Reverse(), Reverse(), Reverse()) 
    @test order(reversearray(AllignedGrid(order=Ordered(Forward(), Reverse(), Forward())))) == 
        Ordered(Forward(), Forward(), Reverse()) 
    @test order(reverseindex(RegularGrid(order=Ordered(Forward(), Reverse(), Reverse())))) == 
        Ordered(Reverse(), Reverse(), Forward()) 
    @test order(reverseindex(CategoricalGrid(order=Ordered(Forward(), Reverse(), Reverse())))) == 
        Ordered(Reverse(), Reverse(), Forward())
end
