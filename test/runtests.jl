using DimensionalData, Statistics, Test, BenchmarkTools

using DimensionalData: val, basetype, sortdims, slicedims, 
      dims2indices, formatdims, hasdim, mapdims, @dim,
      otherdimnums, reduceindices, dimnum, basetype


# Dims creation macro
@dim TestDim "Test dimension" 

@test dimname(TestDim) == "Test dimension"
@test shortname(TestDim) == "TestDim"
@test val(TestDim(:test)) == :test
@test metadata(TestDim(1, "metadata")) == "metadata"


# Basic dim and array initialisation

a = ones(5, 4)
da = DimensionalArray(a, (Lon((140, 148)), Lat((2, 11))))
dimz = dims(da)
@test slicedims(dimz, (2:4, 3)) == ((Lon(LinRange(142,146,3)),), (Lat(8.0),))

a = [1 2 3 4 
     2 3 4 5
     3 4 5 6]
da = DimensionalArray(a, (Lon((143, 145)), Lat((-38, -35))))
dimz = dims(da)

@test dimz == (Lon(LinRange(143, 145, 3)), Lat(LinRange(-38, -35, 4)))
@test dimtype(dimz) == Tuple{Lon{LinRange{Float64},Nothing},Lat{LinRange{Float64},Nothing}}

# Primitives
                                   # dims                      # refdims 
@test slicedims(dimz, (1:2, 3)) == ((Lon(LinRange(143,144,2)),), (Lat(-36.0),))
@test slicedims(dimz, (2:3, :)) == ((Lon(LinRange(144,145,2)), Lat(LinRange(-38.0,-35.0,4))), ())

@test dims2indices(dimtype(dimz), (Lat,)) == (Colon(), Colon())
@test dims2indices(dimtype(dimz), (Lat(1),)) == (Colon(), 1)
@test dims2indices(dimtype(dimz), (Lat(2), Lon(3:7))) == (3:7, 2)
@test dims2indices(dimtype(dimz), (Lon(2), Lat([1, 3, 4]))) == (2, [1, 3, 4])
@test dims2indices(da, (Lon(2), Lat([1, 3, 4]))) == (2, [1, 3, 4])
@test_broken dims2indices(dimtype(dimz), (Lon(2), Time(4)))
emptyval=()
@test dims2indices(dimtype(dimz), (Lat,), emptyval) == ((), ())

@test dimnum(da, Lon) == 1
@test dimnum(da, Lat()) == 2
@test dimnum(da, (Lat, Lon())) == (2, 1)

@test mapdims(x->2x, Lon(3)) == Lon(6)
@test mapdims(x->x^2, (Lon(3), Time(10))) == (Lon(9), Time(100))

@test getdim(dimz, Lon) == dimz[1]
@test getdim(dimz, Lat) == dimz[2]
@test_throws ArgumentError getdim(dimz, Time)

# Not being used currently
# @test hasdim(dimz, Time) == false
# @test hasdim(dimz, Lon) == true
# @test hasdim(da, Time()) == false
# @test hasdim(da, Lon()) == true
# @test hasdim(dimz, (Time(), Lat(), Lon())) == false
# @test hasdim(dimz, (Lon, Lat)) == true
# @test hasdim(typeof(dimz), Lon) == true
# @test hasdim(typeof(dimz), Time) == false

a = [1 2; 3 4]
dimz = (Lon((143, 145)), Lat((-38, -36)))
g = DimensionalArray(a, dimz)

@test sortdims(g, (Lat(1:2), Lon(1))) == (Lon(1), Lat(1:2))

@test otherdimnums(5, (1, 3)) == (2, 4, 5)
@test reduceindices(2, 1) == (1, Colon())
@test reduceindices(g, 2) == (Colon(), 1)



# Indexing: getindex/view with rebuild and dimension slicing 

# getindex for single integers returns values
@test g[Lon(1), Lat(2)] == 2
@test g[Lon(2), Lat(2)] == 4
# for ranges it returns new DimensionArray slices with the right dimensions
a = g[Lon(1:2), Lat(1)]
@test a == [1, 3]
@test typeof(a) <: DimensionalArray{Int,1}
@test dims(a) == (Lon(LinRange(143.0, 145.0, 2)),)
@test refdims(a) == (Lat(-38.0),)
# @test bounds(a, Lon()) == (143, 145)

