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
    rc1 = recode(x, 1 => 2) 
    @test rc1 == [2,2,3]
    @test rc1 isa DimArray
    # with a default
    rc2 = recode(x, 2, 3 => 4)
    @test rc2 == [2,2,4]
    @test rc2 isa DimArray
    # on a categorical dim array
    rc3 = recode(c, 1 => 2) 
    @test rc3 == [2,2,3]
    @test rc3 isa DimArray

    # in-place
    recode!(c, 1 => 2)
    @test c == [2,2,3]

    c3 = categorical(x)
    recode!(c3, c, 2 => 3)
    @test c3 == [3,3,3]

    # from a dim array to a normal array
    c = categorical(x)
    A = categorical([1,2,2])
    recode!(A, c, 3 => 2)
    @test A == [1,2,2]
    recode!(A, x, 2 => 1, 3 => 2)
    @test A == [1,1,2]

    # with a default
    recode!(A, c, 3, 2 => 1)
    @test A == [3,1,3]
    recode!(A, x, 3, 2 => 1)
    @test A == [3,1,3]

    ## from an array to a dim array
    A = categorical([1,2,3])
    rc = recode!(c3, A, 2 => 3)
    @test c3 == [1,3,3]
    @test c3 isa DimArray
    @test rc === c3
    recode!(x, A, 2 => 3)
    @test x == [1,3,3]
    # with a default
    recode!(c3, A, 2, 2 => 3)
    @test c3 == [2,3,2]
    recode!(x, A, 2, 2 => 3)
    @test x == [2,3,2]
end

@testset "cut" begin
    x = DimArray([0.0, 0.2, 0.4, 0.6], X(1:4))
    c = cut(x,2)
    @test c isa DimArray{<:CategoricalArrays.CategoricalValue}
    @test length(levels(c)) == 2
    @test all(CategoricalArrays.refs(c) .== [1,1,2,2])

    c2 = cut(x, [0.1, 0.5, 1.0];extend = missing)
    @test c2 isa DimArray{<:Union{Missing, <:CategoricalArrays.CategoricalValue}}
    @test length(levels(c2)) == 2
    @test all(CategoricalArrays.refs(c2) .== [0,1,1,2])
    @test ismissing(first(c2))
end