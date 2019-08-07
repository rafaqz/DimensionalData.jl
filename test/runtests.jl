using DimensionalData, Statistics, Test, BenchmarkTools

using DimensionalData: val, basetype, sortdims, flattendimtypes, 
      slicedims, dims2indices, formatdims, hasdim, mapdims, @dim


# Dims creation
@dim TestDim "Test dimension" "Testdim"

@test dimname(TestDim) == "Test dimension"
@test shortname(TestDim) == "Testdim"
@test val(TestDim(:test)) == :test


a = [1 2 3 4 
     2 3 4 5
     3 4 5 6
     4 5 6 7]
dimz = (Lon((143, 146)), Lat((-38, -32)))
dimz = formatdims(a, dimz) 
da = DimensionalArray(a, dimz)

@test dimz == (Lon((143.0:1.0:146.0)), Lat((-38.0:2.0:-32.0)))
@test dims(dimz) == dimz
@test dimtype(dimz) == Tuple{Lon{StepRangeLen{Float64,Base.TwicePrecision{Float64},Base.TwicePrecision{Float64}},Nothing},Lat{StepRangeLen{Float64,Base.
                             TwicePrecision{Float64},Base.TwicePrecision{Float64}},Nothing}}


# Dim primitives

                                   # dims                      # refdims 
@test slicedims(dimz, (1:2, 2)) == ((Lon((143.0:1.0:144.0)),), (Lat(-36.0),))
@test slicedims(dimz, (2:4, :)) == ((Lon((144.0:146.0)),        Lat(-38.0:2.0:-32.0)), ())

@test dims2indices(dimtype(dimz), (Lat,)) == (Colon(), Colon())
@test dims2indices(dimtype(dimz), (Lat(1),)) == (Colon(), 1)
@test dims2indices(dimtype(dimz), (Lat(2), Lon(3:7))) == (3:7, 2)
@test dims2indices(dimtype(dimz), (Lon(2), Lat([1, 3, 4]))) == (2, [1, 3, 4])
@test dims2indices(da, (Lon(2), Lat([1, 3, 4]))) == (2, [1, 3, 4])
@test_broken dims2indices(dimtype(dimz), (Lon(2), Time(4)))
# With emptyval=()
@test dims2indices(dimtype(dimz), (Lat,), ()) == ((), ())

@test dimnum(da, Lon) == 1
@test dimnum(da, Lat()) == 2
@test dimnum(da, (Lat, Lon())) == (2, 1)

@test mapdims(x->2x, Lon(3)) == Lon(6)
@test mapdims(x->x^2, (Lon(3), Time(10))) == (Lon(9), Time(100))

@test getdim(dimz, Lon) == dimz[1]
@test getdim(dimz, Lat) == dimz[2]
@test_throws ArgumentError getdim(dimz, Time)

@test hasdim(dimz, Time) == false
@test hasdim(dimz, Lon) == true
@test hasdim(da, Time()) == false
@test hasdim(da, Lon()) == true
@test hasdim(dimz, (Time(), Lat(), Lon())) == false
@test hasdim(dimz, (Lon, Lat)) == true
@test hasdim(typeof(dimz), Lon) == true
@test hasdim(typeof(dimz), Time) == false


a = [1 2; 3 4]
dimz = (Lon((143, 145)), Lat((-38, -36)))
g = DimensionalArray(a, dimz)

@test flattendimtypes(typeof(dimz))[1] <: Lon{<:Tuple,Nothing}
@test flattendimtypes(typeof(dimz))[2] <: Lat{<:Tuple,Nothing}
# Only deal with arrays and step ranges
@test flattendimtypes(typeof(dims(g)))[1] <: Lon{<:StepRangeLen,Nothing}
@test flattendimtypes(typeof(dims(g)))[2] <: Lat{<:StepRangeLen,Nothing}




# Make sure dimtypes is correct and sorts in the right order
@test dimtype(g) <: Tuple{<:Lon,<:Lat}
@test sortdims(g, (Lat(1:2), Lon(1))) == (Lon(1), Lat(1:2))

# getindex for single integers returns values
@test g[Lon(1), Lat(2)] == 2
@test g[Lon(2), Lat(2)] == 4
# for ranges it returns new DimensionArray slices with the right dimensions
a = g[Lon(1:2), Lat(1)]
@test a == [1, 3]
@test typeof(a) <: DimensionalArray{Int,1}
@test dims(a) == (Lon(143:2.0:145),)
@test refdims(a) == (Lat(-38.0),)
# @test bounds(a, Lon()) == (143, 145)

