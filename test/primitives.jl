using DimensionalData, Dates, Test, BenchmarkTools

using DimensionalData: val, basetypeof, slicedims, dims2indices, mode, dimsmatch,
      @dim, reducedims, XDim, YDim, ZDim, commondims, dim2key, key2dim, dimstride, 
      _call, AlwaysTuple, MaybeFirst, _wraparg, _reducedims

@testset "dimsmatch" begin
    @test (@inferred dimsmatch(Y(), Y())) == true
    @test (@inferred dimsmatch(X(), Y())) == false
    @test (@inferred dimsmatch(Y(), Y)) == true
    @test (@inferred dimsmatch(X(), Y)) == false
    @test (@inferred dimsmatch(Y, Y())) == true
    @test (@inferred dimsmatch(X, Y())) == false
    @test (@inferred dimsmatch(X, XDim)) == true
    @test (@inferred dimsmatch(Y, ZDim)) == false
    @test (@inferred dimsmatch(ZDim, Dimension)) == true
    @test (@inferred dimsmatch((Z(), ZDim), (ZDim, Dimension))) == true
    @test (@inferred dimsmatch((Z(), ZDim), (ZDim, XDim))) == false

    @test (@inferred dimsmatch(XDim, nothing)) == false
    @test (@inferred dimsmatch(X(), nothing)) == false
    @test (@inferred dimsmatch(nothing, ZDim)) == false
    @test (@inferred dimsmatch(nothing, Z())) == false
    @test (@inferred dimsmatch(nothing, nothing)) == false

    @test (@ballocated dimsmatch(ZDim, Dimension)) == 0
    @test (@ballocated dimsmatch((Z(), ZDim), (ZDim, XDim))) == 0
end

@dim Tst

@testset "key2dim" begin
    @test key2dim(:test) == Dim{:test}()
    @test key2dim(:X) == X()
    @test key2dim(:x) == Dim{:x}()
    @test key2dim(:Ti) == Ti()
    @test key2dim(:ti) == Dim{:ti}()
    @test key2dim(:Tst) == Tst()
    @test key2dim(Ti) == Ti
    @test key2dim(Ti()) == Ti()
    @test key2dim(Val{TimeDim}()) == Val{TimeDim}()
    @test key2dim((:test, Ti, Ti())) == (Dim{:test}(), Ti, Ti())
end

@testset "dim2key" begin
    @test dim2key(X()) == :X
    @test dim2key(Dim{:x}) == :x
    @test dim2key(Tst()) == :Tst
    @test dim2key(Dim{:test}()) == :test 
    @test (@ballocated dim2key(Dim{:test}())) == 0
    @test dim2key(Val{TimeDim}()) == :TimeDim
end

@testset "_wraparg" begin
    @test _wraparg(X()) == (X(),)
    @test _wraparg((X, Y,), X,) == ((Val(X), Val(Y),), Val(X),)
    @test _wraparg((X, X(), :x), Y, Y(), :y) == 
        ((Val(X), X(), Dim{:x}()), Val(Y), Y(), Dim{:y}())
    f1 = () -> _wraparg((X(), Y()), X(), Y())
    f2 = () -> _wraparg((:x, :y), :x, :y)
    f3 = () -> _wraparg((X(), Y()), X, Y)
    f4 = () -> _wraparg((X, Y), X, Y)
    f5 = () -> _wraparg((X, X(), :x), Y, Y(), :y)
    f6 = () -> _wraparg((:x, :y, :z), :x, :y)
    f7 = () -> _wraparg((:x, :y), :x, :y, :z)
    f8 = () -> _wraparg((:x, :y, :z, :a, :b), :x, :y, :z, :a, :b)
    f9 = () -> _wraparg((:x, :y, :z, :a, :b, :c, :d, :e, :f, :g, :h), :x, :y, :z, :a, :b, :c, :d, :e, :f, :g, :h)
    @inferred f1()
    @inferred f2()
    @inferred f3()
    @inferred f4()
    @inferred f5()
    @inferred f6()
    @inferred f7()
    @inferred f8()
    @test (@inferred f9()) == (DimensionalData.key2dim.(((:x, :y, :z, :a, :b, :c, :d, :e, :f, :g, :h))),
                        DimensionalData.key2dim.(((:x, :y, :z, :a, :b, :c, :d, :e, :f, :g, :h)))...)
end

