# Stacks

An `AbstractDimStack` represents a collection of `AbstractDimArray`
layers that share some or all dimensions. For any two layers, a dimension
of the same name must have the identical lookup - in fact only one is stored
for all layers to enforce this consistency.

The behaviour is somewhere ebetween a `NamedTuple` and an `AbstractArray`

Indexing layers by name with `stack[:layer]` or `stack.layer` works as with a
`NamedTuple`, and returns an `AbstractDimArray`. 
Indexing with `Dimensions`, `Selectors` works as with an `AbstractDimArray`, 
except it indexes for all layers at the same time, returning either a new
small `AbstractDimStack` or a scalar value, if all layers are scalars. 

Base functions like `mean`, `maximum`, `reverse` are applied to all layers of the stack.

`broadcast_dims` broadcasts functions over any mix of `AbstractDimStack` and
`AbstractDimArray` returning a new `AbstractDimStack` with layers the size of
the largest layer in the broadcast. This will work even if dimension permutation 
does not match in the objects.

# Performance 

Indexing stack is fast - indexing a single value return a `NamedTuple` from all layers
usingally, measures in nanoseconds. There are some compilation overheads to this
though, and stacks with very many layers can take a long time to compile.

Hopefully compiler fixes planned for Julia v1.11 will improve this.
