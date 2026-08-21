module DimensionalDataPythonCallExt

using DimensionalData
import DimensionalData as DD
using OrderedCollections: OrderedDict
using PythonCall: PythonCall, Py, PyArray, pyis, pyconvert, pytype, pybuiltins, pylen, pyimport


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

# Convert the metadata of `x` into something that can be passed to xarray as
# `attrs`, warning and skipping it if it isn't a dictionary or `NamedTuple`
# type. `AbstractMetadata` wrappers are unwrapped to their underlying contents.
function _attrs(x)
    meta = metadata(x)
    contents = if meta isa DD.Lookups.AbstractMetadata
        DD.Lookups.val(meta)
    else
        meta
    end

    valid = if contents isa Union{AbstractDict, NamedTuple}
        contents
    else
        @warn "$(nameof(typeof(x))) metadata must be a dictionary or NamedTuple type to pass to xarray, but the passed metadata is a $(typeof(meta)). " *
              "The metadata will be skipped during the conversion."
        NamedTuple()
    end

    return OrderedDict((k isa Symbol ? string(k) : k) => v for (k, v) in pairs(valid))
end

_maybecopy(x, copy) = copy ? Base.copy(x) : x

# `nothing` means respect the preference, otherwise the argument overrides it
_use_xarray(xarray) = isnothing(xarray) ? DD._xarray_convert() : xarray

# Implementation based on:
# https://github.com/arviz-devs/ArviZPythonPlots.jl/blob/70419149d092099f4372b8314bf2cb4119d5573f/src/xarray.jl
function PythonCall.Py(data::DD.AbstractDimArray; copy=false, xarray=nothing)
    if !_use_xarray(xarray)
        return Py(_maybecopy(parent(data), copy))
    end

    xr = pyimport("xarray")

    var_name = name(data) isa DD.NoName ? pybuiltins.None : string(name(data))
    data_dims = DD.dims(data)
    dims = string.(name(data_dims))
    # Dimensions without a lookup have no coordinates in xarray
    coords = OrderedDict(string(name(dim)) => _maybecopy(parent(lookup(dim)), copy)
                         for dim in data_dims if !(lookup(dim) isa DD.AbstractNoLookup))
    values = parent(data)

    if Missing <: eltype(values)
        # Passing `missing` to Python causes the array to have a `PythonCall.jlwrap` dtype
        values = replace(values, missing => NaN)
    end

    # Note that we reverse the dimensions to keep the fast axis the same in
    # Julia and Python.
    return xr.DataArray(Py(values).to_numpy(; copy).T;
                        dims=reverse(dims), coords, attrs=_attrs(data), name=var_name)
end

function PythonCall.Py(data::DD.AbstractDimStack; copy=false, xarray=nothing)
    if !_use_xarray(xarray)
        return PythonCall.pyjl(data)
    end

    xr = pyimport("xarray")

    # The coordinates of each layer are merged by xarray, and the layer names
    # are taken from the keys rather than the name of each DataArray.
    data_vars = OrderedDict{String, Py}(string(k) => Py(layer; copy, xarray=true)
                                        for (k, layer) in pairs(DD.layers(data)))

    return xr.Dataset(data_vars; attrs=_attrs(data))
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
