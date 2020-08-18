
reversearray(A::AbDimArray{T,N}; dims=1) where {T,N} = begin
    dnum = dimnum(A, dims)
    # Reverse the dimension. TODO: make this type stable
    newdims = reversearray(DimensionalData.dims(A), dnum)
    # Reverse the data
    newdata = reverse(data(A); dims=dnum)
    rebuild(A, newdata, newdims)
end
@inline reversearray(dimstorev::Tuple, dnum) = begin
    dim = if length(dimstorev) == dnum
        reversearray(dimstorev[end])
    else
        dimstorev[end]
    end
    (reversearray(Base.front(dimstorev), dnum)..., dim)
end
@inline reversearray(dimstorev::Tuple{}, i) = ()
@inline reversearray(dim::Dimension) =
    rebuild(dim, val(dim), reversearray(mode(dim)))

reverseindex(A::AbDimArray{T,N}; dims=1) where {T,N} = begin
    newdims = reverseindex(DimensionalData.dims(A), dimnum(A, dims))
    rebuild(A, data(A), newdims)
end
@inline reverseindex(dimstorev::Tuple, dnum) = begin
    dim = if length(dimstorev) == dnum
        reverseindex(dimstorev[end])
    else
        dimstorev[end]
    end
    (reverseindex(Base.front(dimstorev), dnum)..., dim)
end
@inline reverseindex(dimstorev::Tuple{}, i) = ()
@inline reverseindex(dim::Dimension) =
    rebuild(dim, reverse(val(dim)), reverseindex(mode(dim)))
@inline reverseindex(dim::Dimension{<:Val}) =
    rebuild(dim, Val(reverse(unwrap(val(dim)))), reverseindex(mode(dim)))


"""
    reorderarray(A, order::Dimension{<:Order})

Reorder the array axes for the given dimension(s), to the order they wrap.

`order` can be a single `Dimension` or a `Tuple` of `Dimension`.
"""
reorderarray(A::AbstractDimensionalArray, order::Tuple, args...) = begin
    for dim in _sortdims(order, dims(A))
        A = reorderarray(A, dim, args...)
    end
    A
end
reorderarray(A::AbstractDimensionalArray, orderdim::Dimension{<:Order}) =
    reorderarray(A, orderdim, val(orderdim))
reorderarray(A::AbstractDimensionalArray, order::Nothing) = A
"""
    reorderarray(A, order::Order)

Reorder all array axes to match `order`.
"""
reorderarray(A::AbstractDimensionalArray, order::Order=Forward()) = begin
    for dim in dims(A)
        A = reorderarray(A, dim, order)
    end
    A
end
reorderarray(A::AbstractDimensionalArray, dim::DimOrDimType, order::Order) =
    if order == arrayorder(dims(A, dim))
        A
    else
        reversearray(A; dims=dim)
    end
reorderarray(A::AbstractDimensionalArray, dim::DimOrDimType, order::Unordered) = A

"""
    reorderrelation(A, order::Dimension{<:Order})

Reorder the relation axes for the given dimension(s), to the order they wrap.

`order` can be a single `Dimension` or a `Tuple` of `Dimension`.
"""
reorderrelation(A::AbstractDimensionalArray, order::Tuple, args...) = begin
    for dim in _sortdims(order, dims(A))
        A = reorderrelation(A, dim, args...)
    end
    A
end
reorderrelation(A::AbstractDimensionalArray, orderdim::Dimension{<:Order}) =
    reorderrelation(A, orderdim, val(orderdim))
reorderrelation(A::AbstractDimensionalArray, order::Nothing) = A
"""
    reorderrelation(A, order::Order)

Reorder all relation axes to match `order`.
"""
reorderrelation(A::AbstractDimensionalArray, order::Order=Forward()) = begin
    for dim in dims(A)
        A = reorderrelation(A, dim, order)
    end
    A
end
reorderrelation(A::AbstractDimensionalArray, dim::DimOrDimType, order::Order) =
    if order == relationorder(dims(A, dim))
        A
    else
        # reverse the array, not the dim
        reversearray(A; dims=dim)
    end
reorderrelation(A::AbstractDimensionalArray, dim::DimOrDimType, order::Unordered) = A

"""
    reorderindex(A, order::Dimension{<:Order})

Reorder the dim index for the given dimension(s) to the order they wrap.

`order` can be a single `Dimension` or a `Tuple` of `Dimension`.
"""
reorderindex(A::AbstractDimensionalArray, order::Tuple, args...) = begin
    for dim in _sortdims(order, dims(A))
        A = reorderindex(A, dim, args...)
    end
    A
end
reorderindex(A::AbstractDimensionalArray, orderdim::Dimension{<:Order}) =
    reorderindex(A, orderdim, val(orderdim))
reorderindex(A::AbstractDimensionalArray, order::Nothing) = A
"""
    reorderindex(A, order::Order)

Reorder all dim indexes to match `order`.
"""
reorderindex(A::AbstractDimensionalArray, order::Order=Forward()) = begin
    for dim in dims(A)
        A = reorderindex(A, dim, order)
    end
    A
end
reorderindex(A::AbstractDimensionalArray, dim::DimOrDimType, order::Order) =
    if order == indexorder(dims(A, dim))
        A
    else
        reverseindex(A, dims=dim)
    end
reorderindex(A::AbstractDimensionalArray, dim::DimOrDimType, order::Unordered) = A

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


