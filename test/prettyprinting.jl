using DimensionalData, Test
using DimensionalData: Time, Z, @dim
using Dates: DateTime, Month

# define dims with both long name and Type name
@dim Lon "Longitude" "lon"
@dim Lat "Latitude" "lat"

timespan = DateTime(2001):Month(1):DateTime(2001,12)
t = Time(timespan)
x = Lon(Vector(0.5:1.0:359.5))
y = Lat(Vector{Union{Float32, Missing}}(-89.5:1.0:89.5))
z = Z('a':'z')
d = (x, y, z, t)

A = DimensionalArray(rand(length.(d)...), d)
B = DimensionalArray(rand(length(x), length(y)), (x,y))
C = DimensionalArray(rand(length(x)), (x,))

# s1 = sprint(show, A)
# s2 = sprint(show, x)
# s3 = sprint(show, MIME("text/plain"), x)

# @test occursin("DimensionalArray with dimensions:", s1)
# @test occursin("X", s1)
# @test occursin("X:", s2)
# @test occursin("dimension X", s3)

# Test again but now with labelled array A
