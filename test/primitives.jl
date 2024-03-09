using DimensionalData, Dates, Test , BenchmarkTools
using DimensionalData.Lookups, DimensionalData.Dimensions

using .Dimensions: _dim_query, _wraparg, _reducedims, AlwaysTuple, MaybeFirst, comparedims

@dim Tst

a = [1 2 3; 4 5 6]
da = DimArray(a, (X(143:2:145), Y(-38:-36)))
dimz = dims(da)

@dim Tst


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

@testset "_dim_query" begin
    @test _dim_query((f, args...) -> args, AlwaysTuple(), (Z, :a, :b), Ti, XDim, :x) ==
          _dim_query((f, args...) -> args, MaybeFirst(), (Z, :a, :b), Ti, XDim, :x) ==
          ((Val(Z), Dim{:a}(), Dim{:b}()), (Val(Ti), Val(XDim), Dim{:x}()))
    @test _dim_query((f, args...) -> args, MaybeFirst(), (Z, :a, :b), Ti) ==
        (Val(Z), Dim{:a}(), Dim{:b}())
    @testset "_dim_query" begin
        f1 = t -> _dim_query((f, args...) -> args, t, (X, :a, :b), (TimeDim, X(), :a, :b, Ti))
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
    # Abstract
    @test sortdims((Z(), Y(), X()), (XDim, TimeDim)) == (X(), nothing)
    # Repeating
    @test sortdims((Z(:a), Y(), Z(:b)), (YDim, Z(), ZDim)) == (Y(), Z(:a), Z(:b))
end

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
    @test dims(da, isforward) isa Tuple{<:X,<:Y}
    @test dims(da, !isforward) isa Tuple{}
    @test dims(da, Z()) isa Nothing
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
            (Dim{:one}(NoLookup(Base.OneTo(4))),
             Dim{:two}(NoLookup(Base.OneTo(5))))
        @test dims(A, :two) == Dim{:two}(NoLookup(Base.OneTo(5)))
    end

    # @test_throws ArgumentError dims(da, Ti)
    # @test_throws ArgumentError dims(dimz, Ti)
    @test_throws ArgumentError dims(nothing, X)

    @test dims(dimz) === dimz
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, Y) === dimz[2]
    TT = typeof(LinRange(1.0,1.0,1)) # TT is different for Julia 1.6 and 1.7
    @test typeof(dims(da)) ==
        Tuple{X{Sampled{Int,StepRange{Int,Int},ForwardOrdered,Regular{Int},Points,NoMetadata}},
              Y{Sampled{Int,UnitRange{Int},ForwardOrdered,Regular{Int},Points,NoMetadata}} }
end

@testset "commondims" begin
    @test commondims(da, X) == (dims(da, X),)
    @test commondims(da, x -> x isa X) == (dims(da, X),)
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
    dims(da)
    @test dimnum(da, Y()) == dimnum(da, 2) == 2
    @test dimnum(da, Base.Fix2(isa,Y)) == (2,)
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
    @test hasdim(da, :X) == true
    @test hasdim(da, isforward) == (true, true) 
    @test (@ballocated hasdim($da, X())) == 0
    @test hasdim(da, Ti) == false
    @test (@ballocated hasdim($da, Ti)) == 0
    @test hasdim(dims(da), Y) == true
    @ballocated hasdim(dims($da), Y)
    @test (@ballocated hasdim(dims($da), Y)) == 0
    @test hasdim(dims(da), (X, Y)) == (true, true)
    @test hasdim(dims(da), (:X, :Y)) == (true, true)
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
    @test otherdims(A, x -> x isa X) == dims(A, (Y, Z))
    @test (@ballocated otherdims($A, X())) == 0
    @test (@ballocated otherdims($A, X)) == 0
    @test (@ballocated otherdims($A, (X, Y))) == 0
    @test (@ballocated otherdims($A, X, Y)) == 0
    @test otherdims(A, X, Y) == dims(A, (Z,))
    @test otherdims(A, Y) == dims(A, (X, Z))
    @test otherdims(A, Z) == dims(A, (X, Y))
    @test otherdims(A) == dims(A, (X, Y, Z))
    @test otherdims(A, DimensionalData.ZDim) == dims(A, (X, Y))
    @test otherdims(A, (X, Z)) == dims(A, (Y,))
    f1 = A -> otherdims(A, (X, Z))
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

