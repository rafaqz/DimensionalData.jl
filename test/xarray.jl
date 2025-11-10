ENV["JULIA_CONDAPKG_ENV"] = "@dimensionaldata-tests"
ENV["JULIA_CONDAPKG_BACKEND"] = "MicroMamba"

# If you've already run the tests once to create the test Python environment,
# you can comment out the lines above and uncomment the lines below. That will
# re-use the environment without re-resolving it, which is a bit faster.
# ENV["JULIA_PYTHONCALL_EXE"] = joinpath(Base.DEPOT_PATH[1], "conda_environments", "dimensionaldata-tests", "bin", "python")
# ENV["JULIA_CONDAPKG_BACKEND"] = "Null"

# Copy CondaPkg.toml to the test project so that it gets found by CondaPkg
# during the tests. If this was instead in the project directory it would also
# be used by CondaPkg outside of the tests, which we don't want.
cp(joinpath(@__DIR__, "CondaPkg.toml"), joinpath(dirname(Base.active_project()), "CondaPkg.toml"))

using DimensionalData, Test, PythonCall
import DimensionalData.Dimensions: NoLookup, NoMetadata


xr = pyimport("xarray")
np = pyimport("numpy")

data = rand(10, 5)
times = sort(rand(10))
x = xr.DataArray(data,
                 dims=("time", "length"),
                 coords=Dict("time" => times),
                 name="data",
                 attrs=Dict("motor" => "hexapod",
                            "pos" => 0.48,
                            "foo" => np.array([1, 2, 3])))

data2 = rand(10, 2)
x2 = xr.DataArray(data2,
                  dims=("time", "mass"),
                  coords=Dict("time" => times),
                  name="data2",
                  attrs=Dict("motor" => "delay",
                             "pos" => 0.48))

@testset "DataArray to DimArray" begin
    y = pyconvert(DimArray, x)
    @test name(y) == "data"
    @test name.(dims(y)) == (:length, :time)
    @test lookup(y, :time) == times
    @test_broken lookup(y, :length) == NoLookup()
    @test metadata(y) == Dict("motor" => "hexapod",
                              "pos" => 0.48,
                              "foo" => [1, 2, 3])

    # Test the zero-copy support
    y[1, 1] = 42f0
    @test parent(y) isa PyArray
    @test pyconvert(Float32, x[0, 0].item()) == 42f0

    # Test copying
    y_copy = pyconvert(DimArray, x; copy=true)
    @test y == y_copy
    @test parent(y_copy) isa Array

    @test_throws ArgumentError pyconvert(DimArray, xr)
    @test pyconvert(DimArray, xr, 42) == 42

    # Sanity test for higher-dimensional arrays
    x3 = xr.DataArray(np.random.rand(2, 5, 5, 3).astype(np.float32),
                      dims=("w", "x", "y", "z"),
                      coords=Dict("w" => [1, 2], "z" => [1, 2, 3]))
    y = pyconvert(DimArray, x3)
    @test lookup(y, :w) == [1, 2]
    @test lookup(y, :z) == [1, 2, 3]
end

@testset "Dataset to DimStack" begin
    dataset = xr.Dataset(Dict("x" => x, "x2" => x2),
                         attrs=Dict("source" => "interwebs"))
    z = pyconvert(DimStack, dataset)

    @test name(z) == (:x2, :x)
    @test name.(dims(z)) == (:mass, :time, :length)
    @test lookup(z, :time) == times
    @test metadata(z) == Dict("source" => "interwebs")

    @test_throws ArgumentError pyconvert(DimStack, x)
    @test pyconvert(DimStack, x, 42) == 42
end
