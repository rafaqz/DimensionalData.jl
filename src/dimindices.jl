
abstract type AbstractDimArrayGenerator{T,N,D} <: AbstractBasicDimArray{T,N,D} end

dims(dg::AbstractDimArrayGenerator) = dg.dims

Base.size(dg::AbstractDimArrayGenerator) = map(length, dims(dg))
Base.axes(dg::AbstractDimArrayGenerator) = map(d -> axes(d, 1), dims(dg))

Base.similar(A::AbstractDimArrayGenerator, ::Type{T}, D::DimTuple) where T =
    dimconstructor(D)(A; data=similar(Array{T}, size(D)), dims=D, refdims=(), metadata=NoMetadata())
Base.similar(A::AbstractDimArrayGenerator, ::Type{T}, D::Tuple{}) where T =
    dimconstructor(D)(A; data=similar(Array{T}, ()), dims=(), refdims=(), metadata=NoMetadata())

# Indexing that returns a new object with the same number of dims
for f in (:getindex, :dotview, :view)
    T = Union{Colon,AbstractRange}
    @eval @propagate_inbounds function Base.$f(di::AbstractDimArrayGenerator, i1::$T, i2::$T, Is::$T...)
        I = (i1, i2, Is...)
        newdims, _ = slicedims(dims(di), I)
        rebuild(di; dims=newdims)
    end
    @eval @propagate_inbounds Base.$f(di::AbstractDimArrayGenerator{<:Any,1}, i::$T) =
        rebuild(di; dims=(dims(di, 1)[i],))
    @eval @propagate_inbounds Base.$f(dg::AbstractDimArrayGenerator, i::Integer) =
        Base.$f(dg, Tuple(CartesianIndices(dg)[i])...)
    if f == :view
        @eval @propagate_inbounds Base.$f(A::AbstractDimArrayGenerator) = A
    else
        @eval @propagate_inbounds Base.$f(::AbstractDimArrayGenerator) = ()
    end
end

@inline Base.permutedims(A::AbstractDimArrayGenerator{<:Any,2}) =
    rebuild(A; dims=reverse(dims(A)))
@inline Base.permutedims(A::AbstractDimArrayGenerator{<:Any,1}) =
    rebuild(A; dims=(AnonDim(Base.OneTo(1)), dims(A)...))
@inline function Base.permutedims(A::AbstractDimArrayGenerator, perm)
    length(perm) == length(dims(A) || throw(ArgumentError("permutation must be same length as dims")))
    rebuild(A; dim=sortdims(dims(A), Tuple(perm)))
end

@inline function Base.PermutedDimsArray(A::AbstractDimArrayGenerator{T,N}, perm) where {T,N}
    perm_inds = dimnum(A, Tuple(perm))
    rebuild(A; dims=dims(dims(A), Tuple(perm)))
end

abstract type AbstractDimIndices{T,N,D} <: AbstractDimArrayGenerator{T,N,D} end

(::Type{T})(::Nothing; kw...) where T<:AbstractDimIndices = throw(ArgumentError("Object has no `dims` method"))
(::Type{T})(x; kw...) where T<:AbstractDimIndices = T(dims(x); kw...)
(::Type{T})(dim::Dimension; kw...) where T<:AbstractDimIndices = T((dim,); kw...)

