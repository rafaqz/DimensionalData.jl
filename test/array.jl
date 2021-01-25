using DimensionalData, Test, Unitful, OffsetArrays, SparseArrays
using DimensionalData: Start, formatdims, basetypeof, identify

a = [1 2; 3 4]
a2 = [1 2 3 4
      3 4 5 6
      4 5 6 7]
dimz2 = (Dim{:row}((10, 30)), Dim{:column}((-20, 10)))
xmeta = DimMetadata(:meta => "X")
ymeta = DimMetadata(:meta => "Y")
ameta = ArrayMetadata(:meta => "da")
dimz = (X((143.0, 145.0); mode=Sampled(order=Ordered()), metadata=xmeta),
        Y((-38.0, -36.0); mode=Sampled(order=Ordered()), metadata=ymeta))
refdimz = (Ti(1:1),)
da = @test_nowarn DimArray(a, dimz, :test; refdims=refdimz, metadata=ameta)
da2 = DimArray(a2, dimz2, :test2; refdims=refdimz)

@testset "size and axes" begin
    @test size(da2, Dim{:row}) == 3
    @test size(da2, Dim{:column}()) == 4
    @test axes(da2, Dim{:row}()) == 1:3
    @test axes(da2, Dim{:column}) == 1:4
    @inferred axes(da2, Dim{:column})
    @test IndexStyle(da) == IndexLinear()
end

@testset "copy and friends" begin

    dac = copy(da2)
    @test dac == da2
    @test dims(dac) == dims(da2)
    @test refdims(dac) == refdims(da2) == (Ti(1:1),)
    @test name(dac) == name(da2) == :test2
    @test metadata(dac) == metadata(da2)
    dadc = deepcopy(da2)
    @test dadc == da2
    @test dims(dadc) == dims(da2)
    @test refdims(dadc) == refdims(da2) == (Ti(1:1),)
    @test name(dadc) == name(da2) == :test2
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

    A = Array(da2)
    @test A == parent(da2)
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
    # TODO we can keep dims, but with NoIndex?
    da_size_float = similar(da2, Float64, (10, 10))
    @test eltype(da_size_float) == Float64
    @test size(da_size_float) == (10, 10)
    @test typeof(da_size_float) <: Array{Float64,2}
    da_size_float_splat = similar(da2, Float64, 10, 10)
    @test size(da_size_float_splat) == (10, 10)
    @test typeof(da_size_float_splat)  <: Array{Float64,2}

    sda = DimArray(sprand(Float64, 10, 10, 0.5), (X, Y))
    sparse_size_int = similar(sda, Int64, (5, 5))
    @test eltype(sparse_size_int) == Int64 != eltype(sda)
    @test size(sparse_size_int) == (5, 5)
    @test sparse_size_int isa SparseMatrixCSC

    @test dims(da_float) == dims(da2)
    @test refdims(da_float) == refdims(da2)
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
    @testset "copy!" begin
        dimz = dims(da2)
        A = zero(a2)
        sp = sprand(Int, 4, 0.5)
        db = DimArray(deepcopy(A), dimz)
        dc = DimArray(deepcopy(A), dimz)

        copy!(A, da2)
        @test A == parent(da2)
        copy!(db, da2)
        @test parent(db) == parent(da2)
        copy!(dc, a2)
        @test parent(db) == a2
        # Sparse vector has its own method for ambiguity
        copy!(sp, da2[1, :])
        @test sp == parent(da2[1, :])

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
    da = DimArray(; data=rand(5, 4), dims=(X, Y))
    @test_throws DimensionMismatch DimArray(1:5, X(1:6))
    @test_throws DimensionMismatch DimArray(1:5, (X(1:5), Y(1:2)))
    da_reconstructed = DimArray(da)
    @test da == da_reconstructed
    @test dims(da) == dims(da_reconstructed)
end

@testset "fill constructor" begin
    da = fill(5.0, X(4), Y(40.0:10.0:80.0))
    @test parent(da) == fill(5.0, (4, 5))
    @test dims(da) == (
         X(Base.OneTo(4), NoIndex(), NoMetadata()), 
         Y(40.0:10.0:80.0, Sampled(Ordered(), Regular(10.0), Points()), NoMetadata())
    )
    @test_throws ErrorException fill(5.0, (X(:e), Y(8)))
end

@testset "dims methods" begin
    @test index(da) == val(da) == (LinRange(143.0, 145.0, 2), LinRange(-38.0, -36.0, 2))
    @test mode(da) == (Sampled(Ordered(), Regular(2.0), Points()), 
                       Sampled(Ordered(), Regular(2.0), Points()))
    @test order(da) == (Ordered(), Ordered())
    @test sampling(da) == (Points(), Points())
    @test span(da) == (Regular(2.0), Regular(2.0))
    @test bounds(da) == ((143.0, 145.0), (-38.0, -36.0))
    @test locus(da) == (Center(), Center())
    @test indexorder(da) == (ForwardIndex(), ForwardIndex())
    @test arrayorder(da) == (ForwardArray(), ForwardArray())
    @test relation(da) == (ForwardRelation(), ForwardRelation())
    # Dim args work too
    @test relation(da, X) == ForwardRelation()
    @test index(da, Y) == LinRange(-38.0, -36.0, 2)
end