a = g[Lon(1), Lat(1:2)]
@test a == [1, 2]
@test typeof(a) <: DimensionalArray{Int,1}
@test dims(a) == (Lat(LinRange(-38, -36, 2)),)
@test refdims(a) == (Lon(143.0),)
# @test bounds(a, Lon(), Lat()) == (143, (-38, -36))

a = g[Lat(:)]
@test a == [1 2; 3 4]
@test typeof(a) <: DimensionalArray{Int,2}
@test dims(a) == (Lon(LinRange(143, 145, 2)), Lat(LinRange(-38, -36, 2)))
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
@test dims(v) == (Lon(LinRange(143, 145, 2)),)
@test refdims(v) == (Lat(-38.0),)

v = view(g, Lat(1:2), Lon(1:1))
@test v == [1 2]
@test typeof(v) <: DimensionalArray{Int,2}
@test typeof(parent(v)) <: SubArray
@test dimtype(v) <: Tuple{<:Lon,<:Lat}
@test dims(v) == (Lon(LinRange(143.0, 143, 1)), Lat(LinRange(-38, -36, 2)))

v = view(g, Lat(Base.OneTo(2)), Lon(1))
@test v == [1, 2]
@test typeof(parent(v)) <: SubArray
@test dimtype(v) <: Tuple{<:Lat}
@test dims(v) == (Lat(LinRange(-38, -36, 2)),)
@test refdims(v) == (Lon(143.0),)


# Arbitrary dimension names also work
a = [1 2 3 4 
     3 4 5 6 
     4 5 6 7]
dimz = (Dim{:row}((10, 30)), Dim{:column}((-20, 10)))
g = DimensionalArray(a, dimz)
@test g[Dim{:row}(2)] == [3, 4, 5, 6]
@test g[Dim{:column}(4)] == [4, 6, 7]
@test g[Dim{:column}(1), Dim{:row}(3)] == 4

# Dimension reducing methods

a = [1 2 
     3 4]
dimz = (Lon((143, 145)), Lat((-38, -36)))
g = DimensionalArray(a, dimz)

# sum, mean etc with dims kwarg
@test sum(g; dims=Lon()) == sum(g; dims=1)
@test sum(g; dims=Lat()) == sum(g; dims=2) 
@test dims(sum(g; dims=Lat())) == (Lon(LinRange(143.0, 145.0, 2)), Lat(LinRange(-38.0, -38.0, 1)))
@test prod(g; dims=Lon()) == [3 8]
@test prod(g; dims=Lat()) == [2 12]'
@test dims(prod(g; dims=Lon())) == (Lon(LinRange(143.0, 143.0, 1)), Lat(LinRange(-38.0, -36.0, 2)))
@test maximum(g; dims=Lon()) == [3 4]
@test maximum(g; dims=Lat()) == [2 4]'
@test minimum(g; dims=Lon()) == [1 2]
@test minimum(g; dims=Lat()) == [1 3]'
@test dims(minimum(g; dims=Lon())) == (Lon(LinRange(143.0, 143.0, 1)), Lat(LinRange(-38.0, -36.0, 2)))
@test mean(g; dims=Lon()) == [2.0 3.0]
@test mean(g; dims=Lat()) == [1.5 3.5]'
@test dims(mean(g; dims=Lat())) == (Lon(LinRange(143.0, 145.0, 2)), Lat(LinRange(-38.0, -38.0, 1)))

@test std(g; dims=Lon()) == [1.4142135623730951 1.4142135623730951]
@test std(g; dims=Lat()) == [0.7071067811865476 0.7071067811865476]'
@test var(g; dims=Lon()) == [2.0 2.0]
@test var(g; dims=Lat()) == [0.5 0.5]'
@test dims(var(g; dims=Lat())) == (Lon(LinRange(143.0, 145.0, 2)), Lat(LinRange(-38.0, -38.0, 1)))

# mapslices
a = [1 2 3 4
     3 4 5 6
     5 6 7 8]
da = DimensionalArray(a, (Lat(10:30), Time(1:4)))
ms = mapslices(sum, da; dims=Lat)
@test ms == [9 12 15 18]
@test dims(ms) == (Time(LinRange(1.0, 4.0, 4)),)
@test refdims(ms) == (Lat(10.0),)
ms = mapslices(sum, da; dims=Time)
@test ms == [10 18 25]'
@test dims(ms) == (Lat(LinRange(10.0, 30.0, 3)),)
@test refdims(ms) == (Time(1.0),)


# Iteration methods