@testset "combinedims" begin
    @test combinedims((X(1:10), Y(1:5)), (X(1:10), Z(3:10))) == (X(1:10), Y(1:5), Z(3:10))
    @test combinedims([]) == combinedims() == ()
    @test_throws DimensionMismatch combinedims((X(1:2), Y(1:5)), (X(1:10), Z(3:10)))
end

@testset "comparedims" begin
    @testset "default keywords" begin
        @test comparedims(Bool, X(1:2), X(1:2))
        @test !comparedims(Bool, X(1:2), Y(1:2))
        @test !comparedims(Bool, X(1:2), X(1:3))
        @test_warn "Found both lengths 2 and 3" comparedims(Bool, X(1:2), X(1:3); warn="")
        @test_warn "X and Y dims on the same axis" comparedims(Bool, X(1:2), Y(1:2); warn="")
        @test comparedims(X(1:2), X(1:2)) == X(1:2)
        @test_throws DimensionMismatch comparedims(X(1:2), Y(1:2))
        @test_throws DimensionMismatch comparedims(X(1:2), X(1:3))
    end
    @testset "compare type" begin
        @test comparedims(Bool, X(1:2), Y(1:2); type=false)
        @test !comparedims(Bool, X(1:2), Y(1:2); type=true)
        @test_warn "X and Y dims on the same axis" comparedims(Bool, X(1:2), Y(1:2); type=true, warn="")
        @test comparedims(X(1:2), Y(1:2); type=false) == X(Sampled(1:2))
        @test_throws DimensionMismatch comparedims(X(Sampled(1:2)), Y(Sampled(1:2)); type=true)
    end
    @testset "compare val type" begin
        @test comparedims(Bool, X(Sampled(1:2)), X(Categorical(1:2)); valtype=false)
        @test !comparedims(Bool, X(Sampled(1:2)), X(Categorical(1:2)); valtype=true)
        @test comparedims(X(Sampled(1:2)), X(Categorical(1:2)); valtype=false) == X(Sampled(1:2))
        @test_throws DimensionMismatch comparedims(X(Sampled(1:2)), X(Categorical(1:2)); valtype=true)
        @test comparedims(Bool, X(Sampled(1:2)), X(Sampled([1, 2])); valtype=false)
        @test !comparedims(Bool, X(Sampled(1:2)), X(Sampled([1, 2])); valtype=true)
        @test comparedims(X(Sampled(1:2)), X(Sampled([1, 2])); valtype=false) == X(Sampled(1:2))
        @test_throws DimensionMismatch comparedims(X(Sampled([1, 2])), X(Sampled(1:2)); valtype=true)
    end
    @testset "compare values" begin
        @test comparedims(Bool, X(1:2), X(2:3); val=false)
        @test !comparedims(Bool, X(1:2), X(2:3); val=true)
        @test_warn "do not match" comparedims(Bool, X(1:2), X(2:3); val=true, warn="")
        @test comparedims(Bool, X(Sampled(1:2)), X(Sampled(2:3)); val=false)
        @test !comparedims(Bool, X(Sampled(1:2)), X(Sampled(2:3)); val=true)
        @test comparedims(X(Sampled(1:2)), X(Sampled(2:3)); val=false) == X(Sampled(1:2))
        @test_throws DimensionMismatch comparedims(X(Sampled(1:2)), X(Sampled(2:3)); val=true)
    end
    @testset "compare length" begin
        @test comparedims(Bool, X(1:2), X(1:3); length=false)
        @test !comparedims(Bool, X(1:2), X(1:3); length=true)
        @test_warn "Found both lengths" comparedims(Bool, X(1:2), X(1:3); length=true, warn="")
        @test comparedims(X(1:2), X(1:3); length=false) == X(1:2)
        @test_throws DimensionMismatch comparedims(X(1:2), X(1:3); length=true)
        @test comparedims(Bool, X(1:2), X(1:1); length=true, ignore_length_one=true)
        @test !comparedims(Bool, X(1:2), X(1:1); length=true, ignore_length_one=false)
        @test comparedims(X(1:2), X(1:1); length=false, ignore_length_one=true) == X(1:2)
        @test_throws DimensionMismatch comparedims(X(1:2), X(1:1); length=true, ignore_length_one=false)
    end
    @testset "compare order" begin
        a, b = X(Sampled(1:2); order=ForwardOrdered()), X(Sampled(1:2); order=ReverseOrdered())
        @test comparedims(Bool, a, b; order=false)
        @test !comparedims(Bool, a, b; order=true)
        @test comparedims(Bool, a, b; order=false)
        @test_nowarn comparedims(Bool, a, b; order=true)
        @test_nowarn comparedims(Bool, a, b; order=true, warn="")
        @test_warn "Lookups do not all have the same order" comparedims(Bool, a, b; order=true, warn="")
        @test_throws DimensionMismatch comparedims(a, b; order=true)
    end
