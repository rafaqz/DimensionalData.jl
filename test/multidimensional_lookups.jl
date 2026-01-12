using DimensionalData
using DimensionalData.Dimensions
using DimensionalData.Lookups
using Test
using Extents

@testset "hasinternaldimensions trait" begin
    # Test default behavior for regular lookups
    @testset "Regular lookups return false" begin
        @test hasinternaldimensions(NoLookup()) == false
        @test hasinternaldimensions(Sampled(1:10)) == false
        @test hasinternaldimensions(Categorical([:a, :b, :c])) == false
        @test hasinternaldimensions(Cyclic(1:12; cycle=12)) == false
        # Test with different span types
        @test hasinternaldimensions(Sampled(1:10; sampling=Points())) == false
        @test hasinternaldimensions(Sampled(1:10; sampling=Intervals())) == false
    end

    @testset "MergedLookup returns true" begin
        x_dim = X(1:3)
        y_dim = Y(10:10:30)
        merged_data = vec(DimPoints((x_dim, y_dim)))
        merged_lookup = MergedLookup(merged_data, (x_dim, y_dim))
        @test hasinternaldimensions(merged_lookup) == true
    end

    @testset "MultiDimensionalLookup abstract type" begin
        # Create a custom MultiDimensionalLookup for testing
        struct TestMultiDimLookup{T} <: DimensionalData.Dimensions.MultiDimensionalLookup{T}
            data::Vector{T}
        end
        
        test_lookup = TestMultiDimLookup([1, 2, 3])
        @test hasinternaldimensions(test_lookup) == true
    end
end

@testset "Extent passthrough for MergedLookup" begin
    @testset "Basic extent with MergedLookup" begin
        # Create dimensions that will be merged
        x_vals = 1.0:3.0
        y_vals = 10.0:10.0:30.0
        x_dim = X(x_vals)
        y_dim = Y(y_vals)
        
        # Create a merged dimension
        merged_dims = mergedims((x_dim, y_dim) => :space)
        
        # Calculate extent
        ext = Extents.extent(merged_dims)
        
        # Check that extent has the original dimension names
        @test haskey(ext, :X)
        @test haskey(ext, :Y)
        
        # Check bounds are correct
        @test ext.X == (1.0, 3.0)
        @test ext.Y == (10.0, 30.0)
    end

    @testset "Mixed regular and merged dimensions" begin
        # Regular dimensions
        t_dim = Ti(1:5)
        z_dim = Z(100:100:300)
        
        # Dimensions to merge
        x_dim = X(1.0:3.0)
        y_dim = Y(10.0:10.0:30.0)
        
        # Create mixed tuple with regular and merged dims
        merged_space = mergedims((x_dim, y_dim) => :space)
        all_dims = (t_dim, merged_space, z_dim)
        
        # Calculate extent
        ext = Extents.extent(all_dims)
        
        # Check regular dimensions
        @test ext.Ti == (1, 5)
        @test ext.Z == (100, 300)
        
        # Check merged dimensions are expanded
        @test ext.X == (1.0, 3.0)
        @test ext.Y == (10.0, 30.0)
    end

    @testset "Multiple merged dimensions" begin
        # First pair to merge
        x1_dim = X(1:3)
        y1_dim = Y(10:10:30)
        
        # Second pair to merge (using different dimension types)
        t_dim = Ti(0.0:0.5:1.0)
        z_dim = Z(-5:5)
        
        # Create two merged dimensions
        merged_space = mergedims((x1_dim, y1_dim) => :space)
        merged_tz = mergedims((t_dim, z_dim) => :timez)
        
        all_dims = (merged_space, merged_tz)
        
        # Calculate extent
        ext = Extents.extent(all_dims)
        
        # Check all original dimensions are present
        @test ext.X == (1, 3)
        @test ext.Y == (10, 30)
        @test ext.Ti == (0.0, 1.0)
        @test ext.Z == (-5, 5)
    end

    @testset "Extent with subset of dimensions" begin
        x_dim = X(1:5)
        y_dim = Y(10:10:50)
        z_dim = Z(100:100:300)
        
        merged = mergedims((x_dim, y_dim) => :space)
        all_dims = (merged, z_dim)
        
        # Get extent for just the Z dimension
        ext_z = Extents.extent(all_dims, Z)
        @test ext_z.Z == (100, 300)
        @test !haskey(ext_z, :X)
        @test !haskey(ext_z, :Y)
        
        # Get extent for merged dimension by name
        ext_space = Extents.extent(all_dims, :space)
        @test ext_space.X == (1, 5)
        @test ext_space.Y == (10, 50)
        @test !haskey(ext_space, :Z)
    end
end

