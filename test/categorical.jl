using DimensionalData, CategoricalArrays

x = DimArray([1, 2, 3], X(1:3))
c = categorical(x; levels = [1,2,3,4])
x2 = DimArray([1, 2, 3, missing], X(1:4))
c2 = categorical(x2; levels = [1,2,3,4])

@test c isa DimArray
@test c2 isa DimArray

@testset "compress" begin
    c_compressed = compress(c)
    @test c_compressed isa DimArray
    @test eltype(CategoricalArrays.refs(c_compressed)) == UInt8

    c_decompressed = decompress(c_compressed)
    @test c_decompressed isa DimArray
    @test eltype(CategoricalArrays.refs(c_decompressed)) == UInt32
end

@testset "levels" begin
    @test CategoricalArrays.leveltype(c) == Int64
    @test CategoricalArrays.leveltype(c2) == Int64
    @test levels(c) == levels(c2) == [1,2,3,4]
    droplevels!(c)
    droplevels!(c2)
    @test levels(c) == levels(c2) == [1,2,3]
    c3 = levels!(c, [1,2,3,4])
    levels!(c2, [1,2,3,4])
    @test levels(c) == levels(c2) == [1,2,3,4]
    @test c3 === c

    @test !isordered(c)
    ordered!(c, true)
    @test isordered(c)

    fill!(c2, 1) |> droplevels!
    @test levels(c2) == [1]
end

@testset "recode" begin
    c = categorical(x)
    c2 = categorical(x2)
    # on a normal dim array
    @test recode(x, 1 => 2) == rebuild(x; data = [2,2,3])
    # with a default
    @test recode(x, 2, 3 => 4) == rebuild(x; data = [2,2,4])
    # on a categorical dim array
    @test recode(c, 1 => 2) == rebuild(c; data = [2,2,3])

    # in-place
    recode!(c, 1 => 2)
    @test c == rebuild(c; data = [2,2,3])

    c3 = categorical(x)
    recode!(c3, c, 2 => 3)
    @test c3 == rebuild(c; data = [3,3,3])

    # from a dim array to a normal array
    A = categorical([1,2,3])
    recode!(A, c, 3 => 2)
    @test A == categorical([2,2,2]; levels = [1,2,3])
    recode!(A, x, 3 => 2)
    @test A == categorical([1,1,2]; levels = [1,2,3])
    # with a default
    recode!(A, c, 3, 2 => 1)
    @test A == categorical([1,1,3]; levels = [1,2,3])
    recode!(A, x, 3, 2 => 1)
    @test A == categorical([1,1,3]; levels = [1,2,3])

    ## from an array to a dim array
    A = categorical([1,2,3])
    recode!(c3, A, 2 => 3)
    @test c3 == rebuild(c3; data = [1,3,3])
    recode!(x, A, 2 => 3)
    @test x == rebuild(x; data = [1,3,3])
    # with a default
    recode!(c3, A, 2, 2 => 3)
    @test c3 == rebuild(c3; data = [2,3,2])
    recode!(x, A, 2, 2 => 3)
    @test x == rebuild(x; data = [2,3,2])
end

@testset "cut" begin
    x = DimArray([0.0, 0.2, 0.4, 0.6], X(1:4))
    c = cut(x,2)
    @test c isa DimArray{<:CategoricalArrays.CategoricalValue}
    @test length(levels(c)) == 2
    @test all(CategoricalArrays.refs(c) .== [1,1,2,2])

    c2 = cut(x, [0.1, 0.5, 1.0];extend = missing)
    @test c2 isa DimArray{<:CategoricalArrays.CategoricalValue}
    @test length(levels(c2)) == 2
    @test all(CategoricalArrays.refs(c2) .== [0,1,1,2])
    @test ismissing(first(c2))
end