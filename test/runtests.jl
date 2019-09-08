using DimensionalData, Statistics, Test, BenchmarkTools, Unitful

using DimensionalData: val, basetype, slicedims, dims2indices, formatdims, 
      @dim, reducedims, dimnum, basetype, X, Y, Z, Time, Forward


# Dims creation macro
@dim TestDim "Test dimension" 

@test name(TestDim) == "Test dimension"
@test shortname(TestDim) == "TestDim"
@test val(TestDim(:test)) == :test
@test metadata(TestDim(1, "metadata", Forward())) == "metadata"
@test units(TestDim) == ""
@test label(TestDim) == "Test dimension" 
@test eltype(TestDim(1)) == Int
@test eltype(TestDim([1,2,3])) == Vector{Int}
@test length(TestDim(1)) == 1
@test length(TestDim([1,2,3])) == 3


# Basic dim and array initialisation

a = ones(5, 4)
da = DimensionalArray(a, (X((140, 148)), Y((2, 11))))
dimz = dims(da)
@test slicedims(dimz, (2:4, 3)) == ((X(LinRange(142,146,3)),), (Y(8.0),))
@test name(dimz) == ("X", "Y") 
@test shortname(dimz) == ("X", "Y") 
@test units(dimz) == ("", "") 
@test label(dimz) == ("X, Y") 

a = [1 2 3 4 
     2 3 4 5
     3 4 5 6]
da = DimensionalArray(a, (X((143, 145)), Y((-38, -35))))
dimz = dims(da)

@test dimz == (X(LinRange(143, 145, 3)), Y(LinRange(-38, -35, 4)))
@test typeof(dimz) == Tuple{X{LinRange{Float64},Nothing,Forward},Y{LinRange{Float64},Nothing,Forward}}


# Dim Primitives

dz = (X(), Y())
@test permutedims((Y(1:2), X(1)), dz) == (X(1), Y(1:2))
@test permutedims((X(1),), dz) == (X(1), nothing)

@test permutedims((Y(), X()), dz) == (X(:), Y(:))
@test permutedims([Y(), X()], dz) == (X(:), Y(:))
@test permutedims((Y, X),     dz) == (X(:), Y(:))
@test permutedims([Y, X],     dz) == (X(:), Y(:))

@test permutedims(dz, (Y(), X())) == (Y(:), X(:))
@test permutedims(dz, [Y(), X()]) == (Y(:), X(:))
@test permutedims(dz, (Y, X)    ) == (Y(:), X(:))
@test permutedims(dz, [Y, X]    ) == (Y(:), X(:))


@test slicedims(dimz, (1:2, 3)) == ((X(LinRange(143,144,2)),), (Y(-36.0),))
@test slicedims(dimz, (2:3, :)) == ((X(LinRange(144,145,2)), Y(LinRange(-38.0,-35.0,4))), ())

emptyval = Colon()
@test dims2indices(dimz, (Y(),), emptyval) == (Colon(), Colon())
@test dims2indices(dimz, (Y(1),), emptyval) == (Colon(), 1)
# Time is just ignored if it's not in dims. Should this be an error?
@test dims2indices(dimz, (Time(4), X(2))) == (2, Colon())
@test dims2indices(dimz, (Y(2), X(3:7)), emptyval) == (3:7, 2)
@test dims2indices(dimz, (X(2), Y([1, 3, 4])), emptyval) == (2, [1, 3, 4])
@test dims2indices(da, (X(2), Y([1, 3, 4])), emptyval) == (2, [1, 3, 4])
emptyval=()
@test dims2indices(dimz, (Y,), emptyval) == ((), Colon())
@test dims2indices(dimz, (Y, X), emptyval) == (Colon(), Colon())
@test dims2indices(da, X, emptyval) == (Colon(), ())
@test dims2indices(da, (X<|At<|143.0, Y<|[1, 3, 4]), emptyval) == (1, [1, 3, 4])
@test dims2indices(da, (X<|Near<|142.5, Y<|Near<|[-37.8, -36.1, -35.3]), emptyval) == (1, [1, 3, 4])
@test dims2indices(da, (X<|Between(143, 145), Y<|Between(-37, -35.0)), emptyval) == (1:3, 2:4)

