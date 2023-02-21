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
    Base.map(f, stacks::AbstractDimStack...)

Apply function `f` to each layer of the `stacks`.

If `f` returns `DimArray`s the result will be another `DimStack`.
Other values will be returned in a `NamedTuple`.
"""
function Base.map(f, s1::Union{AbstractDimStack,NamedTuple}, s::Union{AbstractDimStack,NamedTuple}...)
    results = map(f, map(NamedTuple, (s1, s...)...))
    return _maybestack(_firststack(stacks), results)
end

_maybestack(s::AbstractDimStack, x::NamedTuple) = x
function _maybestack(
    s::AbstractDimStack, das::NamedTuple{K,<:Tuple{Vararg{<:AbstractDimArray}}}
) where K
    rebuild_from_arrays(s, das)
end

_firststack(s::AbstractDimStack, args...) = s
_firststack(arg1, args...) = _firststack(args...) 
_firststack() = nothing

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
        @eval ($mod.$fname)(s::AbstractDimStack) = map(A -> ($mod.$fname)(A), s)
    end
end

# Methods with an argument that return a DimStack
for fname in (:rotl90, :rotr90, :rot180, :PermutedDimsArray, :permutedims)
    @eval (Base.$fname)(s::AbstractDimStack, args...) =
        map(A -> (Base.$fname)(A, args...), s)
end

# Methods with keyword arguments that return a DimStack
for (mod, fnames) in
    (:Base => (:sum, :prod, :maximum, :minimum, :extrema, :dropdims),
     :Statistics => (:mean, :median, :std, :var))
    for fname in fnames
        @eval function ($mod.$fname)(s::AbstractDimStack; dims=:, kw...)
            map(s) do A
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
        map(s) do A
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
            map(A -> ($mod.$fname)(f, A; dims=dims), s)
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

for fname in (:one, :oneunit, :zero, :copy, :deepcopy)
    @eval function (Base.$fname)(s::AbstractDimStack, args...)
        map($fname, s)
    end
end

Base.reverse(s::AbstractDimStack; dims=1) = map(A -> reverse(A; dims=dims), s)
