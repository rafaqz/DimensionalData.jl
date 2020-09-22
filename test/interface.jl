using DimensionalData, Test
using DimensionalData: val

@test name(nothing) == ""
@test name(Nothing) == ""
@test dims(1) == nothing
@test refdims(1) == ()
