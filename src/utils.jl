
for func in (:reversearray, :reverseindex, :fliparray, :flipindex, :fliprelation)
    if func != :reversearray
        @eval begin
            ($func)(A::AbDimArray{T,N}; dims=1) where {T,N} = begin
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

reversearray(A::AbDimArray{T,N}; dims=1) where {T,N} = begin
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

        ($reorder)(A::AbstractDimensionalArray, order::Tuple, args...) = begin
            for dim in _sortdims(order, dims(A))
                A = ($reorder)(A, dim, args...)
            end
            A
        end
        ($reorder)(A::AbstractDimensionalArray, orderdim::Dimension{<:Order}) =
            ($reorder)(A, orderdim, val(orderdim))
        ($reorder)(A::AbstractDimensionalArray, order::Nothing) = A
        ($reorder)(A::AbstractDimensionalArray, order::Order=Forward()) = begin
            for dim in dims(A)
                A = ($reorder)(A, dim, order)
            end
            A
        end
        ($reorder)(A::AbstractDimensionalArray, dim::DimOrDimType, order::Order) =
            if order == ($order)(dims(A, dim))
                A
            else
                ($reverse)(A; dims=dim)
            end
        ($reorder)(A::AbstractDimensionalArray, dim::DimOrDimType, order::Unordered) = A
    end
end


"""
    modify(f, A::AbstractDimensionalArray)

Modify the parent data, rebuilding the `AbstractDimensionalArray` wrapper.
`f` must return a `AbstractArray` of the same size as the original.
"""
modify(f, A::AbstractDimensionalArray) = begin
    newdata = f(data(A))
    size(newdata) == size(A) || error("$f returns an array with a different size")
    rebuild(A, newdata)
end


basetypeof(x) = basetypeof(typeof(x))
@generated function basetypeof(::Type{T}) where T
    getfield(parentmodule(T), nameof(T))
end

# Left pipe operator for cleaning up brackets
f <| x = f(x)

unwrap(::Val{X}) where X = X
unwrap(::Type{Val{X}}) where X = X
unwrap(x) = x


