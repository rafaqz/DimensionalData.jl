using DimensionalData, Test, Dates
using DimensionalData: reindex

@testset "reindex" begin
    A = [10, 20, 30, 40, 50]
    old_coords = [1.0, 2.0, 3.0, 4.0, 5.0]

    @testset "reindex nearest neighbor" begin
        new_coords = [1.4, 2.6, 3.7]
        result = reindex(A, old_coords, new_coords; method = :nearest)
        @test result == [10, 30, 40]

        result_tol = reindex(A, old_coords, [1.5, 6.0]; method = :nearest, tolerance = 0.4)
        @test all(ismissing, result_tol)
    end

    @testset "reindex linear interpolation" begin
        old_coords = [1.0, 2.0, 3.0, 4.0, 5.0]
        new_coords = [1.5, 2.5, 3.5]

        result = reindex(A, old_coords, new_coords; method = :linear)
        @test result ≈ [15.0, 25.0, 35.0]

        result_bounds = reindex(A, old_coords, [0.5, 2.0, 5.5]; method = :linear, fill_value = NaN)
        @test isnan(result_bounds[1])
        @test result_bounds[2] ≈ 20.0
        @test isnan(result_bounds[3])

        A_unordered = [40, 10, 50, 20, 40]
        old_coords_unordered = [3.0, 1.0, 5.0, 2.0, 4.0]  # Unordered
        new_coords = [1.5, 2.5, 3.5]
        result = reindex(A_unordered, old_coords_unordered, new_coords; method = :linear)
        @test result == [15.0, 30.0, 40.0]
    end

    @testset "reindex forward and backward fill" begin
        new_coords = [0.5, 1.5, 2.5, 4.5, 6.0]
        result = reindex(A, old_coords, new_coords; method = :ffill, fill_value = -1)
        @test result == [-1, 10, 20, 40, 50]

        result = reindex(A, old_coords, new_coords; method = :bfill, fill_value = -1)
        @test result == [10, 20, 30, 50, -1]
    end
end

@testset "reindex multi-dimensional arrays" begin

    @testset "reindex 2D array" begin
        A = [1 2 3 4 5; 6 7 8 9 10]
        old_coords = [1.0, 2.0, 3.0, 4.0, 5.0]
        new_coords = [1.6, 3.7]

        result = reindex(A, old_coords, new_coords; method = :linear, dim = 2)
        @test size(result) == (2, 2)
        @test result ≈ [1.6 3.7; 6.6 8.7]

        result_nearest = reindex(A, old_coords, new_coords; method = :nearest, dim = 2)
        @test result_nearest == [2 4; 7 9]
    end

    @testset "reindex 2D array along dim 1" begin
        A = [1 2 3; 4 5 6; 7 8 9]
        old_coords = [10.0, 20.0, 30.0]
        new_coords = [15.0, 25.0]

        result = reindex(A, old_coords, new_coords; method = :linear, dim = 1)
        @test size(result) == (2, 3)
        @test result ≈ [2.5 3.5 4.5; 5.5 6.5 7.5]
    end

    @testset "reindex 3D array" begin
        A = reshape(1:24, 2, 3, 4)
        old_coords = [1.0, 2.0, 3.0, 4.0]
        new_coords = [2.0, 3.0]

        result = reindex(A, old_coords, new_coords; method = :nearest, dim = 3)
        @test size(result) == (2, 3, 2)
    end
end


@testset "reindex edge cases" begin
    A = [10, 20, 30]
    old_coords = [1.0, 2.0, 3.0]
    result_empty = reindex(A, old_coords, Float64[]; method = :nearest)
    @test isempty(result_empty)

    @testset "reindex with DateTime" begin
        times = DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 5)
        A = [10, 20, 30, 40, 50]
        new_times = [DateTime(2020, 1, 1, 12), DateTime(2020, 1, 3, 12)]
        result = reindex(A, times, new_times; method = :linear)
        @test result == [15.0, 35.0]
    end
end

@testset "reindex DimArray" begin
    @testset "reindex DimArray 1D" begin
        times = 1.0:1.0:5.0
        da = DimArray([10, 20, 30, 40, 50], X(times))

        new_times = [1.5, 2.5, 3.5]
        result = reindex(da, X(new_times); method = :linear)
        @test result isa AbstractDimArray
        @test result == [15.0, 25.0, 35.0]
        @test lookup(dims(result, X)) == new_times
    end

    @testset "reindex DimArray 2D" begin
        da = DimArray([1 2 3 4 5; 6 7 8 9 10], (Y([1.0, 2.0]), X([1.0, 2.0, 3.0, 4.0, 5.0])))

        new_x = [1.5, 3.5]
        result = reindex(da, X(new_x); method = :linear)

        @test result == [1.5 3.5; 6.5 8.5]
        @test lookup(dims(result, X)) == new_x
        @test lookup(dims(result, Y)) == [1.0, 2.0]
    end

    @testset "reindex DimArray multiple dimensions" begin
        da = DimArray(reshape(1:20, 4, 5), (Y(1.0:4.0), X(1.0:5.0)))
        newX = X([2.0, 4.0])
        newY = Y([1.5, 3.5])
        result = reindex(da, newX, newY; method = :linear)

        @test result == [5.5 ;7.5 ;; 13.5 ;15.5]
        @test lookup(dims(result, X)) == [2.0, 4.0]
        @test lookup(dims(result, Y)) == [1.5, 3.5]
    end
end