@testset "_call" begin
    @test _call((f, args...) -> args, AlwaysTuple(), (Z, :a, :b), Ti, XDim, :x) ==
          _call((f, args...) -> args, MaybeFirst(), (Z, :a, :b), Ti, XDim, :x) ==
          ((Val(Z), Dim{:a}(), Dim{:b}()), (Val(Ti), Val(XDim), Dim{:x}()))
    @test _call((f, args...) -> args, MaybeFirst(), (Z, :a, :b), Ti) ==
        (Val(Z), Dim{:a}(), Dim{:b}())
    @testset "_call" begin
        f1 = t -> _call((f, args...) -> args, t, (X, :a, :b), (TimeDim, X(), :a, :b, Ti))
        @inferred f1(AlwaysTuple())
        @test (@ballocated $f1(AlwaysTuple())) == 0
    end
end

@testset "sortdims" begin
    dimz = (X(), Y(), Z(), Ti())
    @test (@inferred sortdims((Y(1:2), X(1)), dimz)) == (X(1), Y(1:2), nothing, nothing)
    @test (@inferred sortdims((Ti(1),), dimz)) == (nothing, nothing, nothing, Ti(1))
    @test (@inferred sortdims((Z(), Y(), X()), dimz)) == (X(), Y(), Z(), nothing)
    @test (@inferred sortdims(dimz, (Y(), Z()))) == (Y(), Z())
    @test (@inferred sortdims((Y(), X(), Z(), Ti()), dimz)) == (X(), Y(), Z(), Ti())
    @test (@ballocated sortdims((Y(), X(), Z(), Ti()), $dimz)) == 0
    f1 = (dimz) -> sortdims((Y, X, Z, Ti), dimz)
    @test (@inferred f1(dimz)) == (X, Y, Z, Ti)
    @ballocated $f1($dimz)
    @test (@ballocated $f1($dimz)) == 0
    f2 = (dimz) -> sortdims(dimz, (Y, X, Z, Ti))
    @test (@inferred f2(dimz)) == (Y(), X(), Z(), Ti())
    @test (@ballocated $f2($dimz)) == 0
    # Val
    @inferred sortdims(dimz, (Val{Y}(), Val{Ti}(), Val{Z}(), Val{X}()))
    @test (@ballocated sortdims($dimz, (Val{Y}(), Val{Ti}(), Val{Z}(), Val{X}()))) == 0
    # Transformed
    @test (@inferred sortdims((Y(1:2; mode=Transformed(identity, Z())), X(1)), (X(), Z()))) == 
                             (X(1), Y(1:2; mode=Transformed(identity, Z()))) 
    # Abstract
    @test sortdims((Z(), Y(), X()), (XDim, TimeDim)) == (X(), nothing)
    # Repeating
    @test sortdims((Z(:a), Y(), Z(:b)), (YDim, Z(), ZDim)) == (Y(), Z(:a), Z(:b))
end

a = [1 2 3; 4 5 6]
da = DimArray(a, (X((143, 145)), Y((-38, -36))))
dimz = dims(da)

@testset "dims" begin
    dimz = dims(da)
    @test dims(X()) == X()
    @test (@inferred dims(dimz, X())) isa X
    @test (@ballocated dims($dimz, X())) == 0
    @test (@inferred dims(dimz, Y)) isa Y
    @test (@ballocated dims($dimz, Y)) == 0
    @test dims(dimz, (X(), Y())) isa Tuple{<:X,<:Y}
    @test (@ballocated dims($dimz, (X(), Y()))) == 0
    @test dims(dimz, (XDim, YDim)) isa Tuple{<:X,<:Y}
    # It's hard to make this infer - Types in a tuple are UnionAll
    f1 = (da) -> dims(da, (XDim, YDim))
    @test (@inferred f1(da)) isa Tuple{<:X,<:Y}
    @test (@ballocated $f1($dimz)) == 0

    @test dims(da, X()) isa X
    @test (@inferred dims(da, XDim, YDim)) isa Tuple{<:X,<:Y}
    @test (@ballocated dims($da, XDim, YDim)) == 0
    @test dims(da, ()) == ()
    @test dims(dimz, 1) isa X
    @test dims(dimz, (2, 1)) isa Tuple{<:Y,<:X}
    # Mixed Int/dim indexing is no longer supported
    @test_broken dims(dimz, (2, Y)) isa Tuple{<:Y,<:Y}

    @testset "with Dim{X} and symbols" begin
        A = DimArray(zeros(4, 5), (:one, :two))
        @test dims(A) == 
            (Dim{:one}(Base.OneTo(4), NoIndex(), NoMetadata()), 
             Dim{:two}(Base.OneTo(5), NoIndex(), NoMetadata()))
        @test dims(A, :two) == Dim{:two}(Base.OneTo(5), NoIndex(), NoMetadata())
    end

    # @test_throws ArgumentError dims(da, Ti)
    # @test_throws ArgumentError dims(dimz, Ti)
    @test_throws ArgumentError dims(nothing, X)

    @test dims(dimz) === dimz
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, Y) === dimz[2]
    @test typeof(dims(da)) ==
        Tuple{X{LinRange{Float64},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},NoMetadata},
              Y{LinRange{Float64},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},NoMetadata}}
