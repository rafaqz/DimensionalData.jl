using DimensionalData, Test, Unitful, SparseArrays, Dates, Random
using DimensionalData: layerdims, checkdims

using DimensionalData.LookupArrays, DimensionalData.Dimensions

a = [1 2; 3 4]
a2 = [1 2 3 4
      3 4 5 6
      4 5 6 7]
xmeta = Metadata(:meta => "X")
ymeta = Metadata(:meta => "Y")
tmeta = Metadata(:meta => "T")
ameta = Metadata(:meta => "da")
dimz = (X(Sampled(143.0:2.0:145.0; order=ForwardOrdered(), metadata=xmeta)),
        Y(Sampled(-38.0:2.0:-36.0; order=ForwardOrdered(), metadata=ymeta)))
dimz2 = (Dim{:row}(10:10:30), Dim{:column}(-20:10:10))

refdimz = (Ti(1:1; metadata=tmeta),)
da = @test_nowarn DimArray(a, dimz; refdims=refdimz, name=:test, metadata=ameta)
val(dims(da, 1)) |> typeof
da2 = DimArray(a2, dimz2; refdims=refdimz, name=:test2)

@testset "checkbounds" begin
    @test checkbounds(Bool, da, X(2), Y(1)) == true
    @test checkbounds(Bool, da, X(10), Y(1)) == false
    checkbounds(da, X(2), Y(1))
    @test_throws BoundsError checkbounds(da, X(10), Y(20))
    @test_throws BoundsError checkbounds(da, X(1:10), Y(2:20))
end

@testset "checkdims" begin
    @test checkdims(da2, dimz2)
    @test checkdims(typeof(da2), dimz2)
    @test checkdims(2, dimz2)
    @test_throws ArgumentError checkdims(3, dimz2)
end

@testset "rebuild" begin
    @test rebuild(da2, parent(da2)) === da2
    @test rebuild(da2; dims=dims(da2)) === da2
    @test_throws ArgumentError rebuild(da2; dims=dims(da2, (Y,))) === da2
end

@testset "size and axes" begin
    row_dims = (1, Dim{:row}(), Dim{:row}, :row, dimz2[1])
    for dim in row_dims
        @test size(da2, dim) == 3
        @test axes(da2, dim) == 1:3
        @test axes(da2, dim) isa Dimensions.DimUnitRange
        @test dims(axes(da2, dim)) === dims(da2, dim)
        @test firstindex(da2, dim) == 1
        @test lastindex(da2, dim) == 3
    end
    @test size(da2, :column) == 4
    @test axes(da2, :column) == 1:4
    @test axes(da2, :column) isa Dimensions.DimUnitRange
    @test dims(axes(da2, :column)) === dims(da2, :column)
    @test size(da2) == (3, 4)
    @test axes(da2) == (1:3, 1:4)
    @test axes(da2) isa Tuple{Dimensions.DimUnitRange, Dimensions.DimUnitRange}
    @test firstindex(da2) == 1
    @test lastindex(da2) == 12
    @inferred axes(da2, Dim{:column})
    @test IndexStyle(da) == IndexLinear()
end

@testset "interface methods" begin
    lx = Sampled(143.0:2.0:145.0, ForwardOrdered(), Regular(2.0), Points(), xmeta) 
    ly = Sampled(-38.0:2.0:-36.0, ForwardOrdered(), Regular(2.0), Points(), ymeta)
    @test dims(da) == (X(lx), Y(ly))
    @test dims(da, X) == X(lx)
    @test refdims(da) == refdimz
    @test name(da) == :test
    @test metadata(da) == ameta
    @test lookup(da) == (lx, ly)
    @test order(da) == (ForwardOrdered(), ForwardOrdered())
    @test sampling(da) == (Points(), Points())
    @test span(da) == (Regular(2.0), Regular(2.0))
    @test locus(da) == (Center(), Center())
    @test bounds(da) == ((143.0, 145.0), (-38.0, -36.0))
    @test layerdims(da) == (X(), Y())
    @test index(da, Y) == LinRange(-38.0, -36.0, 2)
    da_intervals = set(da, X => Intervals, Y => Intervals)
    @test intervalbounds(da_intervals) == ([(142.0, 144.0), (144.0, 146.0)], [(-39.0, -37.0), (-37.0, -35.0)])
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

    @test Array(da) == [1 2; 3 4]
    @test Array(da) isa Array{Int,2}
    @test collect(da) == [1 2; 3 4]
    @test collect(da) isa Array{Int,2}
    @test vec(da) == [1, 3, 2, 4]
    @test vec(da) isa Array{Int,1}

    # This should do nothing
    A = read(da2)
    @test A === da2
