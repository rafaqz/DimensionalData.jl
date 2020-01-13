using DimensionalData, Test
using DimensionalData: val

@test name(nothing) == ""
@test name(Nothing) == ""
@test shortname(nothing) == ""
@test shortname(Nothing) == ""
@test_throws MethodError dims(1) == ()
@test refdims(1) == ()
