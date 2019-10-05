#= Benchmarks

Test how much the recalculation of coordinates and dim types
costs over standard getindex/view.

Indexing with Y(1) has no overhead at all, but ranges
have an overhead for slicing the dimensions.
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
