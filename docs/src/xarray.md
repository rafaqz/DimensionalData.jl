```@meta
Description = "Convert between Python Xarray and DimensionalData.jl - seamless interoperability for multidimensional arrays via PythonCall.jl"
```

# Xarray and PythonCall.jl

In the Python ecosystem [Xarray](https://xarray.dev) is by far the most popular
package for working with multidimensional labelled arrays. The main data
structures it provides are:
- [DataArray](https://docs.xarray.dev/en/stable/user-guide/data-structures.html#dataarray),
  analagous to `DimArray`.
- [Dataset](https://docs.xarray.dev/en/stable/user-guide/data-structures.html#dataset),
  analagous to `DimStack`.

DimensionalData integrates with
[PythonCall.jl](https://juliapy.github.io/PythonCall.jl/stable/) to allow
converting these Xarray types to their DimensionalData equivalent:
```julia
import PythonCall: pyconvert

# By default this will share the underlying array
my_dimarray = pyconvert(DimArray, my_dataarray)

my_dimstack = pyconvert(DimStack, my_dataset)
```

Here are some things to keep in mind when converting:
- `pyconvert(DimArray, x)` is zero-copy by default, i.e. it will share the
  underlying array with Python and register itself with Pythons GC to ensure
  that the memory isn't garbage-collected prematurely. If you want to make a
  copy you can call it like `pyconvert(DimArray, x; copy=true)`.
- When doing a zero-copy conversion from `x` to `x_jl`, `parent(x_jl)` will be a
  [PyArray](https://juliapy.github.io/PythonCall.jl/stable/pythoncall-reference/#PythonCall.Wrap.PyArray). In
  most situations there should be no overhead from this but note that a
  `PyArray` is not a `DenseArray` so some operations that dispatch on
  `DenseArray` may not be performant, e.g. BLAS calls. See these issues for more
  information:
  - https://github.com/JuliaPy/PythonCall.jl/issues/319
  - https://github.com/JuliaPy/PythonCall.jl/issues/182

  When `copy=true`, `parent(x_jl)` will always be a standard `Array`. However,
  we do not consider the type of parent array covered by semver so this may
  change in the future.
- Python stores arrays in row-major order whereas Julia stores them in
  column-major order, hence the dimensions on a converted `DimArray` will be in
  reverse order from the original `DataArray`. This is done to ensure that the
  'fast axis' to iterate over is the same dimension in both Julia and Python.
