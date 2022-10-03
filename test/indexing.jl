using DimensionalData, Test, BenchmarkTools, Dates, Statistics
using DimensionalData.LookupArrays, DimensionalData.Dimensions

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
end

@testset "lookup" begin
    l = Sampled(2.0:2.0:10, ForwardOrdered(), Regular(2.0), Points(), nothing)
    @test l[:] == l
    @test l[1:5] == l
    @test l[1:5] isa typeof(l)
    @test l[Near(2.1)] == 2.0
    # TODO properly handle index mashing arrays: here Regular should become Irregular
    # @test d[[1, 3, 4]] == X(Sampled([2.0, 6.0, 8.0], ForwardOrdered(), Regular(2.0), Points(), nothing))
    # @test d[[true, false, false, false, true]] == X(Sampled([2.0, 10.0], ForwardOrdered(), Regular(2.0), Points(), nothing))
    @test l[2] === 4.0
    @test l[CartesianIndex((4,))] == 8.0
    @test l[CartesianIndices((1:3,))] isa Sampled
    @test l[2:2:4] == Sampled(4.0:4.0:8.0, ForwardOrdered(), Regular(2.0), Points(), nothing)
    l = NoLookup(1:100)
    l = NoLookup(1:100)
    @test l[100] == 100
    @test l[1:5] isa typeof(l)
    @test l[CartesianIndex((1,))] == 1 
    @test view(l, 50) === view(1:100, 50)
    @test Base.dotview(l, 50) === 50
end

@testset "dimension" begin
    d = X(Sampled(2.0:2.0:10, ForwardOrdered(), Regular(2.0), Points(), nothing))
    @test d[:] == d
    @test d[1:5] == d
    @test d[1:5] isa typeof(d)
    # TODO properly handle index mashing arrays: here Regular should become Irregular
    # @test d[[1, 3, 4]] == X(Sampled([2.0, 6.0, 8.0], ForwardOrdered(), Regular(2.0), Points(), nothing))
    # @test d[[true, false, false, false, true]] == X(Sampled([2.0, 10.0], ForwardOrdered(), Regular(2.0), Points(), nothing))
    @test d[2] === 4.0
    @test d[CartesianIndex((4,))] == 8.0
    @test d[CartesianIndices((3:4,))] isa X{<:Sampled}
    @test d[2:2:4] == X(Sampled(4.0:4.0:8.0, ForwardOrdered(), Regular(2.0), Points(), nothing))
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
        @test da[X(1), Y(2)] == 2
        @test da[X(2), Y(2)] == 4
        @test da[1, 2] == 2
        @test da[2] == 3
        @inferred getindex(da, X(2), Y(2))
    end


    @testset "LinearIndex getindex returns an Array, except Vector" begin
        @test da[1:2] isa Array
        @test x = da[1, :][1:2] isa DimArray
    end

    @testset "mixed CartesianIndex and CartesianIndices indexing works" begin
        da3 = cat(da, 10da; dims=Z) 
        @test da3[1, CartesianIndex(1, 2)] == 10
        @test view(da3, 1:2, CartesianIndex(1, 2)) == [10, 30]
        @test da3[1, CartesianIndices((1:2, 1:1))] isa DimArray
        @test da3[CartesianIndices(da3)] isa DimArray
        @test da3[CartesianIndices(da3)] == da3
    end

    @testset "getindex returns DimensionArray slices with the right dimensions" begin
        a = da[X(1:2), Y(1)]
        @test a == [1, 3]
        @test typeof(a) <: DimArray{Int,1}
        @test dims(a) == (X(Sampled(143.0:2.0:145.0, ForwardOrdered(), Regular(2.0), Points(), xmeta)),)
        @test refdims(a) == 
            (Ti(1:1), Y(Sampled(-38.0:2.0:-38.0, ForwardOrdered(), Regular(2.0), Points(), ymeta)),)
        @test name(a) == :test
        @test metadata(a) === ameta
        @test metadata(a, X) === xmeta
        @test bounds(a) === ((143.0, 145.0),)
        @test bounds(a, X) === (143.0, 145.0)
        @test locus(da, X) == Center()

        a = da[X(1), Y(1:2)]
        @test a == [1, 2]
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

        # Indexing with array works
        a = da[X([2, 1]), Y([2, 1])]
        @test a == [4 3; 2 1]
    end
    
    @testset "selectors work" begin
        @test da[At(143), -38.0..36.0] == [1, 2]
        @test da[144.0..146.0, Near(-37.1)] == [3]
        @test da[X=At(143), Y=-38.0..36.0] == [1, 2]
        @test da[X=144.0..146.0, Y=Near(-37.1)] == [3]
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

        @test view(da, 1) == fill(1)
    end

    @testset "setindex!" begin
        da_set = copy(da)
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
        A = DimArray(zeros(40, 50), (X, Y));
        I = rand(40, 50) .< 0.5
        @test all(A[I] .== 0.0)
        A[I] .= 3
        @test all(A[I] .== 3.0)
        @test all(view(A, I .== 3.0))
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
        if VERSION >= v"1.5"
            da4 = DimArray(zeros(1, 2, 3, 4, 5, 6, 7, 8), (:a, :b, :c, :d, :d, :f, :g, :h))
            @inferred getindex(da2, a=1, b=2, c=3, d=4, e=5)
            # Type inference breaks with 6 arguments.
            # @inferred getindex(da2, a=1, b=2, c=3, d=4, e=5, f=6)
            # @code_warntype getindex(da2, a=1, b=2, c=3, d=4, e=5, f=6)
        end
    end