end

@testset "commondims" begin
    @test commondims(da, X) == (dims(da, X),)
    # Dims are always in the base order
    @test (@inferred commondims(da, (Y(), X()))) == dims(da, (X, Y))
    @test (@ballocated commondims($da, (Y(), X()))) == 0
    f1 = (da) -> commondims(da, (X, Y))
    @test (@inferred f1(da)) == dims(da, (X, Y))
    @test (@ballocated $f1($da)) == 0
    @test (@inferred commondims(da, X, Y)) == dims(da, (X, Y))
    @test (@ballocated commondims($da, X, Y)) == 0
    @test basetypeof(commondims(da, DimArray(zeros(5), Y()))[1]) <: Y

    @testset "with Dim{X} and symbols" begin
        dimz = Dim{:a}(), Y(), Dim{:b}()
        f1 = (dimz) -> commondims((Dim{:a}(), Dim{:b}()), (:a, :c))
        @test f1(dimz) == (Dim{:a}(),)
        @test (@ballocated $f1(dimz)) == 0 
        f2 = (dimz) -> commondims(dimz, (Y, Dim{:b}))
        @test f2(dimz) == (Y(), Dim{:b}())
        f3 = (dimz) -> commondims(dimz, Y, :b) 
        @test (@inferred f3(dimz)) == (Y(), Dim{:b}())
        @test (@ballocated $f3($dimz)) == 0
        f4 = (dimz) -> commondims(dimz, Y, Z, Dim{:b}) 
        @test (@inferred f4(dimz)) == (Y(), Dim{:b}())
        @test (@ballocated $f4($dimz)) == 0
    end

    @testset "with abstract types" begin
        @test commondims((Z(), Y(), Ti()), (ZDim, Dimension)) == (Z(), Y())
        @test commondims(>:, (TimeDim, YDim), (Z(), Ti(), Dim{:a})) == (TimeDim,)
    end
end

@testset "dimnum" begin
    @test dimnum(da, Y()) == dimnum(da, 2) == 2
    @test (@ballocated dimnum($da, Y())) == 0
    @test dimnum(da, X) == 1
    @test (@ballocated dimnum($da, X)) == 0
    @test dimnum(da, (Y(), X())) == (2, 1)
    @ballocated dimnum($da, (Y(), X()))
    @test (@ballocated dimnum($da, (Y(), X()))) == 0
    f1 = (da) -> dimnum(da, (Y, X()))
    @test (@inferred f1(da)) == (2, 1)
    @ballocated $f1($da)
    @test (@ballocated $f1($da)) == 0
    @test dimnum(da, Y, X) == (2, 1)
    @ballocated dimnum($da, Y, X)
    @test (@ballocated dimnum($da, Y, X)) == 0
    @testset "with Dim{X} and symbols" begin
        @test dimnum((Dim{:a}(), Dim{:b}()), :a) == 1
        @test dimnum((Dim{:a}(), Y(), Dim{:b}()), (:b, :a, Y)) == (3, 1, 2)
        dimz = (Dim{:a}(), Y(), Dim{:b}())
        @test (@ballocated dimnum($dimz, :b, :a, Y)) == 0
    end
end

