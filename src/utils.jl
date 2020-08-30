"""
    reversearray(A; dims) => AbstractDimArray
    reversearray(dim::Dimension) => Dimension

Reverse the array order, and update the dim to match.
"""
function reversearray end

"""
    reverseindex(A; dims) => AbstractDimArray
    reverseindex(dim::Dimension) => Dimension

Reverse the dimension index.
"""
function reverseindex end

"""
    fliparray(A; dims) => AbstractDimArray
    fliparray(dim::Dimension) => Dimension

`Flip` the array order without changing any data.
"""
function fliparray end

"""
    flipindex(A; dims) => AbstractDimArray
    flipindex(dim::Dimension) => Dimension

`Flip` the index order without changing any data.
"""
function flipindex end

"""
    fliprelation(A; dims) => AbstractDimArray
    fliprelation(dim::Dimension) => Dimension

`Flip` the relation between the dimension order and the array axis,
without actually changing any data.
"""
function fliprelation end

for func in (:reversearray, :reverseindex, :fliparray, :flipindex, :fliprelation)
    if func != :reversearray
        @eval begin
            ($func)(A::AbstractDimArray{T,N}; dims) where {T,N} = begin
                dnum = dimnum(A, dims)
                # Reverse the dimension. TODO: make this type stable
                newdims = $func(DimensionalData.dims(A), dnum)
                rebuild(A, parent(A), newdims)
            end
        end
    end
    @eval begin
        # TODO rewrite this it's awful and not type-stable
        @inline ($func)(dimstorev::Tuple, dnum) = begin
            dim = if length(dimstorev) == dnum
                ($func)(dimstorev[end])
            else
                dimstorev[end]
            end
            (($func)(Base.front(dimstorev), dnum)..., dim)
        end
        @inline ($func)(dimstorev::Tuple{}, i) = ()
        ($func)(mode::IndexMode) = rebuild(mode, ($func)(order(mode)))
    end
end

reversearray(A::AbstractDimArray{T,N}; dims=1) where {T,N} = begin
    dnum = dimnum(A, dims)
    # Reverse the dimension. TODO: make this type stable
    newdims = reversearray(DimensionalData.dims(A), dnum)
    # Reverse the data
    newdata = reverse(parent(A); dims=dnum)
    rebuild(A, newdata, newdims)
end
@inline reversearray(dim::Dimension) =
    rebuild(dim, val(dim), reversearray(mode(dim)))

@inline reverseindex(dim::Dimension) =
    rebuild(dim, reverse(val(dim)), reverseindex(mode(dim)))
@inline reverseindex(dim::Dimension{<:Val}) =
    rebuild(dim, Val(reverse(unwrap(val(dim)))), reverseindex(mode(dim)))

@inline flipindex(dim::Dimension) =
    rebuild(dim, val(dim), flipindex(mode(dim)))

@inline fliparray(dim::Dimension) =
    rebuild(dim, val(dim), fliparray(mode(dim)))

@inline fliprelation(dim::Dimension) =
    rebuild(dim, val(dim), fliprelation(mode(dim)))


"""
    reorderindex(A, order::Union{Order,Dimension{<:Order},Tuple})

Reorder every dims index to `order`, or reorder index for 
the the given dimension(s) to the `Order` they wrap.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref) 
or a `Tuple` of `Dimension`.
"""
function reorderindex end

"""
    reorderarray(A, order::Union{Order,Dimension{<:Order},Tuple})

Reorder the array to `order` for every axis, or reorder array 
for the the given dimension(s) to the `Order` they wrap.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref) 
or a `Tuple` of `Dimension`.
"""
function reorderarray end

"""
    reorderrelation(A, order::Union{Order,Dimension{<:Order},Tuple})

Reorder relation to `order` for every dimension, or reorder relation 
for the the given dimension(s) to the `Order` they wrap.

This will reverse the array, not the dimension index.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref) 
or a `Tuple` of `Dimension`.
"""
function reorderrelation end


