
for func in (:reversearray, :reverseindex, :fliparray, :flipindex, :fliprelation)
    if func != :reversearray
        @eval begin
            ($func)(A::AbstractDimArray{T,N}; dims=1) where {T,N} = begin
                dnum = dimnum(A, dims)
                # Reverse the dimension. TODO: make this type stable
                newdims = $func(DimensionalData.dims(A), dnum)
                rebuild(A, data(A), newdims)
            end
        end
    end
    @eval begin
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
    newdata = reverse(data(A); dims=dnum)
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

Reorder index to `order`, or reorder index for the the given 
dimension(s) to the `Order` they wrap.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref) 
or a `Tuple` of `Dimension`.
"""
function reorderindex end

"""
    reorderarray(A, order::Union{Order,Dimension{<:Order},Tuple})

Reorder array to `order`, or reorder array for the the given 
dimension(s) to the `Order` they wrap.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref) 
or a `Tuple` of `Dimension`.
"""
function reorderarray end

"""
    reorderrelation(A, order::Union{Order,Dimension{<:Order},Tuple})

Reorder relation to `order`, or reorder relation for the the given 
dimension(s) to the `Order` they wrap.

`order` can be an [`Order`](@ref), a single [`Dimension`](@ref) 
or a `Tuple` of `Dimension`.
"""
function reorderrelation end


for target in (:index, :array, :relation)
    local order = Symbol(target, :order)
    reorder = Symbol(:reorder, target)
    reverse = if target == :relation 
        # Revsersing the relation reverses the array, not the index
        :reversearray
    else
        Symbol(:reverse, target)
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
            if order == ($order)(dims(A, dim))
                A
            else
                ($reverse)(A; dims=dim)
            end
        ($reorder)(A::AbstractDimArray, dim::DimOrDimType, order::Unordered) = A
    end
end


"""
    modify(f, A::AbstractDimArray)

Modify the parent data, rebuilding the `AbstractDimArray` wrapper.
`f` must return a `AbstractArray` of the same size as the original.
"""
modify(f, A::AbstractDimArray) = begin
    newdata = f(data(A))
    size(newdata) == size(A) || error("$f returns an array with a different size")
    rebuild(A, newdata)
end


"""
    dimwise!(f, A::AbstractDimArray, B::AbstractDimArray)

Dimension-wise application of function `f`. 

## Arguments

-`a`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
-`b`: `AbstractDimArray` to broadcast from all diensions. 
  Dimensions must be a subset of a.

This is like broadcasting over every slice of `A` if it is 
sliced by the dimensions of `B`, and storing the value in `dest`.
"""
dimwise(f, A::AbstractDimArray, B::AbstractDimArray) = 
    dimwise!(f, similar(A, promote_type(eltype(A), eltype(B))), A, B)

"""
    dimwise!(f, dest::AbstractDimArray, A::AbstractDimArray, B::AbstractDimArray)

Dimension-wise application of function `f`. 

## Arguments

-`dest`: `AbstractDimArray` to update
-`a`: `AbstractDimArray` to broacast from, along dimensions not in `b`.
-`b`: `AbstractDimArray` to broadcast from all diensions. 
  Dimensions must be a subset of a.

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
    map(generators) do otherdims
        I = (common..., otherdims...)
        dest[I...] .= f.(a[I...], b[common...])
    end
    return dest
end

dimwise_generators(dims::Tuple{<:Dimension}) =  
    ((basetypeof(dims[1])(i),) for i in axes(dims[1], 1))

dimwise_generators(dims::Tuple) = begin
    dim_constructors = map(basetypeof, dims)
    Base.Generator(
        Base.Iterators.ProductIterator(map(d -> axes(d, 1), dims)),
        vals -> map(dim_constructors, vals)
    )
end

"""
    basetypeof(x)

Get the base type of an object - the minimum required to
define the object without it's fields. By default this is the full
`UnionAll` for the type. But custom `basetypeof` methods can be
defined for types with free type parameters.

In DimensionalData this is primariliy used for comparing dimensions,
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


