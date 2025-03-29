using DimensionalData, Test, BenchmarkTools, Dates, Statistics
using DimensionalData.Lookups, DimensionalData.Dimensions

@testset "dims2indices" begin
    a = [1 2 3; 4 5 6]
    da = DimArray(a, (X(143.0:2:145.0), Y(-38.0:-36.0)))
    dimz = dims(da)

    @test Dimensions._dims2indices(dimz[1], Y) == Colon()
    @test dims2indices(dimz, (Y(),)) == (Colon(), Colon())
    @test (@ballocated dims2indices($dimz, (Y(),))) == 0
    @test dims2indices(dimz, (Y(1),)) == (Colon(), 1)
    @test (@ballocated dims2indices($dimz, (Y(1),))) == 0
    @test dims2indices(dimz, (Ti(4), X(2))) == (2, Colon())
    @test dims2indices(dimz, (Y(2), X(3:7))) == (3:7, 2)
    @test (@ballocated dims2indices($dimz, (Y(2), X(3:7)))) == 0
    @test dims2indices(dimz, (X(2), Y([1, 3, 4]))) == (2, [1, 3, 4])
    @test dims2indices(da, (X(2), Y([1, 3, 4]))) == (2, [1, 3, 4])
    v = [1, 3, 4]
    @test (@ballocated dims2indices($da, (X(2), Y($v)))) == 0
    @test_throws ArgumentError dims2indices(nothing, (Y(2), X(3:7)))
    @test dims2indices(dimz, CartesianIndex(1, 1)) == (CartesianIndex(1, 1),)
    @test dims2indices(dimz[1], 1) == 1
    @test dims2indices(dimz[1], X(2)) == 2

    da2 = DimArray(fill(3), ())
    dimz2 = dims(da2)
    @test dims2indices(dimz2, ()) === ()
end

