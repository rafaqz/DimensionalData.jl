# CUDA & GPUs

Running regular julia code on GPUs is one of the most amazing things
about the language. DimensionalData.jl leans into this as much as possible.

```julia
using DimensionalData, CUDA

# Create a Float32 array to use on the GPU
A = rand(Float32, X(1.0:1000.0), Y(1.0:2000.0))

# Move the parent data to the GPU with `modify` and the `CuArray` constructor:
cuA = modify(CuArray, A)
```

The result of a GPU broadcast is still a `DimArray`:

```julia-repl
julia> cuA2 = cuA .* 2
╭───────────────────────────────╮
│ 1000×2000 DimArray{Float32,2} │
├───────────────────────────────┴────────────────────────────── dims ┐
  ↓ X Sampled{Float64} 1.0:1.0:1000.0 ForwardOrdered Regular Points,
  → Y Sampled{Float64} 1.0:1.0:2000.0 ForwardOrdered Regular Points
└────────────────────────────────────────────────────────────────────┘
    ↓ →  1.0       2.0        3.0        4.0       …  1998.0        1999.0        2000.0
    1.0  1.69506   1.28405    0.989952   0.900394        1.73623       1.30427       1.98193
    2.0  1.73591   0.929995   0.665742   0.345501        0.162919      1.81708       0.702944
    3.0  1.24575   1.80455    1.78028    1.49097         0.45804       0.224375      0.0197492
    4.0  0.374026  1.91495    1.17645    0.995683        0.835288      1.54822       0.487601
    5.0  1.17673   0.0557598  0.183637   1.90645   …     0.88058       1.23788       1.59705
    6.0  1.57019   0.215049   1.9155     0.982762        0.906838      0.1076        0.390081
    ⋮                                              ⋱                              
  995.0  1.48275   0.40409    1.37963    1.66622         0.462981      1.4492        1.26917
  996.0  1.88869   1.86174    0.298383   0.854739  …     0.778222      1.42151       1.75568
  997.0  1.88092   1.87436    0.285965   0.304688        1.32669       0.0599431     0.134186
  998.0  1.18035   1.61025    0.352614   1.75847         0.464554      1.90309       1.30923
  999.0  1.40584   1.83056    0.0804518  0.177423        1.20779       1.95217       0.881149
 1000.0  1.41334   0.719974   0.479126   1.92721         0.0649391     0.642908      1.07277
```

But the data is on the GPU:

```julia-repl
julia> typeof(parent(cuA2))
CuArray{Float32, 2, CUDA.Mem.DeviceBuffer}
```

## GPU Integration goals

DimensionalData.jl has two GPU-related goals:

1. Work seamlessly with `Base` Julia broadcasts and other operations that already
   work on GPU.
2. Work as arguments to custom GPU kernel functions.

This means any `AbstractDimArray` must be automatically moved to the GPU and its
fields converted to GPU-friendly forms whenever required, using [Adapt.jl](https://github.com/JuliaGPU/Adapt.jl).

- The array data must convert to the correct GPU array backend 
  when `Adapt.adapt(dimarray)` is called.
- All DimensionalData.jl objects, except the actual parent array, need to be immutable `isbits` or
  convertible to them. This is one reason DimensionalData.jl uses `rebuild` and a functional style,
  rather than in-place modification of fields.
- Symbols need to be moved to the type system, so `Name{:layer_name}()` replaces `:layer_name`.
- Metadata dictionaries need to be stripped, as they are often too difficult to convert
  and not needed on GPU.

As an example, [DynamicGrids.jl](https://github.com/cesaraustralia/DynamicGrids.jl) uses `AbstractDimArray` for auxiliary 
model data that are passed into [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)/
[CUDA.jl](https://github.com/JuliaGPU/CUDA.jl) kernels.