@testset "hasdim" begin
    @test hasdim(da, X()) == true
    @test (@ballocated hasdim($da, X())) == 0
    @test hasdim(da, Ti) == false
    @test (@ballocated hasdim($da, Ti)) == 0
    @test hasdim(dims(da), Y) == true
    @ballocated hasdim(dims($da), Y)
    @test (@ballocated hasdim(dims($da), Y)) == 0
    @test hasdim(dims(da), (X, Y)) == (true, true)
    f1 = (da) -> hasdim(dims(da), (X, Ti, Y, Z))
    @test @inferred f1(da) == (true, false, true, false)
    @test (@ballocated $f1($da)) == 0
    f2 = (da) -> hasdim(dims(da), X, Ti, Y, Z)
    @test (@ballocated $f2($da)) == 0

    @testset "hasdim for Abstract types" begin
        @test hasdim(dims(da), (XDim, YDim)) == (true, true)
        @test hasdim(dims(da), (XDim, XDim)) == (true, false)
        @test hasdim(dims(da), (ZDim, YDim)) == (false, true)
        @test hasdim(dims(da), (ZDim, ZDim)) == (false, false)
        @test (@ballocated hasdim($da, YDim)) == 0
        @test (@ballocated hasdim($da, (ZDim, YDim))) == 0
        @test (@ballocated hasdim($da, ZDim, YDim)) == 0
    end

    @testset "with Dim{X} and symbols" begin
        @test hasdim((Dim{:a}(), Dim{:b}()), (:a, :c)) == (true, false)
        @test hasdim((Dim{:a}(), Dim{:b}()), (:b, :a, :c, :d, :e)) == (true, true, false, false, false)
        @test hasdim((Dim{:a}(), Dim{:b}()), (:b, :a, :c, :d, :e)) == (true, true, false, false, false)
        @ballocated hasdim((Dim{:a}(), Dim{:b}()), (:b, :a, :c, :d, :e))
        @test (@ballocated hasdim((Dim{:a}(), Dim{:b}()), (:b, :a, :c, :d, :e))) == 0
    end
    @test_throws ArgumentError hasdim(nothing, X)
end

@testset "otherdims" begin
    A = DimArray(ones(5, 10, 15), (X, Y, Z));
    @test otherdims(A, X()) == dims(A, (Y, Z))
    @test (@ballocated otherdims($A, X())) == 0
    @test otherdims(A, Y) == dims(A, (X, Z))
    @test otherdims(A, Z) == dims(A, (X, Y))
    @test otherdims(A, (X, Z)) == dims(A, (Y,))
    f1 = A -> otherdims(A, (X, Z))
    @ballocated $f1($A)
    @test (@ballocated $f1($A)) == 0
    f2 = (A) -> otherdims(A, Ti)
    @test f2(A) == dims(A, (X, Y, Z))
    @test (@ballocated $f2($A)) == 0
    @testset "with Dim{X} and symbols" begin
        dimz = (Z(), Dim{:a}(), Y(), Dim{:b}())
        f3 = (dimz) -> otherdims(dimz, (:b, :a, Y))
        @test (@inferred f3(dimz)) == (Z(),)
        @test (@ballocated $f3($dimz)) == 0
        @test otherdims((Dim{:a}(), Dim{:b}(), Ti()), (:a, :c)) == (Dim{:b}(), Ti())
    end
    @test_throws ArgumentError otherdims(nothing, X)
end

@testset "setdims" begin
    A = setdims(da, X(LinRange(150,152,2)))
    @test index(dims(dims(A), X())) == LinRange(150,152,2)
    @test dims(dims(A)) isa Tuple{<:X,<:Y}
    A = setdims(da, Y(10:12), X(LinRange(150,152,2)))
    @test index(dims(dims(A), Y())) == 10:12
    @test dims(dims(A)) isa Tuple{<:X,<:Y}
end

@testset "swapdims" begin
    @testset "swap type wrappers" begin
        A = swapdims(da, (Z, Dim{:test1}))
        @test dims(A) isa Tuple{<:Z,<:Dim{:test1}}
        @test map(val, dims(A)) == map(val, dims(da))
        @test map(mode, dims(A)) == map(mode, dims(da))
    end
    @testset "swap whole dim instances" begin
        A = swapdims(da, Z(2:2:4), Dim{:test2}(3:5))
        @test dims(A) isa Tuple{<:Z,<:Dim{:test2}}
        @test map(val, dims(A)) == (2:2:4, 3:5)
        @test map(mode, dims(A)) == 
            (Sampled(Ordered(), Regular(2), Points()), 
             Sampled(Ordered(), Regular(1), Points()))
    end
    @testset "passing `nothing` keeps the original dim" begin
        A = swapdims(da, (Z(2:2:4), nothing))
        dims(A) isa Tuple{<:Z,<:Y}
        @test map(val, dims(A)) == (2:2:4, val(dims(da, 2)))
        A = swapdims(da, (nothing, Dim{:test3}))
        @test dims(A) isa Tuple{<:X,<:Dim{:test3}}
    end
    @testset "new instances are checked against the array" begin
        @test_throws DimensionMismatch swapdims(da, (Z(2:2:4), Dim{:test4}(3:6)))
    end
