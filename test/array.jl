using DimensionalData, Test, Unitful, OffsetArrays, SparseArrays
using DimensionalData: Start, formatdims, basetypeof, identify

a = [1 2; 3 4]
dimz = (X(143.0:2:145.0; mode=Sampled(order=Ordered()), metadata=Dict(:meta => "X")),
        Y(-38.0:2:-36.0; mode=Sampled(order=Ordered()), metadata=Dict(:meta => "Y")))
da = DimensionalArray(a, dimz, "test"; refdims=refdimz, metadata=Dict(:meta => "da"))

@testset "getindex for single integers returns values" begin
    @test da[X(1), Y(2)] == 2
    @test da[X(2), Y(2)] == 4
    @test da[1, 2] == 2
    @test da[2] == 3
    @inferred getindex(da, X(2), Y(2))
end

@testset "LinearIndex getindex returns an Array, except Vector" begin
    @test da[1:2] isa Array
    @test da[1, :][1:2] isa DimensionalArray
end

@testset "getindex returns DimensionArray slices with the right dimensions" begin
    a = da[X(1:2), Y(1)]
    @test a == [1, 3]
    @test typeof(a) <: DimensionalArray{Int,1}
    @test dims(a) == (X(LinRange(143.0, 145.0, 2),
                        Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),)
    @test refdims(a) == 
        (Ti(1:1), Y(-38.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")),)
    @test name(a) == "test"
    @test metadata(a) == Dict(:meta => "da")
    @test metadata(a, X) == Dict(:meta => "X")
    @test bounds(a) == ((143.0, 145.0),)
    @test bounds(a, X) == (143.0, 145.0)
    @test locus(mode(dims(da, X))) == Center()

    a = da[X(1), Y(1:2)]
    @test a == [1, 2]
    @test typeof(a) <: DimensionalArray{Int,1}
    @test typeof(data(a)) <: Array{Int,1}
    @test dims(a) == 
        (Y(LinRange(-38.0, -36.0, 2), Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")),)
    @test refdims(a) == 
        (Ti(1:1), X(143.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),)
    @test name(a) == "test"
    @test metadata(a) == Dict(:meta => "da")
    @test bounds(a) == ((-38.0, -36.0),)
    @test bounds(a, Y()) == (-38.0, -36.0)

    a = da[X(:), Y(:)]
    @test a == [1 2; 3 4]
    @test typeof(a) <: DimensionalArray{Int,2}
    @test typeof(data(a)) <: Array{Int,2}
    @test typeof(dims(a)) <: Tuple{<:X,<:Y}
    @test dims(a) == (X(LinRange(143.0, 145.0, 2),
                        Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),
                      Y(LinRange(-38.0, -36.0, 2),
                        Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")))
    @test refdims(a) == (Ti(1:1),)
    @test name(a) == "test"
    @test bounds(a) == ((143.0, 145.0), (-38.0, -36.0))
    @test bounds(a, X) == (143.0, 145.0)
end

@testset "view returns DimensionArray containing views" begin
    v = view(da, Y(1), X(1))
    @test v[] == 1
    @test typeof(v) <: DimensionalArray{Int,0}
    @test typeof(data(v)) <:SubArray{Int,0}
    @test typeof(dims(v)) == Tuple{}
    @test dims(v) == ()
    @test refdims(v) == 
        (Ti(1:1), X(143.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),
         Y(-38.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")))
    @test name(v) == "test"
    @test metadata(v) == Dict(:meta => "da")
    @test bounds(v) == ()

    v = view(da, Y(1), X(1:2))
    @test v == [1, 3]
    @test typeof(v) <: DimensionalArray{Int,1}
    @test typeof(data(v)) <: SubArray{Int,1}
    @test typeof(dims(v)) <: Tuple{<:X}
    @test dims(v) == 
        (X(LinRange(143.0, 145.0, 2), 
           Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),)
    @test refdims(v) == 
        (Ti(1:1), Y(-38.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")),)
    @test name(v) == "test"
    @test metadata(v) == Dict(:meta => "da")
    @test bounds(v) == ((143.0, 145.0),)

    @inferred v = view(da, Y(1:2), X(1:1))
    @test v == [1 2]
    @test typeof(v) <: DimensionalArray{Int,2}
    @test typeof(data(v)) <: SubArray{Int,2}
    @test typeof(dims(v)) <: Tuple{<:X,<:Y}
    @test dims(v) == 
        (X(LinRange(143.0, 143.0, 1),
           Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),
         Y(LinRange(-38, -36, 2), 
           Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")))
    @test bounds(v) == ((143.0, 143.0), (-38.0, -36.0))

    v = view(da, Y(Base.OneTo(2)), X(1))
    @test v == [1, 2]
    @test typeof(data(v)) <: SubArray{Int,1}
    @test typeof(dims(v)) <: Tuple{<:Y}
    @test dims(v) == 
        (Y(LinRange(-38.0, -36.0, 2),
           Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")),)
    @test refdims(v) == 
        (Ti(1:1), X(143.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),)
    @test bounds(v) == ((-38.0, -36.0),)
end

a2 = [1 2 3 4
      3 4 5 6
      4 5 6 7]
b2 = [4 4 4 4
      4 4 4 4
      4 4 4 4]

@testset "indexing into empty dims is just regular indexing" begin
    ida = DimensionalArray(a2, (X, Y))
    ida[Y(3:4), X(2:3)] = [5 6; 6 7]
end


dimz2 = (Dim{:row}((10, 30)), Dim{:column}((-20, 10)))
da2 = DimensionalArray(a2, dimz2, "test2"; refdims=refdimz)

@testset "arbitrary dimension names also work for indexing" begin
    @test da2[Dim{:row}(2)] == [3, 4, 5, 6]
    @test da2[Dim{:column}(4)] == [4, 6, 7]
    @test da2[Dim{:column}(1), Dim{:row}(3)] == 4
    @inferred getindex(da2, Dim{:column}(1), Dim{:row}(3))
end

@testset "size and axes" begin
    @test size(da2, Dim{:row}) == 3
    @test size(da2, Dim{:column}()) == 4
    @test axes(da2, Dim{:row}()) == 1:3
    @test axes(da2, Dim{:column}) == 1:4
    @inferred axes(da2, Dim{:column})
end

@testset "OffsetArray" begin
    oa = OffsetArray(a2, -1:1, 5:8)
    @testset "Regular dimensions don't work: axes must match" begin
        dimz = (X(100:100:300), Y([:a, :b, :c, :d]))
        @test_throws DimensionMismatch DimensionalArray(oa, dimz)
    end
    odimz = (X(OffsetArray(100:100:300, -1:1)), Y(OffsetArray([:a, :b, :c, :d], 5:8)))
    oda = DimensionalArray(oa, odimz)
    @testset "Indexing and selectors work with offsets" begin
        @test axes(oda) == (-1:1, 5:8)
        @test oda[-1, 5] == oa[-1, 5] == 1
        @test oda[Near(105), At(:a)] == oa[-1, 5] == 1
        @test oda[Between(100, 250), At(:a)] == oa[-1:0, 5] == [1, 3]
    end
    @testset "Subsetting reverts to a regular array and dims" begin
        @test axes(oda[0:1, 7:8]) == (1:2, 1:2)
        @test axes.(dims(oda[0:1, 7:8])) == ((1:2,), (1:2,))
    end
end

@testset "similar" begin
    da_sim = similar(da2)
    @test eltype(da_sim) == eltype(da2)
    @test size(da_sim) == size(da2)
    @test dims(da_sim) == dims(da2)
    @test refdims(da_sim) == refdims(da2)

    da_float = similar(da2, Float64)
    @test eltype(da_float) == Float64
    @test size(da_float) == size(da2)
    @test dims(da_float) == dims(da2)
    @test refdims(da_float) == refdims(da2)

    da_size_float = similar(da2, Float64, (10, 10))
    @test eltype(da_size_float) == Float64
    @test size(da_size_float) == (10, 10)

    sda = DimensionalArray(sprand(Float64, 10, 10, .5), (X, Y))
    sparse_size_int = similar(sda, Int64, (5, 5))
    @test eltype(sparse_size_int) == Int64 != eltype(sda)
    @test size(sparse_size_int) == (5, 5)
    @test sparse_size_int isa SparseMatrixCSC

    # TODO what should this actually be?
    # Some dimensions (i.e. where values are not explicitly enumerated) could be resizable?
    # @test dims(da_float) == dims(da2)
    # @test refdims(da_float) == refdims(da2)
end

@testset "broadcast" begin
    da = DimensionalArray(ones(Int, 5, 2, 4), (Y((10, 20)), Ti(10:11), X(1:4)))
    dab = da .* 2.0
    @test dab == fill(2.0, 5, 2, 4)
    @test eltype(dab) <: Float64
    @test dims(dab) ==
        (Y(LinRange(10, 20, 5); mode=Sampled(Ordered(), Regular(2.5), Points())),
         Ti(10:11; mode=Sampled(Ordered(), Regular(1), Points())),
         X(1:4; mode=Sampled(Ordered(), Regular(1), Points())))
    dab = da .+ fill(10, 5, 2, 4)
    @test dab == fill(11, 5, 2, 4)
    @test eltype(dab) <: Int

    # TODO permute dims to match in broadcast?
end

@testset "eachindex" begin
    # Should have linear index
    da = DimensionalArray(ones(5, 2, 4), (Y((10, 20)), Ti(10:11), X(1:4)))
    @test eachindex(da) == eachindex(data(da))
    # Should have cartesian index
    sda = DimensionalArray(sprand(10, 10, .1), (Y(1:10), X(1:10)))
    @test eachindex(sda) == eachindex(data(sda))
end

@testset "convert" begin
    ac = convert(Array, da2)
    @test ac isa Array{Int,2}
    @test ac == a2
end

@testset "copy" begin
    rebuild(da2, copy(data(da2)))

    dac = copy(da2)
    @test dac == da2
    @test dims(dac) == dims(da2)
    @test refdims(dac) == refdims(da2) == (Ti(1:1),)
    @test name(dac) == name(da2) == "test2"
    @test metadata(dac) == metadata(da2)
    dadc = deepcopy(da2)
    @test dadc == da2
    @test dims(dadc) == dims(da2)
    @test refdims(dadc) == refdims(da2) == (Ti(1:1),)
    @test name(dadc) == name(da2) == "test2"
    @test metadata(dadc) == metadata(da2)
end

if VERSION > v"1.1-"
    @testset "copy!" begin
        db = DimensionalArray(deepcopy(b2), dimz)
        dc = DimensionalArray(deepcopy(b2), dimz)
        @test db != da2
        @test b2 != da2

        copy!(b2, da2)
        @test b2 == a2
        copy!(db, da2)
        @test db == da2
        copy!(dc, a2)
        @test db == a2
    end
end

@testset "constructor" begin
    da = DimensionalArray(rand(5, 4), (X, Y))
    @test_throws DimensionMismatch DimensionalArray(1:5, X(1:6))
    @test_throws MethodError DimensionalArray(1:5, (X(1:5), Y(1:2)))
end

