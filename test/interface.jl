using DimensionalData, Interfaces, Test

@test name(nothing) == ""
@test name(Nothing) == ""
@test dims(1) == nothing
@test dims(nothing) == nothing
@test refdims(1) == ()

@test Interfaces.test(DimensionalData)