end

@testset "slicedims" begin
    @testset "Regular" begin
        @test slicedims(dimz, (1:2, 3)) == slicedims(dimz, 1:2, 3) == slicedims(dimz, (), (1:2, 3)) == 
            ((X(LinRange(143,145,2), Sampled(Ordered(), Regular(2.0), Points()), NoMetadata()),),
             (Y(-36.0, Sampled(Ordered(), Regular(1.0), Points()), NoMetadata()),))
        @test slicedims(dimz, (Z(),), (1:2, 3)) == slicedims(dimz, (Z(),), 1:2, 3) == 
            ((X(LinRange(143,145,2), Sampled(Ordered(), Regular(2.0), Points()), NoMetadata()),),
             (Z(), Y(-36.0, Sampled(Ordered(), Regular(1.0), Points()), NoMetadata()),))
        @test slicedims(dimz, 2:2, :) == slicedims(dimz, (), 2:2, :) == 
            ((X(LinRange(145,145,1), Sampled(Ordered(), Regular(2.0), Points()), NoMetadata()), 
              Y(LinRange(-38.0,-36.0, 3), Sampled(Ordered(), Regular(1.0), Points()), NoMetadata())), ())
        @test slicedims((), (1:2, 3)) == slicedims((), (), (1:2, 3)) == 
              slicedims((), 1:2, 3) == slicedims((), (), 1:2, 3) == ((), ())
        @test slicedims(dimz, CartesianIndex(2, 3)) == 
            ((), (X(145.0, Sampled(Ordered(), Regular(2.0), Points()), NoMetadata()),
                         Y(-36.0, Sampled(Ordered(), Regular(1.0), Points()), NoMetadata())),)
    end

    @testset "Irregular" begin
        irreg = DimArray(a, (X([140.0, 142.0]; mode=Sampled(Ordered(), Irregular(140.0, 144.0), Intervals(Start()))), 
                             Y([10.0, 20.0, 40.0]; mode=Sampled(Ordered(), Irregular(0.0, 60.0), Intervals(Center()))), ))
        irreg_dimz = dims(irreg)
        @test slicedims(irreg, (1:2, 3)) == slicedims(irreg, 1:2, 3) == 
            ((X([140.0, 142.0], Sampled(Ordered(), Irregular(140.0, 144.0), Intervals(Start())), NoMetadata()),),
                    (Y(40.0, Sampled(Ordered(), Irregular(30.0, 60.0), Intervals(Center())), NoMetadata()),))
        @test slicedims(irreg, (2:2, 1:2)) == slicedims(irreg, 2:2, 1:2) == 
            ((X([142.0], Sampled(Ordered(), Irregular(142.0, 144.0), Intervals(Start())), NoMetadata()), 
              Y([10.0, 20.0], Sampled(Ordered(), Irregular(0.0, 30.0), Intervals(Center())), NoMetadata())), ())
        @test slicedims((), (1:2, 3)) == slicedims((), (), (1:2, 3)) == ((), ())
    end

    @testset "Val index" begin
        da = DimArray(a, (X(Val((143, 145))), Y(Val((:x, :y, :z)))))
        dimz = dims(da)
        @test slicedims(dimz, (1:2, 3)) == slicedims(dimz, (), (1:2, 3)) == 
            ((X(Val((143,145)), Categorical(), NoMetadata()),),
             (Y(:z, Categorical(), NoMetadata()),))
        @test slicedims(dimz, (2:2, :)) == 
            ((X(Val((145,)), Categorical(), NoMetadata()), 
              Y(Val((:x, :y, :z)), Categorical(), NoMetadata())), ())
    end

    @testset "NoIndex" begin
        da = DimArray(a, (X(), Y()))
        dimz = dims(da)
        @test slicedims(dimz, (1:2, 3)) == ((X(1:2, NoIndex()),), (Y(3, NoIndex()),))
        @test slicedims(dimz, (2:2, :)) == ((X(2:2, NoIndex()), Y(Base.OneTo(3), NoIndex())), ())
    end
    @testset "No slicing" begin
        da = DimArray(a, (X([143, 145]), Y([:x, :y, :z])))
        dimz = dims(da)
        @test slicedims(dimz, ()) == (dimz, ())
    end
