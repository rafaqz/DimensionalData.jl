module DimensionalDataPythonCall

using DimensionalData
import PythonCall
import PythonCall: Py, pyis, pyconvert, pytype, pybuiltins
import DimensionalData.Lookups: NoLookup

function dtype2type(dtype::String)
    if dtype == "float16"
        Float16
    elseif dtype == "float32"
        Float32
    elseif dtype == "float64"
        Float64
    elseif dtype == "int8"
        Int8
    elseif dtype == "int16"
        Int16
    elseif dtype == "int32"
        Int32
    elseif dtype == "int64"
        Int64
    elseif dtype == "uint8"
        UInt8
    elseif dtype == "uint16"
        UInt16
    elseif dtype == "uint32"
        UInt32
    elseif dtype == "uint64"
        UInt64
    elseif dtype == "bool"
        Bool
    else
        error("Unsupported dtype: '$dtype'")
    end
end

function PythonCall.pyconvert(::Type{DimArray}, x::Py, d=nothing)
    x_pytype = string(pytype(x).__name__)
    if x_pytype != "DataArray"
        if isnothing(d)
            throw(ArgumentError("Cannot convert $(pytype(x)) to a DimArray, it must be an xarray.DataArray"))
        else
            return d
        end
    end

    # Transpose here so that the fast axis remains the same in the Julia array
    data_npy = x.data.T
    data_type = dtype2type(string(data_npy.dtype.name))
    data_ndim = pyconvert(Int, data_npy.ndim)
    data = pyconvert(Array{data_type, data_ndim}, data_npy)

    dim_names = Symbol.(collect(x.dims))
    coord_names = Symbol.(collect(x.coords.keys()))
    lookups_dict = Dict{Symbol, Any}()
    for dim in dim_names
        if dim in coord_names
            coord = getproperty(x, dim).data
            coord_type = dtype2type(string(coord.dtype.name))
            coord_ndim = pyconvert(Int, coord.ndim)

            lookups_dict[dim] = pyconvert(Array{coord_type, coord_ndim}, coord)
        else
            lookups_dict[dim] = NoLookup()
        end
    end

    lookups = NamedTuple(lookups_dict)

    metadata = pyconvert(Dict, x.attrs)

    array_name = pyis(x.name, pybuiltins.None) ? nothing : string(x.name)

    return DimArray(data, lookups; name=array_name, metadata)
end

function PythonCall.pyconvert(::Type{DimStack}, x::Py, d=nothing)
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
        arrays[name] = pyconvert(DimArray, getproperty(x, name))
    end

    metadata = pyconvert(Dict, x.attrs)

    return DimStack(NamedTuple(arrays); metadata)
end

end
