"""
    AbstractDimTree

Abstract supertype for tree-like dimensional data.

These objects are mutable and fast compiled, as
an alternative to the flat, immutable `AbstractDimStack`.
"""
abstract type AbstractDimTree end

(::Type{T})(A1::AbstractDimArray, As::AbstractDimArray...) where T<:AbstractDimTree = 
    T([A1, As...])
(::Type{T})(As::Tuple{Vararg{AbstractDimArray}}) where T<:AbstractDimTree = 
    T(collect(As))
(::Type{T})(As::AbstractArray{<:AbstractDimArray}) where T<:AbstractDimTree = 
    T(OrderedDict(Symbol(name(A)) => A for A in As))
(::Type{T})(pairs::Pair...) where T<:AbstractDimTree = T(OrderedDict(pairs))
(::Type{T})(data, dims::DimTuple; kw...) where T <:AbstractDimTree = 
    DimTree(; data, dims, kw...)
function (::Type{T})(pairs::AbstractDict{<:Symbol,<:AbstractDimArray}; 
    data=DataDict((k => parent(v) for (k, v) in pairs)),
    dims=DD.combinedims(collect(dims(A) for (k, A) in pairs)),
    layerdims=TupleDict((k => basedims(v) for (k, v) in pairs)),
    layermetadata=DataDict((k => metadata(v) for (k, v) in pairs)),
    kw...
) where T <:AbstractDimTree
    T(data, dims; layerdims, layermetadata, kw...)
end
function (::Type{T})(stack::AbstractDimStack;
    metadata=metadata(stack),
    layerdims=TupleDict(pairs(layerdims(stack))),
    layermetadata=DataDict(pairs(layermetadata(stack))),
    kw...
) where T<:AbstractDimTree
    data = DataDict(pairs(parent(stack)))
    DimTree(data, dims(stack); metadata, layerdims, layermetadata, kw...)
end

data(dt::AbstractDimTree) = getfield(dt, :data)
data(dt::AbstractDimTree, key::Symbol) = data(dt)[key]
tree(dt::AbstractDimTree) = getfield(dt, :tree)
branches(dt::AbstractDimTree) = getfield(dt, :branches)

const TupleDict = OrderedDict{Symbol,Tuple}
const DataDict = OrderedDict{Symbol,Any}
const TreeDict = OrderedDict{Symbol,AbstractDimTree}
const PairKeys = Pair{Symbol,<:Union{<:Pair,Symbol}}

# TODO fix the order to match the arrays
function dims(dt::AbstractDimTree)
    ds = _dims(dt)
    t = tree(dt)
    return isnothing(t) ? ds : (dims(t)..., ds...)
end
_dims(dt::AbstractDimTree) = getfield(dt, :dims)

layermetadata(dt::AbstractDimTree) = getfield(dt, :layermetadata)
layermetadata(dt::AbstractDimTree, key::Symbol) = layermetadata(dt)[key]
layerdims(dt::AbstractDimTree) = getfield(dt, :layerdims)
layerdims(dt::AbstractDimTree, key::Symbol) = layerdims(dt)[key]
layers(dt::AbstractDimTree) = DataDict((pn => dt[pn] for pn in keys(dt)))

# DimStack constructors on DimTree
function (::Type{T})(dt::AbstractDimTree; keep=nothing) where {T<:AbstractDimStack}
    if isnothing(keep)
        pruned = DD.prune(dt; keep)
        T(pruned[Tuple(keys(pruned))])
    else
        T(dt[Tuple(keys(dt))])
    end
end

function Extents.extent(dt::AbstractDimTree)
    ext = Extents.extent(dims(dt))
    for (key, branch) in pairs(branches(dt))
        ext = Extents.extent(branch)
    end
    return ext
end