@testset "lookup" begin
    @testset "Points" begin
        l = Sampled(2.0:2.0:10, ForwardOrdered(), Regular(2.0), Points(), nothing)
        @test l[:] == l[Begin:End] == l[1:End] == l[Begin:5] == l[1:5] == l
        @test l[Begin+1:End-1] ==l[Begin+1:4] ==  l[2:End-1] == l[2:4]
        @test l[Begin:End] isa typeof(l)
        @test l[1:5] isa typeof(l)
        @test l[[1, 3, 4]] == view(l, [1, 3, 4]) == 
            Base.dotview(l, [1, 3, 4]) ==
            Sampled([2.0, 6.0, 8.0], ForwardOrdered(), Irregular(nothing, nothing), Points(), NoMetadata())
        @test l[Int[]] == view(l, Int[]) == Base.dotview(l, Int[]) == 
            Sampled(Float64[], ForwardOrdered(), Irregular(nothing, nothing), Points(), nothing)
        @test l[Near(2.1)] == Base.dotview(l, Near(2.1)) == 2.0
        @test view(l, Near(2.1)) == fill(2.0)
        @test l[[false, true, true, false, true]] == 
            view(l, [false, true, true, false, true]) == 
            Base.dotview(l, [false, true, true, false, true]) == 
            Sampled([4.0, 6.0, 10.0], ForwardOrdered(), Irregular(nothing, nothing), Points(), nothing)
        @test l[2] == Base.dotview(l, 2) === 4.0
        @test view(l, 2) == fill(4.0)
        @test l[CartesianIndex((4,))] === Base.dotview(l, CartesianIndex((4,))) === 8.0
        @test view(l, CartesianIndex((4,))) == fill(8.0)
        @test l[CartesianIndices((1:3,))] == 
            view(l, CartesianIndices((1:3,))) == 
            Base.dotview(l, CartesianIndices((1:3,))) == 
            Sampled(2.0:2.0:6.0, ForwardOrdered(), Regular(2.0), Points(), NoMetadata())
        @test l[2:2:4] == 
            view(l, 2:2:4) == 
            Base.dotview(l, 2:2:4) == 
            Sampled(4.0:4.0:8.0, ForwardOrdered(), Regular(4.0), Points(), nothing)
        # End Locus
        l = Sampled(2.0:2.0:10.0, ForwardOrdered(), Regular(2.0), Points(), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([4.0, 6.0, 10.0], ForwardOrdered(), Irregular(nothing, nothing), Points(), nothing)
        # Center Locus
        l = Sampled(2.0:2.0:10.0, ForwardOrdered(), Regular(2.0), Points(), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([4.0, 6.0, 10.0], ForwardOrdered(), Irregular(nothing, nothing), Points(), nothing)
        # Center Locus DateTime
        l = Sampled(DateTime(2001, 1, 1):Day(1):DateTime(2001, 1, 5), ForwardOrdered(), Regular(Day(1)), Points(), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([DateTime(2001, 1, 2), DateTime(2001, 1, 3), DateTime(2001, 1, 5)], ForwardOrdered(), Irregular(nothing, nothing), Points(), nothing)
        # Reverse
        l = Sampled(10.0:-2.0:2.0, ReverseOrdered(), Regular(-2.0), Points(), nothing)
        @test l[:] == l
        @test l[1:5] == l
        @test l[1:5] isa typeof(l)
        @test l[[1, 3, 4]] == Sampled([10.0, 6.0, 4.0], ReverseOrdered(), Irregular(nothing, nothing), Points(), nothing)
        @test l[Int[]] == Sampled(Float64[], ReverseOrdered(), Irregular(nothing, nothing), Points(), nothing)
        @test l[Near(2.1)] == 2.0
        @test l[[false, true, true, false, true]] == 
            Sampled([8.0, 6.0, 2.0], ReverseOrdered(), Irregular(nothing, nothing), Points(), nothing)
        @test l[2] === 8.0
        @test l[CartesianIndex((4,))] == 4.0
        @test l[CartesianIndices((2:4,))] == Sampled(8.0:-2.0:4.0, ReverseOrdered(), Regular(-2.0), Points(), nothing)
        @test l[2:2:4] == Sampled(8.0:-4.0:4.0, ReverseOrdered(), Regular(-4.0), Points(), nothing)
        # End Locus
        l = Sampled(10.0:-2.0:2.0, ReverseOrdered(), Regular(-2.0), Points(), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([8.0, 6.0, 2.0], ReverseOrdered(), Irregular(nothing, nothing), Points(), nothing)
        # Center Locus
        l = Sampled(10.0:-2.0:2.0, ReverseOrdered(), Regular(-2.0), Points(), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([8.0, 6.0, 2.0], ReverseOrdered(), Irregular(nothing, nothing), Points(), nothing)
        # Center Locus DateTime
        l = Sampled(DateTime(2001, 1, 5):Day(-1):DateTime(2001, 1, 1), ReverseOrdered(), Regular(Day(-1)), Points(), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([DateTime(2001, 1, 4), DateTime(2001, 1, 3), DateTime(2001, 1, 1)], ReverseOrdered(), Irregular(nothing, nothing), Points(), nothing)
    end

    @testset "Intervals" begin
        l = Sampled(2.0:2.0:10, ForwardOrdered(), Regular(2.0), Intervals(Start()), nothing)
        @test l[:] == l[Begin:End] == l
        @test l[1:5] == l
        @test l[1:5] isa typeof(l)
        @test l[Begin:End] isa typeof(l)
        @test l[[1, 3, 4]] == Sampled([2.0, 6.0, 8.0], ForwardOrdered(), Irregular(2.0, 10.0), Intervals(Start()), nothing)
        @test l[Int[]] == Sampled(Float64[], ForwardOrdered(), Irregular(nothing, nothing), Intervals(Start()), nothing)
        @test l[Near(2.1)] == 2.0
        @test l[[false, true, true, false, true]] == 
            Sampled([4.0, 6.0, 10.0], ForwardOrdered(), Irregular(4.0, 12.0), Intervals(Start()), nothing)
        @test l[2] === 4.0
        @test l[CartesianIndex((4,))] == 8.0
        @test l[CartesianIndices((1:3,))] == 
            Sampled(2.0:2.0:6.0, ForwardOrdered(), Regular(2.0), Intervals(Start()), NoMetadata())
        @test l[2:2:4] == Sampled(4.0:4.0:8.0, ForwardOrdered(), Regular(4.0), Intervals(Start()), nothing)
        # End Locus
        l = Sampled(2.0:2.0:10.0, ForwardOrdered(), Regular(2.0), Intervals(End()), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([4.0, 6.0, 10.0], ForwardOrdered(), Irregular(2.0, 10.0), Intervals(End()), nothing)
        # Center Locus
        l = Sampled(2.0:2.0:10.0, ForwardOrdered(), Regular(2.0), Intervals(Center()), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([4.0, 6.0, 10.0], ForwardOrdered(), Irregular(3.0, 11.0), Intervals(Center()), nothing)
        # Reverse Start Locus
        l = Sampled(10.0:-2.0:2.0, ReverseOrdered(), Regular(-2.0), Intervals(Start()), nothing)
        @test l[:] == l
        @test l[1:5] == l
        @test l[1:5] isa typeof(l)
        @test l[[1, 3, 4]] == Sampled([10.0, 6.0, 4.0], ReverseOrdered(), Irregular(4.0, 12.0), Intervals(Start()), nothing)
        @test l[Near(2.1)] == 2.0
        @test l[[false, true, true, false, true]] == 
            Sampled([8.0, 6.0, 2.0], ReverseOrdered(), Irregular(2.0, 10.0), Intervals(Start()), nothing)
        @test l[2] === 8.0
        @test l[CartesianIndex((4,))] == 4.0
        @test l[CartesianIndices((1:3,))] == 
            Sampled(10.0:-2.0:6.0, ReverseOrdered(), Regular(-2.0), Intervals(Start()), nothing)
        @test l[2:2:4] == Sampled(8.0:-4.0:4.0, ReverseOrdered(), Regular(-4.0), Intervals(Start()), nothing)
        # End Locus
        l = Sampled(10.0:-2.0:2.0, ReverseOrdered(), Regular(-2.0), Intervals(End()), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([8.0, 6.0, 2.0], ReverseOrdered(), Irregular(0.0, 8.0), Intervals(End()), nothing)
        # Center Locus
        l = Sampled(10.0:-2.0:2.0, ReverseOrdered(), Regular(-2.0), Intervals(Center()), nothing)
        @test l[[false, true, true, false, true]] == 
            Sampled([8.0, 6.0, 2.0], ReverseOrdered(), Irregular(1.0, 9.0), Intervals(Center()), nothing)
    end
    @testset "NoLookup" begin
        nl = NoLookup(1:100)
        @test nl[100] == 100
        @test nl[1:5] isa typeof(nl)
        @test nl[CartesianIndex((1,))] == 1 
        @test view(nl, 50) === view(1:100, 50)
        @test Base.dotview(nl, 50) === 50
    end
end

@testset "dimension" begin
    d = X(Sampled(2.0:2.0:10, ForwardOrdered(), Regular(2.0), Points(), nothing))
    @test @inferred d[:] == d
    @test @inferred d[1:5] == d
    @test d[1:5] isa typeof(d)
    @test @inferred d[Begin:End] == d
    @test d[Begin+1:End-1] == d[2:-1+End] == d[1+Begin:4] == d[2:4]
    @test d[Begin:End] isa typeof(d)
    # TODO properly handle index mashing arrays: here Regular should become Irregular
    # @test d[[1, 3, 4]] == X(Sampled([2.0, 6.0, 8.0], ForwardOrdered(), Regular(2.0), Points(), nothing))
    # @test d[[true, false, false, false, true]] == X(Sampled([2.0, 10.0], ForwardOrdered(), Regular(2.0), Points(), nothing))
    @test @inferred d[2] === 4.0
    @test @inferred d[CartesianIndex((4,))] == 8.0
    @test @inferred d[CartesianIndices((3:4,))] isa X{<:Sampled}
    @test @inferred d[2:2:4] == X(Sampled(4.0:4.0:8.0, ForwardOrdered(), Regular(4.0), Points(), nothing))
    d = Y(NoLookup(1:100))
    @test d[100] == 100
    @test d[1:5] isa typeof(d)
    @test d[CartesianIndex((1,))] == 1 
    @test view(d, 50) === view(1:100, 50)
    @test Base.dotview(d, 50) === 50
end

@testset "array" begin
    a = [1 2; 3 4]
    xmeta = Metadata(:meta => "X")
    ymeta = Metadata(:meta => "Y")
    ameta = Metadata(:meta => "da")
    dimz = (X(Sampled(143.0:2:145.0; order=ForwardOrdered(), metadata=xmeta)),
            Y(Sampled(-38.0:2:-36.0; order=ForwardOrdered(), metadata=ymeta)))
    refdimz = (Ti(1:1),)
    da = @test_nowarn DimArray(a, dimz; refdims=refdimz, name=:test, metadata=ameta)

    @testset "getindex for single integers returns values" begin
        @test @inferred da[X(1), Y(2)] == 2
        @test @inferred da[X(2), Y(2)] == 4
        @test @inferred da[1, 2] == 2
        @test @inferred da[2] == 3
    end

    @testset "LinearIndex getindex returns an Array, except Vector" begin
        @test @inferred da[1:2] isa Array
        @test @inferred da[Begin:Begin+1] isa Array
        @test da[1:2] == da[begin:begin+1] == da[Begin:Begin+1]
        @test @inferred da[rand(Bool, length(da))] isa Array
        @test @inferred da[rand(Bool, size(da))] isa Array
        @test @inferred da[:] isa Array
        @test da[:] == da[Begin:End] == vec(da)
        b = @inferred da[[!iseven(i) for i in 1:length(da)]]
        @test b isa Array
        @test b == da[1:2:end] == da[Begin:2:End]  
        
        v = @inferred da[1, :]
        @test @inferred v[1:2] isa DimArray
        @test @inferred v[rand(Bool, length(v))] isa DimArray
        b = v[[!iseven(i) for i in 1:length(v)]]
        @test b isa DimArray
        # Indexing with a Vector{Bool} returns an irregular lookup, so these are not exactly equal
        @test parent(b) == v[1:2:end]
    end

    @testset "mixed CartesianIndex and CartesianIndices indexing works" begin
        da3 = cat(da, 10da; dims=Z) 
        @test @inferred da3[1, CartesianIndex(1, 2)] == 10
        @test @inferred view(da3, 1:2, CartesianIndex(1, 2)) == [10, 30]
        @test @inferred da3[1, CartesianIndices((1:2, 1:1))] isa DimArray
        @test @inferred da3[CartesianIndices(da3), 1] isa DimArray
        @test @inferred da3[CartesianIndices(da3)] == da3
    end

    @testset "getindex returns DimensionArray slices with the right dimensions" begin
        a = da[X(Begin:Begin+1), Y(1)]
        @test a == [1, 3]
        @test typeof(a) <: DimArray{Int,1}
        @test dims(a) == (X(Sampled(143.0:2.0:145.0, ForwardOrdered(), Regular(2.0), Points(), xmeta)),)
        @test refdims(a) == 
            (Ti(1:1), Y(Sampled(-38.0:2.0:-38.0, ForwardOrdered(), Regular(2.0), Points(), ymeta)),)
        @test name(a) == :test
        @test metadata(a) === ameta
        @test metadata(dims(a, X)) === xmeta
        @test bounds(a) === ((143.0, 145.0),)
        @test bounds(a, X) === (143.0, 145.0)
        @test locus(da, X) == Center()

        a = da[(X(1), Y(1:2))] # Can use a tuple of dimensions like a CartesianIndex
        @test a == [1, 2] == da[(X(1), Y(Begin:Begin+1))]
        @test typeof(a) <: DimArray{Int,1}
        @test typeof(parent(a)) <: Array{Int,1}
        @test dims(a) == (Y(Sampled(-38.0:2.0:-36.0, ForwardOrdered(), Regular(2.0), Points(), ymeta)),)
        @test refdims(a) == 
            (Ti(1:1), X(Sampled(143.0:2.0:143.0, ForwardOrdered(), Regular(2.0), Points(), xmeta)),)
        @test name(a) == :test
        @test metadata(a) == ameta
        @test bounds(a) == ((-38.0, -36.0),)
        @test bounds(a, Y()) == (-38.0, -36.0)

        a = da[X(:), Y(:)]
        @test a == [1 2; 3 4]
        @test typeof(a) <: DimArray{Int,2}
        @test typeof(parent(a)) <: Array{Int,2}
        @test typeof(dims(a)) <: Tuple{<:X,<:Y}
        @test dims(a) == (X(Sampled(143.0:2.0:145.0,
                            ForwardOrdered(), Regular(2.0), Points(), xmeta)),
                          Y(Sampled(-38.0:2.0:-36.0,
                            ForwardOrdered(), Regular(2.0), Points(), ymeta)))
        @test refdims(a) == (Ti(1:1),)
        @test name(a) == :test
        @test bounds(a) == ((143.0, 145.0), (-38.0, -36.0))
        @test bounds(a, X) == (143.0, 145.0)

        a = da[X([2, 1]), Y([2, 1])] # Indexing with array works
        @test a == [4 3; 2 1]
    end

    @testset "dimindices and dimselectors" begin
        @test da[DimIndices(da)] == da
        da[DimIndices(da)[X(1)]]
        da[DimSelectors(da)]
        da[DimSelectors(da)[X(1)]]
        da1 = da .* 0
        da2 = da .* 0
        da1[DimIndices(da)] += da
        da2[DimSelectors(da)] += da
        @test da == da1
        @test da == da2
        da1 *= 0
        da2 *= 0
        da1[DimIndices(da)] += da
        da2[DimSelectors(da)] += da
        @test da == da1
        @test da == da2
    end
    
    @testset "selectors work" begin
        @test @inferred da[At(143), -38.0..36.0] == [1, 2]
        @test @inferred da[144.0..146.0, Near(-37.1)] == [3]
        @test @inferred da[X=At(143), Y=-38.0..36.0] == [1, 2]
        @test @inferred da[X=144.0..146.0, Y=Near(-37.1)] == [3]
    end

    @testset "view DimensionArray containing views" begin
        v = view(da, Y(1), X(1))
        @test v[] == 1
        @test typeof(v) <: DimArray{Int,0}
        @test typeof(parent(v)) <:SubArray{Int,0}
        @test typeof(dims(v)) == Tuple{}
        @test dims(v) == ()
        @test refdims(v) == 
            (Ti(1:1), X(Sampled(143.0:2.0:143, ForwardOrdered(), Regular(2.0), Points(), xmeta)),
             Y(Sampled(-38.0:2.0:-38.0, ForwardOrdered(), Regular(2.0), Points(), ymeta)))
        @test name(v) == :test
        @test metadata(v) == ameta
        @test bounds(v) == ()

        v = view(da, Y(1), X(1:2))
        @test v == [1, 3]
        @test typeof(v) <: DimArray{Int,1}
        @test typeof(parent(v)) <: SubArray{Int,1}
        @test typeof(dims(v)) <: Tuple{<:X}
        @test dims(v) == (X(Sampled(143.0:2.0:145.0, ForwardOrdered(), Regular(2.0), Points(), xmeta)),)
        @test refdims(v) == 
            (Ti(1:1), Y(Sampled(-38.0:-38.0, ForwardOrdered(), Regular(2.0), Points(), ymeta)),)
        @test name(v) == :test
        @test metadata(v) == ameta
        @test bounds(v) == ((143.0, 145.0),)

        # Test that dims are actually views using a vector
        da_vec = rebuild(da; dims=map(d -> rebuild(d, rebuild(lookup(d); data=Array(d))), dims(da)))
        v = view(da_vec, Y(1:2), X(1:1))
        @test v == [1 2]
        @test typeof(v) <: DimArray{Int,2}
        @test typeof(parent(v)) <: SubArray{Int,2}
        @test typeof(dims(v)) <: Tuple{<:X,<:Y}
        testdims = (X(Sampled(view([143.0, 143.0], 1:1), ForwardOrdered(), Regular(2.0), Points(), xmeta)),
             Y(Sampled(view([-38.0, -36.0], 1:2), ForwardOrdered(), Regular(2.0), Points(), ymeta)))
        @test typeof(dims(v)) == typeof(testdims)
        @test dims(v) == testdims
        @test bounds(v) == ((143.0, 143.0), (-38.0, -36.0))

        v = view(da, Y(Base.OneTo(2)), X(1))
        @test v == [1, 2]
        @test typeof(parent(v)) <: SubArray{Int,1}
        @test typeof(dims(v)) <: Tuple{<:Y}
        @test dims(v) == (Y(Sampled(-38.0:2.0:-36.0, ForwardOrdered(), Regular(2.0), Points(), ymeta)),)
        @test refdims(v) == 
            (Ti(1:1), X(Sampled(143.0:2.0:143.0, ForwardOrdered(), Regular(2.0), Points(), xmeta)),)
        @test bounds(v) == ((-38.0, -36.0),)

        @testset "view with all dimensions indexed returns 0-dimensional DimArray" begin
            da0 = DimArray(fill(3), ())
            da1 = DimArray(randn(2), X(1:2))
            da2 = DimArray(randn(2, 3), (X(1:2), Y(1:3)))

            for inds in ((), (1,), (1, 1), (1, 1, 1), (CartesianIndex(),), (CartesianIndices(da0),))
                a = view(da0, inds...)
                @test typeof(parent(a)) === typeof(view(parent(da0), inds...))
                @test parent(a) == view(parent(da0), inds...)
                @test a isa DimArray{eltype(da0),0}
                @test length(dims(a)) == 0
                @test length(refdims(a)) == 0
            end

            for inds in ((1,), (1, 1), (2, 1, 1), (CartesianIndex(2),))
                @test typeof(parent(view(da1, inds...))) === typeof(view(parent(da1), inds...))
                @test parent(view(da1, inds...)) == view(parent(da1), inds...)
                a = view(da1, inds...) 
                @test a isa DimArray{eltype(da1),0}
                @test length(dims(a)) == 0
                @test length(refdims(a)) == 1
            end

            for inds in ((2, 3), (1, 3, 1), (CartesianIndex(2, 1),))
                inds = (CartesianIndex(2, 1),)
                @test typeof(parent(view(da2, inds...))) === typeof(view(parent(da2), inds...))
                @test parent(view(da2, inds...)) == view(parent(da2), inds...)
                a = view(da2, inds...)
                @test a isa DimArray{eltype(da2),0}
                @test length(dims(a)) == 0
                @test length(refdims(a)) == 2
            end
        end

        @testset "@views macro and maybeview work even with kw syntax" begin
            v1 = @views da[Y(1:2), X(1)]
            v2 = @views da[Y=1:2, X=1]
            @test v1 == v2 == [1, 2]
        end
    end

    @testset "setindex!" begin
        da_set = deepcopy(da)
        da_set[X(2), Y(2)] = 77 
        @test da_set == [1 2; 3 77]
        da_set[X(1:2), Y(1)] .= 99
        @test da_set == [99 2; 99 77]
        da_set[1] = 55
        @test da_set == [55 2; 99 77]
        da_set[1, 1, 1, 1] = 66
        @test da_set == [66 2; 99 77]
        @test_throws BoundsError da_set[2, 2, 2, 2] = 66
        da_set[:, :] = [1 2; 3 4]
        @test da_set == [1 2; 3 4]
    end

    @testset "logical indexing" begin
        A = DimArray(zeros(40, 50), (X, Y))
        I = rand(Bool, 40, 50)
        @test all(A[I] .== 0.0)
        A[I] .= 3
        @test all(A[I] .== 3.0)
        @test all(view(A, I .== 3.0))
    end

    @testset "zero dim dim getindex doesn't unwrap" begin
        A = DimArray(fill(1), ())
        @test A[notadim=1] isa DimArray{Int,0,Tuple{}}
        @test A[X(1)] isa DimArray{Int,0,Tuple{}}
        @test A[notadim=1] == A[X(1)] == A
    end

    @testset "Empty getindedex/view/setindex throws a BoundsError" begin
        @test_throws BoundsError da[]
        @test_throws BoundsError view(da)
        @test_throws BoundsError da[] = 1
    end

    @testset "Cartesian indices work as usual" begin
        @test da[CartesianIndex(2, 2)] == 4 
        @test view(da, CartesianIndex(2, 2)) == view(parent(da), 2, 2) 
        da_set = deepcopy(da)
        da_set[CartesianIndex(2, 2)] = 5
        @test da_set[2, 2] == 5
    end

    a2 = [1 2 3 4
          3 4 5 6
          4 5 6 7]
    b2 = [4 4 4 4
          4 4 4 4
          4 4 4 4]

    @testset "indexing into NoLookup dims is just regular indexing" begin
        ida = DimArray(a2, (X(), Y()))
        ida[Y(3:4), X(2:3)] = [5 6; 6 7]
    end

    dimz2 = (Dim{:row}(10:10:30), Dim{:column}(-20:10:10))
    da2 = DimArray(a2, dimz2; refdims=refdimz, name=:test2)

    @testset "lookup step is updated when indexed with a range" begin
        @test step.(lookup(da2)) == (10.0, 10.0)
        @test step.(lookup(da2[1:3, 1:4])) == (10.0, 10.0)
        @test step.(lookup(da2[1:2:3, 1:3:4])) == (20.0, 30.0)
        @test step.(lookup(da2[column=1:2:4, row=1:3:3])) == (30.0, 20.0)
    end

    @testset "Symbol dimension names also work for indexing" begin
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
    end

    @testset "Type inference holds indexing with Symbol dimension names" begin
        da2_set = deepcopy(da2)
        # Inrerence
        @inferred getindex(da2, column=1, row=3)
        @inferred view(da2, column=1, row=3)
        @inferred setindex!(da2_set, 77, Dim{:row}(1), column=2)

        # With a large type
        da4 = DimArray(zeros(1, 2, 3, 4, 5, 6, 7, 8), (:a, :b, :c, :d, :d, :f, :g, :h))
        @inferred getindex(da2, a=1, b=2, c=3, d=4, e=5)
        # Type inference breaks with 6 arguments.
        # @inferred getindex(da2, a=1, b=2, c=3, d=4, e=5, f=6)
        # @code_warntype getindex(da2, a=1, b=2, c=3, d=4, e=5, f=6)
    
    end

    @testset "trailing colon" begin
        @test da[X(1), Y(2)] == 2
        @test da[X(2), Y(2)] == 4
        @test da[1, 2] == 2
        @test da[2] == 3
        @inferred getindex(da, X(2), Y(2))
    end

    @testset "mixed dimensions" begin
        a = [[1 2 3; 4 5 6];;; [11 12 13; 14 15 16];;;]
        da = DimArray(a, (X(143.0:2:145.0), Y(-38.0:-36.0), Ti(100:100:200)); name=:test)
        da[Ti=1, DimIndices(da[Ti=1])]
        da[DimIndices(da[Ti=1]), Ti(2)]
        da[DimIndices(da[Ti=1])[:], Ti(2)]
        da[DimIndices(da[Ti=1])[:], DimIndices(da[X=1, Y=1])]
        da[DimIndices(da[X=1, Y=1]), DimIndices(da[Ti=1])[:]]
        da[DimIndices(da[X=1, Y=1])[:], DimIndices(da[Ti=1])[:]]
    end
end

@testset "stack" begin
    A = [1.0 2.0 3.0;
         4.0 5.0 6.0]
    dimz = (X([:a, :b]), Y(10.0:10.0:30.0))
    da1 = DimArray(A, dimz; name=:one)
    da2 = DimArray(Float32.(2A), dimz; name=:two)
    da3 = DimArray(Int.(3A), dimz; name=:three)
    da4 = rebuild(Int.(4da1)[Y=1]; name=:four)

    s = DimStack((da1, da2, da3))
    s_mixed = DimStack((da1, da2, da3, da4))

    @testset "cartesian Int" begin
        @inferred s[1, 1]
        @inferred view(s, 1, 1)
        @test view(s, Begin, Begin)[] === view(s, 1, 1)[] === 
            s[Begin, Begin] === s[1, 1] === (one=1.0, two=2.0f0, three=3)
        @test view(s_mixed, 1, 1)[] == view(s_mixed, 1, 1)[] == 
            s_mixed[Begin, Begin] == (one=1.0, two=2.0f0, three=3, four=4)
    end
    @testset "cartesian mixed" begin
        @inferred s[At(:a), :] 
        @inferred view(s, At(:a), :)
        @inferred s_mixed[At(:a), :] 
        @inferred view(s_mixed, At(:a), :)

        @test s[At(:a), :] == view(s, At(:a), :) == 
              s[1, :] == view(s, 1, :) == 
              s[Begin, :] == view(s, Begin, :) == 
              s[1, 1:3] == view(s, 1, 1:3) == 
              s[1, Begin:End] == view(s, 1, Begin:End) == 
              s[X=1, Y=Begin:End] == view(s, X=1, Y=Begin:End) ==
              s[X=At(:a), Y=Begin:End] == view(s, X=At(:a), Y=Begin:End) ==
              s[Y=Begin:End, X=1] == view(s, Y=Begin:End, X=1) ==
                  DimStack((one=[1.0, 2.0, 3.0], two=[2.0f0, 4.0f0, 6.0f0], three=[3, 6, 9]), (Y(10.0:10:30.0),))

        y = dims(s, Y)
        @test s_mixed[At(:a), :] == view(s_mixed, At(:a), :) == 
              s_mixed[1, :] == view(s_mixed, 1, :) == 
              s_mixed[Begin, :] == view(s_mixed, Begin, :) == 
              s_mixed[1, 1:3] == view(s_mixed, 1, 1:3) == 
              s_mixed[1, Begin:End] == view(s_mixed, 1, Begin:End) == 
              s_mixed[X=1, Y=Begin:End] == view(s_mixed, X=1, Y=Begin:End) ==
              s_mixed[X=At(:a), Y=Begin:End] == view(s_mixed, X=At(:a), Y=Begin:End) ==
              s_mixed[Y=Begin:End, X=1] == view(s_mixed, Y=Begin:End, X=1) ==
                  DimStack((one=DimArray([1.0, 2.0, 3.0], y), two=DimArray([2.0f0, 4.0f0, 6.0f0], y), three=DimArray([3, 6, 9], y), four=DimArray(fill(4), ())))
    end

    @testset "linear" begin
        s1d = s[X(2)]
        @inferred s[1]
        @inferred s[:]
        @inferred s[[1, 2]] 
        @inferred s[1:2]
        @inferred s1d[1]
        @inferred s1d[:]
        @inferred s1d[1:2]
        # @inferred s[[1, 2]] # Irregular bounds are not type-stable
        @inferred view(s, 1)
        @inferred view(s, :)
        @inferred view(s, 1:2)
        @inferred view(s, [1, 2])
        @inferred view(s1d, 1)
        @inferred view(s1d, :)
        @inferred view(s1d, 1:2)
        # @inferred view(s1d, [1, 2])

        @testset "Integer indexing" begin
            @test s[1] == view(s, 1)[] == (one=1.0, two=2.0f0, three=3)
            @test s1d[1] == view(s1d, 1)[] == (one=4.0, two=8.0f0, three=12)
            @test s1d[1] isa NamedTuple
            @test s[1] isa NamedTuple
            @test view(s1d, 1) isa DimStack
            @test view(s, 1) isa SubArray{<:NamedTuple,0}
        end

        @testset "Colon and Vector{Int/Bool} indexing" begin
            b = [false, false, false, true, false, true]
            v = [4, 6]
            @test s[:][b] == s[b] == 
                s[:][v] == s[v] == [s[4], s[6]] == 
                view(s, :)[b] == view(s, b) ==
                view(s, :)[v] == view(s, v) == [
                (one = 5.0, two = 10.0, three = 15),
                (one = 6.0, two = 12.0, three = 18),
            ]
            @test s_mixed[:][b] == s_mixed[b] ==
                s_mixed[:][v] == s_mixed[v] == [s_mixed[4], s_mixed[6]] ==
                view(s_mixed, :)[b] == view(s_mixed, b) == 
                view(s_mixed, :)[v] == view(s_mixed, v) == [
                (one = 5.0, two = 10.0, three = 15, four=16),
                (one = 6.0, two = 12.0, three = 18, four=16),
            ]
            m = [false true false; false false true]
            @test s[m] == view(s, m) == [
               (one = 2.0, two = 4.0, three = 6)
               (one = 6.0, two = 12.0, three = 18)
            ]
            @test s_mixed[m] == view(s_mixed, m) == [
               (one = 2.0, two = 4.0, three = 6, four=4),
               (one = 6.0, two = 12.0, three = 18, four=16),
            ]
            @test s1d[1:2] isa DimStack
            @test s[1:2] isa Vector
        end
    end

    @testset "CartesianIndex" begin
        @inferred s[CartesianIndex(2, 2)]
        @inferred view(s, CartesianIndex(2, 2))
        @test s[CartesianIndex(2, 2)] == 
            view(s, CartesianIndex(2, 2))[] == (one=5.0, two=10.0, three=15.0)
    end

    @testset "CartesianIndices" begin
        @inferred s[CartesianIndices((1, 2))]
        @inferred view(s, CartesianIndices((1, 2)))
        @test s[CartesianIndices((1, 2))] == 
            view(s, CartesianIndices((1, 2))) ==
            s[X=1:1, Y=1:2]
    end

    @testset "CartesianIndex Vector" begin
        @inferred s[[CartesianIndex(1, 2)]]
        @inferred view(s, [CartesianIndex(1, 2)]) 
        @test s[[CartesianIndex(1, 2)]] == 
            view(s, [CartesianIndex(1, 2)]) ==
            s[[3]]
    end

    @testset "Mixed CartesianIndex and CartesianIndices" begin
        da3d = cat(da1, 10da1; dims=Z) 
        s3 = merge(s, (; ten=da3d))
        @test @inferred s3[2, CartesianIndex(2, 2)] === (one=5.0, two=10.0f0, three=15, ten=50.0)
        @test @inferred view(s3, 1:2, CartesianIndex(1, 2)) isa DimStack
        @test @inferred NamedTuple(view(s3, 1:2, CartesianIndex(1, 2))) == (one=[1.0, 4.0], two=Float32[2.0, 8.0], three=[3, 12], ten=[10.0, 40.0])
        @test @inferred s3[2, CartesianIndices((1:2, 1:1))] isa DimStack
        @test @inferred s3[CartesianIndex((2,)), CartesianIndices((1:2, 1:1)), 1, 1, 1] isa DimStack
        @test @inferred s3[CartesianIndices(s3.one), CartesianIndex(2,)] isa DimStack
        @test @inferred NamedTuple(s3[CartesianIndices(s3.one), CartesianIndex(2,)]) ==
            (one=[1.0 2.0 3.0; 4.0 5.0 6.0], two=Float32[2.0 4.0 6.0; 8.0 10.0 12.0], three=[3 6 9; 12 15 18], ten=[10 20 30; 40 50 60])
        @test @inferred s3[CartesianIndices(s3.one), 2, 1, 1, 1] isa DimStack
        @test @inferred s3[CartesianIndices(s3)] == s3
    end

    @testset "getindex Symbol Tuple" begin
        @test_broken st1 = @inferred s[(:three, :one)]
        st1 = s[(:three, :one)]
        @test keys(st1) === (:three, :one)
        @test values(st1) == (da3, da1)
    end

    @testset "view" begin
        @testset "0-dimensional" begin
            sv = @inferred view(s, Begin, Begin)
            @test parent(sv) == (one=fill(1.0), two=fill(2.0f0), three=fill(3))
            @test dims(sv) == ()
            ds = @inferred view(s, X(1), Y(1))
            @test ds isa DimStack
            @test dims(ds) === ()
            @test @inferred view(s, X(1), Y(2))[:one] == view(da1, X(1), Y(2))
            @test @inferred view(s, X(1), Y(1))[:two] == view(da2, X(1), Y(1))
            @test @inferred view(s, X(2), Y(3))[:three] == view(da3, X(2), Y(3))
        end
        @testset "@views macro and maybeview work even with kw syntax" begin
            sv1 = @views s[X(1:2), Y(3:3)]
            sv2 = @views s[X=1:2, Y=3:3]
            @test parent(sv1) == parent(sv2) == (one=[3.0 6.0]', two=[6.0f0 12.0f0]', three=[9 18]')
        end
    end

    @testset "setindex!" begin
        s_set = deepcopy(s)
        s_set[1] = (one=4, two=5, three=6)
        @test s_set[1, 1] === (one=4.0, two=5.0f0, three=6)
        s_set[1, 1] = (one=9, two=10, three=11)
        @test s_set[1, 1] === (one=9.0, two=10.0f0, three=11) 
        s_set[X=At(:b), Y=At(10.0)] = (one=7, two=11, three=13)
        @test s_set[2, 1] === (one=7.0, two=11.0f0, three=13) 

        s_set = deepcopy(s)
        s_set[CartesianIndex(2, 2)] = (one=5, two=6, three=7)
        @test @inferred s_set[2, 2] === (one=5.0, two=6.0f0, three=7)
        s_set[CartesianIndex(2, 2)] = (9, 10, 11)
        @test @inferred s_set[2, 2] === (one=9.0, two=10.0f0, three=11)
        @test_throws ArgumentError s_set[CartesianIndex(2, 2)] = (seven=5, two=6, three=7)

        s_set_mixed1 = deepcopy(s_mixed)
        s_set_mixed2 = deepcopy(s_mixed)
        s_set_mixed3 = deepcopy(s_mixed)
        s_set_mixed1[1, 1] = (one=9, two=10, three=11, four=12)
        s_set_mixed2[X=1, Y=1] = (one=19, two=20, three=21, four=22)
        s_set_mixed3[Y(1), X(1)] = (one=29, two=30, three=31, four=32)
        @test @inferred s_set_mixed1[1] === (one=9.0, two=10.0f0, three=11, four=12)
        @test @inferred s_set_mixed2[1] === (one=19.0, two=20.0f0, three=21, four=22)
        @test @inferred s_set_mixed3[1] === (one=29.0, two=30.0f0, three=31, four=32)
    end

    @testset "Empty getindedex/view/setindex throws a BoundsError" begin
        @test_throws BoundsError s[]
        @test_throws BoundsError view(s)
        @test_throws BoundsError s[] = 1
    end
end

@testset "indexing irregular with bounds slice" begin
    total_time = 5
    t1 = Ti([mod1(i, 12) for i in 1:total_time]; sampling=Intervals()) # centurial averages with seasonal cycle
    t2 = Ti([Date(-26000 + ((i-1)÷12)*100, mod1(i, 12), 1) for i in 1:total_time]; sampling=Intervals()) # centurial averages with seasonal cycle
    t3 = Ti([DateTime(-26000 + ((i-1)÷12)*100, mod1(i, 12), 1) for i in 1:total_time]; sampling=Intervals()) # centurial averages with seasonal cycle
    t4 = Ti([DateTime(-26000 + ((i-1)÷12)*100, mod1(i, 12), 1) for i in 1:total_time]; sampling=Points()) # centurial averages with seasonal cycle

    p = reshape([1, 2, 3, 4, 5], 1, 1, 5)
    A1 = DimArray(p, (X, Y, t1))
    A2 = DimArray(p, (X, Y, t2))
    A3 = DimArray(p, (X, Y, t3))

    @test @inferred view(A1, Ti(5)) == permutedims([5])
    @test @inferred view(A2, Ti(5)) == permutedims([5])
    @test @inferred view(A3, Ti(5)) == permutedims([5])
end

@testset "Begin End indexing" begin
    @testset "generic indexing" begin
        @test (1:10)[Begin] == 1
        @test (1:10)[Begin()] == 1
        @test (1:10)[End] == 10
        @test (1:10)[End()] == 10
        @test (1:10)[Begin:End] == 1:10
        @test (1:10)[Begin:10] == 1:10
        @test (1:10)[1:End] == 1:10
        @test (1:10)[Begin():End()] == 1:10
        @test (1:10)[Begin+1:End-1] == 2:9
        @test (1:10)[1+Begin:End-1] == 2:9
        @test (1:10)[Begin()+1:End()-1] == 2:9
        @test (1:10)[Begin:End÷2] == 1:5
        @test (1:10)[Begin|3:End] == 3:10
        @test (1:10)[Begin:End&3] == 1:2
        @test (1:10)[Begin()+1:End()-1] == 2:9
        @test_broken (1:10)[1+(End÷2)] == 6
        (1:10)[1+(Begin+2)] == 4
    end
    @testset "dimension indexing" begin
        A = DimArray((1:5)*(6:3:20)', (X, Y))
        @test A[Begin, End] == 18
        @test A[Begin(), End()] == 18
        @test A[X=Begin, Y=End] == 18
        @test A[X=End(), Y=Begin()] == 30
        @test A[Begin:Begin+1, End] == [18, 36]
        @test A[Begin():Begin()+1, End()] == [18, 36]
        @test A[X=Begin:Begin+1, Y=End] == [18, 36]
    end
    @testset "BeginEndRange" begin
        a = Begin:End
        @test first(a) == Begin()
        @test last(a) == End()
        b = Begin:5
        @test first(b) == Begin()
        @test last(b) == 5
        c = Begin:2:Begin+6
        @test step(c) == 2
        @test last(c) == Begin+6
        d = Begin()+2:End()
        @test first(d) == Begin+2
    end
end