"""
    DimIndices <: AbstractArray

    DimIndices(x)
    DimIndices(dims::Tuple)
    DimIndices(dims::Dimension)

Like `CartesianIndices`, but for `Dimension`s. Behaves as an `Array` of `Tuple`
of `Dimension(i)` for all combinations of the axis indices of `dims`.

This can be used to view/index into arbitrary dimensions over an array, and
is especially useful when combined with `otherdims`, to iterate over the
indices of unknown dimension.

`DimIndices` can be used directly in `getindex` like `CartesianIndices`,
and freely mixed with individual `Dimension`s or tuples of `Dimension`.

## Example

Index a `DimArray` with `DimIndices`.

Notice that unlike CartesianIndices, it doesn't matter if the dimensions
are not in the same order. Or even if they are not all contained in each.

```jldoctest; setup = :(using DimensionalData, Random; Random.seed!(123))
julia> A = rand(Y(0.0:0.3:1.0), X('a':'f'))
┌ 4×6 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.3:0.9 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':1:'f' ForwardOrdered
└─────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'b'       'c'        'd'        'e'       'f'
 0.0  0.9063    0.253849  0.0991336  0.0320967  0.774092  0.893537
 0.3  0.443494  0.334152  0.125287   0.350546   0.183555  0.354868
 0.6  0.745673  0.427328  0.692209   0.930332   0.297023  0.131798
 0.9  0.512083  0.867547  0.136551   0.959434   0.150155  0.941133

julia> di = DimIndices((X(1:2:4), Y(1:2:4)))
┌ 2×2 DimIndices{Tuple{X{Int64}, Y{Int64}}, 2} ┐
├──────────────────────────────────────── dims ┤
  ↓ X 1:2:3,
  → Y 1:2:3
└──────────────────────────────────────────────┘
 ↓ →  1                3
 1     (↓ X 1, → Y 1)   (↓ X 1, → Y 3)
 3     (↓ X 3, → Y 1)   (↓ X 3, → Y 3)

julia> A[di] # Index A with these indices
┌ 2×2 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────── dims ┐
  ↓ Y Sampled{Float64} 0.0:0.6:0.6 ForwardOrdered Regular Points,
  → X Categorical{Char} 'a':2:'c' ForwardOrdered
└─────────────────────────────────────────────────────────────────┘
 ↓ →   'a'       'c'
 0.0  0.9063    0.0991336
 0.6  0.745673  0.692209
```
"""
struct DimIndices{T,N,D<:Tuple{Vararg{Dimension}}} <: AbstractDimIndices{T,N,D}
    dims::D
    # Manual inner constructor for ambiguity only
    function DimIndices{T,N,D}(dims::Tuple{Vararg{Dimension}}) where {T,N,D<:Tuple{Vararg{Dimension}}}
        new{T,N,D}(dims)
    end
end
function DimIndices(dims::D) where {D<:Tuple{Vararg{Dimension}}}
    T = typeof(map(d -> rebuild(d, 1), dims))
    N = length(dims)
    dims = N > 0 ? _dimindices_format(dims) : dims
    DimIndices{T,N,typeof(dims)}(dims)
end