end

@testset "setdims" begin
    A = setdims(da, X(Sampled(LinRange(150,152,2))))
    @test index(A, X()) == LinRange(150,152,2)
    @test dims(dims(A)) isa Tuple{<:X,<:Y}
    A = setdims(da, Y(Sampled(10:12)), X(Sampled(LinRange(150,152,2))))
    @test index(dims(dims(A), Y())) == 10:12
    @test dims(dims(A)) isa Tuple{<:X,<:Y}
    @testset "set an empty tuple" begin
        A = setdims(da, ())
        @test dims(A) === dims(da)
    end
end

@testset "swapdims" begin
    @testset "swap type wrappers" begin
        A = swapdims(da, (Z, Dim{:test1}))
        @test dims(A) isa Tuple{<:Z,<:Dim{:test1}}
        @test map(val, dims(A)) == map(val, dims(da))
        @test map(lookup, dims(A)) == map(lookup, dims(da))
    end
    @testset "swap whole dim instances" begin
        A = swapdims(da, Z(2:2:4), Dim{:test2}(3:5))
        @test dims(A) isa Tuple{<:Z,<:Dim{:test2}}
        @test map(index, dims(A)) === (2:2:4, 3:5)
        @test map(lookup, dims(A)) ===
            (Sampled(2:2:4, ForwardOrdered(), Regular(2), Points(), NoMetadata()),
             Sampled(3:5, ForwardOrdered(), Regular(1), Points(), NoMetadata()))
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
    @testset "Regular Points" begin
        da = DimArray(a, (X(143:2:145), Y(-20:-1:-22)))
        dimz = dims(da)
        @test slicedims(dimz, (1:2, 3)) == slicedims(dimz, 1:2, 3) == slicedims(dimz, (), (1:2, 3)) ==
            ((X(Sampled(143:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),),
              (Y(Sampled(-22:-1:-22, ReverseOrdered(), Regular(-1), Points(), NoMetadata())),))
        @test slicedims(dimz, (Z(),), (1:2, 3)) == slicedims(dimz, (Z(),), 1:2, 3) ==
            ((X(Sampled(143:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),),
             (Z(), Y(Sampled(-22:-1:-22, ReverseOrdered(), Regular(-1), Points(), NoMetadata())),))
        @test slicedims(dimz, 2:2, :) == slicedims(dimz, (), 2:2, :) ==
            ((X(Sampled(145:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
              Y(Sampled(-20:-1:-22, ReverseOrdered(), Regular(-1), Points(), NoMetadata()))), ())
        # What is this testing, it should error...
        @test_broken slicedims((), (1:2, 3)) == slicedims((), (), (1:2, 3)) ==
              slicedims((), 1:2, 3) == slicedims((), (), 1:2, 3) == ((), ())
        @test slicedims(dimz, CartesianIndex(2, 3)) ==
            ((), (X(Sampled(145:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
                  Y(Sampled(-22:-1:-22, ReverseOrdered(), Regular(-1), Points(), NoMetadata()))),)
        @test slicedims(dimz, (CartesianIndex(2, 3),)) ==
            ((), (X(Sampled(145:2:145, ForwardOrdered(), Regular(2), Points(), NoMetadata())),
                  Y(Sampled(-22:-1:-22, ReverseOrdered(), Regular(-1), Points(), NoMetadata()))),)
    end

    @testset "Regular Intervals" begin
        irreg = DimArray(a, (X(Sampled([140.0, 142.0], ForwardOrdered(), Regular(2.0), Intervals(Start()), NoMetadata())),
                             Y(Sampled([30.0, 20.0, 10.0], ReverseOrdered(), Regular(-10.0), Intervals(Center()), NoMetadata())), ))
        irreg_dimz = dims(irreg)
        @test slicedims(irreg, (1:2, 3)) == slicedims(irreg, 1:2, 3) ==
            ((X(Sampled([140.0, 142.0], ForwardOrdered(), Regular(2.0), Intervals(Start()), NoMetadata())),),
                 (Y(Sampled([10.0], ReverseOrdered(), Regular(-10.0), Intervals(Center()), NoMetadata())),))
        @test slicedims(irreg, (2:2, 1:2)) == slicedims(irreg, 2:2, 1:2) ==
            ((X(Sampled([142.0], ForwardOrdered(), Regular(2.0), Intervals(Start()), NoMetadata())),
              Y(Sampled([30.0, 20.0], ReverseOrdered(), Regular(-10.0), Intervals(Center()), NoMetadata()))), ())
        # This should never happen, not sure why it was tested?
        @test_broken slicedims((), (1:2, 3)) == slicedims((), (), (1:2, 3)) == ((), ()) 
        @test slicedims((), (1, 1)) == slicedims((), (), (1, 1)) == ((), ()) 
    end

    @testset "Irregular Points" begin
        irreg = DimArray(a, (X(Sampled([140.0, 142.0], ForwardOrdered(), Irregular(), Points(), NoMetadata())),
                             Y(Sampled([40.0, 20.0, 10.0], ReverseOrdered(), Irregular(), Points(), NoMetadata())), ))
        irreg_dimz = dims(irreg)
        @test slicedims(irreg, (1:2, 3)) == slicedims(irreg, 1:2, 3) ==
        ((X(Sampled([140.0, 142.0], ForwardOrdered(), Irregular(140, 142), Points(), NoMetadata())),),
         (Y(Sampled([10.0], ReverseOrdered(), Irregular(10.0, 10.0), Points(), NoMetadata())),))
        @test slicedims(irreg, (2:2, 1:2)) == slicedims(irreg, 2:2, 1:2) ==
        ((X(Sampled([142.0], ForwardOrdered(), Irregular(142, 142), Points(), NoMetadata())),
          Y(Sampled([40.0, 20.0], ReverseOrdered(), Irregular(20.0, 40.0), Points(), NoMetadata()))), ())
        @test_broken slicedims((), (1:2, 3)) == slicedims((), (), (1:2, 3)) == ((), ())
        @test slicedims((), (1, 1)) == slicedims((), (), (1, 1)) == ((), ())
    end

    @testset "Irregular Intervals" begin
        irreg = DimArray(a, (X(Sampled([140.0, 142.0], ForwardOrdered(), Irregular(140.0, 144.0), Intervals(Start()), NoMetadata())),
                             Y(Sampled([40.0, 20.0, 10.0], ReverseOrdered(), Irregular(0.0, 60.0), Intervals(Center()), NoMetadata())), ))
        irreg_dimz = dims(irreg)
        @test slicedims(irreg, (1:2, 3)) == slicedims(irreg, 1:2, 3) ==
            ((X(Sampled([140.0, 142.0], ForwardOrdered(), Irregular(140.0, 144.0), Intervals(Start()), NoMetadata())),),
             (Y(Sampled([10.0], ReverseOrdered(), Irregular(0.0, 15.0), Intervals(Center()), NoMetadata())),))
        @test slicedims(irreg, (2:2, 1:2)) == slicedims(irreg, 2:2, 1:2) ==
            ((X(Sampled([142.0], ForwardOrdered(), Irregular(142.0, 144.0), Intervals(Start()), NoMetadata())),
              Y(Sampled([40.0, 20.0], ReverseOrdered(), Irregular(15.0, 60.0), Intervals(Center()), NoMetadata()))), ())
        @test_broken slicedims((), (1:2, 3)) == slicedims((), (), (1:2, 3)) == ((), ())
        @test slicedims((), (1, 1)) == slicedims((), (), (1, 1)) == ((), ())
    end

    @testset "NoLookup" begin
        da = DimArray(a, (X(), Y()))
        dimz = dims(da)
        @test slicedims(dimz, (1:2, 3)) == ((X(NoLookup(1:2)),), (Y(NoLookup(3:3)),))
        @test slicedims(dimz, (2:2, :)) == ((X(NoLookup(2:2)), Y(NoLookup(Base.OneTo(3)))), ())
    end
    @testset "No slicing" begin
        da = DimArray(a, (X([143, 145]), Y([:x, :y, :z])))
        dimz = dims(da)
        @test slicedims(dimz, ()) == (dimz, ())
    end
end

@testset "reducedims" begin
    @test _reducedims((X(Sampled(3:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
                 Y(Sampled(1:5, ForwardOrdered(), Regular(1), Points(), NoMetadata()))), (X, Y)) ==
                     (X(Sampled(3.5:2:3.5, ForwardOrdered(), Regular(2.0), Points(), NoMetadata())),
                      Y(Sampled(3.0:5.0:3.0, ForwardOrdered(), Regular(5.0), Points(), NoMetadata())))
    @test _reducedims((X(Sampled(3:4, ForwardOrdered(), Regular(1), Intervals(Start()), NoMetadata())),
                       Y(Sampled(1:5, ForwardOrdered(), Regular(1), Intervals(End()), NoMetadata()))), (X, Y)) ==
        (X(Sampled(3:2:3, ForwardOrdered(), Regular(2), Intervals(Start()), NoMetadata())),
         Y(Sampled(5:5:5, ForwardOrdered(), Regular(5), Intervals(End()), NoMetadata())))

   @test _reducedims((X(Sampled(3:4, ForwardOrdered(), Irregular(2.5, 4.5), Intervals(Center()), NoMetadata())),
                      Y(Sampled(1:5, ForwardOrdered(), Irregular(0.5, 5.5), Intervals(Center()), NoMetadata()))), (X, Y))[1] ==
       (X(Sampled([3.5], ForwardOrdered(), Irregular(2.5, 4.5), Intervals(Center()), NoMetadata())),
        Y(Sampled([3.0], ForwardOrdered(), Irregular(0.5, 5.5), Intervals(Center()), NoMetadata())))[1]
   @test _reducedims((X(Sampled(3:4, ForwardOrdered(), Irregular(3, 5), Intervals(Start()), NoMetadata())),
                      Y(Sampled(1:5, ForwardOrdered(), Irregular(0, 5), Intervals(End()), NoMetadata()))), (X, Y))[1] ==
      (X(Sampled([3], ForwardOrdered(), Irregular(3, 5), Intervals(Start()), NoMetadata())),
       Y(Sampled([5], ForwardOrdered(), Irregular(0, 5), Intervals(End()), NoMetadata())))[1]

    args = ForwardOrdered(), Irregular(), Points(), NoMetadata()
    @test _reducedims((X(Sampled(3:4, args...)), Y(Sampled(1:5, args...))), (X, Y)) ==
        (X(Sampled([3.5], args...)), Y(Sampled([3.0], args...)))
    @test _reducedims((X(Sampled(3:4, ForwardOrdered(), Regular(1), Points(), NoMetadata())),
                       Y(Sampled(1:5, ForwardOrdered(), Regular(1), Points(), NoMetadata()))), (X, Y)) ==
                      (X(Sampled(3.5:2.0:3.5, ForwardOrdered(), Regular(2.0), Points(), NoMetadata())),
                       Y(Sampled(3.0:5.0:3.0, ForwardOrdered(), Regular(5.0), Points(), NoMetadata())))

    @test _reducedims((X(Categorical([:a,:b])),
                       Y(Categorical(["1","2","3","4","5"]))), (X, Y)) ==
        (X(Categorical([:combined])), Y(Categorical(["combined"])))

    @test _reducedims((X(NoLookup(Base.OneTo(10))),
                 Y(NoLookup(Base.OneTo(10)))), (X(), Y())) ==
        (X(NoLookup(Base.OneTo(1))), Y(NoLookup(Base.OneTo(1))))

    @testset "Special case CompoundPeriod" begin
        step_ = Dates.CompoundPeriod([Month(1), Day(3)])
        timespan = [DateTime(2001, 1), DateTime(2001, 1, 3)]
        teststep = Dates.CompoundPeriod([Month(2), Day(6)])
        testdim = Ti(Sampled([DateTime(2001, 1, 2)], ForwardOrdered(), Regular(teststep), Points(), NoMetadata()))
        reduceddim = _reducedims((Ti(Sampled(timespan, ForwardOrdered(), Regular(step_), Points(), NoMetadata())),), (Ti,))[1]
        @test typeof(testdim) == typeof(reduceddim)
        @test testdim == reduceddim
        @test step(testdim) == step(reduceddim)
    end
end