a = g[Lon(1), Lat(1:2)]
@test a == [1, 2]
@test typeof(a) <: DimensionalArray{Int,1}
@test dims(a) == (Lat(-38:2.0:-36),)
@test refdims(a) == (Lon(143.0),)
# @test bounds(a, Lon(), Lat()) == (143, (-38, -36))

a = g[Lat(:)]
@test a == [1 2; 3 4]
@test typeof(a) <: DimensionalArray{Int,2}
@test dims(a) == (Lon(143:2.0:145), Lat(-38:2.0:-36))
@test refdims(a) == ()
@test dimtype(a) <: Tuple{<:Lon,<:Lat}


# view() returns DimensionArray containing views
v = view(g, Lat(1), Lon(1));
@test v[] == 1
@test typeof(v) <: DimensionalArray{Int,0}
@test typeof(parent(v)) <:SubArray
@test dimtype(v) == Tuple{}
@test dims(v) == ()
@test refdims(v) == (Lon(143.0), Lat(-38.0))

v = view(g, Lat(1), Lon(1:2))
@test v == [1, 3]
@test typeof(v) <: DimensionalArray{Int,1}
@test typeof(parent(v)) <: SubArray
@test dimtype(v) <: Tuple{<:Lon}
@test dims(v) == (Lon(143:2.0:145),)
@test refdims(v) == (Lat(-38.0),)

v = view(g, Lat(1:2), Lon(1:1))
@test v == [1 2]
@test typeof(v) <: DimensionalArray{Int,2}
@test typeof(parent(v)) <: SubArray
@test dimtype(v) <: Tuple{<:Lon,<:Lat}
@test dims(v) == (Lon(143.0:2.0:143), Lat(-38:2.0:-36))

v = view(g, Lat(Base.OneTo(2)), Lon(1))
@test v == [1, 2]
@test typeof(parent(v)) <: SubArray
@test dimtype(v) <: Tuple{<:Lat}
@test dims(v) == (Lat(-38:2.0:-36),)
@test refdims(v) == (Lon(143.0),)


a = [1 2; 3 4]
dimz = (Lon((143, 145)), Lat((-38, -36)))
g = DimensionalArray(a, dimz)

# sum, mean etc with dims kwarg
@test sum(g; dims=Lon()) == sum(g; dims=1)
@test dims(sum(g; dims=Lat())) sum(g; dims=2) 
# @test prod(g; dims=Lon()) == [3, 8]
# @test prod(g; dims=Lat()) == [2, 12]
# @test maximum(g; dims=Lon()) == [3, 4]
# @test maximum(g; dims=Lat()) == [2, 4]
# @test minimum(g; dims=Lon()) == [1, 2]
# @test minimum(g; dims=Lat()) == [1, 3]
# @test mean(g; dims=Lon()) == [2.0, 3.0]
# @test mean(g; dims=Lat()) == [1.5, 3.5]
# @test std(g; dims=Lon()) == [1.4142135623730951, 1.4142135623730951]
# @test std(g; dims=Lat()) == [0.7071067811865476, 0.7071067811865476]
# @test var(g; dims=Lon()) == [2.0, 2.0]
# @test var(g; dims=Lat()) == [0.5, 0.5]



#####################################################################
# Benchmarks
#
# Test how much the recalculation of coordinates and dimtypes
# costs over standard getindex/view.
#
# Seems to be about 50% slower for small arrays sizes - so still really fast.

println("\n\nPerformance of view()\n")
vd1(g) = view(g, Lon(1), Lat(1))
vd2(g) = view(g, Lon(:), Lat(:))
vd3(g) = view(g, Lon(1:2), Lat(1:2))
vi1(g) = view(parent(g), 1, 2)
vi2(g) = view(parent(g), :, :)
vi3(g) = view(parent(g), 1:2, 1:2)

println("Dims with Number")
@btime vd1($g)
println("Parent indices with Number")
@btime vi1($g)
println()
println("Dims with Colon")
@btime vd2($g)
println("Parent indices with Colon")
@btime vi2($g)
println()
println("Dims with UnitRange")
@btime vd3($g)
println("Parent indices with UnitRange")
@btime vi3($g)


println("\n\nPerformance of getindex()\n")
d1(g) = g[Lat(1), Lon(1)]
d2(g) = g[Lat(:), Lon(:)]
d3(g) = g[Lat(1:2), Lon(1:2)]
i1(g) = parent(g)[1, 1]
i2(g) = parent(g)[:, :]
i3(g) = parent(g)[1:2, 1:2]

println("Dims with Number")
@btime d1($g)
println("Parent indices with Number")
@btime i1($g)
println()
println("Dims with Colon")
@btime d2($g)
println("Parent indices with Colon")
@btime i2($g)
println()
println("Dims with UnitRange")
@btime d3($g)
println("Parent indices with UnitRange")
@btime i3($g)
