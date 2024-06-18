using DimensionalData, Interfaces, Test, Dates

@test_throws MethodError name(nothing)
@test_throws MethodError name(Nothing)
@test dims(1) == nothing
@test dims(nothing) == nothing
@test refdims(1) == ()

# @test Interfaces.test(DimensionalData)
@test Interfaces.test(DimensionalData.DimArrayInterface)
@test Interfaces.test(DimensionalData.DimStackInterface)

# For when BaseInterfaces registered...
# using BaseInterfaces
# @implements ArrayInterface{(:setindex!,:similar_type,:similar_eltype)} AbstractDimArray [
#     rand(X(10)),
#     rand(Y(1:10), Ti(DateTime(2000):Month(1):DateTime(2000, 12))),
#     rand(X(1:7), Y(1:8), Z('a':'h'))
# ]
# @test BaseInterfaces.test(AbstractDimArray)
