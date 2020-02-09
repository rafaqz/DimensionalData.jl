using DimensionalData, Test
using DimensionalData: val

@test name(nothing) == ""
@test name(Nothing) == ""
@test shortname(nothing) == ""
@test shortname(Nothing) == ""
@test dims(1) == nothing
@test refdims(1) == ()
