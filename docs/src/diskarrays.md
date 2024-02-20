### [DiskArrays.jl](https://github.com/meggart/DiskArrays.jl) compatability


The combination of DiskArrays.jl and DimensionalData.jl is Julias answer to
pythons [xarray](https://xarray.dev/). 

Rasters.jl and YAXArrays.jl are the user-facing tools building on this
combination.

DiskArrays.jl is rarely used directly by users, but is present in most 
disk and cloud based spatial data packages in julia, including:
- ArchGDAL.jl
- NetCDF.jl
- Zarr.jl
- NCDatasets.lj
- GRIBDatasets.jl
- CommonDataModel.jl
- etc...

So that lazy, chunked data access conforms to julias array 
interface but also scales to operating on terrabytes of data. 

DiskArrays enables chunk ordered lazy application of:

- broadcast
- reduce
- iteration
- generators
- zip

DimensionalData.jl is a common front-end for accessing DiskArrays.jl 
compatible datasets. Wherever An `AbstractDimArray` wraps a disk array we 
will do our best to make sure all of the DimensionalData.jl indexing and
DiskArrays.jl lazy/chunked operations work together cleanly.

They have no direct dependency relationships, with but are intentionally 
designed to integrate via both adherence to julias `AbstractArray` 
interface, and by coordination during development of both packages.


# Example

Out of the box integration.

DimensionalData.jl and DiskArrays.jl play nice no matter the size of the data.
To make this all work in CI we will simulate some huge data by multiplying 
a huge `BitArray` with a `BigInt`, meant to make it 128 x larger in memory.

```@ansi diskarray
using DimensionalData, DiskArrays 

# This holds is a 100_100 * 50_000 `BitArray`  
A = trues(100_000, 50_000)
diska = DiskArrays.TestTypes.AccessCountDiskArray(A; chunksize=(100, 100))
dima = DimArray(diska, (X(0.01:0.01:1000), Y(0.02:0.02:1000)))
```

# How big is this thing?
```@ansi diskarray
GB = sizeof(A) / 1e9
```


Now if we multiply that by 2.0 they will be Float64, ie 64 x larger.

But:

```@ansi diskarray
dimb = view(permutedims(dima .* BigInt(200000000000), (X, Y)); X=1:99999)
sizeof(dimb)
```

The size should be:
```@ansi diskarray
GB = (sizeof(eltype(dimb)) * prod(size(dimb))) / 1e9
```

I'm writing this on a laptop with only 32Gb or ram, but this runs instantly.

The trick is nothing happens until we index:

```@ansi diskarray
diska.getindex_count
```

These are just access for printing in the repl!

When we actually get data the calulations happen, 
and for real disk arrays the chunked reads too:

```@ansi diskarray
dimb[X=1:100, Y=1:10]
```

