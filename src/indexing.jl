const DimArrayOrStack = Union{AbstractDimArray,AbstractDimStack}

# getindex/view/setindex! ======================================================

#### Array getindex/view ####
# Integer returns a single value, but not for view
@propagate_inbounds Base.getindex(A::AbstractDimArray, i1::Integer, i2::Integer, I::Integer...) =
    Base.getindex(parent(A), i1, i2, I...)
@propagate_inbounds Base.dotview(A::AbstractDimArray, i1::Integer, i2::Integer, I::Integer...) =
    Base.getindex(parent(A), i1, i2, I...)
# No indices. These just prevent stack overflows
@propagate_inbounds Base.getindex(A::AbstractDimArray) = Base.getindex(parent(A))
@propagate_inbounds Base.view(A::AbstractDimArray) = rebuild(A, Base.view(parent(A)), ())
#### Stack getindex ####
# Symbol key
@propagate_inbounds Base.getindex(s::AbstractDimStack, key::Symbol) =
    DimArray(data(s)[key], dims(s), refdims(s), key, nothing)
@propagate_inbounds Base.getindex(s::AbstractDimStack, i::Int, I::Int...) =
    map(A -> Base.getindex(A, i, I...), data(s))

for f in (:getindex, :view, :dotview)
    @eval begin
        #### Array getindex/view ###
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::Integer) = Base.$f(parent(A), i)
        @propagate_inbounds function Base.$f(A::AbstractDimArray, I...)
            I1 = dims2indices(A, I)
            a = Base.$f(parent(A), I1...)
            return a isa AbstractArray ? rebuildsliced(A, a, I1) : a
        end
        # Linear indexing returns parent type
        @propagate_inbounds Base.$f(A::AbstractDimArray, i::Union{Colon,AbstractVector{<:Integer}}) =
            Base.$f(parent(A), i)
        # Except 1D DimArrays
        @propagate_inbounds Base.$f(A::AbstractDimArray{<:Any, 1}, i::Union{Colon,AbstractVector{<:Integer}}) =
            rebuildsliced(A, Base.$f(parent(A), i), (i,))
        # Dimension indexing. Allows indexing with A[somedim=25.0] for Dim{:somedim}
        @propagate_inbounds Base.$f(A::AbstractDimArray, args::Dimension...; kw...) =
            Base.$f(A, dims2indices(A, (args..., _kwdims(kw.data)...))...)
        # Standard indices
        @propagate_inbounds Base.$f(A::AbstractDimArray, i1::StandardIndices, i2::StandardIndices, I::StandardIndices...) =
            rebuildsliced(A, Base.$f(parent(A), i1, i2, I...), (i1, i2, I...))
        @propagate_inbounds Base.$f(A::AbstractDimArray, I::CartesianIndex) = Base.$f(parent(A), I)

        #### Stack ###
        @propagate_inbounds function Base.$f(s::AbstractDimStack, I...; kw...)
            vals = map(A -> Base.$f(A, I...; kw...), dimarrays(s))
            if all(map(v -> v isa AbstractDimArray, vals))
                rebuildsliced(s, vals, (dims2indices(first(s), I)))
            else
                vals
            end
        end
    end
end

#### Array setindex ####
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x) = setindex!(parent(A), x)
@propagate_inbounds function Base.setindex!(A::AbstractDimArray, x, I...)
    I1 = dims2indices(A, I)
    Base.setindex(parent(A), x, I1...)
    A
end
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, args::Dimension...; kw...) =
    setindex!(A, x, dims2indices(A, (args..., _kwdims(kw.data)...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i, I...) =
    setindex!(A, x, dims2indices(A, maybeselector(i, I...))...)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, i1::StandardIndices, I::StandardIndices...) =
    (setindex!(parent(A), x, i1, I...); A)
@propagate_inbounds Base.setindex!(A::AbstractDimArray, x, I::CartesianIndex) =
    (setindex!(parent(A), x, I); A)
#### Stack setindex ####
@propagate_inbounds Base.setindex!(s::AbstractDimStack, xs, I...; kw...) =
    (map((A, x) -> setindex!(A, x, I...; kw...), dimarrays(s), xs); s)
@propagate_inbounds function Base.setindex!(
    s::AbstractDimStack{<:NamedTuple{K1}}, xs::NamedTuple{K2}, I...; kw...
) where {K1,K2}
    K1 == K2 || _keysmismatch(K1, K2)
    map((A, x) -> setindex!(A, x, I...; kw...), dimarrays(s), xs)
    return s
end


#### dims2indices ####

"""
    dims2indices(dim::Dimension, lookup) => NTuple{Union{Colon,AbstractArray,Int}}

Convert a `Dimension` or `Selector` lookup to indices of Int, AbstractArray or Colon.
"""
@inline dims2indices(dim::Dimension, lookup) = _dims2indices(dim, lookup)
@inline dims2indices(dim::Dimension, lookup::StandardIndices) = lookup

@inline dims2indices(x, lookup) = dims2indices(dims(x), lookup)
@inline dims2indices(::Nothing, lookup) = _dimsnotdefinederror()
@inline dims2indices(dims::DimTuple, lookup) = dims2indices(dims, (lookup,))
# Standard array indices are simply returned
@inline dims2indices(dims::DimTuple, lookup::Tuple{Vararg{<:StandardIndices}}) = lookup
@inline dims2indices(dims::DimTuple, lookup::Tuple{<:CartesianIndex}) = lookup
@inline dims2indices(dims::DimTuple, lookup::Tuple) = sel2indices(dims, lookup)
@inline dims2indices(dims::DimTuple, lookup::Tuple{}) = ()
# Otherwise attempt to convert dims to indices
@inline dims2indices(dims::DimTuple, lookup::DimTuple) =
    _dims2indices(map(mode, dims), dims, sortdims(lookup, dims))

# Handle tuples with @generated
@inline _dims2indices(modes::Tuple{}, dims::Tuple{}, lookup::Tuple{}) = ()
@generated function _dims2indices(modes::Tuple, dims::Tuple, lookup::Tuple)
    unalligned = Expr(:tuple)
    ualookups = Expr(:tuple)
    alligned = Expr(:tuple)
    dimmerge = Expr(:tuple)
    a_count = ua_count = 0
    for (i, mp) in enumerate(modes.parameters)
        if mp <: Unaligned
            ua_count += 1
            push!(unalligned.args, :(dims[$i]))
            push!(ualookups.args, :(lookup[$i]))
            push!(dimmerge.args, :(uadims[$ua_count]))
        else
            a_count += 1
            push!(alligned.args, :(_dims2indices(dims[$i], lookup[$i])))
            # Update  the merged tuple
            push!(dimmerge.args, :(adims[$a_count]))
        end
    end

    if length(unalligned.args) > 1
        # Output the dimmerge, that will combine uadims and adims in the right order
        quote
             adims = $alligned
             # Unaligned dims have to be run together as a set
             uadims = unalligned2indices($unalligned, $ualookups)
             $dimmerge
        end
    else
        alligned
    end
end
# Single dim methods
# A Dimension type always means Colon(), as if it was constructed with the default value.
@inline _dims2indices(dim::Dimension, lookup::Type{<:Dimension}) = Colon()
# Nothing means nothing was passed for this dimension
@inline _dims2indices(dim::Dimension, lookup::Nothing) = Colon()
# Simply unwrap dimensions
@inline _dims2indices(dim::Dimension, lookup::Dimension) = sel2indices(dim, val(lookup))


@noinline _keysmismatch(K1, K2) = throw(ArgumentError("NamedTuple keys $K2 do not mach stack keys $K1"))
