module DimensionalDataPythonCallExt

using DimensionalData
import DimensionalData as DD
import PythonCall
import PythonCall: Py, PyArray, pyis, pyconvert, pytype, pybuiltins, pylen


function PythonCall.pyconvert(::Type{DimArray}, x::Py, d=nothing; copy=false)
    x_pytype = string(pytype(x).__name__)
    if x_pytype != "DataArray"
        if isnothing(d)
            throw(ArgumentError("Cannot convert $(pytype(x)) to a DimArray, it must be an xarray.DataArray"))
        else
            return d
        end
    end

    # Transpose here so that the fast axis remains the same in the Julia array
    data_py = PyArray(x.data.T; copy=false)
    data = copy ? pyconvert(Array, data_py) : data_py

    dim_names = Symbol.(collect(x.dims))
    coord_names = Symbol.(collect(x.coords.keys()))
    new_dims = Dim[]
    for dim in reverse(dim_names) # Iterate in reverse order because of row/col major
        if dim in coord_names
            coord_py = PyArray(getproperty(x, dim).data; copy=false)
            coord = copy ? pyconvert(Array, coord_py) : coord_py
            push!(new_dims, Dim{dim}(coord))
        else
            push!(new_dims, Dim{dim}())
        end
    end

    metadata = pylen(x.attrs) == 0 ? DD.NoMetadata() : pyconvert(Dict, x.attrs)

    array_name = pyis(x.name, pybuiltins.None) ? DD.NoName() : string(x.name)

    return DimArray(data, Tuple(new_dims); name=array_name, metadata)
end

function PythonCall.pyconvert(::Type{DimStack}, x::Py, d=nothing; copy=false)
    x_pytype = string(pytype(x).__name__)
    if x_pytype != "Dataset"
        if isnothing(d)
            throw(ArgumentError("Cannot convert $(x) to a DimStack, it must be an xarray.Dataset"))
        else
            return d
        end
    end

    variable_names = Symbol.(collect(x.data_vars.keys()))
    arrays = Dict{Symbol, DimArray}()
    for name in variable_names
        arrays[name] = pyconvert(DimArray, getproperty(x, name); copy)
    end

    metadata = pyconvert(Dict, x.attrs)

    return DimStack(NamedTuple(arrays); metadata)
end

# Precompile main calls to pyconvert(::DimArray) with copy=true and copy=false
precompile(Tuple{typeof(PythonCall.Core.pyconvert), Type{DimensionalData.DimArray{T, N, D, R, A, Na, Me} where Me where Na where A<:AbstractArray{T, N} where R<:Tuple where D<:Tuple where N where T}, PythonCall.Core.Py})
precompile(Tuple{typeof(Core.kwcall), NamedTuple{(:copy,), Tuple{Bool}}, typeof(PythonCall.Core.pyconvert), Type{DimensionalData.DimArray{T, N, D, R, A, Na, Me} where Me where Na where A<:AbstractArray{T, N} where R<:Tuple where D<:Tuple where N where T}, PythonCall.Core.Py})

# Precompile lower-level conversion calls for common types and dimensions
for T in (Int32, Int64, UInt32, UInt64, Float32, Float64)
    for N in (1, 2, 3, 4, 5)
        precompile(Tuple{typeof(PythonCall.Core.pyconvert), Type{Array{T, N}}, PythonCall.Core.Py})
    end
end

end
