using DimensionalData, Test

# Tests taken from NamedDims. Thanks @oxinabox

@testset "Binary broadcasting operations (.+)" begin
    da = DimensionalArray(ones(3), X)

    @testset "standard case" begin
        @test da .+ da == 2ones(3)
        @test dims(da .+ da) == dims(da)
        @test da .+ da .+ da == 3ones(3)
        @test dims(da .+ da .+ da) == dims(da)
    end

    @testset "in place" begin
        @test data(da .= 1 .* da .+ 7) == 8 * ones(3)
        @test dims(da .= 1 .* da .+ 7) == (X(),)
    end

    @testset "Dimension disagreement" begin
        @test_throws DimensionMismatch begin
            DimensionalArray(zeros(3, 3, 3), (X, Y, Z)) .+
            DimensionalArray(ones(3, 3, 3), (Y, Z, X))
        end
    end

    @testset "dims and regular" begin
        da = DimensionalArray(ones(3, 3, 3), (X, Y, Z))
        left_sum = da .+ ones(3, 3, 3)
        @test left_sum == fill(2, 3, 3, 3)
        @test dims(left_sum) == dims(da)
        right_sum = ones(3, 3, 3) .+ da
        @test right_sum == fill(2, 3, 3, 3)
        @test dims(right_sum) == dims(da)
    end

    @testset "broadcasting" begin
        v = DimensionalArray(zeros(3,), X)
        m = DimensionalArray(ones(3, 3), (X, Y))
        s = 0

        @test v .+ m == ones(3, 3) == m .+ v
        @test s .+ m == ones(3, 3) == m .+ s
        @test s .+ v .+ m == ones(3, 3) == m .+ s .+ v

        @test dims(v .+ m) == (X(), Y()) == dims(m .+ v)
        @test dims(s .+ m) == (X(), Y()) == dims(m .+ s)
        @test dims(s .+ v .+ m) == (X(), Y()) == dims(m .+ s .+ v)
    end

    @testset "Mixed array types" begin
        casts = (
            A->DimensionalArray(A, (X, Y)),  # Named Matrix
            A->DimensionalArray(A[:, 1], X),  # Named Vector
            A->DimensionalArray(A[:, 1:1], (X, Y)),  # Named Single Column Matrix
            identity, # Matrix
            A->A[:, 1], # Vector
            A->A[:, 1:1], # Single Column Matrix
            first, # Scalar
         )

        for (T1, T2, T3) in Iterators.product(casts, casts, casts)
            all(isequal(identity), (T1, T2, T3)) && continue
            !any(isequal(DimensionalArray), (T1, T2, T3)) && continue
            total = T1(ones(3, 6)) .+ T2(2ones(3, 6)) .+ T3(3ones(3, 6))
            @test total == 6ones(3, 6)
            @test dims(total) == (X(), Y())
        end

    end

    @testset "in-place assignment .=" begin
        ab = DimensionalArray(rand(2,2), (X, Y))
        ba = DimensionalArray(rand(2,2), (Y, X))
        ac = DimensionalArray(rand(2,2), (X, Z))
        z = zeros(2,2)

        # https://github.com/invenia/Dimensional.jl/issues/71
        @test_throws DimensionMismatch z .= ab .+ ba
        @test_throws DimensionMismatch z .= ab .+ ac
        # @test_throws DimensionMismatch a_ .= ab .+ ac
        # @test_throws DimensionMismatch ab .= a_ .+ ac
        @test_throws DimensionMismatch ac .= ab .+ ba

        # check that dest is written into:
        @test dims(z .= ab .+ ba') == (X(), Y())
        @test z == (ab.data .+ ba.data')
        @test z isa Array  # has not itself magically gained names

        # TODO add a non-comparing dim like NamedDims :_ ?
        # @test dims(z .= ab .+ a_) == (X(), Y())
        # @test dims(a_ .= ba' .+ ab) == (X(), Y())
    end

end

# TODO make this work
# @testset "Competing Wrappers" begin
#     da = DimensionalArray(ones(4), X)
#     ta = TrackedArray(5 * ones(4))
#     dt = DimensionalArray(TrackedArray(5 * ones(4)), X)

#     arrays = (da, ta, dt)
#     @testset "$a .- $b" for (a, b) in Iterators.product(arrays, arrays)
#         a === b && continue
#         @test typeof(da .- ta) <: DimensionalArray
#         @test typeof(parent(da .- ta)) <: TrackedArray
#     end
# end