@testset "Multidimensional lookup indexing" begin
    @testset "dims2indices with MergedLookup" begin
        # Create a DimArray with merged dimensions
        x_dim = X(1:3)
        y_dim = Y(10:10:30)
        regular_data = rand(3, 3)
        
        # Create array and merge dimensions
        da = DimArray(regular_data, (x_dim, y_dim))
        merged_da = mergedims(da, (X, Y) => :space)
        
        # Test that indexing with original dimension selectors works
        # This should use the multidimensional indexing path
        result = merged_da[X(At(2)), Y(At(20))]
        @test result isa Number
        
        # Test with Near selector
        result_near = merged_da[X(Near(2.1)), Y(Near(19))]
        @test result_near isa Number
    end

    @testset "otherdims filtering for multidimensional lookups" begin
        x_dim = X(1:3)
        y_dim = Y(10:10:30)
        z_dim = Z(100:100:300)
        
        merged = mergedims((x_dim, y_dim) => :space)
        all_dims = (merged, z_dim)
        
        # Get dims that are not multidimensional
        regular_dims = Dimensions.dims(all_dims, d -> !hasinternaldimensions(lookup(d)))
        @test length(regular_dims) == 1
        @test first(regular_dims) isa Dim{:Z}
        
        # Get dims that are multidimensional
        multi_dims = Dimensions.dims(all_dims, d -> hasinternaldimensions(lookup(d)))
        @test length(multi_dims) == 1
        @test first(multi_dims) isa Dim{:space}
    end
end

@testset "Edge cases and error handling" begin
    @testset "Empty merged dimensions" begin
        # Test with empty vector
        empty_merged = MergedLookup(Vector{Tuple{Float64,Float64}}(), ())
        @test hasinternaldimensions(empty_merged) == true
        
        # Extent should handle empty merged lookups gracefully
        dim_with_empty = Dim{:empty}(empty_merged)
        @test_nowarn Extents.extent((dim_with_empty,))
    end

    @testset "Single dimension in MergedLookup" begin
        # Merge a single dimension (edge case)
        x_dim = X(1:5)
        single_merged = mergedims(x_dim => :single)
        
        @test hasinternaldimensions(lookup(single_merged)) == true
        
        # Extent should still work
        ext = Extents.extent((single_merged,))
        @test ext.X == (1, 5)
    end

    @testset "Nested merged dimensions handling" begin
        # This is likely not supported, but test for graceful behavior
        x_dim = X(1:3)
        y_dim = Y(10:10:30)
        z_dim = Z(100:100:300)
        
        # First merge
        merged_xy = mergedims((x_dim, y_dim) => :space2d)
        
        # Try to merge again with another dimension
        # This might not be intended usage but shouldn't crash
        all_dims = (merged_xy, z_dim)
        ext = Extents.extent(all_dims)
        
        @test ext.X == (1, 3)
        @test ext.Y == (10, 30)
        @test ext.Z == (100, 300)
    end
end

@testset "Integration with DimArray operations" begin
    @testset "Broadcasting with merged dimensions" begin
        x = X(1:3)
        y = Y(10:10:30)
        data = rand(3, 3)
        
        da = DimArray(data, (x, y))
        merged_da = mergedims(da, (X, Y) => :space)
        
        # Broadcasting should preserve merged structure
        result = merged_da .+ 1
        @test size(result) == size(merged_da)
        @test dims(result) == dims(merged_da)
        @test hasinternaldimensions(lookup(dims(result, :space)))
    end

    @testset "Slicing preserves multidimensional trait" begin
        x = X(1:5)
        y = Y(10:10:50)
        z = Z(1:3)
        data = rand(5, 5, 3)
        
        da = DimArray(data, (x, y, z))
        merged_da = mergedims(da, (X, Y) => :space)
        
        # Slice on Z dimension
        sliced = merged_da[Z(At(2))]
        
        # Check that space dimension still has multidimensional trait
        space_dim = dims(sliced, :space)
        @test hasinternaldimensions(lookup(space_dim))
        
        # Check extent still works
        ext = Extents.extent(dims(sliced))
        @test haskey(ext, :X)
        @test haskey(ext, :Y)
    end
end

@testset "Performance considerations" begin
    @testset "Extent calculation performance" begin
        # Create larger dimensions for performance testing
        x = X(1:100)
        y = Y(1:100)
        z = Z(1:50)
        t = Ti(1:200)
        
        # Mix of regular and merged dimensions
        merged_xy = mergedims((x, y) => :space)
        all_dims = (merged_xy, z, t)
        
        # This should complete quickly even with larger dimensions
        @test_nowarn @time ext = Extents.extent(all_dims)
        
        # Verify correctness
        ext = Extents.extent(all_dims)
        @test ext.X == (1, 100)
        @test ext.Y == (1, 100)
        @test ext.Z == (1, 50)
        @test ext.Ti == (1, 200)
    end
end