using DimensionalData, Test
using JLArrays
using DimensionalData: NoLookup

# Tests taken from NamedDims. Thanks @oxinabox

da = ones(X(3))
dajl = rebuild(da, JLArray(parent(da)));
@test Base.BroadcastStyle(typeof(da)) isa DimensionalData.DimensionalStyle

@testset "standard case" begin
    @test da .+ da == 2ones(3)
    @test dims(da .+ da) == dims(da)
    @test da .+ da .+ da == 3ones(3)
    @test dims(da .+ da .+ da) == dims(da)
end

@testset "broadcast over length one dimension" begin
    da2 = DimArray((1:4) * (1:2:8)', (X, Y))
    @test da2 .* da2[:, 1:1] == [1, 4, 9, 16] * (1:2:8)'
end

@testset "JLArray broadcast over length one dimension" begin
    da2 = DimArray(JLArray((1:4) * (1:2:8)'), (X, Y))
    @test Array(da2 .* da2[:, 1:1]) == [1, 4, 9, 16] * (1:2:8)'
end

@testset "in place" begin
    @test parent(da .= 1 .* da .+ 7) == 8 * ones(3)
    @test dims(da .= 1 .* da .+ 7) == dims(da)
end

@testset "JLArray in place" begin
    @test Array(parent(dajl .= 1 .* dajl .+ 7)) == 8 * ones(3)
    @test dims(dajl .= 1 .* dajl .+ 7) == dims(da)
end

@testset "Dimension disagreement" begin
    @test_throws DimensionMismatch begin
        DimArray(zeros(3, 3, 3), (X, Y, Z)) .+
        DimArray(ones(3, 3, 3), (Y, Z, X))
    end
end

@testset "JLArray Dimension disagreement" begin
    @test_throws DimensionMismatch begin
        DimArray(JLArray(zeros(3, 3, 3)), (X, Y, Z)) .+
        DimArray(JLArray(ones(3, 3, 3)), (Y, Z, X))
    end
end

@testset "dims and regular" begin
    da = DimArray(ones(3, 3, 3), (X, Y, Z))
    left_sum = da .+ ones(3, 3, 3)
    @test left_sum == fill(2, 3, 3, 3)
    @test dims(left_sum) == dims(da)
    right_sum = ones(3, 3, 3) .+ da
    @test right_sum == fill(2, 3, 3, 3)
    @test dims(right_sum) == dims(da)
end

@testset "JLArray dims and regular" begin
    da = DimArray(JLArray(ones(3, 3, 3)), (X, Y, Z))
    left_sum = da .+ ones(3, 3, 3)
    @test Array(left_sum) == fill(2, 3, 3, 3)
    @test dims(left_sum) == dims(da)
    right_sum = ones(3, 3, 3) .+ da
    @test Array(right_sum) == fill(2, 3, 3, 3)
    @test dims(right_sum) == dims(da)
end

@testset "changing type" begin
    @test (da .> 0) isa DimArray
    @test (da .* da .> 0) isa DimArray
    @test (da  .> 0 .> rand(3)) isa DimArray
    @test (da .* rand(3) .> 0.0) isa DimArray
    @test (0 .> da .> 0 .> rand(3)) isa DimArray
    @test (rand(3) .> da  .> 0 .* rand(3)) isa DimArray
    @test (rand(3) .> 1 .> 0 .* da) isa DimArray
end

@testset "JLArray changing type" begin
    @test (dajl .> 0) isa DimArray
    @test (dajl .* dajl .> 0) isa DimArray
    @test (dajl  .> 0 .> rand(3)) isa DimArray
    @test (dajl .* rand(3) .> 0.0) isa DimArray
    @test (0 .> dajl .> 0 .> rand(3)) isa DimArray
    @test (rand(3) .> dajl  .> 0 .* rand(3)) isa DimArray
    @test (rand(3) .> 1 .> 0 .* dajl) isa DimArray
end

@testset "trailng dimensions" begin
    @test zeros(X(10), Y(5)) .* zeros(X(10), Y(1)) ==
        zeros(X(10), Y(5)) .* zeros(X(1), Y(1)) ==
        zeros(X(1), Y(1)) .* zeros(X(10), Y(5)) ==
        zeros(X(10), Y(5)) .* zeros(X(1), Y(5)) ==
        zeros(X(10), Y(1)) .* zeros(X(1), Y(5)) ==
        zeros(X(10), Y(5)) .* zeros(X(1)) ==
        zeros(X(1), Y(5)) .* zeros(X(10))
end

@testset "mixed order fails" begin
    @test_throws DimensionMismatch zeros(X(1:3), Y(5)) .* zeros(X(3:-1:1), Y(5))
    @test_throws DimensionMismatch zeros(X([1, 3, 2]), Y(5)) .* zeros(X(3:-1:1), Y(5))
    zeros(X([1, 3, 2]), Y(5)) .* zeros(X(3), Y(5))
end

@testset "broadcasting" begin
    v = DimArray(zeros(3,), X)
    m = DimArray(ones(3, 3), (X, Y))
    s = 0
    @test v .+ m == ones(3, 3) == m .+ v
    @test s .+ m == ones(3, 3) == m .+ s
    @test s .+ v .+ m == ones(3, 3) == m .+ s .+ v
    @test dims(v .+ m) == dims(m .+ v)
    @test dims(s .+ m) == dims(m .+ s)
    @test dims(s .+ v .+ m) == dims(m .+ s .+ v)
end

@testset "JLArray broadcasting" begin
    v = DimArray(JLArray(zeros(3,)), X)
    m = DimArray(JLArray(ones(3, 3)), (X, Y))
    s = 0
    @test Array(v .+ m) == ones(3, 3) == Array(m .+ v)
    @test Array(s .+ m) == ones(3, 3) == Array(m .+ s)
    @test Array(s .+ v .+ m) == ones(3, 3) == Array(m .+ s .+ v)
    @test dims(v .+ m) == dims(m .+ v)
    @test dims(s .+ m) == dims(m .+ s)
    @test dims(s .+ v .+ m) == dims(m .+ s .+ v)
end

@testset "adjoint broadcasting" begin
    a = DimArray(reshape(1:12, (4, 3)), (X, Y))
    b = DimArray(1:3, Y)
    @test_throws DimensionMismatch a .* b
    @test_throws DimensionMismatch parent(a) .* parent(b)
    @test parent(a) .* parent(b)' == parent(a .* b')
    @test dims(a .* b') == dims(a)
end

@testset "JLArray adjoint broadcasting" begin
    a = DimArray(JLArray(reshape(1:12, (4, 3))), (X, Y))
    b = DimArray(JLArray(1:3), Y)
    @test_throws DimensionMismatch a .* b
    @test_throws DimensionMismatch parent(a) .* parent(b)
    @test Array(parent(a) .* parent(b)') == Array(parent(a .* b'))
    @test dims(a .* b') == dims(a)
end



@testset "Mixed array types" begin
    casts = (
        A -> DimArray(A, (X, Y)),  # Named Matrix
        A -> DimArray(A[:, 1], X),  # Named Vector
        A -> DimArray(A[:, 1:1], (X, Y)),  # Named Single Column Matrix
        identity, # Matrix
        A -> A[:, 1], # Vector
        A -> A[:, 1:1], # Single Column Matrix
        first, # Scalar
     )
    for (T1, T2, T3) in Iterators.product(casts, casts, casts)
        all(isequal(identity), (T1, T2, T3)) && continue
        !any(isequal(DimArray), (T1, T2, T3)) && continue
        total = T1(ones(3, 6)) .+ T2(2ones(3, 6)) .+ T3(3ones(3, 6))
        @test total == 6ones(3, 6)
        @test dims(total) == (X(), Y())
    end
end

@testset "in-place assignment .=" begin
    ab = DimArray(rand(2,2), (X, Y))
    ba = DimArray(rand(2,2), (Y, X))
    ac = DimArray(rand(2,2), (X, Z))
    a_ = DimArray(rand(2,2), (X(), DimensionalData.AnonDim()))
    z = zeros(2,2)

    @test_throws DimensionMismatch z .= ab .+ ba
    @test_throws DimensionMismatch z .= ab .+ ac
    @test_throws DimensionMismatch a_ .= ab .+ ac
    @test_throws DimensionMismatch ab .= a_ .+ ac
    @test_throws DimensionMismatch ac .= ab .+ ba

    # check that dest is written into:
    z .= ab .+ ba'
    @test z == (ab.data .+ ba.data')
end

@testset "JLArray in-place assignment .=" begin
    ab = DimArray(JLArray(rand(2,2)), (X, Y))
    ba = DimArray(JLArray(rand(2,2)), (Y, X))
    ac = DimArray(JLArray(rand(2,2)), (X, Z))
    a_ = DimArray(JLArray(rand(2,2)), (X(), DimensionalData.AnonDim()))
    z = JLArray(zeros(2,2))

    @test_throws DimensionMismatch z .= ab .+ ba
    @test_throws DimensionMismatch z .= ab .+ ac
    @test_throws DimensionMismatch a_ .= ab .+ ac
    @test_throws DimensionMismatch ab .= a_ .+ ac
    @test_throws DimensionMismatch ac .= ab .+ ba

    # check that dest is written into:
    z .= ab .+ ba'
    @test z == (ab.data .+ ba.data')
end

@testset "assign using named indexing and dotview" begin
    A = DimArray(zeros(3,2), (X, Y))
    A[X=1:2] .= [1, 2]
    A[X=3] .= 7
    @test A == [1.0 1.0; 2.0 2.0; 7.0 7.0]
end

@testset "JLArray assign using named indexing and dotview" begin
    A = DimArray(JLArray(zeros(3,2)), (X, Y))
    A[X=1:2] .= JLArray([1, 2])
    A[X=3] .= 7
    @test Array(A) == [1.0 1.0; 2.0 2.0; 7.0 7.0]
end

@testset "0-dimensional array broadcasting" begin
    x = DimArray(fill(3), ())
    y = DimArray(fill(4), ())
    z = fill(3)
    @test @inferred(x .- y) === -1
    @test !(x ≈ y)
    @test x ≈ x
    @test @inferred(x .+ z) === 6
    @test @inferred(z .+ x) === 6
end

@testset "DimIndices broadcasting" begin
    ds = X(1.0:0.2:2.0), Y(10:2:20)
    A = rand(ds)
    B = zeros(ds)
    C = zeros(ds)
    B[DimIndices(B)] .+= A
    C[DimSelectors(C)] .+= A
    @test A == B == C
    sub = A[1:4, 1:3]
    B .= 0
    C .= 0
    B[DimIndices(sub)] .+= sub
    C[DimSelectors(sub)] .+= sub
    @test A[DimIndices(sub)] == B[DimIndices(sub)] == C[DimIndices(sub)]
    sub = A[2:4, 2:5]
    C .= 0
    C[DimSelectors(sub)] .+= sub
    @test A[DimSelectors(sub)] == C[DimSelectors(sub)]
end

@testset "JLArray DimIndices broadcasting" begin
    ds = X(1.0:0.2:2.0), Y(10:2:20)
    _A = (rand(ds))
    _B = (zeros(ds))
    _C = (zeros(ds))

    A = rebuild(_A, JLArray(parent(_A)))
    B = rebuild(_B, JLArray(parent(_B)))
    C = rebuild(_C, JLArray(parent(_C)))

    B[DimIndices(B)] .+= A
    C[DimSelectors(C)] .+= A
    @test Array(A) == Array(B) == Array(C)
    sub = A[1:4, 1:3]
    B .= 0
    C .= 0
    B[DimIndices(sub)] .+= sub
    C[DimSelectors(sub)] .+= sub
    @test Array(A[DimIndices(sub)]) == Array(B[DimIndices(sub)]) == Array(C[DimIndices(sub)])
    sub = A[2:4, 2:5]
    C .= 0
    C[DimSelectors(sub)] .+= sub
    @test Array(A[DimSelectors(sub)]) == Array(C[DimSelectors(sub)])
end

# @testset "Competing Wrappers" begin
#     da = DimArray(ones(4), X)
#     ta = TrackedArray(5 * ones(4))
#     dt = DimArray(TrackedArray(5 * ones(4)), X)
#     arrays = (da, ta, dt)
#     @testset "$a .- $b" 
#     for (a, b) in Iterators.product(arrays, arrays)
#         a === b && continue
#         @test typeof(da .- ta) <: DimArray
#         @test typeof(parent(da .- ta)) <: TrackedArray
#     end
# end