Base.pairs(dt::AbstractDimTree) = (k => dt[k] for k in keys(dt))
Base.keys(dt::AbstractDimTree) = collect(keys(data(dt)))
Base.length(dt::AbstractDimTree) = length(data(dt))
Base.haskey(dt::AbstractDimTree, key::Symbol) = haskey(data(dt), key::Symbol)
Base.propertynames(dt::AbstractDimTree) = collect(keys(branches(dt)))
function Base.copy(dt::AbstractDimTree) 
    rebuild(dt; 
        data=copy(data(dt)),
        layerdims=copy(layerdims(dt)),
        layermetadata=copy(layermetadata(dt)),
        branches=copy(branches(dt)),
        tree=isnothing(getfield(dt, :tree)) ? nothing : copy(getfield(dt, :tree)),
    )
end
# If we select a single name we get a DimArray
Base.getproperty(dt::AbstractDimTree, name::Symbol) = branches(dt)[name]

function Base.:(==)(dt1::AbstractDimTree, dt2::AbstractDimTree) 
    data(dt1) == data(dt2) &&
    layerdims(dt1) === layerdims(dt2) &&
    dims(dt2) == dims(dt2) &&
    branches(dt2) == branches(dt2)
end
Base.only(dt::AbstractDimTree) = dt[only(keys(data(dt)))]
Base.get(dt::AbstractDimTree, name::Symbol, default) =
    haskey(dt, name) ? dt[name] : default
Base.get(f::Base.Callable, dt::AbstractDimTree, name::Symbol) =
    haskey(dt, name) ? dt[name] : f()
function Base.filter!(pred, dt::AbstractDimTree)
    for p in pairs(dt)
        pred(p) || delete!(dt, k)
    end
end
function Base.get!(f::Base.Callable, dt::AbstractDimTree, name::Symbol)
    if haskey(dt, name) 
        return dt[name] 
    else
        x = f()
        dt[name] = x
        return x
    end
end

# If we select a Tuple or Vector of names we get a DimStack
function Base.getindex(
    dt::AbstractDimTree, names::Union{AbstractArray{Symbol},NTuple{<:Any,Symbol}}
)
    N = Tuple(names)
    data = map(n -> DD.data(dt, n), names) |> NamedTuple{N}
    layerdims = map(names) do n
        DD.layerdims(dt, n)
    end |> NamedTuple{N}
    layermetadata = map(names) do n
        DD.layermetadata(dt, n)
    end |> NamedTuple{N}
    dims = reduce(names; init=Symbol[]) do acc, n
        union(acc, collect(DD.layerdims(dt, n)))
    end |> Tuple
    return DimStack(data, DD.dims(dt, dims); 
        refdims=DD.refdims(dt),
        metadata=metadata(dt),
        layerdims,
        layermetadata,
    ) 
end
for f in (:getindex, :view)
    @eval function Base.$f(dt::AbstractDimTree; kw...)
        Base.$f(dt::AbstractDimTree, Dimensions.kw2dims(kw)...)
    end
    @eval function Base.$f(dt::AbstractDimTree, D::Dimension{<:SelectorOrInterval}...)
        newlayers = map(collect(pairs(layers(dt)))) do (name, A)
            name => $f(A, D...)
        end
        newbranches = map(collect(pairs(branches(dt)))) do (name, branch)
            name => $f(branch, D...)
        end |> TreeDict
        rebuild_from_arrays(dt, newlayers; branches=newbranches)
    end
end
function Base.getindex(dt::AbstractDimTree, name::Symbol)
    data = DD.data(dt, name)
    dims = DD.dims(dt, layerdims(dt, name))
    refdims = DD.refdims(dt)
    metadata = layermetadata(dt, name)
    return DimArray(data, dims; refdims, name, metadata) 
end

# A DimArray and a symbol sets a layer
function Base.setindex!(dt::AbstractDimTree, A::AbstractDimArray, key::Symbol)
    _adddims!(dt, dims(A))
    data(dt)[key] = parent(A)
    layerdims(dt)[key] = basedims(A)
    layermetadata(dt)[key] = metadata(A)
    return A
end

function _adddims!(dt::AbstractDimTree, newdims::Tuple)
    # Check first so we don't change anything before we error
    _checkbranchdims(dt, newdims)
    # Add new dims to the tree
    if length(dims(dt)) == 0
        setfield!(dt, :dims, newdims)
    else
        # If there are already dims, check they match before we do anything
        comparedims(dims(dt, newdims), newdims)
        setfield!(dt, :dims, otherdims(newdims, dims(dt)))
    end
    # If any of the branches already had these 
    # dims, we need to remove them now
    _removebranchdims!(dt, newdims)