for target in (:index, :array, :relation)
    reorder = Symbol(:reorder, target)
    if target == :relation 
        # Revsersing the relation reverses the array, not the index
        reverse = :reversearray
        ord = relation
    else
        reverse = Symbol(:reverse, target)
        ord = Symbol(target, :order)
    end
    @eval begin

        ($reorder)(A::AbstractDimArray, order::Tuple, args...) = begin
            for dim in _sortdims(order, dims(A))
                A = ($reorder)(A, dim, args...)
            end
            A
        end
        ($reorder)(A::AbstractDimArray, orderdim::Dimension{<:Order}) =
            ($reorder)(A, orderdim, val(orderdim))
        ($reorder)(A::AbstractDimArray, order::Nothing) = A
        ($reorder)(A::AbstractDimArray, order::Order=Forward()) = begin
            for dim in dims(A)
                A = ($reorder)(A, dim, order)
            end
            A
        end
        ($reorder)(A::AbstractDimArray, dim::DimOrDimType, order::Order) =
            if order == ($ord)(dims(A, dim))
                A
            else
                ($reverse)(A; dims=dim)
            end
        ($reorder)(A::AbstractDimArray, dim::DimOrDimType, order::Unordered) = A
    end
end


"""
    modify(f, A::AbstractDimArray) => AbstractDimArray

Modify the parent data, rebuilding the `AbstractDimArray` wrapper without
change. `f` must return a `AbstractArray` of the same size as the original.
"""
modify(f, A::AbstractDimArray) = begin
    newdata = f(parent(A))
    size(newdata) == size(A) || error("$f returns an array with a different size")
    rebuild(A, newdata)
end


"""
    dimwise(f, A::AbstractDimArray{T,N}, B::AbstractDimArray{T2,M}) => AbstractDimArray{T3,N}

Dimension-wise application of function `f` to `A` and `B`. 

## Arguments

- `a`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
- `b`: `AbstractDimArray` to broadcast from all dimensions. Dimensions must be a subset of a.

This is like broadcasting over every slice of `A` if it is 
sliced by the dimensions of `B`.
"""
dimwise(f, A::AbstractDimArray, B::AbstractDimArray) = 
    dimwise!(f, similar(A, promote_type(eltype(A), eltype(B))), A, B)

"""
    dimwise!(f, dest::AbstractDimArray{T1,N}, A::AbstractDimArray{T2,N}, B::AbstractDimArray) => dest

Dimension-wise application of function `f`. 

## Arguments

- `dest`: `AbstractDimArray` to update
- `a`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
- `b`: `AbstractDimArray` to broadcast from all dimensions. Dimensions must be a subset of a.

This is like broadcasting over every slice of `A` if it is 
sliced by the dimensions of `B`, and storing the value in `dest`.
"""
dimwise!(f, dest::AbstractDimArray{T,N}, a::AbstractDimArray{TA,N}, b::AbstractDimArray{TB,NB}
        ) where {T,TA,TB,N,NB} = begin
    N >= NB || error("B-array cannot have more dimensions than A array")
    comparedims(dest, a)
    common = commondims(a, dims(b))
    generators = dimwise_generators(otherdims(a, common))
    # Lazily permute B dims to match the order in A, if required
    if !dimsmatch(common, dims(b))
        b = PermutedDimsArray(b, common)
    end
    # Broadcast over b for each combination of dimensional indices D
    map(generators) do D
        dest[D...] .= f.(a[D...], b)
    end
    return dest
end

# Single dimension generator
dimwise_generators(dims::Tuple{<:Dimension}) =  
    ((basetypeof(dims[1])(i),) for i in axes(dims[1], 1))

# Multi dimensional generators
dimwise_generators(dims::Tuple) = begin
    dim_constructors = map(basetypeof, dims)
    # Get the axes of the dims to iterate over
    dimaxes = map(d -> axes(d, 1), dims)
    # Make an iterator over all axes
    proditr = Base.Iterators.ProductIterator(dimaxes)
    # Wrap the produced index I in dimensions as it is generated
    Base.Generator(proditr) do I
        map((D, i) -> D(i), dim_constructors, I)
    end
end



"""
    basetypeof(x) => Type

Get the "base" type of an object - the minimum required to
define the object without it's fields. By default this is the full
`UnionAll` for the type. But custom `basetypeof` methods can be
defined for types with free type parameters.

In DimensionalData this is primariliy used for comparing `Dimension`s,
where `Dim{:x}` is different from `Dim{:y}`.
"""
basetypeof(x) = basetypeof(typeof(x))
@generated function basetypeof(::Type{T}) where T
    getfield(parentmodule(T), nameof(T))
end

# Left pipe operator for cleaning up brackets
f <| x = f(x)

unwrap(::Val{X}) where X = X
unwrap(::Type{Val{X}}) where X = X
unwrap(x) = x


