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

my_dimarray = pyconvert(DimArray, my_dataarray)

my_dimstack = pyconvert(DimStack, my_dataset)
```

Note that:
- The current implementation will make a copy of the underlying arrays.
- Python stores arrays in row-major order whereas Julia stores them in
  column-major order, hence the dimensions on a converted `DimArray` will be in
  reverse order from the original `DataArray`. This is done to ensure that the
  'fast axis' to iterate over is the same dimension in both Julia and Python.