end

@testset "reducedims" begin
    @test _reducedims((X(3:4; mode=Sampled(Ordered(), Regular(1), Points())), 
                      Y(1:5; mode=Sampled(Ordered(), Regular(1), Points()))), (X, Y)) == 
                     (X([4], Sampled(Ordered(), Regular(2), Points()), NoMetadata()), 
                      Y([3], Sampled(Ordered(), Regular(5), Points()), NoMetadata()))
    @test _reducedims((X(3:4; mode=Sampled(Ordered(), Regular(1), Intervals(Start()))), 
                      Y(1:5; mode=Sampled(Ordered(), Regular(1), Intervals(End())))), (X, Y)) ==
        (X([3], Sampled(Ordered(), Regular(2), Intervals(Start())), NoMetadata()), 
         Y([5], Sampled(Ordered(), Regular(5), Intervals(End())), NoMetadata()))

    @test _reducedims((X(3:4; mode=Sampled(Ordered(), Irregular(2.5, 4.5), Intervals(Center()))),
                      Y(1:5; mode=Sampled(Ordered(), Irregular(0.5, 5.5), Intervals(Center())))), (X, Y))[1] ==
                     (X([4], Sampled(Ordered(), Irregular(2.5, 4.5), Intervals(Center())), NoMetadata()),
                      Y([3], Sampled(Ordered(), Irregular(0.5, 5.5), Intervals(Center())), NoMetadata()))[1]
    @test _reducedims((X(3:4; mode=Sampled(Ordered(), Irregular(3, 5), Intervals(Start()))),
                      Y(1:5; mode=Sampled(Ordered(), Irregular(0, 5), Intervals(End()  )))), (X, Y))[1] ==
                     (X([3], Sampled(Ordered(), Irregular(3, 5), Intervals(Start())), NoMetadata()),
                      Y([5], Sampled(Ordered(), Irregular(0, 5), Intervals(End()  )), NoMetadata()))[1]

    @test _reducedims((X(3:4; mode=Sampled(Ordered(), Irregular(), Points())), 
                      Y(1:5; mode=Sampled(Ordered(), Irregular(), Points()))), (X, Y)) ==
        (X([4], Sampled(Ordered(), Irregular(), Points()), NoMetadata()), 
         Y([3], Sampled(Ordered(), Irregular(), Points()), NoMetadata()))
    @test _reducedims((X(3:4; mode=Sampled(Ordered(), Regular(1), Points())), 
                      Y(1:5; mode=Sampled(Ordered(), Regular(1), Points()))), (X, Y)) ==
                     (X([4], Sampled(Ordered(), Regular(2), Points()), NoMetadata()), 
                      Y([3], Sampled(Ordered(), Regular(5), Points()), NoMetadata()))

    @test _reducedims((X([:a,:b]; mode=Categorical()), 
                      Y(["1","2","3","4","5"]; mode=Categorical())), (X, Y)) ==
                     (X([:combined]; mode=Categorical()), 
                      Y(["combined"]; mode=Categorical()))

    @test _reducedims((X(Base.OneTo(10); mode=NoIndex()), 
                       Y(Base.OneTo(10); mode=NoIndex())), (X(), Y())) == 
        (X(Base.OneTo(1); mode=NoIndex()), Y(Base.OneTo(1); mode=NoIndex()))

    @testset "Special case CompoundPeriod" begin
        step_ = Dates.CompoundPeriod([Month(1), Day(3)])
        timespan = [DateTime(2001, 1), DateTime(2001, 1, 3)]
        teststep = Dates.CompoundPeriod([Month(2), Day(6)])
        testdim = Ti(timespan[2:2], Sampled(Ordered(), Regular(teststep), Points()), NoMetadata())
        reduceddim = _reducedims((Ti(timespan; mode=Sampled(Ordered(), Regular(step_), Points())),), (Ti,))[1] 
        @test typeof(testdim) == typeof(reduceddim)
        @test val(testdim) == val(reduceddim)
        @test step(testdim) == step(reduceddim)
    end
end

@testset "dimstride" begin
    dimz = (X(), Y(), Dim{:test}())
    da = DimArray(ones(3, 2, 3), dimz, :data)
    @test dimstride(da, X()) == 1
    @test dimstride(da, Y()) == 3
    @test dimstride(da, Dim{:test}()) == 6
    @test_throws ArgumentError dimstride(nothing, X())
end
