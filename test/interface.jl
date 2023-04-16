using DimensionalData, Test

@test name(nothing) == ""
@test name(Nothing) == ""
@test dims(1) == nothing
@test dims(nothing) == nothing
@test refdims(1) == ()
