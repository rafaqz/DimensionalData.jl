ENV["JULIA_CONDAPKG_ENV"] = "@dimensionaldata-tests"
ENV["JULIA_CONDAPKG_BACKEND"] = "MicroMamba"
ENV["JULIA_CONDAPKG_VERBOSITY"] = -1

# If you've already run the tests once to create the test Python environment,
# you can comment out the lines above and uncomment the lines below. That will
# re-use the environment without re-resolving it, which is a bit faster.
# ENV["JULIA_PYTHONCALL_EXE"] = joinpath(Base.DEPOT_PATH[1], "conda_environments", "dimensionaldata-tests", "bin", "python")
# ENV["JULIA_CONDAPKG_BACKEND"] = "Null"

# CondaPkg only reads CondaPkg.toml from the active project. On Julia 1.12+ the
# test/ workspace project is activated directly, but older versions sandbox the
# tests into a temp env so the file has to be copied there.
let condapkg = joinpath(dirname(Base.active_project()), "CondaPkg.toml")
    if !isfile(condapkg)
        cp(joinpath(@__DIR__, "CondaPkg.toml"), condapkg)
    end
end

using DimensionalData, Test, PythonCall
import DimensionalData.Dimensions: NoLookup, NoMetadata
import DimensionalData.Lookups: Metadata


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

@testset "DimArray to DataArray" begin
    # Test __array_interface__ specifically because this is what allows for a
    # zero-copy conversion.
    x = rand(X(rand(10)), Y(5:10); name="foo", metadata=Dict(1 => 3.14, "bar" => "baz"))
    x_lookup = lookup(x, X)
    @test @pyeval(x_lookup => "x_lookup.__array_interface__") isa Py

    # Test zero-copy behaviour
    x_py = Py(x; xarray=true)
    @test pyisinstance(x_py, xr.DataArray)
    x[1, 1] = 42
    @test pyconvert(Float64, x_py[0, 0].item()) == 42

    # Test copying behaviour
    x_py = Py(x; copy=true, xarray=true)
    x[1, 1] = 3.14
    @test pyconvert(Float64, x_py[0, 0].item()) == 42

    # The dimension order should be flipped
    @test pyconvert(Tuple, x_py.shape) == reverse(size(x))

    # Test coordinates for arrays and ranges
    @test parent(lookup(x, X)) isa Vector
    @test pyconvert(Array, x_py.X.data) == lookup(x, X)
    @test parent(lookup(x, Y)) isa UnitRange
    @test pyconvert(Array, x_py.Y.data) == lookup(x, Y)

    # Dimensions without a lookup shouldn't get a coordinate
    @test pylen(Py(rand(X(10)); xarray=true).coords) == 0
    @test lookup(pyconvert(DimArray, Py(rand(X(10)); xarray=true)), :X) isa NoLookup

    # The array name should be a string or None
    @test pyconvert(String, x_py.name) == "foo"
    @test pyis(Py(rand(X(10)); xarray=true).name, pybuiltins.None)

    # Attributes should be a dict or NamedTuple, anything else will be skipped
    @test pyconvert(Dict, x_py.attrs) == metadata(x)
    @test pyconvert(Dict, Py(rand(X(10); metadata=(; a=1)); xarray=true).attrs) == Dict("a" => 1)
    @test pyconvert(Dict, Py(rand(X(10); metadata=Metadata(; a=1)); xarray=true).attrs) == Dict("a" => 1)
    @test pylen(Py(rand(X(10)); xarray=true).attrs) == 0
    @test_logs (:warn, r"must be a dictionary or NamedTuple type") Py(rand(X(10); metadata=42); xarray=true)

    # Without the conversion only the underlying array is passed to Python
    x_py = Py(x; xarray=false)
    @test !pyisinstance(x_py, xr.DataArray)
    @test @pyeval(x_py => "x_py.__array_interface__") isa Py
    @test pyconvert(Array, np.asarray(x_py)) == parent(x)
end

@testset "DimStack to Dataset" begin
    stack = DimStack((a=rand(X(times), Y(1:5)),
                      b=rand(X(times), Z(1:2); metadata=Dict("unit" => "m"))),
                     metadata=Dict("foo" => "bar"))
    stack_py = Py(stack; xarray=true)
    @test pyisinstance(stack_py, xr.Dataset)

    # Test zero-copy behaviour
    @test pyconvert(Float64, stack_py.a[0, 0].item()) == stack.a[1, 1]
    stack.a[1, 1] = 42
    @test pyconvert(Float64, stack_py.a[0, 0].item()) == 42

    # Test copying behaviour
    stack_py = Py(stack; copy=true, xarray=true)
    stack.a[1, 1] = 3.14
    @test pyconvert(Float64, stack_py.a[0, 0].item()) == 42

    # Layers become variables, keyed by their name in the stack
    @test pyconvert(Tuple, stack_py.data_vars.keys()) == string.(name(stack))

    # Coordinates shared between layers are merged
    @test pyconvert(Array, stack_py.X.data) == lookup(stack, X)
    @test pyconvert(Array, stack_py.Y.data) == lookup(stack, Y)
    @test pyconvert(Array, stack_py.Z.data) == lookup(stack, Z)

    # Stack and layer metadata are both passed through
    @test pyconvert(Dict, stack_py.attrs) == metadata(stack)
    @test pyconvert(Dict, stack_py.b.attrs) == metadata(stack.b)
    @test_logs (:warn, r"must be a dictionary or NamedTuple type") Py(DimStack((a=rand(X(10)),); metadata=42); xarray=true)

    # Without the conversion the stack is passed as an opaque Julia object
    stack_py = Py(stack; xarray=false)
    @test !pyisinstance(stack_py, xr.Dataset)
    @test_throws ArgumentError pyconvert(DimStack, stack_py)
end
