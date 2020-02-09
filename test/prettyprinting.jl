using DimensionalData, Test
using Dates: DateTime, Month

# define dims with both long name and Type name
@dim Lon "Longitude" "lon"
@dim Lat "Latitude" "lat"

timespan = DateTime(2001):Month(1):DateTime(2001,12)
t = Ti(timespan)
x = Lon(Vector(0.5:1.0:359.5))
y = Lat(Vector{Union{Float32, Missing}}(-89.5:1.0:89.5))
z = Z('a':'z')
d = (x, y, z, t)

A = DimensionalArray(rand(length.(d)...), d)
a = DimensionalArray(rand(length(x), length(y)), (x,y))
B = DimensionalArray(rand(length(x)), (x,))

s1 = sprint(show, A)
s2 = sprint(show, x)
s3 = sprint(show, MIME("text/plain"), x)

@test occursin("DimensionalArray", s1)
for s in (s1, s2, s3)
    @test occursin("Lon", s)
    @test occursin("Longitude", s)
end

# Test again but now with labelled array A
