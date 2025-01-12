abstract type AbstractDimTree end

data(dt::AbstractDimTree) = getfield(dt, :data)
data(dt::AbstractDimTree, key::Symbol) = data(dt)[key]
# TODO fix the order
function dims(dt::AbstractDimTree) 
    ds = getfield(dt, :dims)
    p = getfield(dt, :parent)
    if isnothing(p)
        ds
    else
        (dims(p)..., ds...)
    end
end
groups(dt::AbstractDimTree) = getfield(dt, :groups)
groups(dt::AbstractDimTree, key::Symbol) = groups(dt)[key] 
setgroup(dt::AbstractDimTree, key::Symbol, group::AbstractDimStack) =
    setgroup(dt, key, DimTree(group))
function setgroup(dt::AbstractDimTree, key::Symbol, group::AbstractDimTree)
    if dt == group
        group = copy(group)
    end
    comparedims(dims(dt), dims(group))
    # Set the parent in the group
    setfield!(group, :dims, otherdims(group, dims(dt)))
    setfield!(group, :parent, dt)
    # Add the group to the parent
    groups(dt)[key] = group
    return group
end
layermetadata(dt::AbstractDimTree) = getfield(dt, :layermetadata)
layermetadata(dt::AbstractDimTree, key::Symbol) = layermetadata(dt)[key]
layerdims(dt::AbstractDimTree) = getfield(dt, :layerdims)
layerdims(dt::AbstractDimTree, key::Symbol) = layerdims(dt)[key]
layers(dt::AbstractDimTree) = Dict(pairs(dt))

(::Type{T})(dt::AbstractDimTree) where {T<:AbstractDimStack} =
    T(dt[keys(dt)])

Base.pairs(dt) = (k => dt[k] for k in keys(dt))
Base.keys(dt::AbstractDimTree) = getfield(dt, :keys)
function Base.copy(dt::AbstractDimTree) 
    rebuild(dt; 
        keys=copy(keys(dt)),
        data=copy(data(dt)),
        layerdims=copy(layerdims(dt)),
        layermetadata=copy(layermetadata(dt)),
        groups=copy(groups(dt)),
        parent=isnothing(getfield(dt, :parent)) ? nothing : copy(getfield(dt, :parent)),
    )
end
# If we select a single name we get a DimArray
function Base.getindex(dt::AbstractDimTree, name::Symbol)
    data = DD.data(dt, name)
    dims = DD.dims(dt, layerdims(dt, name))
    refdims = DD.refdims(dt)
    metadata = layermetadata(dt, name)
    DimArray(data, dims; refdims, name, metadata) 
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
Base.getproperty(dt::AbstractDimTree, name::Symbol) =
    dt[name]

"""
    DimTree 

A nested tree of dimensional arrays.

`DimTree` is loosely typed and based on `Dict` rather
than `NamedTuple` of `DimStack`, so it is much slower to index
but very fast to compile.

Trees can be nested indefinately, and leef nodes inherit dimension
from the tree. 

Branches may have duplicates of the same dimension with different 
lookup values. This can enable use for tiles or pyramids.
"""
@kwdef mutable struct DimTree <: AbstractDimTree
    data::Dict{Symbol,AbstractArray} = Dict{Symbol,AbstractArray}()
    dims::Tuple = ()
    keys::Vector{Symbol} = Symbol[]
    refdims::Tuple = ()
    layerdims::Dict{Symbol,Tuple}
    layermetadata::Dict{Symbol,Any} = Dict(keys(layerdims) .=> NoMetadata()) 
    groups::Dict{Symbol,AbstractDimTree} = Dict{Symbol,AbstractDimTree}()
    metadata::Any = NoMetadata()
    parent::Union{Nothing,AbstractDimTree} = nothing
end
DimTree(data, dims; keys=keys(data), kw...) = 
    DimTree(; data, dims, keys, kw...)
function DimTree(stack::AbstractDimStack)
    keys = collect(Base.keys(stack))
    data = Dict{Symbol,AbstractArray}(pairs(parent(stack)))
    DimTree(data, dims(stack); 
        keys,
        metadata = metadata(stack),
        layerdims = Dict{Symbol,Tuple}(pairs(layerdims(stack))),
        layermetadata = Dict{Symbol,Any}(pairs(layermetadata(stack))),
    )
end
function rebuild(dt::AbstractDimTree; 
    data=data(dt), 
    dims=dims(dt),
    refdims=refdims(dt), 
    metadata=metadata(dt), 
    layerdims=layerdims(dt), 
    layermetadata=layermetadata(dt),
    keys=keys(dt),
    parent=getfield(dt, :parent),
    groups=groups(dt),
)
    basetypeof(dt)(; 
        data, 
        dims, 
        refdims,
        metadata,
        layerdims,
        layermetadata,
        keys,
        parent,
        groups,
    )
end