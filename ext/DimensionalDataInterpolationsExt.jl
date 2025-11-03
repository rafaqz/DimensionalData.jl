module DimensionalDataInterpolationsExt

using DimensionalData
import DimensionalData as DD
import DimensionalData: AbstractBasicDimArray
# import Interpolations as Intp
import Interpolations:AbstractInterpolation, Gridded, NoInterp, Linear, interpolate, extrapolate

import UnrolledUtilities

"""
    DimGriddedInterpolation{T,N,A<:AbstractDimArray{T,N},I<:AbstractInterpolation,ICoords}

A gridded interpolation object for `AbstractDimArray`s.

# Fields
- `array::A`: The array to interpolate.
- `itp::I`: The interpolation object.
- `itp_coords::ICoords`: The interpolation coordinates.

Construct using `gridded_interpolate`.
"""
struct DimGriddedInterpolation{T,N,A<:AbstractDimArray{T,N},I<:AbstractInterpolation,ICoords}
    array::A
    itp::I
    itp_coords::ICoords
end

"""
    gridded_interpolate(A::AbstractDimArray, opts::NamedTuple; extrapolation_bc, [default_opt = NoInterp()])

Interpolate `A` using the interpolation options `opts`.

# Arguments
- `A`: The array to interpolate.
- `opts`: A named tuple of interpolation options for each dimension, see `Interpolations.jl` for available options.
- `extrapolation_bc`: The extrapolation boundary conditions. One of:
    `Throw()`, `Flat()`, `Line()`, `Free()`, `Reflect()`, `InPlace()`, `InPlaceQ()`, `Periodic()`
- `default_opt`: The default interpolation option for each dimension.

# Returns
- `dgi::DimGriddedInterpolation`: The interpolated array.

# Examples
```julia-repl
julia> using DimensionalData, Interpolations

julia> A = DimArray(reshape(1.0:100.0, 10, 10), (X(1:10), Y(1:10)));

julia> itp = DimensionalData.gridded_interpolate(A, (X = Gridded(Linear()), Y = Gridded(Linear())); extrapolation_bc = Line())
10×10 DimGriddedInterpolation{Float64, 2} DimensionalData.NoName()
  ↓ X Gridded(Linear()) [1, …, 10]
  → Y Gridded(Linear()) [1, …, 10]
Extrapolation: Line()

julia> itp(X(5), Y(5))
45.0

julia> B = itp(X(5), Y([2, 4, 6]))
┌ 3-element DimArray{Float64, 1} ┐
├────────────────────────────────┴───────────────────────── dims ┐
  ↓ Y Sampled{Int64} [2, …, 6] ForwardOrdered Irregular Points
└────────────────────────────────────────────────────────────────┘
 2  15.0
 4  35.0
 6  55.0

julia> refdims(B)  # Reference to "scalar" dimensions are retained
(↓ X 5)
```
"""
function DD.gridded_interpolate(A::AbstractDimArray, opts::NamedTuple; extrapolation_bc, default_opt = NoInterp())
    # Set all dimensions to `default_opt` by default
    default_opts = NamedTuple{DD.name(dims(A))}(ntuple(i -> default_opt, length(dims(A))))
    opts = merge(default_opts, opts)
    # Assert all opts are either Gridded or NoInterp
    @assert all(Base.Fix2(isa, Union{Gridded, NoInterp}), opts) "All interpolation options must be either Gridded or NoInterp"

    # `NoInterp` requires 1:length(dim) as nodes and coords.
    nodes = map(dims(A)) do dim
        opts[DD.name(dim)] isa Gridded ? lookup(dim) : Base.OneTo(length(dim))
    end
    itp_coords = map(dims(A)) do dim
        opts[DD.name(dim)] isa Gridded ? dim : rebuild(dim, Base.OneTo(length(dim)))
    end

    itp = interpolate(nodes, A, values(opts))
    extp = extrapolate(itp, extrapolation_bc)
    DimGriddedInterpolation(A, extp, itp_coords)
end

