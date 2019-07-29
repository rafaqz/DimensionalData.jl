using GeoArrayBase, Test, BenchmarkTools, CoordinateReferenceSystemsBase

using GeoArrayBase: subsetdim, val, basetype, sortdims

# Define a small GeoArray
a = [1 2; 3 4]
dimz = (LongDim((143, 145)), LatDim((-38, -36)))
g = GeoArray(a, dimz; crs=EPSGcode("EPSG:28992"))

# Make sure dimtypes is correct and sorts in the right order
@test dimtype(g) <: Tuple{<:LongDim,<:LatDim}
@test sortdims(g, (LatDim(1:2), LongDim(1))) == (LongDim(1), LatDim(1:2))

# getindex for single integers returns values
@test g[LongDim(1), LatDim(2)] == 2
@test g[LongDim(2), LatDim(2)] == 4
# for ranges it returns new GeoArray slices with the right dimensions
a = g[LongDim(1:2), LatDim(1)]
@test a == [1, 3]
@test typeof(a) <: GeoArray{Int,1}
@test dims(a) == (LongDim(143:2.0:145),)
@test refdims(a) == (LatDim(-38.0),)
@test crs(a) == EPSGcode("EPSG:28992")
@test bounds(a, LongDim()) == (143, 145)

a = g[LongDim(1), LatDim(1:2)]
@test a == [1, 2]
@test typeof(a) <: GeoArray{Int,1}
@test dims(a) == (LatDim(-38:2.0:-36),)
@test refdims(a) == (LongDim(143.0),)
@test crs(a) == EPSGcode("EPSG:28992")
# @test bounds(a, LongDim(), LatDim()) == (143, (-38, -36))

a = g[LatDim(:)]
@test a == [1 2; 3 4]
@test typeof(a) <: GeoArray{Int,2}
@test dims(a) == (LongDim(143:2.0:145), LatDim(-38:2.0:-36))
@test refdims(a) == ()
@test dimtype(a) <: Tuple{<:LongDim,<:LatDim}
@test crs(a) == EPSGcode("EPSG:28992")


# view() returns GeoArrays containing views
v = view(g, LatDim(1), LongDim(1))
@test v[] == 1
@test typeof(parent(v)) <:SubArray
@test dimtype(v) == Tuple{}
@test dims(v) == ()
@test refdims(v) == (LongDim(143.0), LatDim(-38.0))
@test crs(v) == EPSGcode("EPSG:28992")

v = view(g, LatDim(1), LongDim(1:2))
@test v == [1, 3]
@test typeof(parent(v)) <: SubArray
@test dimtype(v) <: Tuple{<:LongDim}
@test dims(v) == (LongDim(143:2.0:145),)
@test refdims(v) == (LatDim(-38.0),)
@test crs(v) == EPSGcode("EPSG:28992")

v = view(g, LatDim(1:2), LongDim(1))
@test v == [1, 2]
@test typeof(parent(v)) <: SubArray
@test dimtype(v) <: Tuple{<:LatDim}
@test dims(v) == (LatDim(-38:2.0:-36),)
@test refdims(v) == (LongDim(143.0),)
@test crs(v) == EPSGcode("EPSG:28992")


# @test lattitude(g, 1:2) == [-38.0, -36.0]
# @test longitude(g, 1:2) == [143.0, 145.0]
# @test vertical(g, 1:2) ==
# @test timespan(g, 1:2) ==



#####################################################################
# Benchmarks
#
# Test how much the recalculation of coordinates and dimtypes
# costs over standard getindex/view.
#
# Seems to be about 50% slower for small arrays sizes - so still really fast.

println("\n\nPerformance of view()\n")
vd1(g) = view(g, LongDim(1), LatDim(1))
vd2(g) = view(g, LongDim(:), LatDim(:))
vd3(g) = view(g, LongDim(1:2), LatDim(1:2))
vi1(g) = view(g.data, 1, 2)
vi2(g) = view(g.data, :, :)
vi3(g) = view(g.data, 1:2, 1:2)

println("Dims with Number")
@btime vd1(g)
println("Indices with Number")
@btime vi1(g)
println()
println("Dims with Colon")
@btime vd2(g)
println("Indices with Colon")
@btime vi2(g)
println()
println("Dims with UnitRange")
@btime vd3(g)
println("Indices with UnitRange")
@btime vi3(g)


println("\n\nPerformance of getindex()\n")
d1(g) = g[LatDim(1), LongDim(1)]
d2(g) = g[LatDim(:), LongDim(:)]
d3(g) = g[LatDim(1:2), LongDim(1:2)]
i1(g) = g.data[1, 1]
i2(g) = g.data[:, :]
i3(g) = g.data[1:2, 1:2]

println("Dims with Number")
@btime d1(g)
println("Indices with Number")
@btime i1(g)
println()
println("Dims with Colon")
@btime d2(g)
println("Indices with Colon")
@btime i2(g)
println()
println("Dims with UnitRange")
@btime d3(g)
println("Indices with UnitRange")
@btime i3(g)


using HDF5, Plots
datafile = "../DispersalScripts/spread_inputs_US_SWD.h5"
data = h5open(datafile, "r")
array = replace(read(data["x_y_month_intrinsicGrowthRate"]) , NaN => missing)
array = read(data["x_y_month_intrinsicGrowthRate"])
dimz = (LatDim((20.0, 50.0)), LongDim((80, 105)), TimeDim(1:12))
a = GeoArray(array, dimz; label="Growth rate")
ll = view(a, TimeDim(5))
lt = view(a, LatDim(35))
tl = permutedims(lt)
@test dims(lt) == reverse(dims(tl))
t = a[LongDim(25), LatDim(32)]

plot(ll)
plot(lt)
plot(tl)
plot(t)
# pyplot()
# gr()
