# Base methods

"""
    Base.copy!(dst::AbstractArray, src::AbstractGimStack, key::Key)

Copy the stack layer `key` to `dst`, which can be any `AbstractArray`.

## Example

Copy the `:humidity` layer from `stack` to `array`.

```julia
copy!(array, stack, :humidity)
```
"""
Base.copy!(dst::AbstractArray, src::AbstractDimStack, key) = copy!(dst, src[key])

"""
    Base.copy!(dst::AbstractDimStack, src::AbstractDimStack, [keys=keys(dst)])

Copy all or a subset of layers from one stack to another.

## Example

Copy just the `:sea_surface_temp` and `:humidity` layers from `src` to `dst`.

```julia
copy!(dst::AbstractDimStack, src::AbstractDimStack, keys=(:sea_surface_temp, :humidity))
```
"""
function Base.copy!(dst::AbstractDimStack, src::AbstractDimStack, keys=keys(dst))
    # Check all keys first so we don't copy anything if there is any error
    for key in keys
        key in Base.keys(dst) || throw(ArgumentError("key $key not found in dest keys"))
        key in Base.keys(src) || throw(ArgumentError("key $key not found in source keys"))
    end
    for key in keys
        copy!(dst[key], src[key])
    end
end

function Base.copyto!(
    dst::Array{<:DimStack,3}, dstI::CartesianIndices,
    src::DimSlices{<:DimStack}, srcI::CartesianIndices
)
    dst[dstI] = src[srcI]
end

"""
    Base.eachslice(stack::AbstractDimStack; dims, drop=true)

Create a generator that iterates over dimensions `dims` of `stack`, returning stacks that
select all the data from the other dimensions in `stack` using views.

The generator has `size` and `axes` equivalent to those of the provided `dims`.

# Examples

```julia
julia> ds = DimStack((
           x=DimArray(randn(2, 3, 4), (X([:x1, :x2]), Y(1:3), Z)),
           y=DimArray(randn(2, 3, 5), (X([:x1, :x2]), Y(1:3), Ti))
       ));

julia> slices = eachslice(ds; dims=(Z, X));

julia> size(slices)
(4, 2)

julia> map(dims, axes(slices))
Z,
X Categorical{Symbol} Symbol[x1, x2] ForwardOrdered

julia> first(slices)
DimStack with dimensions:
  Y Sampled{Int64} 1:3 ForwardOrdered Regular Points,
  Ti
and 2 layers:
  :x Float64 dims: Y (3)
  :y Float64 dims: Y, Ti (3×5)
```
"""
function Base.eachslice(s::AbstractDimStack; dims, drop=true)
    dimtuple = _astuple(dims)
    if !(dimtuple == ())
        all(hasdim(s, dimtuple)) || throw(DimensionMismatch("A doesn't have all dimensions $dims"))
    end
    # Avoid getting DimUnitRange from `axes(s)`
    axisdims = map(DD.dims(s, dimtuple)) do d
        rebuild(d, axes(lookup(d), 1))
    end
    return DimSlices(s; dims=axisdims, drop)
end


"""
    Base.cat(stacks::AbstractDimStack...; [keys=keys(stacks[1])], dims)

Concatenate all or a subset of layers for all passed in stacks.

# Keywords

- `keys`: `Tuple` of `Symbol` for the stack keys to concatenate.
- `dims`: Dimension of child array to concatenate on.

# Example

Concatenate the :sea_surface_temp and :humidity layers in the time dimension:

```julia
cat(stacks...; keys=(:sea_surface_temp, :humidity), dims=Ti)
```
"""
function Base.cat(s1::AbstractDimStack, stacks::AbstractDimStack...; keys=keys(s1), dims)
    vals = Tuple(cat((s[k] for s in (s1, stacks...))...; dims) for k in keys)
    rebuild_from_arrays(s1, vals)
end

# Methods with no arguments that return a DimStack
for (mod, fnames) in
    (:Base => (:inv, :adjoint, :transpose, :permutedims, :PermutedDimsArray), :LinearAlgebra => (:Transpose,))
    for fname in fnames
        @eval function ($mod.$fname)(s::AbstractDimStack)
            map(s) do l
                ndims(l) > 1 ? ($mod.$fname)(l) : l
            end
        end
    end
end

# Methods with an argument that return a DimStack
for fname in (:rotl90, :rotr90, :rot180)
    @eval (Base.$fname)(s::AbstractDimStack, args...) =
        map(A -> (Base.$fname)(A, args...), s)
end
for fname in (:PermutedDimsArray, :permutedims)
    @eval function (Base.$fname)(s::AbstractDimStack, perm)
        map(s) do l
            lperm = dims(l, dims(s, perm))
            length(lperm) > 1 ? (Base.$fname)(l, lperm) : l
        end
    end
end

# Methods with keyword arguments that return a DimStack
for (mod, fnames) in
    (:Base => (:sum, :prod, :maximum, :minimum, :extrema, :dropdims),
     :Statistics => (:mean, :median, :std, :var))
    for fname in fnames
        @eval function ($mod.$fname)(s::AbstractDimStack; dims=:, kw...)
            map(s) do A
                layer_dims = dims isa Colon ? dims : commondims(A, dims)
                $mod.$fname(A; dims=layer_dims, kw...)
            end
        end
    end
end
for fname in (:cor, :cov)
    @eval function (Statistics.$fname)(s::AbstractDimStack; dims=1, kw...)
        d = DD.dims(s, dims)
        map(s) do A
            layer_dims = only(commondims(A, d))
            Statistics.$fname(A; dims=layer_dims, kw...)
        end
    end
end

# Methods that take a function
for (mod, fnames) in (:Base => (:reduce, :sum, :prod, :maximum, :minimum, :extrema),
                      :Statistics => (:mean,))
    for fname in fnames
        _fname = Symbol(:_, fname)
        @eval function ($mod.$fname)(f::Function, s::AbstractDimStack; dims=Colon())
            map(s) do A
                layer_dims = dims isa Colon ? dims : commondims(A, dims)
                $mod.$fname(f, A; dims=layer_dims)
            end
        end
    end
end

for fname in (:one, :oneunit, :zero, :copy)
    @eval function (Base.$fname)(s::AbstractDimStack, args...)
        map($fname, s)
    end
end

Base.reverse(s::AbstractDimStack; dims=:) = map(A -> reverse(A; dims=dims), s)

# Random
Random.Sampler(RNG::Type{<:AbstractRNG}, st::AbstractDimStack, n::Random.Repetition) =
    Random.SamplerSimple(st, Random.Sampler(RNG, DimIndices(st), n))

Random.rand(rng::AbstractRNG, sp::Random.SamplerSimple{<:AbstractDimStack,<:Random.Sampler}) =
    @inbounds return sp[][rand(rng, sp.data)...]
