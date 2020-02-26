using Test, DimensionalData, SparseArrays, Combinatorics
using Base: product

"""Basic indexers which are valid for the provided axis"""
function basic_indexers(axis::AbstractArray)
    (
        rand(1:length(axis)),  # Integer
        UnitRange(rand(1:length(axis), 2)...),  # Slice
        rand(1:length(axis), rand(1:length(axis)))  # Array
    )
end

integer_index(d::AbstractDimension) = rand(1:length(d))
slice_index(d::AbstractDimension) = UnitRange(sort!(rand(1:length(d), 2))...)
array_index(d::AbstractDimension) = rand(1:length(d), rand(1:length(d)))
single_selector(d::AbstractDimension) = At(rand(val(d)))
between_selector(d::AbstractDimension{<:Any, G} where G<:AbstractAlignedGrid{<:Ordered}) = Between(sort!(rand(val(d), 2))...)

index_methods = Function[
    integer_index,
    slice_index,
    array_index,
    single_selector,
    between_selector,
]

positional_indexers(dim) = map(x->x(dim), filter(x->applicable(x, dim), index_methods))
dim_indexers(dim) = map(constructorof(typeof(dim)), positional_indices(dim))

@testset "indexing" begin
    da_basic_dims = DimensionalArray(randn(50, 50, 50), (X, Y, Z))
    sda_basic_dims = DimensionalArray(sprand(50, 50, .1), (X, Y))
    da_char_dims = DimensionalArray(randn(5, 5, 5), (X('a':'e'), Y('f':'j'), Z('k':'o')))
    da_mixed_dims = DimensionalArray(randn(5, 5, 5), (X('a':'e'), Y(5:-1:1), Z(100:2:108)))

    arrays = [
        da_basic_dims,
        sda_basic_dims,
        da_char_dims,
        da_mixed_dims
    ]

    for array in arrays
        for idx in product(map(basic_indexers, axes(array))...)
            @test (@inferred array[idx...]) == data(array)[idx...]
        end
        for idx in product(map(positional_indices, dims(array))...)
            @inferred array[idx...]
            @inferred view(array, idx...)
        end
        for c in combinations(dims(array))
            for idx in product(map(dim_indexers, c)...)
                @inferred array[idx...]
                @inferred view(array, idx...)
            end
        end
    end
end