end
function _checkbranchdims(dt::AbstractDimTree, newdims)
    for (key, branch) in pairs(branches(dt))
        comparedims(newdims, dims(_dims(branch), newdims))
    end
end
function _removebranchdims!(dt::AbstractDimTree, newdims)
    # Remove dims now present on a lower branch
    for (key, branch) in pairs(branches(dt))
        # Keep only dims not in the tree
        setfield!(branch, :dims, otherdims(dims(branch), newdims))
        _removebranchdims!(branch, newdims)
    end
end

# A DimTree or DimStack and a symbol sets a branch
Base.setindex!(tr::AbstractDimTree, br::Union{AbstractDimTree,AbstractDimStack}, key::Symbol) =
    branches(tr)[key] = br
function Base.setindex!(tr::AbstractDimTree, layers::Union{AbstractDimTree,AbstractDimStack})
    for key in keys(layers)
        tr[key] = layers[key]
    end
    return layers
end
Base.setproperty!(dt::AbstractDimTree, key::Symbol, A::AbstractDimArray) =
    setproperty!(dt, key, DimTree(A))
Base.setproperty!(dt::DimTree, key::Symbol, newbranch::AbstractDimStack) =
    setproperty!(dt, key, DimTree(newbranch))
function Base.setproperty!(dt::DimTree, key::Symbol, newbranch::AbstractDimTree)
    if dt == newbranch
        newbranch = copy(newbranch)
    end
    comparedims(dims(dt, dims(newbranch)), dims(newbranch))
    # The branch only holds dimensions not in the tree
    setfield!(newbranch, :dims, otherdims(newbranch, dims(dt)))
    # Set the tree in the new branch
    setfield!(newbranch, :tree, dt)
    # Add the branch to the data Dict
    branches(dt)[key] = newbranch
    return newbranch
end

function Base.empty!(dt::AbstractDimTree) 
    empty!(data(dt))
    empty!(layerdims(dt))
    empty!(layermetadata(dt))
    return dt
end
function Base.sort!(dt::AbstractDimTree, args...; kw...)
    sort!(data(dt), args...; kw...)
    sort!(layerdims(dt), args...; kw...)
    sort!(layermetadata(dt), args...; kw...)
    return dt
end
function Base.delete!(tr::AbstractDimTree)
    trunk = tree(tr)
    if isnothing(trunk)
        return tr
    else
        for (key, branch) in pairs(branches(trunk))
            if branch === tr 
                delete!(branches(trunk), key)
            end
        end
    end
    return trunk
end
function Base.delete!(tr::AbstractDimTree, key::Symbol)
    delete!(data(tr), key) 
    delete!(layerdims(tr), key) 
    delete!(layermetadata(tr), key) 
    ldims = reduce(layerdims(tr); init=Dimension[]) do acc, (k, v)
        union(v, acc)
    end
    if length(ldims) != length(_dims(tr))
        setfield!(tr, :dims, dims(_dims(tr), Tuple(ldims)))
    end
    return tr
end
function Base.pop!(tr::AbstractDimTree, key::Symbol)
    l = tr[key]
    delete!(data(tr), key) 
    delete!(layerdims(tr), key) 
    delete!(layermetadata(tr), key) 
    return l
end
Base.pop!(tr::AbstractDimTree, key::Symbol, default) =
    haskey(tr, key) ? pop!(tr, key) : default
function Base.pop!(dt::AbstractDimTree)
    ks = keys(dt)
    length(ks) > 0 || throw(ArgumentError("$(basetypeof(dt)) must be non-empty"))
    key = last(ks)
    return key => pop!(dt, key)
end

