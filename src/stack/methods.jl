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

"""
    maplayers(f, stacks::AbstractDimStack...)

Apply function `f` to each layer of the `stacks`.

If `f` returns `DimArray`s the result will be another `DimStack`.
Other values will be returned in a `NamedTuple`.
"""
function maplayers(f, s::AbstractDimStack)
    _maybestack(s, map(f, values(s)))
end
function maplayers(f, x1::Union{AbstractDimStack,NamedTuple}, xs::Union{AbstractDimStack,NamedTuple}...)
    stacks = (x1, xs...)
    _check_same_names(stacks...)
    vals = map(f, map(values, stacks)...)
    return _maybestack(_firststack(stacks...), vals)
end


_check_same_names(::Union{AbstractDimStack{<:NamedTuple{names}},NamedTuple{names}}, 
            ::Union{AbstractDimStack{<:NamedTuple{names}},NamedTuple{names}}...) where {names} = nothing
_check_same_names(::Union{AbstractDimStack,NamedTuple}, ::Union{AbstractDimStack,NamedTuple}...) = throw(ArgumentError("Named tuple names do not match."))

_firststack(s::AbstractDimStack, args...) = s
_firststack(arg1, args...) = _firststack(args...) 
_firststack() = nothing

_maybestack(s::AbstractDimStack{<:NamedTuple{K}}, xs::Tuple) where K = NamedTuple{K}(xs)
_maybestack(s::AbstractDimStack, xs::Tuple) = NamedTuple{keys(s)}(xs)
# Without the `@nospecialise` here this method is also compile with the above method
# on every call to _maybestack. And `rebuild_from_arrays` is expensive to compile.
function _maybestack(
    s::AbstractDimStack, das::Tuple{AbstractDimArray,Vararg{AbstractDimArray}}
)
    # Avoid compiling this in the simple cases in the above method
    Base.invokelatest() do
        rebuild_from_arrays(s, das)
    end
end
function _maybestack(
    s::AbstractDimStack{<:NamedTuple{K}}, das::Tuple{AbstractDimArray,Vararg{AbstractDimArray}}
) where K
    # Avoid compiling this in the simple cases in the above method
    Base.invokelatest() do
        rebuild_from_arrays(s, das)
    end
end

"""
    Base.eachslice(stack::AbstractDimStack; dims)

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
function Base.eachslice(s::AbstractDimStack; dims)
    dimtuple = _astuple(dims)
    all(hasdim(s, dimtuple...)) || throw(DimensionMismatch("s doesn't have all dimensions $dims"))
    _eachslice(s, dimtuple)
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
    (:Base => (:inv, :adjoint, :transpose), :LinearAlgebra => (:Transpose,))
    for fname in fnames
        @eval ($mod.$fname)(s::AbstractDimStack) = maplayers(A -> ($mod.$fname)(A), s)
    end
end

# Methods with an argument that return a DimStack
for fname in (:rotl90, :rotr90, :rot180, :PermutedDimsArray, :permutedims)
    @eval (Base.$fname)(s::AbstractDimStack, args...) =
        maplayers(A -> (Base.$fname)(A, args...), s)
end

# Methods with keyword arguments that return a DimStack
for (mod, fnames) in
    (:Base => (:sum, :prod, :maximum, :minimum, :extrema, :dropdims),
     :Statistics => (:mean, :median, :std, :var))
    for fname in fnames
        @eval function ($mod.$fname)(s::AbstractDimStack; dims=:, kw...)
            maplayers(s) do A
                # Ignore dims not found in layer
                if dims isa Union{Colon,Int}
                    ($mod.$fname)(A; dims, kw...)
                else
                    ldims = commondims(DD.dims(A), dims)
                    # With no matching dims we do nothing
                    ldims == () ? A : ($mod.$fname)(A; dims=ldims, kw...)
                end
            end
        end
    end
end
for fname in (:cor, :cov)
    @eval function (Statistics.$fname)(s::AbstractDimStack; dims=1, kw...)
        maplayers(s) do A
            if dims isa Int
                (Statistics.$fname)(A; dims, kw...)
            else
                ldims = only(commondims(DD.dims(A), dims))
                ldims == () ? A : (Statistics.$fname)(A; dims=ldims, kw...)
            end
        end
    end
end

# Methods that take a function
for (mod, fnames) in (:Base => (:reduce, :sum, :prod, :maximum, :minimum, :extrema),
                      :Statistics => (:mean,))
    for fname in fnames
        _fname = Symbol(:_, fname)
        @eval function ($mod.$fname)(f::Function, s::AbstractDimStack; dims=Colon())
            maplayers(A -> ($mod.$fname)(f, A; dims=dims), s)
        end
                # ($_fname)(f, s, dims)
            # Colon returns a NamedTuple
            # ($_fname)(f::Function, s::AbstractDimStack, dims::Colon) =
                # map(A -> ($mod.$fname)(f, A), data(s))
            # Otherwise maybe return a DimStack
            # function ($_fname)(f::Function, s::AbstractDimStack, dims) =
            # end
        # end
    end
end

for fname in (:one, :oneunit, :zero, :copy)
    @eval function (Base.$fname)(s::AbstractDimStack, args...)
        maplayers($fname, s)
    end
end

Base.reverse(s::AbstractDimStack; dims=1) = maplayers(A -> reverse(A; dims=dims), s)

# Random
# Random.Sampler(RNG::Type{<:AbstractRNG}, st::AbstractDimStack, n::Random.Repetition) =
#     Random.SamplerSimple(st, Random.Sampler(RNG, DimIndices(st), n))

# Random.rand(rng::AbstractRNG, sp::Random.SamplerSimple{<:AbstractDimStack,<:Random.Sampler}) =
#     @inbounds return sp[][rand(rng, sp.data)...]
