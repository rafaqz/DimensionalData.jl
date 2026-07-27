const XARRAY_CONVERT_PREF = "xarray_convert"

# Whether converting an `AbstractDimArray`/`AbstractDimStack` to Python with
# `PythonCall.Py()` should create an `xarray.DataArray`/`xarray.Dataset`.
_xarray_convert() = @load_preference(XARRAY_CONVERT_PREF, false)

"""
    set_xarray_convert!(x::Bool)

Set whether converting an `AbstractDimArray`/`AbstractDimStack` to Python with
`PythonCall.Py()` should create an `xarray.DataArray`/`xarray.Dataset`.

Defaults to `false`, in which case an `AbstractDimArray` is converted to a plain
Python array and an `AbstractDimStack` is passed through as an opaque Julia
object. Note that enabling it means that any conversion to Python will import
xarray, so it must be installed.

The preference is set for the active project, and restarting Julia afterwards is
recommended.
"""
function set_xarray_convert!(x::Bool)
    @set_preferences!(XARRAY_CONVERT_PREF => x)
    return x
end
