using Dates, DimensionalData
using DimensionalData: Time, X, Y
timespan = DateTime(2001):Month(1):DateTime(2001,12)
t = Time(timespan)
x = X(Vector(10:10:500))
A = DimensionalArray(rand(12,length(x)), (t, x))

s1 = sprint(show, A)
s2 = sprint(show, x)
s3 = sprint(show, MIME("text/plain"), x)

@test occursin("DimensionalArray with dimensions:", s1)
@test occursin("X", s1)
@test occursin("X:", s2)
@test occursin("dimension X", s3)

@test haskey(A, Time)
@test haskey(A, X)
@test haskey(A, "Time")
@test haskey(A, "X")
@test !haskey(A, Y)
@test !haskey(A, "Y")
# @test getkey(A, X) == x # == is not behaving correctly here.
x2 = getkey(A, X)
@test x2.val == x.val
@test_throws ErrorException getkey(A, Y)
