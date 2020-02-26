using Test, DimensionalData, SparseArrays, Combinatorics
using Base: product
using DimensionalData: constructorof

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
colon_index(d::AbstractDimension) = Colon()
array_index(d::AbstractDimension) = rand(1:length(d), rand(1:length(d)))
single_selector(d::AbstractDimension) = At(rand(val(d)))
between_selector(d::AbstractDimension{<:Any, G} where G<:AbstractAlignedGrid{<:Ordered}) = Between(sort!(rand(val(d), 2))...)

index_methods = Function[
    integer_index,
    slice_index,
    array_index,
    colon_index,
    single_selector,
    between_selector,
]

"""Modified version of @inferred which doesn't crash the test run when it fails."""
macro test_inferred(ex)
    _test_inferred(ex, __module__)
end
macro test_inferred(allow, ex)
    _test_inferred(ex, __module__, allow)
end
function _test_inferred(ex, mod, allow = :(Union{}))
    if Meta.isexpr(ex, :ref)
        ex = Expr(:call, :getindex, ex.args...)
    end
    str_rep = string(ex)
    Meta.isexpr(ex, :call)|| error("@test_inferred requires a call expression")
    farg = ex.args[1]
    if isa(farg, Symbol) && first(string(farg)) == '.'
        farg = Symbol(string(farg)[2:end])
        ex = Expr(:call, GlobalRef(Test, :_materialize_broadcasted),
            farg, ex.args[2:end]...)
    end
    Base.remove_linenums!(quote
        let
            allow = $(esc(allow))
            allow isa Type || throw(ArgumentError("@test_inferred requires a type as second argument"))
            $(if any(a->(Meta.isexpr(a, :kw) || Meta.isexpr(a, :parameters)), ex.args)
                # Has keywords
                args = gensym()
                kwargs = gensym()
                quote
                    $(esc(args)), $(esc(kwargs)), result = $(esc(Expr(:call, Test._args_and_call, ex.args[2:end]..., ex.args[1])))
                    inftypes = $(Test.gen_call_with_extracted_types(mod, Base.return_types, :($(ex.args[1])($(args)...; $(kwargs)...))))
                end
            else
                # No keywords
                quote
                    args = ($([esc(ex.args[i]) for i = 2:length(ex.args)]...),)
                    result = $(esc(ex.args[1]))(args...)
                    inftypes = Base.return_types($(esc(ex.args[1])), Base.typesof(args...))
                end
            end)
            @assert length(inftypes) == 1
            rettype = result isa Type ? Type{result} : typeof(result)
            result = rettype <: allow || rettype == Test.typesubtract(inftypes[1], allow)
            if !(result)
                # TODO: Is there a better way to report this?
                println(
                    "`", $str_rep, "` failed to infer correctly for args:\n\t", join(map(string ∘ typeof, args), ",\n\t")..., 
                    "\n\n Predicted types are:\n\t", join(map(string, inftypes), "\n\t")
                )
            end
            result
        end
    end)
end

positional_indexers(dim) = map(x->x(dim), filter(x->applicable(x, dim), index_methods))
dim_indexers(dim) = map(constructorof(typeof(dim)), positional_indexers(dim))

@testset "indexing" begin
    da_basic_dims = DimensionalArray(randn(50, 50, 50), (X, Y, Z))
    sda_basic_dims = DimensionalArray(sprand(50, 50, .1), (X, Y))
    da_char_dims = DimensionalArray(randn(5, 5, 5), (X('a':'e'), Y('f':'j'), Z('k':'o')))
    da_mixed_int_dims = DimensionalArray(randn(2, 2, 2, 2), (X([1, 2]), Y(2:-1:1), Z(100:50:150), Dim{:W}([-2, -100])))
    da_mixed_dims = DimensionalArray(randn(5, 5, 5), (X('a':'e'), Y(5:-1:1), Z(100:2:108)))
    da_mixed_array_dims = DimensionalArray(randn(5, 5, 5), (X([1.5, 2.3, 9.5, 7.3, 8.]), Y(rand('a':'z', 5)), Z(["the", "quick", "brown", "fox", "jumped"])))

    arrays = [
        da_basic_dims,
        sda_basic_dims,
        da_mixed_int_dims,
        da_char_dims,
        da_mixed_dims,
        da_mixed_array_dims
    ]

    @testset "positional indexing" begin
    for array in arrays
        for pos_idx in product(map(positional_indexers, dims(array))...)
            @test @test_inferred array[pos_idx...]
            @test @test_inferred view(array, pos_idx...)
        end
    end
    end
    @testset "dimensional indexing" begin
    for array in arrays
        for c in combinations(dims(array))
            for dim_idx in product(map(dim_indexers, c)...)
                @test @test_inferred array[dim_idx...]
                @test @test_inferred view(array, dim_idx...)
            end
        end
    end
    end
end;