# eachslice
da = DimensionalArray(a, (Lat(10:30), Time(1:4)))
@test [mean(s) for s in eachslice(da; dims=Time)] == [3.0, 4.0, 5.0, 6.0]
slices = [s .* 2 for s in eachslice(da; dims=Lat)] 
@test slices[1] == [2, 4, 6, 8]
@test slices[2] == [6, 8, 10, 12]
@test slices[3] == [10, 12, 14, 16]
dims(slices[1]) == (Time(1.0:1.0:4.0),)
slices = [s .* 2 for s in eachslice(da; dims=Time)] 
@test slices[1] == [2, 6, 10]
dims(slices[1]) == (Lat(10.0:10.0:30.0),)


# Dimension reordering methods

da = DimensionalArray(zeros(5, 4), (Lat(10:20), Lon(1:4)))
tda = transpose(da)
@test dims(tda) == (Lon(LinRange(1.0, 4.0, 4)), Lat(LinRange(10.0, 20.0, 5)))
@test size(tda) == (4, 5)
ada = adjoint(da)
@test dims(ada) == (Lon(LinRange(1.0, 4.0, 4)), Lat(LinRange(10.0, 20.0, 5)))
@test size(ada) == (4, 5)
dsp = permutedims(da)
@test parent(dsp) == permutedims(parent(da))
@test dims(dsp) == reverse(dims(da))
da = DimensionalArray(ones(5, 2, 4), (Lat(10:20), Time(10:11), Lon(1:4)))
dsp = permutedims(da, [3, 1, 2])
dsp = permutedims(da, [Lon, Lat, Time])
@test dims(dsp) == (Lon(LinRange(1.0, 4.0, 4)), Lat(LinRange(10.0, 20.0, 5)), Time(LinRange(10.0, 11.0, 2)))


# Dimension mirroring methods

# Need to think about dims for these, currently (Lat, Lat) etc.
# But you can't index (Lat, Lat). It will plot correctly at least
a = rand(5, 4)
da = DimensionalArray(a, (Lat(10:20), Lon(1:4)))
cvda = cov(da; dims=Lon)
@test cvda == cov(a; dims=2)
crda = cor(da; dims=Lat)
@test crda == cor(a; dims=1)

# These need fixes in base. kwargs are ::Integer so we can't add methods
# or dispatch on AbstractDimension in underscore _methods
accumulate
cumsum
cumprod


# Broadcast 

da = DimensionalArray(ones(5, 2, 4), (Lat(10:20), Time(10:11), Lon(1:4)))
da2 = da .* 2
@test da2 == ones(5, 2, 4) .* 2
@test dims(da2) == (Lat(LinRange(10, 20, 5)), Time(LinRange(10.0, 11.0, 2)), Lon(LinRange(1.0, 4.0, 4)))

#= Benchmarks

Test how much the recalculation of coordinates and dimtypes
costs over standard getindex/view.

Indexing with Lat(1) has no overhead at all, but ranges
have an overhead for constructing the neew GeoArray and slicing
the dimensions.
=#

g = DimensionalArray(rand(100, 50), (Lon(51:150), Lat(-40:9)))

println("\n\nPerformance of view()\n")
vi1(g) = view(parent(g), 1, 2)
vd1(g) = view(g, Lon(1), Lat(2))
vi2(g) = view(parent(g), :, :)
vd2(g) = view(g, Lon(:), Lat(:))
vi3(g) = view(parent(g), 10:40, 1:20)
vd3(g) = view(g, Lon(10:40), Lat(1:20))

println("Parent indices with Number")
@btime vi1($g)
println("Dims with Number")
@btime vd1($g)
println()
println("Parent indices with Colon")
@btime vi2($g)
println("Dims with Colon")
@btime vd2($g)
println()
println("Parent indices with UnitRange")
@btime vi3($g)
println("Dims with UnitRange")
@btime vd3($g)


println("\n\nPerformance of getindex()\n")
i1(g) = parent(g)[10, 20]
d1(g) = g[Lat(10), Lon(20)]
i2(g) = parent(g)[:, :]
d2(g) = g[Lat(:), Lon(:)]
i3(g) = parent(g)[1:20, 10:40]
d3(g) = g[Lat(1:20), Lon(10:40)]

println("Parent indices with Number")
@btime i1($g)
println("Dims with Number")
@btime d1($g)
println()
println("Parent indices with Colon")
@btime i2($g)
println("Dims with Colon")
@btime d2($g)
println()
println("Parent indices with UnitRange")
@btime i3($g)
println("Dims with UnitRange")
@btime d3($g)