end

@testset "similar" begin
    @testset "similar with no args" begin
        da_sim = similar(da)
        @test eltype(da_sim) == eltype(da)
        @test size(da_sim) == size(da)
        @test dims(da_sim) === dims(da)
        @test refdims(da_sim) === refdims(da)
        @test refdims(da_sim) === refdims(da)
        @test metadata(da_sim) === metadata(da)
    end

    @testset "similar with a type" begin
        da_float = similar(da, Float64)
        @test eltype(da_float) == Float64
        @test size(da_float) == size(da)
        @test dims(da_float) === dims(da)
        @test refdims(da_float) === refdims(da)
        @test metadata(da_float) === metadata(da)
    end

    @testset "similar with a size" begin
        # Changing the axis size removes dims.
        # TODO we can keep dims, but with NoLookup?
        da_size = similar(da2, (5, 5))
        @test eltype(da_size) == Int
        @test size(da_size) == (5, 5)
        da_size_splat = similar(da2, 5, 5)
        @test eltype(da_size_splat) == Int
        @test size(da_size_splat) == (5, 5)
        da_size_float = similar(da2, Float64, (10, 10))
        @test eltype(da_size_float) == Float64
        @test size(da_size_float) == (10, 10)
        @test typeof(da_size_float) <: Array{Float64,2}
        da_size_float_splat = similar(da2, Float64, 10, 10)
        @test size(da_size_float_splat) == (10, 10)
        @test typeof(da_size_float_splat)  <: Array{Float64,2}
    end

    @testset "similar with sparse arrays" begin
        sda = DimArray(sprand(Float64, 10, 10, 0.5), (X, Y))
        sparse_size_int = similar(sda, Int64, (5, 5))
        @test eltype(sparse_size_int) == Int64 != eltype(sda)
        @test size(sparse_size_int) == (5, 5)
        @test sparse_size_int isa SparseMatrixCSC
    end

    @testset "similar with dims" begin
        da_sim_dims = similar(da, dims(da))
        da_sim_dims_splat = similar(da, dims(da))
        for A in (da_sim_dims, da_sim_dims_splat)
            @test eltype(A) == eltype(da)
            @test size(A) == size(da)
            @test dims(A) === dims(da)
            @test refdims(A) == ()
        end
        da_sim_type_dims = similar(da2, Bool, dims(da))
        da_sim_type_dims_splat = similar(da2, Bool, dims(da)...)
        for A in (da_sim_type_dims, da_sim_type_dims_splat)
            @test eltype(A) == Bool
            @test size(A) == size(da)
            @test dims(A) === dims(da)
            @test refdims(A) == ()
            @test metadata(A) == NoMetadata()
        end
    end

    @testset "similar with DimArray and its axes" begin
        da_all = similar(da, Bool, axes(da))
        @test eltype(da_all) === Bool
        @test size(da_all) == size(da)
        @test dims(da_all) === dims(da)
        @test refdims(da_all) == ()
        @test metadata(da_all) == NoMetadata()

        da_first = similar(da, Missing, (axes(da, 1),))   
        @test eltype(da_first) === Missing
        @test size(da_first) == (size(da, 1),)
        @test dims(da_first) === (dims(da, 1),)
        @test refdims(da_first) == ()
        @test metadata(da_first) == NoMetadata()

        da_last = similar(da, Nothing, (axes(da, 2),))
        @test eltype(da_last) === Nothing
        @test size(da_last) == (size(da, 2),)
        @test dims(da_last) === (dims(da, 2),)
        @test refdims(da_last) == ()
        @test metadata(da_last) == NoMetadata()
    end

    @testset "similar with DimArray and new axes" begin
        ax = Dimensions.DimUnitRange(Base.OneTo(2), Dim{:foo}([:a, :b]))
        da_sim = similar(da, ax)
        @test eltype(da_sim) === eltype(da)
        @test size(da_sim) == (2,)
        @test dims(da_sim) == (dims(ax),)
        @test refdims(da_sim) == ()
        @test metadata(da_sim) == NoMetadata()
    end

    @testset "similar with AbstractArray and DimUnitRange" begin
        da_sim = @inferred similar(trues(2), axes(da))
        @test da_sim isa DimArray{Bool,2}
        @test size(da_sim) == size(da)
        @test parent(da_sim) isa BitMatrix
        @test dims(da_sim) == dims(da)

        da_sim2 = @inferred similar(trues(2), Float64, axes(da))
        @test da_sim2 isa DimArray{Float64,2}
        @test size(da_sim2) == size(da)
        @test dims(da_sim2) == dims(da)
    end

    @testset "similar with AbstractArray type and DimUnitRange" begin
        da_sim = similar(BitArray, axes(da))
        @test da_sim isa DimArray{Bool,2}
        @test size(da_sim) == size(da)
        @test parent(da_sim) isa BitMatrix
        @test dims(da_sim) == dims(da)
    end

    @testset "similar with mixed DimUnitRange and Base.OneTo" begin
        x = randn(10)
        T = ComplexF64
        for ax1 in (Base.OneTo(2), axes(X(1:2), 1))
            s11 = @inferred(similar(x, (ax1,)))
            s12 = @inferred(similar(x, T, (ax1,)))
            s13 = @inferred(similar(BitArray, (ax1,)))
            if ax1 isa Base.OneTo
                @test s11 isa Vector{Float64}
                @test s12 isa Vector{T}
                @test s13 isa BitVector
                @test size(s11) == size(s12) == size(s13) == (length(ax1),)
            else
                @test s11 isa DimArray{Float64,1}
                @test s12 isa DimArray{T,1}
                @test s13 isa DimArray{Bool,1}
                @test parent(s13) isa BitVector
                @test dims(s11) == dims(s12) == dims(s13) == (dims(ax1),)
            end
            for ax2 in (Base.OneTo(3), axes(Y(1:3), 1))
                s21 = @inferred(similar(x, (ax1, ax2)))
                s22 = @inferred(similar(x, T, (ax1, ax2)))
                s23 = @inferred(similar(BitArray, (ax1, ax2)))
                if ax1 isa Base.OneTo || ax2 isa Base.OneTo
                    @test s21 isa Matrix{Float64}
                    @test s22 isa Matrix{T}
                    @test s23 isa BitMatrix
                    @test size(s21) == size(s22) == size(s23) == (length(ax1), length(ax2))
                else
                    @test s21 isa DimArray{Float64,2}
                    @test s22 isa DimArray{T,2}
                    @test s23 isa DimArray{Bool,2}
                    @test parent(s23) isa BitMatrix
                    @test dims(s21) == dims(s22) == dims(s23) == (dims(ax1), dims(ax2))
                end
                for ax3 in (Base.OneTo(4), axes(Z(1:4), 1))
                    s31 = @inferred(similar(x, (ax1, ax2, ax3)))
                    s32 = @inferred(similar(x, T, (ax1, ax2, ax3)))
                    s33 = @inferred(similar(BitArray, (ax1, ax2, ax3)))
                    if ax1 isa Base.OneTo || ax2 isa Base.OneTo || ax3 isa Base.OneTo
                        @test s31 isa Array{Float64,3}
                        @test s32 isa Array{T,3}
                        @test s33 isa BitArray{3}
                        @test size(s31) == size(s32) == size(s33) == map(length, (ax1, ax2, ax3))
                    else
                        @test s31 isa DimArray{Float64,3}
                        @test s32 isa DimArray{T,3}
                        @test s33 isa DimArray{Bool,3}
                        @test parent(s33) isa BitArray{3}
                        @test dims(s31) == dims(s32) == dims(s33) == map(dims, (ax1, ax2, ax3))
                    end
                    for ax4 in (Base.OneTo(5), axes(Ti(1:5), 1))
                        s41 = @inferred(similar(x, (ax1, ax2, ax3, ax4)))
                        s42 = @inferred(similar(x, T, (ax1, ax2, ax3, ax4)))
                        s43 = @inferred(similar(BitArray, (ax1, ax2, ax3, ax4)))
                        if ax1 isa Base.OneTo || ax2 isa Base.OneTo || ax3 isa Base.OneTo || ax4 isa Base.OneTo
                            @test s41 isa Array{Float64,4}
                            @test s42 isa Array{T,4}
                            @test s43 isa BitArray{4}
                            @test size(s41) == size(s42) == size(s43) == map(length, (ax1, ax2, ax3, ax4))
                        else
                            @test s41 isa DimArray{Float64,4}
                            @test s42 isa DimArray{T,4}
                            @test s43 isa DimArray{Bool,4}
                            @test parent(s43) isa BitArray{4}
                            @test dims(s41) == dims(s42) == dims(s43) == map(dims, (ax1, ax2, ax3, ax4))
                        end
                    end
                end
            end
        end
    end