@test dimnum(da, X) == 1
@test dimnum(da, Y()) == 2
@test dimnum(da, (Y, X())) == (2, 1)

@test dims(dimz) === dimz
@test dims(dimz, X) === dimz[1]
@test dims(dimz, Y) === dimz[2]
@test_throws ArgumentError dims(dimz, Time)

@test reducedims((X(:), Y(1:5))) == (X(1), Y(1))


# Indexing: getindex/view with rebuild and dimension slicing 

a = [1 2; 3 4]
dimz = (X((143, 145)), Y((-38, -36)))
g = DimensionalArray(a, dimz)

# getindex for single integers returns values
@test g[X(1), Y(2)] == 2
@test g[X(2), Y(2)] == 4
# for ranges it returns new DimensionArray slices with the right dimensions
a = g[X(1:2), Y(1)]
@test a == [1, 3]
@test typeof(a) <: DimensionalArray{Int,1}
@test dims(a) == (X(LinRange(143.0, 145.0, 2)),)
@test refdims(a) == (Y(-38.0),)
@test bounds(a) == ((143.0, 145.0),)
@test bounds(a, X) == (143.0, 145.0)

a = g[X(1), Y(1:2)]
@test a == [1, 2]
@test typeof(a) <: DimensionalArray{Int,1}
@test typeof(parent(a)) <: Array{Int,1}
@test dims(a) == (Y(LinRange(-38, -36, 2)),)
@test refdims(a) == (X(143.0),)
@test bounds(a) == ((-38, -36),)
@test bounds(a, Y()) == (-38, -36)

a = g[Y(:)]

dims2indices(g, (Y(:),))
@test a == [1 2; 3 4]
@test typeof(a) <: DimensionalArray{Int,2}
@test typeof(parent(a)) <: Array{Int,2}
@test typeof(dims(a)) <: Tuple{<:X,<:Y}
@test dims(a) == (X(LinRange(143, 145, 2)), Y(LinRange(-38, -36, 2)))
@test refdims(a) == ()
@test bounds(a) == ((143, 145), (-38, -36))
@test bounds(a, X) == (143, 145)


# view() returns DimensionArray containing views
v = view(g, Y(1), X(1))
@test v[] == 1
@test typeof(v) <: DimensionalArray{Int,0}
@test typeof(parent(v)) <:SubArray{Int,0}
@test typeof(dims(v)) == Tuple{}
@test dims(v) == ()
@test refdims(v) == (X(143.0), Y(-38.0))
@test bounds(v) == ()

v = view(g, Y(1), X(1:2))
@test v == [1, 3]
@test typeof(v) <: DimensionalArray{Int,1}
@test typeof(parent(v)) <: SubArray{Int,1}
@test typeof(dims(v)) <: Tuple{<:X}
@test dims(v) == (X(LinRange(143, 145, 2)),)
@test refdims(v) == (Y(-38.0),)
@test bounds(v) == ((143.0, 145.0),)

v = view(g, Y(1:2), X(1:1))
@test v == [1 2]
@test typeof(v) <: DimensionalArray{Int,2}
@test typeof(parent(v)) <: SubArray{Int,2}
@test typeof(dims(v)) <: Tuple{<:X,<:Y}
@test dims(v) == (X(LinRange(143.0, 143.0, 1)), Y(LinRange(-38, -36, 2)))
@test bounds(v) == ((143.0, 143.0), (-38.0, -36.0))

v = view(g, Y(Base.OneTo(2)), X(1))
@test v == [1, 2]
@test typeof(parent(v)) <: SubArray{Int,1}
@test typeof(dims(v)) <: Tuple{<:Y}
@test dims(v) == (Y(LinRange(-38, -36, 2)),)
@test refdims(v) == (X(143.0),)
@test bounds(v) == ((-38.0, -36.0),)

x = [1 2; 3 4]

# Arbitrary dimension names also work
a = [1 2 3 4 
     3 4 5 6 
     4 5 6 7]
dimz = (Dim{:row}((10, 30)), Dim{:column}((-20, 10)))
da = DimensionalArray(a, dimz)
@test name(dimz) == ("Dim row", "Dim column")
@test shortname(dimz) == ("row", "column")
@test label(dimz) == ("Dim row, Dim column")
@test da[Dim{:row}(2)] == [3, 4, 5, 6]
@test da[Dim{:column}(4)] == [4, 6, 7]
@test da[Dim{:column}(1), Dim{:row}(3)] == 4

