using DimensionalData, Test

using DimensionalData.Lookups: Begin, End, LazyMath

@testset "Begin" begin
    A = reshape(1:50, (10,5))
    dd = DimArray(A, (X(1:10), Y(50:-10:10)))
    @test dd[X=End, Y=Begin] == 10
    @test dd[Y=Begin, X=End] == 10
    @test dd[Y=End()÷2, X=End ÷ 2] == 15
    @test dd[Y=Begin+1, X=End] == 20
    @test dd[Y=End-1, X=End] == 40
    @test dd[Y=End, X=Begin:2:End].data == [41,43,45,47,49]
end