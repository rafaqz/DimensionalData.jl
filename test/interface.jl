using DimensionalData, Interfaces, Test, Dates

@test name(nothing) == ""
@test name(Nothing) == ""
@test dims(1) == nothing
@test dims(nothing) == nothing
@test refdims(1) == ()

# @test Interfaces.test(DimensionalData)
@test Interfaces.test(DimensionalData.DimArrayInterface)
@test Interfaces.test(DimensionalData.DimStackInterface)

using BaseInterfaces
@implements ArrayInterface AbstracDimArray [rand(X(10), rand(Y(1:10))), Ti(DateTime(2000):Month(1):DateTime(2000, 12)), rand(X(1:7), Y(1:8), Z('a':'h'))]