# size and axes
@test size(da, Dim{:row}) == 3  
@test size(da, Dim{:column}()) == 4  
@test axes(da, Dim{:row}()) == 1:3  
@test axes(da, Dim{:column}) == 1:4  

# dropdims
@test dropdims(da[Dim{:column}(1:1)]; dims=Dim{:column}()) == [1, 3, 4]
@test dropdims(da[3:3, 2:2]; dims=(Dim{:row}(), Dim{:column}()))[] == 5
# TODO: test refdims after dropdims
@test typeof(dropdims(da[3:3, 2:2]; dims=(Dim{:row}(), Dim{:column}()))) <: DimensionalArray{Int,0,Tuple{}}


# Dimension reducing methods

a = [1 2; 3 4]
dimz = (X((143, 145)), Y((-38, -36)))
da = DimensionalArray(a, dimz)

# sum, mean etc with dims kwarg
@test sum(da; dims=X) == sum(da; dims=1)
@test sum(da; dims=Y()) == sum(da; dims=2) 
@test dims(sum(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(LinRange(-38.0, -38.0, 1)))
@test prod(da; dims=X) == [3 8]
@test prod(da; dims=Y()) == [2 12]'
@test dims(prod(da; dims=X())) == (X(LinRange(143.0, 143.0, 1)), Y(LinRange(-38.0, -36.0, 2)))
@test maximum(da; dims=X) == [3 4]
@test maximum(da; dims=Y()) == [2 4]'
@test minimum(da; dims=X) == [1 2]
@test minimum(da; dims=Y()) == [1 3]'
@test dims(minimum(da; dims=X())) == (X(LinRange(143.0, 143.0, 1)), Y(LinRange(-38.0, -36.0, 2)))
@test mean(da; dims=X) == [2.0 3.0]
@test mean(da; dims=Y()) == [1.5 3.5]'
@test dims(mean(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(LinRange(-38.0, -38.0, 1)))
@test reduce(+, da; dims=X) == [4 6]
@test reduce(+, da; dims=Y()) == [3 7]'
@test dims(reduce(+, da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(LinRange(-38.0, -38.0, 1)))
@test mapreduce(x-> x > 3, +, da; dims=X) == [0 1]
@test mapreduce(x-> x > 3, +, da; dims=Y()) == [0 1]'
@test dims(mapreduce(x-> x > 3, +, da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(LinRange(-38.0, -38.0, 1)))
@test std(da; dims=X()) == [1.4142135623730951 1.4142135623730951]
@test std(da; dims=Y()) == [0.7071067811865476 0.7071067811865476]'
@test var(da; dims=X()) == [2.0 2.0]
@test var(da; dims=Y()) == [0.5 0.5]'
@test dims(var(da; dims=Y())) == (X(LinRange(143.0, 145.0, 2)), Y(LinRange(-38.0, -38.0, 1)))
a = [1 2 3; 4 5 6]
da = DimensionalArray(a, dimz)
@test median(da; dims=Y()) == [2.0 5.0]'
@test median(da; dims=X()) == [2.5 3.5 4.5]

# mapslices
a = [1 2 3 4
     3 4 5 6
     5 6 7 8]
da = DimensionalArray(a, (Y(10:30), Time(1:4)))
ms = mapslices(sum, da; dims=Y)
@test ms == [9 12 15 18]
@test dims(ms) == (Time(LinRange(1.0, 4.0, 4)),)
@test refdims(ms) == (Y(10.0),)
ms = mapslices(sum, da; dims=Time)
@test parent(ms) == [10 18 26]'
@test dims(ms) == (Y(LinRange(10.0, 30.0, 3)),)
@test refdims(ms) == (Time(1.0),)

# Iteration methods

if VERSION > v"1.1-"
    # eachslice
    da = DimensionalArray(a, (Y(10:30), Time(1:4)))
    @test [mean(s) for s in eachslice(da; dims=Time)] == [3.0, 4.0, 5.0, 6.0]
    slices = [s .* 2 for s in eachslice(da; dims=Y)] 
    @test slices[1] == [2, 4, 6, 8]
    @test slices[2] == [6, 8, 10, 12]
    @test slices[3] == [10, 12, 14, 16]
    dims(slices[1]) == (Time(1.0:1.0:4.0),)
    slices = [s .* 2 for s in eachslice(da; dims=Time)] 
    @test slices[1] == [2, 6, 10]
    dims(slices[1]) == (Y(10.0:10.0:30.0),)
end


# Dimension reordering methods

da = DimensionalArray(zeros(5, 4), (Y(10:20), X(1:4)))
tda = transpose(da)
@test dims(tda) == (X(LinRange(1.0, 4.0, 4)), Y(LinRange(10.0, 20.0, 5)))
@test size(tda) == (4, 5)
ada = adjoint(da)
@test dims(ada) == (X(LinRange(1.0, 4.0, 4)), Y(LinRange(10.0, 20.0, 5)))
@test size(ada) == (4, 5)

# Array dispatch
dsp = permutedims(da)
@test parent(dsp) == permutedims(parent(da))
@test dims(dsp) == reverse(dims(da))
da = DimensionalArray(ones(5, 2, 4), (Y(10:20), Time(10:11), X(1:4)))
dsp = permutedims(da, [3, 1, 2])
# Dim dispatch arg possibilities
dsp = permutedims(da, [X, Y, Time])
dsp = permutedims(da, (X, Y, Time))
dsp = permutedims(da, [X(), Y(), Time()])
dsp = permutedims(da, (X(), Y(), Time()))

@test dims(dsp) == (X(LinRange(1.0, 4.0, 4)), Y(LinRange(10.0, 20.0, 5)), Time(LinRange(10.0, 11.0, 2)))


# Dimension mirroring methods

# Need to think about dims for these, currently (Y, Y) etc.
# But you can't currently index (Y, Y) with dims as you get the
# first Y both times. It will plot correctly at least.
a = rand(5, 4)
da = DimensionalArray(a, (Y(10:20), X(1:4)))

cvda = cov(da; dims=X)
@test cvda == cov(a; dims=2)
@test dims(cvda) == (X(LinRange(1.0, 4.0, 4)), X(LinRange(1.0, 4.0, 4)))
crda = cor(da; dims=Y)
@test crda == cor(a; dims=1)
@test dims(crda) == (Y(LinRange(10.0, 20.0, 5)), Y(LinRange(10.0, 20.0, 5)))

# These need fixes in base. kwargs are ::Integer so we can't add methods
# or dispatch on AbstractDimension in underscore _methods
accumulate
cumsum
cumprod


# Broadcast 
da = DimensionalArray(ones(5, 2, 4), (Y(10:20), Time(10:11), X(1:4)))
da2 = da .* 2
@test da2 == ones(5, 2, 4) .* 2
@test dims(da2) == (Y(LinRange(10, 20, 5)), Time(LinRange(10.0, 11.0, 2)), X(LinRange(1.0, 4.0, 4)))


# Select -- also with Unitful units
a = [1 2  3  4
     5 6  7  8
     9 10 11 12]
da = DimensionalArray(a, (Y(10:30), Time((1:4)u"s")))
# At() is the default
@test da[Y<|At([10, 30]), Time<|At([1u"s", 4u"s"])] == [1 4; 9 12]
@test_throws ArgumentError da[Y<|At([9, 30]), Time<|At([1u"s", 4u"s"])]
@test view(da, Y<|At(20), Time<|At((3:4)u"s")) == [7, 8]
@test view(da, Y<|Near(17), Time<|Near([1.3u"s", 3.3u"s"])) == [5, 7]
@test view(da, Y<|Between(9, 31), Time<|At((3:4)u"s")) == [3 4; 7 8; 11 12]
# without dim wrappers
@test da[At(20:10:30), At(1u"s")] == [5, 9]
@test view(da, Between(9, 31), Near((3:4)u"s")) == [3 4; 7 8; 11 12]
# Mixed selector/index
@test view(da, Near(22), At(3u"s", 4u"s")) == [7, 8]

# Direct select without dims
@test view(da, At(20), At((2:3)u"s")) == [6, 7]
@test view(da, Near<|13, Near<|[1.3u"s", 3.3u"s"]) == [1, 3]
# Near works with a tuple input
@test view(da, Near<|(13,), Near<|(1.3u"s", 3.3u"s")) == [1 3]
@test view(da, Between(11, 20), At((2:3)u"s")) == [6 7]
# Between also accepts a tuple input
@test view(da, Between((11, 20)), Between(2u"s", 3u"s")) == [6 7]

# setindex!
da[Near(11), At(3u"s")] = 100
@test a[1, 3] == 100
da[Time<|Near(2.2u"s"), Y<|Between(10, 30)] = [200, 201, 202]
@test a[1:3, 2] == [200, 201, 202] 

# More Unitful dims
a = [1 2  3  4
     5 6  7  8
     9 10 11 12]
dimz = Time<|1.0u"s":1.0u"s":3.0u"s", Y<|(1u"km", 4u"km")
da = DimensionalArray(a, dimz)
@test da[Y<|Between(2u"km", 3.9u"km"), Time<|At<|3.0u"s"] == [10, 11]

# Ad-hoc categorical indices. Syntax could be simplified?
dimz = Time<|[:one, :two, :three], Y<|[:a, :b, :c, :d]
da = DimensionalArray(a, dimz)
@test da[Time<|At(:one, :two), Y<|At(:b)] == [2, 6]
@test da[At([:one, :three]), At([:b, :c, :d])] == [2 3 4; 10 11 12]


#= Benchmarks

Test how much the recalculation of coordinates and dim types
costs over standard getindex/view.

Indexing with Y(1) has no overhead at all, but ranges
have an overhead for constructing the neew GeoArray and slicing
the dimensions.
=#

g = DimensionalArray(rand(100, 50), (X(51:150), Y(-40:9)))

println("\n\nPerformance of view()\n")
vi1(g) = view(parent(g), 1, 2)
vd1(g) = view(g, X(1), Y(2))
vi2(g) = view(parent(g), :, :)
vd2(g) = view(g, X(:), Y(:))
vi3(g) = view(parent(g), 10:40, 1:20)
vd3(g) = view(g, X(10:40), Y(1:20))

println("Parent indices with Number")
@btime vi1($g)
println("Dims with Number")
@btime vd1($g)
println()
println("Parent indices with Colon")
@btime vi2($g);
println("Dims with Colon")
@btime vd2($g);
println()
println("Parent indices with UnitRange")
@btime vi3($g);
println("Dims with UnitRange")
@btime vd3($g);

println("\n\nPerformance of getindex()\n")
i1(g) = parent(g)[10, 20]
d1(g) = g[Y(10), X(20)]
i2(g) = parent(g)[:, :]
d2(g) = g[Y(:), X(:)]
i3(g) = parent(g)[1:20, 10:40]
d3(g) = g[Y(1:20), X(10:40)]

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
@btime d3($g);

a = rand(5, 4, 3);
da = DimensionalArray(a, (Y((1u"m", 5u"m")), X(1:4), Time(1:3)))
dimz = dims(da)

if VERSION > v"1.1-"
    println("\n\neachslice: normal, numbers + rebuild, dims + rebuild")
    @btime (() -> eachslice($a; dims=2))();
    @btime (() -> eachslice($da; dims=2))();
    @btime (() -> eachslice($da; dims=Y))();
    println("eachslice to vector: normal, numbers + rebuild, dims + rebuild")
    @btime [slice for slice in eachslice($a; dims=2)];
    @btime [slice for slice in eachslice($da; dims=2)];
    @btime [slice for slice in eachslice($da; dims=X)];
    @test [slice for slice in eachslice(da; dims=1)] == [slice for slice in eachslice(da; dims=Y)]
end


println("\n\nmean: normal, numbers + rebuild, dims + rebuild")
@btime mean($a; dims=2);
@btime mean($da; dims=2);
@btime mean($da; dims=X);
println("permutedims: normal, numbers + rebuild, dims + rebuild")
@btime permutedims($a, (2, 1, 3))
@btime permutedims($da, (2, 1, 3))
@btime permutedims($da, (Y(), X(), Time()))
println("reverse: normal, numbers + rebuild, dims + rebuild")
@btime reverse($a; dims=1) 
@btime reverse($da; dims=1) 
@btime reverse($da; dims=Y) 