end

@testset "replace" begin
    dar = replace(da, 1 => 99) 
    dar isa DimArray
    @test dar == [99 2; 3 4]

    dar = copy(da)
    replace!(dar, 4 => 99)
    @test dar == [1 2; 3 99]
end

@testset "broadcast" begin
    da = DimArray(ones(Int, 5, 2, 4), (Y(10:2:18), Ti(10:11), X(1:4)))
    dab = da .* 2.0
    @test dab == fill(2.0, 5, 2, 4)
    @test eltype(dab) <: Float64
    @test dims(dab) ==
        (Y(Sampled(10:2:18, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
         Ti(Sampled(10:11, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
         X(Sampled(1:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())))
    dab = da .+ fill(10, 5, 2, 4)
    @test dab == fill(11, 5, 2, 4)
    @test eltype(dab) <: Int
end

@testset "eachindex" begin
    # Should have linear index
    da = DimArray(ones(5, 2, 4), (Y(10:2:18), Ti(10:11), X(1:4)))
    @test eachindex(da) == eachindex(parent(da))
    @test eachindex(da[:, 1, 1]) == eachindex(parent(da)[:, 1, 1])
    @test eachindex(da[:, 1, 1]) isa Dimensions.DimUnitRange
    @test dims(eachindex(da[:, 1, 1])) == dims(da,1)
    # Should have cartesian index
    sda = DimArray(sprand(10, 10, .1), (Y(1:10), X(1:10)))
    @test eachindex(sda) == eachindex(parent(sda))
end

@testset "convert" begin
    # To Array
    ac = convert(Array, da2)
    @test ac isa Array{Int,2}
    @test ac == a2
    # To DimArray
    @test all(convert(DimArray{Float32}, da) .=== Float32.(da))
    @test convert(DimArray{eltype(da)}, da) === convert(DimArray, da) === da
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

@testset "copyto!" begin
    A = zero(a2)
    da = DimArray(ones(size(A)), dims(da2))
    copyto!(A, da)
    @test all(A .== 1)
    copyto!(da, 1, zeros(5, 5), 1, 12)
    @test all(da .== 0)
    x = reshape(10:10:40, 1, 4)
    copyto!(da, CartesianIndices(view(da, 1:1, 1:4)), x, CartesianIndices(x))
    @test da[1, 1:4] == 10:10:40
    copyto!(A, CartesianIndices(view(da, 1:1, 1:4)), DimArray(x, (X, Y)), CartesianIndices(x))
    @test A[1, 1:4] == 10:10:40
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
         X(NoLookup(Base.OneTo(4))), 
         Y(Sampled(40.0:10.0:80.0, ForwardOrdered(), Regular(10.0), Points(), NoMetadata()))
    )
    @test_throws ArgumentError fill(5.0, (X(:e), Y(8)))
end

@testset "ones, zeros, trues, falses constructors" begin
    da = zeros(X(4), Y(40.0:10.0:80.0); metadata=(a=1, b=2))
    @test eltype(da) <: Float64
    @test metadata(da) == (a=1, b=2)
    @test all(==(0), da) 
    ti = Ti(Date(2001):Year(1):Date(2004))
    da = ones(Int32, ti)
    @test size(da) == (4,)
    @test eltype(da) <: Int32
    @test all(==(1), da) 
    @test dims(da) == (Ti(Sampled(Date(2001):Year(1):Date(2004), ForwardOrdered(), Regular(Year(1)), Points(), NoMetadata())),)
    da = trues(ti)
    @test size(da) == (4,)
    @test eltype(da) <: Bool
    @test all(==(true), da) 
    @test dims(da) == (Ti(Sampled(Date(2001):Year(1):Date(2004), ForwardOrdered(), Regular(Year(1)), Points(), NoMetadata())),)
    da = falses(ti)
    @test size(da) == (4,)
    @test eltype(da) <: Bool
    @test all(==(false), da) 
    @test dims(da) == (Ti(Sampled(Date(2001):Year(1):Date(2004), ForwardOrdered(), Regular(Year(1)), Points(), NoMetadata())),)

    for f in (ones, zeros, trues, falses)
        da = f(X(4), Y(40.0:10.0:80.0); metadata=(a=1, b=2))
        @test size(da) == (4, 5)
        @test metadata(da) == (a=1, b=2)
        @test dims(da) == (
             X(NoLookup(Base.OneTo(4))), 
             Y(Sampled(40.0:10.0:80.0, ForwardOrdered(), Regular(10.0), Points(), NoMetadata()))
        )
    end
end

@testset "undef Array constructor" begin
    A = Array{Bool}(undef, dimz...)
    @test eltype(A) === Bool
    @test size(A) === size(da)
    @test A isa Array
    A = DimArray{Int}(undef, dimz...)
    @test eltype(A) === Int
    @test size(A) === size(da)
    @test A isa DimArray
    @test dims(A) === dims(da)
end

@testset "rand constructors" begin
    da = rand(1:10, X(8), Y(11:20); metadata=(a=1, b=2))
    @test size(da) == (8, 10)
    @test eltype(da) <: Int
    @test metadata(da) == (a=1, b=2)
    @test dims(da) == (
         X(NoLookup(Base.OneTo(8))), 
         Y(Sampled(11:20, ForwardOrdered(), Regular(1), Points(), NoMetadata()))
    )
    da = rand(X([:a, :b]), Y(3))
    @test size(da) == (2, 3)
    @test eltype(da) <: Float64
    da = rand(Bool, X([:a, :b]), Y(3))
    @test size(da) == (2, 3)
    @test eltype(da) <: Bool
    da = rand(MersenneTwister(), Float32, X([:a, :b]), Y(3))
    @test size(da) == (2, 3)
    @test eltype(da) <: Float32
    da = rand(MersenneTwister(), 1:2, X([:a, :b]), Y(3))
    @test eltype(da) <: Int
    @test size(da) == (2, 3)
    @test maximum(da) in (1, 2)
    @test minimum(da) in (1, 2)
end

@testset "NamedTuple" begin
    @test NamedTuple(da) == (; test=da)
    @test NamedTuple(da, da2) == (; test=da, test2=da2)
    da3 = DimArray(a2, dimz2; refdims=refdimz, name=DimensionalData.Name(:test3))
    @test NamedTuple(da, da3) == (; test=da, test3=da3)
end

@testset "Base.dataids and mightalias" begin
    a = rand(X(3), Y(2))
    @test Base.dataids(a) == Base.dataids(parent(a))
    @test Base.mightalias(a, parent(a))
end
