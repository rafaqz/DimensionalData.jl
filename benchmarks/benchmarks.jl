BENCHMARK_ENV = abspath((@__DIR__) * "/..")
BENCHMARK_RESULTS_DIR = (@__DIR__) * "/results"
PACKAGE_DIR = BENCHMARK_ENV

using Pkg
Pkg.activate(BENCHMARK_ENV)

using DimensionalData, BenchmarkTools, Unitful, SparseArrays, Dates, Statistics, LibGit2

if !isdir(BENCHMARK_RESULTS_DIR)
    mkdir(BENCHMARK_RESULTS_DIR)
end

# Utils

"""Generate a path for benchmarking results using current repository status"""
function gen_results_pth()
    repo = LibGit2.GitRepo(PACKAGE_DIR)
    head = LibGit2.head(repo)
    branchname = replace(LibGit2.shortname(head), "/" => "\\/")  # Normalize paths
    hash_str = string(LibGit2.GitHash(LibGit2.peel(LibGit2.GitCommit, head)))
    basename = "$(BENCHMARK_RESULTS_DIR)/$(branchname)-$(hash_str)"
    if LibGit2.isdirty(repo)
        basename *= "-dirty"
    end
    if isfile(basename * ".json")
        i = 1
        while isfile(basename * "-$i.json")
            i += 1
        end
        basename *= "-$i"
    end
    basename *= ".json"
end


#= Benchmarks

Test how much the recalculation of coordinates and dim types
costs over standard getindex/view.

Indexing with Y(1) has no overhead at all, but ranges
have an overhead for slicing the dimensions. =#

const suite = BenchmarkGroup()

suite["view"] = BenchmarkGroup(["view"])
g = DimArray(rand(100, 50), (X(51:150), Y(-40:9)))

vi1(g) = view(data(g), 1, 2)
vd1(g) = view(g, X(1), Y(2))
vi2(g) = view(data(g), :, :)
vd2(g) = view(g, X(:), Y(:))
vi3(g) = view(data(g), 10:40, 1:20)
vd3(g) = view(g, X(10:40), Y(1:20))

suite["view"]["Parent indices with Number"] = @benchmarkable vi1($g)
suite["view"]["Dims with Number"] = @benchmarkable vd1($g)
suite["view"]["Parent indices with Colon"] = @benchmarkable vi2($g);
suite["view"]["Dims with Colon"] = @benchmarkable vd2($g);
suite["view"]["Parent indices with UnitRange"] = @benchmarkable vi3($g);
suite["view"]["Dims with UnitRange"] = @benchmarkable vd3($g);

suite["getindex"] = BenchmarkGroup()
i1(g) = data(g)[10, 20]
d1(g) = g[Y(10), X(20)]
i2(g) = data(g)[:, :]
d2(g) = g[Y(:), X(:)]
i3(g) = data(g)[1:20, 10:40]
d3(g) = g[Y(1:20), X(10:40)]

suite["getindex"]["Parent indices with Number"] = @benchmarkable i1($g)
suite["getindex"]["Dims with Number"] = @benchmarkable d1($g)
suite["getindex"]["Parent indices with Colon"] = @benchmarkable i2($g)
suite["getindex"]["Dims with Colon"] = @benchmarkable d2($g)
suite["getindex"]["Parent indices with UnitRange"] = @benchmarkable i3($g)
suite["getindex"]["Dims with UnitRange"] = @benchmarkable d3($g);

a = rand(5, 4, 3);
da = DimArray(a, (Y((1u"m", 5u"m")), X(1:4), Ti(1:3)))
dimz = dims(da)

suite["eachslice"] = BenchmarkGroup()
suite["eachslice"]["array_intdim"] = @benchmarkable (()->eachslice($a; dims = 2))();
suite["eachslice"]["dimarray_intdim"] = @benchmarkable (()->eachslice($da; dims = 2))();
suite["eachslice"]["dimarray_dim"] = @benchmarkable (()->eachslice($da; dims = Y()))();
suite["eachslice_to_vector"] = BenchmarkGroup()
suite["eachslice_to_vector"]["array_intdim"] = @benchmarkable [slice for slice in eachslice($a; dims = 2)];
suite["eachslice_to_vector"]["dimarray_intdim"] = @benchmarkable [slice for slice in eachslice($da; dims = 2)];
suite["eachslice_to_vector"]["dimarray_dim"] = @benchmarkable [slice for slice in eachslice($da; dims = X())];
# @test [slice for slice in eachslice(da; dims=1)] == [slice for slice in eachslice(da; dims=Y)]



suite["mean"] = BenchmarkGroup()
suite["mean"]["array_intdim"] = @benchmarkable mean($a; dims = 2);
suite["mean"]["dimarray_intdim"] = @benchmarkable mean($da; dims = 2);
suite["mean"]["dimarray_dim"] = @benchmarkable mean($da; dims = X());
suite["permutedims"] = BenchmarkGroup()
suite["permutedims"]["array_intdim"] = @benchmarkable permutedims($a, (2, 1, 3))
suite["permutedims"]["dimarray_intdim"] = @benchmarkable permutedims($da, (2, 1, 3))
suite["permutedims"]["dimarray_dim"] = @benchmarkable permutedims($da, (Y(), X(), Ti()))
suite["reverse"] = BenchmarkGroup()
suite["reverse"]["array_intdim"] = @benchmarkable reverse($a; dims = 1)
suite["reverse"]["dimarray_intdim"] = @benchmarkable reverse($da; dims = 1)
suite["reverse"]["dimarray_dim"] = @benchmarkable reverse($da; dims = Y())

# Sparse (and similar specialised arrays)

@dim Var "Variable"
@dim Obs "Observation"

sparse_a = sprand(1000, 1000, 0.1)
sparse_d = DimArray(sparse_a, (Var <| 1:1000, Obs <| 1:1000))

suite["sparse"] = BenchmarkGroup()
# Benchmarks
suite["sparse"]["mean with dims arge: regular sparse"] = @benchmarkable mean($sparse_a, dims = $1)
suite["sparse"]["mean with dims arge: dims sparse"] = @benchmarkable mean($sparse_d, dims = $(Var()))

suite["sparse"]["mean: regular sparse"] = @benchmarkable mean($sparse_a)
suite["sparse"]["mean: dims sparse"] = @benchmarkable mean($sparse_d)

suite["sparse"]["copy: regular sparse"] = @benchmarkable copy($sparse_a)
suite["sparse"]["copy: dims sparse"] = @benchmarkable copy($sparse_d)

suite["sparse"]["reduce: regular sparse"] = @benchmarkable reduce(+, $sparse_a)
suite["sparse"]["reduce: dims sparse"] = @benchmarkable reduce(+, $sparse_a)

suite["sparse"]["map: regular sparse"] = @benchmarkable map(sin, $sparse_a)
suite["sparse"]["map: dims sparse"] = @benchmarkable map(sin, $sparse_a)

paramspath = joinpath(dirname(@__FILE__), "params.json")
resultpath = gen_results_pth()

if isfile(paramspath)
    println("Found tuning info at $(paramspath)")
    loadparams!(suite, BenchmarkTools.load(paramspath)[1], :evals);
else
    println("Running tuning...")
    tune!(suite)
    BenchmarkTools.save(paramspath, params(suite));
    println("Tuning results cached to $(paramspath)")
end

results = run(suite, verbose = true)
println("Writing results to: $(resultpath)")
BenchmarkTools.save(resultpath, results)