# Forces multiple indices not linear
function Base.getindex(di::DimIndices, i1::Integer, i2::Integer, I::Integer...)
    map(dims(di), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
end
# Dispatch to avoid linear indexing in multidimensional DimIndices
function Base.getindex(di::DimIndices{<:Any,1}, i::Integer)
    d = dims(di, 1)
    (rebuild(d, d[i]),)
end

_dimindices_format(dims::Tuple{}) = ()
_dimindices_format(dims::Tuple) = map(rebuild, dims, map(_dimindices_axis, dims))

# Allow only CartesianIndices arguments
_dimindices_axis(x::Integer) = Base.OneTo(x)
_dimindices_axis(x::AbstractRange{<:Integer}) = x
# And Lookup, which we take the axes from
_dimindices_axis(x::Dimension) = _dimindices_axis(val(x))
_dimindices_axis(x::Lookup) = axes(x, 1)
_dimindices_axis(x) =
    throw(ArgumentError("`$x` is not a valid input for `DimIndices`. Use `Dimension`s wrapping `Integer`, `AbstractArange{<:Integer}`, or a `Lookup` (the `axes` will be used)"))


"""
    DimPoints <: AbstractArray

    DimPoints(x; order)
    DimPoints(dims::Tuple; order)
    DimPoints(dims::Dimension; order)

Like `CartesianIndices`, but for the point values of the dimension index.
Behaves as an `Array` of `Tuple` lookup values (whatever they are) for all
combinations of the lookup values of `dims`.

Either a `Dimension`, a `Tuple` of `Dimension` or an object `x`
that defines a `dims` method can be passed in.

# Keywords

- `order`: determines the order of the points, the same as the order of `dims` by default.
"""
struct DimPoints{T,N,D<:Tuple{Vararg{Dimension}},O} <: AbstractDimIndices{T,N,D}
    dims::D
    order::O
end
DimPoints(dims::Tuple; order=dims) = DimPoints(dims, order)
function DimPoints(dims::Tuple, order::Tuple)
    order = map(d -> basetypeof(d)(), order)
    T = Tuple{map(eltype, dims)...}
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimPoints{T,N,typeof(dims),typeof(order)}(dims, order)
end

function Base.getindex(dp::DimPoints, i1::Integer, i2::Integer, I::Integer...)
    # Get dim-wrapped point values at i1, I...
    pointdims = map(dims(dp), (i1, i2, I...)) do d, i
        rebuild(d, d[i])
    end
    # Return the unwrapped point sorted by `order
    return map(val, DD.dims(pointdims, dp.order))
end
Base.getindex(di::DimPoints{<:Any,1}, i::Integer) = (dims(di, 1)[i],)

_format(::Tuple{}) = ()
function _format(dims::Tuple)
    ax = map(d -> axes(val(d), 1), dims)
    return format(dims, ax)
end

"""
    DimSelectors <: AbstractArray

    DimSelectors(x; selectors, atol...)
    DimSelectors(dims::Tuple; selectors, atol...)
    DimSelectors(dims::Dimension; selectors, atol...)

Like [`DimIndices`](@ref), but returns `Dimensions` holding
the chosen [`Selector`](@ref)s.

Indexing into another `AbstractDimArray` with `DimSelectors`
is similar to doing an interpolation.

## Keywords

- `selectors`: `Near`, `At` or `Contains`, or a mixed tuple of these.
  `At` is the default, meaning only exact or within `atol` values are used.
- `atol`: used for `At` selectors only, as the `atol` value.

## Example

Here we can interpolate a `DimArray` to the lookups of another `DimArray`
using `DimSelectors` with `Near`. This is essentially equivalent to
nearest neighbour interpolation.

```jldoctest; setup = :(using DimensionalData, Random; Random.seed!(123))
julia> A = rand(X(1.0:3.0:30.0), Y(1.0:5.0:30.0), Ti(1:2));

julia> target = rand(X(1.0:10.0:30.0), Y(1.0:10.0:30.0));

julia> A[DimSelectors(target; selectors=Near), Ti=2]
┌ 3×3 DimArray{Float64, 2} ┐
├──────────────────────────┴──────────────────────────────────────── dims ┐
  ↓ X Sampled{Float64} [1.0, 10.0, 22.0] ForwardOrdered Irregular Points,
  → Y Sampled{Float64} [1.0, 11.0, 21.0] ForwardOrdered Irregular Points
└─────────────────────────────────────────────────────────────────────────┘
  ↓ →  1.0        11.0       21.0
  1.0  0.691162    0.218579   0.539076
 10.0  0.0303789   0.420756   0.485687
 22.0  0.0967863   0.864856   0.870485
```

Using `At` would make sure we only use exact interpolation,
while `Contains` with sampling of `Intervals` would make sure that
each values is taken only from an Interval that is present in the lookups.
"""
struct DimSelectors{T,N,D<:Tuple{Vararg{Dimension}},S<:Tuple} <: AbstractDimIndices{T,N,D}
    dims::D
    selectors::S
end
function DimSelectors(dims::Tuple{Vararg{Dimension}}; atol=nothing, selectors=At())
    s = _format_selectors(dims, selectors, atol)
    DimSelectors(dims, s)
end
function DimSelectors(dims::Tuple{Vararg{Dimension}}, selectors::Tuple)
    T = typeof(map(rebuild, dims, selectors))
    N = length(dims)
    dims = N > 0 ? _format(dims) : dims
    DimSelectors{T,N,typeof(dims),typeof(selectors)}(dims, selectors)
end

@inline _format_selectors(dims::Tuple, selector, atol) =
    _format_selectors(dims, map(_ -> selector, dims), atol)
@inline _format_selectors(dims::Tuple, selectors::Tuple, atol) =
    _format_selectors(dims, selectors, map(_ -> atol, dims))
@inline _format_selectors(dims::Tuple, selectors::Tuple, atol::Tuple) =
    map(_format_selectors, dims, selectors, atol)

_format_selectors(d::Dimension, T::Type, atol) = _format_selectors(d, T(), atol)
@inline _format_selectors(d::Dimension, ::Near, atol) =
    Near(zero(eltype(d)))
@inline _format_selectors(d::Dimension, ::Contains, atol) =
    Contains(zero(eltype(d)))
@inline function _format_selectors(d::Dimension, ::At, atol)
    atolx = _atol(eltype(d), atol)
    v = first(val(d))
    At{typeof(v),typeof(atolx),Nothing}(v, atolx, nothing)
end

_atol(::Type, atol) = atol
_atol(T::Type{<:AbstractFloat}, atol::Nothing) = eps(T)

@propagate_inbounds function Base.getindex(di::DimSelectors, i1::Integer, i2::Integer, I::Integer...)
    map(dims(di), di.selectors, (i1, i2, I...)) do d, s, i
        rebuild(d, rebuild(s; val=d[i])) # At selector with the value at i
    end
end
@propagate_inbounds function Base.getindex(di::DimSelectors{<:Any,1}, i::Integer)
    d = dims(di, 1)
    (rebuild(d, rebuild(di.selectors[1]; val=d[i])),)
end

# Deprecated
const DimKeys = DimSelectors

struct DimSlices{T,N,D<:Tuple{Vararg{Dimension}},P} <: AbstractDimArrayGenerator{T,N,D}
    _data::P
    dims::D
end
DimSlices(x; dims, drop=true) = DimSlices(x, dims; drop)
DimSlices(x, dim; kw...) = DimSlices(x, (dim,); kw...)
function DimSlices(x, dims::Tuple; drop=true)
    dims1 = DD.dims(x, dims)
    newdims = if length(dims) == 0
        map(d  -> rebuild(d, :), DD.dims(x))
    else
        dims1
    end 
    inds = map(basedims(newdims)) do d
        rebuild(d, first(axes(x, d)))
    end
    # `getindex` returns these views
    T = typeof(view(x, inds...))
    N = length(newdims)
    D = typeof(newdims)
    P = typeof(x)
    return DimSlices{T,N,D,P}(x, newdims)
end

rebuild(ds::A; dims) where {A<:DimSlices{T,N}} where {T,N} =
    DimSlices{T,N,typeof(dims),typeof(ds._data)}(ds._data, dims)

function Base.summary(io::IO, A::DimSlices{T,N}) where {T,N}
    print_ndims(io, size(A))
    print(io, string(nameof(typeof(A)), "{$(nameof(T)),$N}"))
end

@propagate_inbounds function Base.getindex(ds::DimSlices, i1::Integer, i2::Integer, Is::Integer...)
    I = (i1, i2, Is...)
    @boundscheck checkbounds(ds, I...)
    D = map(dims(ds), I) do d, i
        rebuild(d, d[i])
    end
    return view(ds._data, D...)
end
# Dispatch to avoid linear indexing in multidimensional DimIndices
@propagate_inbounds function Base.getindex(ds::DimSlices{<:Any,1}, i::Integer)
    d = dims(ds, 1)
    return view(ds._data, rebuild(d, d[i]))
end

# Extends the dimensions of any `AbstractBasicDimArray`
# as if the array assigned into a larger array across all dimensions,
# but without the copying. Theres is a cost for linear indexing these objects
# as we need to convert to Cartesian.
struct DimExtensionArray{T,N,D<:Tuple{Vararg{Dimension}},R<:Tuple{Vararg{Dimension}},A<:AbstractBasicDimArray{T}} <: AbstractDimArrayGenerator{T,N,D}
    _data::A
    dims::D
    refdims::R
    function DimExtensionArray(A::AbstractBasicDimArray{T}, dims::Tuple, refdims::Tuple) where T
        all(hasdim(dims, DD.dims(A))) || throw(ArgumentError("all dim in array must also be in `dims`"))
        comparedims(A, DD.dims(dims, DD.dims(A)))
        fdims = format(dims, CartesianIndices(map(length, dims)))
        N = length(dims)
        new{T,N,typeof(fdims),typeof(refdims),typeof(A)}(A, fdims, refdims)
    end
end
DimExtensionArray(A::AbstractBasicDimArray, dims::Tuple; refdims=refdims(A)) =
    DimExtensionArray(A, dims, refdims)

name(A::DimExtensionArray) = name(A._data)
metadata(A::DimExtensionArray) = metadata(A._data)

# Indexing that returns a new object with the same number of dims
for f in (:getindex, :dotview, :view)
    __f = Symbol(:__, f)
    T = Union{Colon,AbstractRange}
    # For ambiguity
    @eval @propagate_inbounds function Base.$f(de::DimExtensionArray{<:Any,1}, i::Integer)
        if ndims(parent(de)) == 0
            $f(de._data)
        else
            $f(de._data, i)
        end
    end
    @eval @propagate_inbounds function Base.$f(di::DimExtensionArray{<:Any,1}, i::Union{AbstractRange,Colon})
        rebuild(di; _data=di.data[i], dims=(dims(di, 1)[i],))
    end
    # For ambiguity
    @eval @propagate_inbounds function Base.$f(de::DimExtensionArray, i1::$T, i2::$T, Is::$T...)
        $__f(de, i1, i2, Is...)
    end
    @eval @propagate_inbounds function Base.$f(de::DimExtensionArray, i1::StandardIndices, i2::StandardIndices, Is::StandardIndices...)
        $__f(de, i1, i2, Is...)
    end
    @eval @propagate_inbounds function Base.$f(
        de::DimensionalData.DimExtensionArray,
        i1::Union{AbstractArray{Union{}}, DimensionalData.DimIndices{<:Integer}, DimensionalData.DimSelectors{<:Integer}},
        i2::Union{AbstractArray{Union{}}, DimensionalData.DimIndices{<:Integer}, DimensionalData.DimSelectors{<:Integer}},
        Is::Vararg{Union{AbstractArray{Union{}}, DimensionalData.DimIndices{<:Integer}, DimensionalData.DimSelectors{<:Integer}}}
    )
        $__f(de, i1, i2, Is...)
    end
    @eval Base.@assume_effects :foldable @propagate_inbounds function $__f(de::DimExtensionArray, i1, i2, Is...)
        I = (i1, i2, Is...)
        newdims, newrefdims = slicedims(dims(de), refdims(de), I)
        D = map(rebuild, dims(de), I)
        A = de._data
        realdims = dims(D, dims(A))
        if all(map(d -> val(d) isa Colon, realdims))
            rebuild(de; dims=newdims, refdims=newrefdims)
        else
            newrealparent = begin
                x = parent(A)[dims2indices(A, realdims)...]
                x isa AbstractArray ? x : fill(x)
            end
            newrealdims = dims(newdims, realdims)
            newdata = rebuild(A; data=newrealparent, dims=newrealdims)
            rebuild(de; _data=newdata, dims=newdims, refdims=newrefdims)
        end
    end
    @eval @propagate_inbounds function $__f(de::DimExtensionArray{<:Any,1}, i::$T)
        newdims, _ = slicedims(dims(de), (i,))
        A = de._data
        D = rebuild(only(dims(de)), i)
        rebuild(de; dims=newdims, _data=A[D...])
    end
end
for f in (:getindex, :dotview)
    __f = Symbol(:__, f)
    @eval function $__f(de::DimExtensionArray, i1::Int, i2::Int, Is::Int...)
        D = map(rebuild, dims(de), (i1, i2, Is...))
        A = de._data
        return $f(A, dims(D, dims(A))...)
    end
    @eval $__f(de::DimExtensionArray{<:Any,1}, i::Int) = $f(de._data, rebuild(dims(de, 1), i))
end

function mergedims(A::DimExtensionArray, dim_pairs::Pair...)
    all_dims = dims(A)
    dims_new = mergedims(all_dims, dim_pairs...)
    dimsmatch(all_dims, dims_new) && return A
    dims_perm = _unmergedims(dims_new, map(last, dim_pairs))
    Aperm = PermutedDimsArray(A, dims_perm)
    data_merged = reshape(parent(Aperm), map(length, dims_new))
    return DimArray(data_merged, dims_new)
end