"""
    prune(dt::AbstractDimTree; keep::Union{Symbol,Pair{Symbol}})

Prune a tree to remove branches.

`keep` specifies a branch to incorprate into the tree, after
it is also pruned. A `Pair` can be used to specify a branch
to keep in that branch, and these may be chained as e.g.
`keep=:branch => :smallbranch => :leaf`.

`prune` results in a DimTree that is completely convertable to a 
[`DimStack`](@ref), as it no longer has branches with divergent dimensions.

# Example 

```julia
prune(dimtree; keep=:branch => :leaf)
```
"""
function prune(dt::AbstractDimTree; 
    keep::Union{Nothing,Symbol,PairKeys}=nothing
)
    # No kept branches, just make a new `branches` dict
    isnothing(keep) &&
        return rebuild(dt; 
            branches=TreeDict(),
            tree=nothing
        )

    # Otherwise prune the kept branch
    branch = if keep isa Symbol
        # Symbol keeps one pruned branch
        prune(branches(dt, keep))
    else
        # Pairs will also keep a branch of the branch
        prune(branches(dt, first(keep)); keep=last(keep))
    end
    rebuild(dt; 
        data=DataDict(hcat(collect(pairs(dt)), collect(pairs(branch)))),
        branches=TreeDict(), # There a no branches after flattening
        dims=dims(branch), # The branch has all the dims already
        tree=nothing,
    ) 
end

"""
    DimTree 

A nested tree of dimensional arrays.

`DimTree` is loosely typed and based on `OrderedDict` rather
than `NamedTuple` of `DimStack`, so it is slower to index
but very fast to compile, and very flexible.

Trees can be nested indefinately, branches inheriting dimensions
from the tree. 

## Dimensions and branches

Dimensions that are shared with the tree must be identical.
They are in fact stored at the basal level of the tree that they 
are used in, and propagate out to branches.

Within a branch, all layers use a subset of the dimensions available
to the branch.

Accross branches, there may be versions of the same dimensions with 
different lookup values. These may cover different extents, resolutions, 
or whatever properties of lookups are required.

This property can be used for tiles or pyramids, for example.

## Example

```julia
xdim, ydim = X(1:10), Y(1:15), 
z1, z2 = Z([:a, :b, :c]), Z([:d, :e, :f])
a = rand(xdim, ydim)
b = rand(Float32, xdim, ydim)
c = rand(Int, xdim, ydim, z1)
d = rand(Int, xdim, z2)
DimTree(a, b)
````
"""
@kwdef mutable struct DimTree <: AbstractDimTree
    data::DataDict = DataDict()
    dims::Tuple = ()
    refdims::Tuple = ()
    layerdims::TupleDict = TupleDict()
    layermetadata::DataDict = DataDict(Base.keys(layerdims) .=> NoMetadata()) 
    metadata::Any = NoMetadata()
    branches::TreeDict = TreeDict()
    tree::Union{Nothing,AbstractDimTree} = nothing
end

function rebuild(dt::AbstractDimTree; 
    data=data(dt), 
    dims=dims(dt),
    refdims=refdims(dt), 
    metadata=metadata(dt), 
    layerdims=layerdims(dt), 
    layermetadata=layermetadata(dt),
    tree=tree(dt),
    branches=branches(dt),
)
    basetypeof(dt)(; 
        data, 
        dims, 
        refdims,
        metadata,
        layerdims,
        layermetadata,
        tree,
        branches,
    )
end

function rebuild_from_arrays(dt::AbstractDimTree, layers::AbstractArray{<:Pair}; 
    data=DataDict(k => parent(v) for (k, v) in layers),
    dims=DD.combinedims(map(last, layers)),
    refdims=refdims(dt), 
    metadata=metadata(dt), 
    layerdims=layerdims(layers), 
    layermetadata=layermetadata(layers),
    branches=branches(dt),
    tree=nothing,
)
    rebuild(dt; data, dims, refdims, layerdims, metadata, layermetadata, branches, tree)
end

layerdims(layers::AbstractArray{<:Pair}) = 
    TupleDict(map(((k, v),) -> k => basedims(v), layers))
layermetadata(layers::AbstractArray{<:Pair}) = 
    DataDict(map(((k, v),) -> k => metadata(v), layers))