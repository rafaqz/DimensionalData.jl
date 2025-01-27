ENV["JULIA_CONDAPKG_ENV"] = "@dimensionaldata-tests"

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

    @test_throws ArgumentError pyconvert(DimArray, xr)
    @test pyconvert(DimArray, xr, 42) == 42
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