function (dgi::DimGriddedInterpolation)(interp_dims...; da_kwargs...)
    # Interpolate along the dimensions specified in `interp_dims`,
    # use the original dimensions for the rest.
    itp_dims = DD.setdims(dgi.itp_coords, interp_dims)  # insert dimensions in the correct order
    result_arr = dgi.itp(val.(itp_dims)...)

    # If `dgi` has any `NoInterp()`-dimensions, we need to fetch the values from the original dimensions.
    nointerp_dims = DD.otherdims(dims(dgi.array), interp_dims)
    dd_coords = DD.setdims(itp_dims, nointerp_dims)

    # Filter out scalar dimensions (UnrolledUtilities needed for type-stability)
    isvector(dim) = val(dim) isa AbstractVector
    vector_coords, scalar_coords = UnrolledUtilities.unrolled_split(isvector, dd_coords)
    isempty(vector_coords) && return result_arr  # Return scalar result if all dimensions were filtered

    return DD.DimArray(result_arr, vector_coords; refdims = scalar_coords, da_kwargs...)
end

"""
    interpolate!(dgi::DimGriddedInterpolation, A_to::AbstractDimArray)

Interpolate using `dgi` and write the result into `A_to` in-place.

The dimensions of `A_to` determine where to interpolate.

# Arguments
- `dgi`: The interpolation object.
- `A_to`: The output array to write to. Its dimensions determine the interpolation coordinates.

# Returns
- `A_to`: Returns the modified array.

# Notes:
- (For now,) the order of the dimensions of `A_to` must match the underlying data of `dgi`.

# Examples
```julia-repl
julia> using DimensionalData, Interpolations

julia> A_from = DimArray(reshape(1.0:100.0, 10, 10), (X(1:10), Y(1:10)));

julia> itp = DimensionalData.gridded_interpolate(A_from, (X = Gridded(Linear()), Y = Gridded(Linear())); extrapolation_bc = Line())
10×10 DimGriddedInterpolation{Float64, 2} DimensionalData.NoName()
  ↓ X Gridded(Linear()) [1, …, 10]
  → Y Gridded(Linear()) [1, …, 10]
Extrapolation: Line()

julia> A_to = zeros((X(1:0.5:3), Y(1:0.1:2)));  # `DimArray` with desired dimensions

julia> DimensionalData.interpolate!(itp, A_to)  # does in-place interpolation, zero allocations
┌ 5×11 DimArray{Float64, 2} ┐
├───────────────────────────┴──────────────────────────────── dims ┐
  ↓ X Sampled{Float64} 1.0:0.5:3.0 ForwardOrdered Regular Points,
  → Y Sampled{Float64} 1.0:0.1:2.0 ForwardOrdered Regular Points
└──────────────────────────────────────────────────────────────────┘
 ↓ →  1.0  1.1  1.2  1.3  1.4  1.5  1.6   1.7   1.8   1.9   2.0
 1.0  1.0  2.0  3.0  4.0  5.0  6.0  7.0   8.0   9.0  10.0  11.0
 ⋮                        ⋮                           ⋮    
 3.0  3.0  4.0  5.0  6.0  7.0  8.0  9.0  10.0  11.0  12.0  13.0
```
"""
function DD.interpolate!(dgi::DimGriddedInterpolation, A_to::AbstractDimArray)
    # Interpolate along the dimensions specified in `A_to`,
    # Check that `A_to` has the same dimensions as `dgi.itp_coords`, in the same order.
    @assert DD.name(dims(A_to)) == DD.name(dgi.itp_coords) "`A_to` has different dimensions than `dgi.itp_coords`, or in a different order."
    # Insert the interpolation dimensions in the correct order
    itp_dims = DD.setdims(dgi.itp_coords, dims(A_to))
    # Interpolate
    itp_splat = splat(dgi.itp)
    dd_pts = DimPoints(itp_dims)
    @. A_to = itp_splat(dd_pts)
    return A_to
end

function Base.show(io::IO, dgi::DimGriddedInterpolation)
    A = dgi.array
    dims_A = DD.dims(A)

    # compact header: size and type
    s_size = join(size(A), "×")
    elty = eltype(A)
    nd = ndims(A)
    name = DD.name(A)
    println(io, "$s_size DimGriddedInterpolation{$elty, $nd} $name")

    # arrow glyphs to indicate axis directions (cycle if more dims)
    arrows = ["↓", "→", "↗", "↖", "←", "↘"]

    opts = dgi.itp.itp.it
    for (i, d) in enumerate(dims_A)
        arrow = arrows[mod1(i, length(arrows))]
        nm = DD.name(d)
        left, right = DD.extrema(d)
        opt = opts[i]
        println(io, "  $arrow $nm $opt [$left, …, $right]")
    end
    print(io, "Extrapolation: $(dgi.itp.et)")
end

end  # end module