using DimensionalData, Test, Unitful, OffsetArrays, SparseArrays
using DimensionalData: Start, formatdims, basetypeof, identify

a = [1 2; 3 4]
dimz = (X((143.0, 145.0); mode=Sampled(order=Ordered()), metadata=Dict(:meta => "X")),
        Y((-38.0, -36.0); mode=Sampled(order=Ordered()), metadata=Dict(:meta => "Y")))
refdimz = (Ti(1:1),)
da = DimArray(a, dimz, "test"; refdims=refdimz, metadata=Dict(:meta => "da"))

@testset "getindex for single integers returns values" begin
    @test da[X(1), Y(2)] == 2
    @test da[X(2), Y(2)] == 4
    @test da[1, 2] == 2
    @test da[2] == 3
    @inferred getindex(da, X(2), Y(2))
end

@testset "LinearIndex getindex returns an Array, except Vector" begin
    @test da[1:2] isa Array
    @test da[1, :][1:2] isa DimArray
end

@testset "getindex returns DimensionArray slices with the right dimensions" begin
    a = da[X(1:2), Y(1)]
    @test a == [1, 3]
    @test typeof(a) <: DimArray{Int,1}
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
    @test typeof(a) <: DimArray{Int,1}
    @test typeof(parent(a)) <: Array{Int,1}
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
    @test typeof(a) <: DimArray{Int,2}
    @test typeof(parent(a)) <: Array{Int,2}
    @test typeof(dims(a)) <: Tuple{<:X,<:Y}
    @test dims(a) == (X(LinRange(143.0, 145.0, 2),
                        Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),
                      Y(LinRange(-38.0, -36.0, 2),
                        Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")))
    @test refdims(a) == (Ti(1:1),)
    @test name(a) == "test"
    @test bounds(a) == ((143.0, 145.0), (-38.0, -36.0))
    @test bounds(a, X) == (143.0, 145.0)

    # Indexing with array works
    a = da[X([2, 1]), Y([2, 1])]
    @test a == [4 3; 2 1]
    @test dims(a) == 
        ((X([145.0, 143.0], mode(da, X), metadata(da, X)), Y([-36.0, -38.0], mode(da, Y), metadata(da, Y))))
end

@testset "view returns DimensionArray containing views" begin
    v = @inferred view(da, Y(1), X(1))
    @test v[] == 1
    @test typeof(v) <: DimArray{Int,0}
    @test typeof(parent(v)) <:SubArray{Int,0}
    @test typeof(dims(v)) == Tuple{}
    @test dims(v) == ()
    @test refdims(v) == 
        (Ti(1:1), X(143.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),
         Y(-38.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")))
    @test name(v) == "test"
    @test metadata(v) == Dict(:meta => "da")
    @test bounds(v) == ()

    v = @inferred view(da, Y(1), X(1:2))
    @test v == [1, 3]
    @test typeof(v) <: DimArray{Int,1}
    @test typeof(parent(v)) <: SubArray{Int,1}
    @test typeof(dims(v)) <: Tuple{<:X}
    @test dims(v) == 
        (X(LinRange(143.0, 145.0, 2), 
           Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),)
    @test refdims(v) == 
        (Ti(1:1), Y(-38.0, Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")),)
    @test name(v) == "test"
    @test metadata(v) == Dict(:meta => "da")
    @test bounds(v) == ((143.0, 145.0),)

    v = @inferred view(da, Y(1:2), X(1:1))
    @test v == [1 2]
    @test typeof(v) <: DimArray{Int,2}
    @test typeof(parent(v)) <: SubArray{Int,2}
    @test typeof(dims(v)) <: Tuple{<:X,<:Y}
    @test dims(v) == 
        (X(LinRange(143.0, 143.0, 1),
           Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "X")),
         Y(LinRange(-38, -36, 2), 
           Sampled(Ordered(), Regular(2.0), Points()), Dict(:meta => "Y")))
    @test bounds(v) == ((143.0, 143.0), (-38.0, -36.0))

    v = @inferred view(da, Y(Base.OneTo(2)), X(1))
    @test v == [1, 2]
    @test typeof(parent(v)) <: SubArray{Int,1}
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
    ida = @inferred DimArray(a2, (X(), Y()))
    ida[Y(3:4), X(2:3)] = [5 6; 6 7]
end


dimz2 = (Dim{:row}((10, 30)), Dim{:column}((-20, 10)))
da2 = DimArray(a2, dimz2, "test2"; refdims=refdimz)

@testset "arbitrary dimension names also work for indexing" begin
    @test da2[Dim{:row}(2)] == [3, 4, 5, 6]
    @test da2[Dim{:column}(4)] == [4, 6, 7]
    @test da2[column=4] == [4, 6, 7]
    @test da2[Dim{:column}(1), Dim{:row}(3)] == 4
    @test da2[column=1, Dim{:row}(3)] == 4
    @test da2[Dim{:column}(1), row=3] == 4
    @test da2[column=1, row=3] == 4
    @test view(da2, column=1, row=3) == fill(4)
    @test view(da2, column=1, Dim{:row}(1)) == fill(1)
    da2_set = deepcopy(da2)
    da2_set[Dim{:column}(1), Dim{:row}(1)] = 99
    @test da2_set[1, 1] == 99
    da2_set[column=2, row=2] = 88
    @test da2_set[2, 2] == 88
    da2_set[Dim{:row}(3), column=3] = 77
    @test da2_set[3, 3] == 77

    # We can also construct without using `Dim{X}`
    @test dims(DimArray(a2, (:a, :b))) == dims(DimArray(a2, (Dim{:a}, Dim{:b})))

    # Inrerence
    @inferred getindex(da2, column=1, row=3)
    @inferred view(da2, column=1, row=3)
    @inferred setindex!(da2_set, 77, Dim{:row}(1), column=2)
    # With a large type

    if VERSION >= v"1.5"
        da4 = DimArray(zeros(1, 2, 3, 4, 5, 6, 7, 8), (:a, :b, :c, :d, :d, :f, :g, :h))
        @inferred getindex(da2, a=1, b=2, c=3, d=4, e=5)
        # Type inference breaks with 6 arguments.
        # @inferred getindex(da2, a=1, b=2, c=3, d=4, e=5, f=6)
        # @code_warntype getindex(da2, a=1, b=2, c=3, d=4, e=5, f=6)
    end
end

@testset "size and axes" begin
    @test size(da2, Dim{:row}) == 3
    @test size(da2, Dim{:column}()) == 4
    @test axes(da2, Dim{:row}()) == 1:3
    @test axes(da2, Dim{:column}) == 1:4
    @inferred axes(da2, Dim{:column})
end

@testset "copy and friends" begin
    rebuild(da2, copy(parent(da2)))

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

    o = one(da)
    @test o == [1 0; 0 1]
    @test dims(o) == dims(da) 

    ou = oneunit(da)
    @test ou == [1 0; 0 1]
    @test dims(ou) == dims(da) 

    z = zero(da)
    @test z == [0 0; 0 0]
    @test dims(z) == dims(da) 
end

@testset "OffsetArray" begin
    oa = OffsetArray(a2, -1:1, 5:8)
    @testset "Regular dimensions don't work: axes must match" begin
        dimz = (X(100:100:300), Y([:a, :b, :c, :d]))
        @test_throws DimensionMismatch DimArray(oa, dimz)
    end
    odimz = (X(OffsetArray(100:100:300, -1:1)), Y(OffsetArray([:a, :b, :c, :d], 5:8)))
    oda = DimArray(oa, odimz)
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

    # Changing the axis size removes dims.
    da_size_float = similar(da2, Float64, (10, 10))
    @test eltype(da_size_float) == Float64
    @test size(da_size_float) == (10, 10)
    @test typeof(da_size_float) <: Array{Float64,2}
    da_size_float_splat = similar(da2, Float64, 10, 10)
    @test size(da_size_float_splat) == (10, 10)
    @test typeof(da_size_float_splat)  <: Array{Float64,2}

    sda = DimArray(sprand(Float64, 10, 10, .5), (X, Y))
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
    da = DimArray(ones(Int, 5, 2, 4), (Y((10, 20)), Ti(10:11), X(1:4)))
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
    da = DimArray(ones(5, 2, 4), (Y(10:2:18), Ti(10:11), X(1:4)))
    @test eachindex(da) == eachindex(parent(da))
    # Should have cartesian index
    sda = DimArray(sprand(10, 10, .1), (Y(1:10), X(1:10)))
    @test eachindex(sda) == eachindex(parent(sda))
end

@testset "convert" begin
    ac = convert(Array, da2)
    @test ac isa Array{Int,2}
    @test ac == a2
end

if VERSION > v"1.1-"
    dimz = (X(LinRange(143.0, 145.0, 3); mode=Sampled(order=Ordered()), metadata=Dict(:meta => "X")),
            Y(LinRange(-38.0, -36.0, 4); mode=Sampled(order=Ordered()), metadata=Dict(:meta => "Y")))
    @testset "copy!" begin
        db = DimArray(deepcopy(b2), dimz)
        dc = DimArray(deepcopy(b2), dimz)
        @test db != da2
        @test b2 != da2

        copy!(b2, da2)
        @test b2 == a2
        copy!(db, da2)
        @test db == da2
        copy!(dc, a2)
        @test db == a2

        @testset "vector copy! (ambiguity fix)" begin
            v = zeros(3)
            dv = DimArray(zeros(3), X)
            copy!(v, DimArray([1.0, 2.0, 3.0], X))
            @test v == [1.0, 2.0, 3.0]
            copy!(dv, DimArray([9.9, 9.9, 9.9], X))
            @test dv == [9.9, 9.9, 9.9]
            copy!(dv, [5.0, 5.0, 5.0])
            @test dv == [5.0, 5.0, 5.0]
        end

    end
end

@testset "constructor" begin
    da = DimArray(rand(5, 4), (X, Y))
    @test_throws DimensionMismatch DimArray(1:5, X(1:6))
    @test_throws DimensionMismatch DimArray(1:5, (X(1:5), Y(1:2)))
end


@testset "fill constructor" begin
    da = fill(5.0, (X(4), Y(40.0:10.0:80.0)))
    @test parent(da) == fill(5.0, (4, 5))
    @test dims(da) == 
        (X(Base.OneTo(4), NoIndex(), nothing), 
         Y(40.0:10.0:80.0, Sampled(Ordered(), Regular(10.0), Points()), nothing))
    @test_throws ErrorException fill(5.0, (X(:e), Y(8)))
end
