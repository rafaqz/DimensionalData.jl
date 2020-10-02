using DimensionalData, Test

@test name(nothing) == ""
@test name(Nothing) == ""
@test dims(1) == nothing
@test_throws ErrorException dims(nothing) 
@test refdims(1) == ()
