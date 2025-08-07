using DimensionalData, Test, SparseArrays, LinearAlgebra
using DimensionalData: AbstractDimArray

@testset "SparseArrays Extension" begin
    # Test data setup
    dims2d = (X(1:4), Y(1:3))
    dims1d = (X(1:5),)
    
    @testset "copyto! from CHOLMOD.Dense to DimArray" begin
        # Create test data for CHOLMOD.Dense types
        src_float64 = SparseArrays.CHOLMOD.Dense(rand(Float64, 4, 3))
        src_complexf64 = SparseArrays.CHOLMOD.Dense(rand(ComplexF64, 4, 3))
        src_other = SparseArrays.CHOLMOD.Dense(rand(Float32, 4, 3))
        
        # Test 2D DimArray with Float64
        dst2d_f64 = DimArray(zeros(Float64, 4, 3), dims2d)
        result = copyto!(dst2d_f64, src_float64)
        @test result === dst2d_f64
        @test parent(dst2d_f64) == src_float64
        @test dims(dst2d_f64) == dims2d
        
        # Test 2D DimArray with ComplexF64
        dst2d_cf64 = DimArray(zeros(ComplexF64, 4, 3), dims2d)
        result = copyto!(dst2d_cf64, src_complexf64)
        @test result === dst2d_cf64
        @test parent(dst2d_cf64) == src_complexf64
        @test dims(dst2d_cf64) == dims2d
        
        # Test generic DimArray (any type, any dimensions)
        dst_generic = DimArray(zeros(Float32, 4, 3), dims2d)
        result = copyto!(dst_generic, src_other)
        @test result === dst_generic
        @test parent(dst_generic) == src_other
        @test dims(dst_generic) == dims2d
        
        # Test 1D DimArray with Float64
        src_1d_f64 = SparseArrays.CHOLMOD.Dense(rand(Float64, 5))
        dst1d_f64 = DimArray(zeros(Float64, 5), dims1d)
        result = copyto!(dst1d_f64, src_1d_f64)
        @test result === dst1d_f64
        @test parent(dst1d_f64) == src_1d_f64
        @test dims(dst1d_f64) == dims1d
    end
    
    @testset "copyto! from DimArray to SparseArrays.AbstractCompressedVector" begin
        src_da = DimArray(rand(Float64, 5), dims1d)
        dst_sparse = spzeros(Float64, 5)
        
        result = copyto!(dst_sparse, src_da)
        @test result === dst_sparse
        @test dst_sparse == parent(src_da)
    end
    
    @testset "copyto! from SparseArrays.AbstractSparseMatrixCSC to DimArray" begin
        src_sparse = sprand(Float64, 4, 3, 0.5)
        dst_da = DimArray(zeros(Float64, 4, 3), dims2d)
        
        result = copyto!(dst_da, src_sparse)
        @test result === dst_da
        @test parent(dst_da) == src_sparse
        @test dims(dst_da) == dims2d
    end
    
    @testset "copyto! with CartesianIndices" begin
        src_sparse = sprand(Float64, 2, 2, 0.8)
        dst_da = DimArray(zeros(Float64, 4, 3), dims2d)
        
        # Copy to a subset of the destination
        dst_indices = CartesianIndices((1:2, 1:2))
        src_indices = CartesianIndices((1:2, 1:2))
        
        result = copyto!(dst_da, dst_indices, src_sparse, src_indices)
        @test result === dst_da
        @test parent(dst_da)[1:2, 1:2] == src_sparse[1:2, 1:2]
        @test dims(dst_da) == dims2d
    end
    
    @testset "copy! from DimArray to SparseArrays.AbstractCompressedVector" begin
        src_da = DimArray(rand(Float64, 5), dims1d)
        dst_compressed = spzeros(Float64, 5)
        
        result = copy!(dst_compressed, src_da)
        @test result === dst_compressed
        @test dst_compressed == parent(src_da)
    end
    
    @testset "copy! from DimArray to SparseArrays.SparseVector" begin
        src_da = DimArray(rand(Float64, 5), dims1d)
        dst_sparse_vec = spzeros(Float64, 5)
        
        result = copy!(dst_sparse_vec, src_da)
        @test result === dst_sparse_vec
        @test dst_sparse_vec == parent(src_da)
    end
    
    @testset "Integration with existing copyto! functionality" begin
        # Ensure that the SparseArrays extension doesn't break existing copyto! functionality
        da1 = DimArray(rand(4, 3), dims2d)
        da2 = DimArray(zeros(4, 3), dims2d)
        
        result = copyto!(da2, da1)
        @test result === da2
        @test parent(da2) == parent(da1)
        @test dims(da2) == dims2d
    end
end