end

@testset "stack" begin
    A = [1.0 2.0 3.0;
         4.0 5.0 6.0]
    dimz = (X([:a, :b]), Y(10.0:10.0:30.0))
    da1 = DimArray(A, dimz; name=:one)
    da2 = DimArray(Float32.(2A), dimz; name=:two)
    da3 = DimArray(Int.(3A), dimz; name=:three)

    s = DimStack((da1, da2, da3))

    @testset "getindex" begin
        @test s[1, 1] === (one=1.0, two=2.0f0, three=3)
        @test s[X(2), Y(3)] === (one=6.0, two=12.0f0, three=18)
        @test s[X=At(:b), Y=At(10.0)] === (one=4.0, two=8.0f0, three=12)
        slicedds = s[At(:a), :]
        @test slicedds[:one] == [1.0, 2.0, 3.0]
        @test slicedds.data == (one=[1.0, 2.0, 3.0], two=[2.0f0, 4.0f0, 6.0f0], three=[3, 6, 9])
        @testset "linear indices" begin
            linear2d = s[1:2]
            @test linear2d isa NamedTuple
            @test linear2d == (one=[1.0, 4.0], two=[2.0f0, 8.0f0], three=[3, 12])
            linear1d = s[Y(1)][1:2]
            @test linear1d isa DimStack
            @test linear1d.data == (one=[1.0, 4.0], two=[2.0f0, 8.0f0], three=[3, 12])
        end
    end

    @testset "getindex Tuple" begin
        st1 = s[(:three, :one)]
        @test keys(st1) === (:three, :one)
        @test values(st1) == (da3, da1)
    end

    @testset "view" begin
        sv = view(s, 1, 1)
        @test sv.data == (one=fill(1.0), two=fill(2.0f0), three=fill(3))
        @test dims(sv) == ()
        sv = view(s, X(1:2), Y(3:3)) 
        @test sv.data == (one=[3.0 6.0]', two=[6.0f0 12.0f0]', three=[9 18]')
        slicedds = view(s, X=At(:a), Y=:)
        @test slicedds[:one] == [1.0, 2.0, 3.0]
        @test slicedds.data == (one=[1.0, 2.0, 3.0], two=[2.0f0, 4.0f0, 6.0f0], three=[3, 6, 9])
        @testset "linear indices" begin
            linear2d = view(s, 1)
            @test linear2d isa NamedTuple
            @test linear2d == (one=fill(1.0), two=fill(2.0f0), three=fill(3))
            linear1d = view(s[X(1)], 1)
            @test linear1d == (one=fill(1.0), two=fill(2.0f0), three=fill(3))
            # Its not clear if this should work or not
            @test_broken linear1d isa DimStack
        end
    end

    @testset "setindex!" begin
        s_set = deepcopy(s)
        s_set[1, 1] = (one=9, two=10, three=11)
        @test s_set[1, 1] === (one=9.0, two=10.0f0, three=11) 
        s_set[X=At(:b), Y=At(10.0)] = (one=7, two=11, three=13)
        @test s_set[2, 1] === (one=7.0, two=11.0f0, three=13) 
    end

    @testset "Empty getindedex/view/setindex throws a BoundsError" begin
        @test_throws BoundsError s[]
        @test_throws BoundsError view(s)
        @test_throws BoundsError s[] = 1
    end

    @testset "Cartesian indices work as usual" begin
        @test s[CartesianIndex(2, 2)] == (one=5.0, two=10.0, three=15.0)
        @test view(s, CartesianIndex(2, 2)) == map(d -> view(d, 2, 2), s.data)
        s_set = deepcopy(s)
        s_set[CartesianIndex(2, 2)] = (one=5, two=6, three=7)
        @test s_set[2, 2] === (one=5.0, two=6.0f0, three=7)
        s_set[CartesianIndex(2, 2)] = (9, 10, 11)
        @test s_set[2, 2] === (one=9.0, two=10.0f0, three=11)
        @test_throws ArgumentError s_set[CartesianIndex(2, 2)] = (seven=5, two=6, three=7)
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

    @test view(A1, Ti(5)) == [5;;]
    @test view(A2, Ti(5)) == [5;;]
    @test view(A3, Ti(5)) == [5;;]
end
