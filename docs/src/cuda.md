# CUDA & GPUs

Running regular julia code on GPUs is one of the most amazing things
about the language. DimensionalData.jl leans into this as much as possible.

From the beginning DimensionalData.jl has had two GPU-related goals:

1. Work seamlessly with Base julia broadcasts and other operations that already
  work on GPU. 
2. Work as arguments to custom GPU kernel funcions.

This means any `AbstractDimArray` must be automatically moved to the gpu and its
fields converted to GPU friendly forms whenever required, using [Adapt.jl](https://github.com/JuliaGPU/Adapt.jl)).

- The array data must converts to the correct GPU array backend 
  when `Adapt.adapt(dimarray)` is called.
- All DimensionalData.jl objects, except the actual parent array, need to be immutable `isbits` or
  convertable to them. This is one reason DimensionalData.jl uses `rebuild` and a functional style,
  rather than in-place modification of fields.
- Symbols need to be moved to the type system `Name{:layer_name}()` replaces `:layer_name`
- Metadata dicts need to be stripped, they are often too difficult to convert,
  and not needed on GPU.


As an example, DynamicGrids.jl uses `AbstractDimArray` for auxiliary 
model data that are passed into [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)/
[CUDA.jl](https://github.com/JuliaGPU/CUDA.jl) kernels.


Note: due to limitations of the machines available in our github actions CI, 
we *do not* currently test on GPU. But we should.

If anyone wants to set us up with CI that has a GPU, please make a PR!

```julia
using DimensionalData, CUDA

# Create a Float32 array to use on the GPU
A = rand(Float32, X(1.0:1000.0), Y(1.0:2000.0))

# Move the parent data to the GPU with `modify` and the `CuArray` constructor:
cuA = modify(CuArray, A)

# Broadcast to a new GPU array: it will still be a DimArray!
cuA2 = cuA .* 2
```
