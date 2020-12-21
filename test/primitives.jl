using DimensionalData, Test

using DimensionalData: val, basetypeof, slicedims, dims2indices, mode,
      @dim, reducedims, XDim, YDim, ZDim, commondims, dim2key, key2dim, dimstride

@testset "sortdims" begin
    dimz = (X(), Y(), Z(), Ti())
    @test @inferred sortdims((Y(1:2), X(1)), dimz) == (X(1), Y(1:2), nothing, nothing)
    @test @inferred sortdims((Ti(1),), dimz) == (nothing, nothing, nothing, Ti(1))
    @test @inferred sortdims((Y, X, Z, Ti), dimz) == (X(), Y(), Z(), Ti())
    @test @inferred sortdims((Y(), X(), Z(), Ti()), dimz) == (X(), Y(), Z(), Ti())
    @test @inferred sortdims([Y(), X(), Z(), Ti()], dimz) == (X(), Y(), Z(), Ti())
    @test @inferred sortdims((Z(), Y(), X()),     dimz) == (X(), Y(), Z(), nothing)
    @test @inferred sortdims(dimz, (Y(), Z())) == (Y(), Z())
    @test @inferred sortdims(dimz, [Ti(), X(), Z()]) == (Ti(), X(), Z())
    @test @inferred sortdims(dimz, (Y, Ti)    ) == (Y(), Ti())
    @test @inferred sortdims(dimz, [Ti, Z, X, Y]    ) == (Ti(), Z(), X(), Y())
    # Transformed
    @test @inferred sortdims((Y(1:2; mode=Transformed(identity, Z())), X(1)), (X(), Z())) == 
                             (X(1), Y(1:2; mode=Transformed(identity, Z()))) 
    # Abstract
    @test @inferred sortdims((Z(), Y(), X()), (XDim, TimeDim)) == (X(), nothing)
    # Repeating
    @test @inferred sortdims((Z(:a), Y(), Z(:b)), (YDim, Z(), ZDim)) == (Y(), Z(:a), Z(:b))
end

a = [1 2 3; 4 5 6]
da = DimArray(a, (X((143, 145)), Y((-38, -36))))
dimz = dims(da)

@testset "slicedims" begin
    @testset "Regular" begin
        @test slicedims(dimz, (1:2, 3)) == 
            ((X(LinRange(143,145,2), Sampled(Ordered(), Regular(2.0), Points()), NoMetadata()),),
             (Y(-36.0, Sampled(Ordered(), Regular(1.0), Points()), NoMetadata()),))
        @test slicedims(dimz, (2:2, :)) == 
            ((X(LinRange(145,145,1), Sampled(Ordered(), Regular(2.0), Points()), NoMetadata()), 
              Y(LinRange(-38.0,-36.0, 3), Sampled(Ordered(), Regular(1.0), Points()), NoMetadata())), ())
        @test slicedims((), (1:2, 3)) == ((), ())
    end
    @testset "Irregular" begin
        irreg = DimArray(a, (X([140.0, 142.0]; mode=Sampled(Ordered(), Irregular(140.0, 144.0), Intervals(Start()))), 
                                     Y([10.0, 20.0, 40.0]; mode=Sampled(Ordered(), Irregular(0.0, 60.0), Intervals(Center()))), ))
        irreg_dimz = dims(irreg)
        @test slicedims(irreg, (1:2, 3)) == 
            ((X([140.0, 142.0], Sampled(Ordered(), Irregular(140.0, 144.0), Intervals(Start())), NoMetadata()),),
                    (Y(40.0, Sampled(Ordered(), Irregular(30.0, 60.0), Intervals(Center())), NoMetadata()),))
        @test slicedims(irreg, (2:2, 1:2)) == 
            ((X([142.0], Sampled(Ordered(), Irregular(142.0, 144.0), Intervals(Start())), NoMetadata()), 
              Y([10.0, 20.0], Sampled(Ordered(), Irregular(0.0, 30.0), Intervals(Center())), NoMetadata())), ())
        @test slicedims((), (1:2, 3)) == ((), ())
    end
    @testset "Val index" begin
        da = DimArray(a, (X(Val((143, 145))), Y(Val((:x, :y, :z)))))
        dimz = dims(da)
        @test slicedims(dimz, (1:2, 3)) == 
            ((X(Val((143,145)), Categorical(), NoMetadata()),),
             (Y(Val(:z), Categorical(), NoMetadata()),))
        @test slicedims(dimz, (2:2, :)) == 
            ((X(Val((145,)), Categorical(), NoMetadata()), 
              Y(Val((:x, :y, :z)), Categorical(), NoMetadata())), ())
    end
    @testset "NoIndex" begin
        da = DimArray(a, (X(Val((143, 145))), Y(Val((:x, :y, :z)))))
        dimz = dims(da)
        @test slicedims(dimz, (1:2, 3)) == 
            ((X(Val((143,145)), Categorical(), NoMetadata()),),
             (Y(Val(:z), Categorical(), NoMetadata()),))
        @test slicedims(dimz, (2:2, :)) == 
            ((X(Val((145,)), Categorical(), NoMetadata()), 
              Y(Val((:x, :y, :z)), Categorical(), NoMetadata())), ())
    end

    @testset "No slicing" begin
        da = DimArray(a, (X(Val((143, 145))), Y(Val((:x, :y, :z)))))
        dimz = dims(da)
        @test slicedims(dimz, (Ti(),), ()) == (dimz, (Ti(),))
    end
end

@testset "dims2indices" begin
    @test DimensionalData._dims2indices(dimz[1], Y) == Colon()
    @test dims2indices(dimz, (Y(),)) == (Colon(), Colon())
    @test dims2indices(dimz, (Y(1),)) == (Colon(), 1)
    @test dims2indices(dimz, (Ti(4), X(2))) == (2, Colon())
    @test dims2indices(dimz, (Y(2), X(3:7))) == (3:7, 2)
    @test dims2indices(dimz, (X(2), Y([1, 3, 4]))) == (2, [1, 3, 4])
    @test dims2indices(da, (X(2), Y([1, 3, 4]))) == (2, [1, 3, 4])
end

@testset "dims2indices with Transformed" begin
    tdimz = Dim{:trans1}(mode=Transformed(identity, X())), 
            Dim{:trans2}(mode=Transformed(identity, Y())), 
            Z(1:1, NoIndex(), nothing)
    @test dims2indices(tdimz, (X(1), Y(2), Z())) == (1, 2, Colon())
    @test dims2indices(tdimz, (Dim{:trans1}(1), Dim{:trans2}(2), Z())) == (1, 2, Colon())
end

@testset "dimnum" begin
    @test dimnum(da, X) == 1
    @test dimnum(da, Y()) == 2
    @test dimnum(da, (Y, X())) == (2, 1)
    @test_throws ArgumentError dimnum(da, Ti) == (2, 1)

    @testset "with Dim{X} and symbols" begin
        @test dimnum((Dim{:a}(), Dim{:b}()), :a) == 1
        @test dimnum((Dim{:a}(), Y(), Dim{:b}()), (:b, :a, Y())) == (3, 1, 2)
    end
end

@testset "reducedims" begin
    @test reducedims((X(3:4; mode=Sampled(Ordered(), Regular(1), Points())), 
                      Y(1:5; mode=Sampled(Ordered(), Regular(1), Points()))), (X, Y)) == 
                     (X([4], Sampled(Ordered(), Regular(2), Points()), NoMetadata()), 
                      Y([3], Sampled(Ordered(), Regular(5), Points()), NoMetadata()))
    @test reducedims((X(3:4; mode=Sampled(Ordered(), Regular(1), Intervals(Start()))), 
                      Y(1:5; mode=Sampled(Ordered(), Regular(1), Intervals(End())))), (X, Y)) ==
        (X([3], Sampled(Ordered(), Regular(2), Intervals(Start())), NoMetadata()), 
         Y([5], Sampled(Ordered(), Regular(5), Intervals(End())), NoMetadata()))

    @test reducedims((X(3:4; mode=Sampled(Ordered(), Irregular(2.5, 4.5), Intervals(Center()))),
                      Y(1:5; mode=Sampled(Ordered(), Irregular(0.5, 5.5), Intervals(Center())))), (X, Y))[1] ==
                     (X([4], Sampled(Ordered(), Irregular(2.5, 4.5), Intervals(Center())), NoMetadata()),
                      Y([3], Sampled(Ordered(), Irregular(0.5, 5.5), Intervals(Center())), NoMetadata()))[1]
    @test reducedims((X(3:4; mode=Sampled(Ordered(), Irregular(3, 5), Intervals(Start()))),
                      Y(1:5; mode=Sampled(Ordered(), Irregular(0, 5), Intervals(End()  )))), (X, Y))[1] ==
                     (X([3], Sampled(Ordered(), Irregular(3, 5), Intervals(Start())), NoMetadata()),
                      Y([5], Sampled(Ordered(), Irregular(0, 5), Intervals(End()  )), NoMetadata()))[1]

    @test reducedims((X(3:4; mode=Sampled(Ordered(), Irregular(), Points())), 
                      Y(1:5; mode=Sampled(Ordered(), Irregular(), Points()))), (X, Y)) ==
        (X([4], Sampled(Ordered(), Irregular(), Points()), NoMetadata()), 
         Y([3], Sampled(Ordered(), Irregular(), Points()), NoMetadata()))
    @test reducedims((X(3:4; mode=Sampled(Ordered(), Regular(1), Points())), 
                      Y(1:5; mode=Sampled(Ordered(), Regular(1), Points()))), (X, Y)) ==
                     (X([4], Sampled(Ordered(), Regular(2), Points()), NoMetadata()), 
                      Y([3], Sampled(Ordered(), Regular(5), Points()), NoMetadata()))

    @test reducedims((X([:a,:b]; mode=Categorical()), 
                      Y(["1","2","3","4","5"]; mode=Categorical())), (X, Y)) ==
                     (X([:combined]; mode=Categorical()), 
                      Y(["combined"]; mode=Categorical()))
end

@testset "dims" begin
    dimz = dims(da)
    @test dims(X()) == X()
    @test dims(dimz, Y) isa Y
    @test dims(dimz, 1) isa X
    @test dims(dimz, (2, 1)) isa Tuple{<:Y,<:X}
    @test dims(dimz, (2, Y)) isa Tuple{<:Y,<:Y}
    @test dims(da, X) isa X
    @test dims(da, (X, Y)) isa Tuple{<:X,<:Y}
    @test dims(da, ()) == ()

    @testset "with Dim{X} and symbols" begin
        A = DimArray(zeros(4, 5), (:one, :two))
        @test dims(A) == 
            (Dim{:one}(Base.OneTo(4), NoIndex(), NoMetadata()), 
             Dim{:two}(Base.OneTo(5), NoIndex(), NoMetadata()))
        @test dims(A, :two) == Dim{:two}(Base.OneTo(5), NoIndex(), NoMetadata())
    end
    @test_throws ArgumentError dims(da, Ti)
    @test_throws ArgumentError dims(dimz, Ti)
    @test_throws ArgumentError dims(nothing, X)

    @test dims(dimz) === dimz
    @test dims(dimz, X) === dimz[1]
    @test dims(dimz, Y) === dimz[2]
    @test dims(dimz, Y) === dimz[2]
    @test typeof(dims(da)) ==
        Tuple{X{LinRange{Float64},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},NoMetadata},
              Y{LinRange{Float64},Sampled{Ordered{ForwardIndex,ForwardArray,ForwardRelation},Regular{Float64},Points},NoMetadata}}
end

@testset "commondims" begin
    @test commondims(da, X) == (dims(da, X),)
    # Dims are always in the base order
    @test commondims(da, (X, Y)) == dims(da, (X, Y))
    @test commondims(da, (Y, X)) == dims(da, (X, Y))
    @test basetypeof(commondims(da, DimArray(zeros(5), Y()))[1]) <: Y

    @testset "with Dim{X} and symbols" begin
        @test @inferred commondims((Dim{:a}(), Dim{:b}()), (:a, :c)) == (Dim{:a}(),)
        @test @inferred commondims((Dim{:a}(), Y(), Dim{:b}()), (Y, :b, :z)) == (Y(), Dim{:b}())
    end

    @testset "with abstract types" begin
        @test @inferred commondims((Z(), Y(), Ti()), (ZDim, Dimension)) == (Z(), Y())
        @test @inferred commondims((TimeDim, YDim), (Z(), Ti(), Dim{:a}); op=(>:)) == (TimeDim,)
    end
end

@testset "hasdim" begin
    @test hasdim(da, X) == true
    @test hasdim(da, Ti) == false
    @test hasdim(dims(da), Y) == true
    @test hasdim(dims(da), (X, Y)) == (true, true)
    @test hasdim(dims(da), (X, Ti)) == (true, false)

    @testset "hasdim for Abstract types" begin
        @test hasdim(dims(da), (XDim, YDim)) == (true, true)
        # TODO : should this actually be (true, false) ?
        # Do we remove the second one for hasdim as well?
        @test hasdim(dims(da), (XDim, XDim)) == (true, true)
        @test hasdim(dims(da), (ZDim, YDim)) == (false, true)
        @test hasdim(dims(da), (ZDim, ZDim)) == (false, false)
    end

    @testset "with Dim{X} and symbols" begin
        @test hasdim((Dim{:a}(), Dim{:b}()), (:a, :c)) == (true, false)
        @test hasdim((Dim{:a}(), Dim{:b}()), (:b, :a, :c)) == (true, true, false)
    end
    @test_throws ArgumentError hasdim(nothing, X)
end

@testset "otherdims" begin
    A = DimArray(ones(5, 10, 15), (X, Y, Z));
    @test otherdims(A, X) == dims(A, (Y, Z))
    @test otherdims(A, Y) == dims(A, (X, Z))
    @test otherdims(A, Z) == dims(A, (X, Y))
    @test otherdims(A, (X, Z)) == dims(A, (Y,))
    @test otherdims(A, Ti) == dims(A, (X, Y, Z))

    @testset "with Dim{X} and symbols" begin
        @test otherdims((Z(), Dim{:a}(), Y(), Dim{:b}()), (:b, :a, Y)) == (Z(),)
        @test otherdims((Dim{:a}(), Dim{:b}(), Ti()), (:a, :c)) == (Dim{:b}(), Ti())
    end
    @test_throws ArgumentError otherdims(nothing, X)
end

@testset "setdims" begin
    A = setdims(da, X(LinRange(150,152,2)))
    @test val(dims(dims(A), X())) == LinRange(150,152,2)
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
        A = swapdims(da, (Z(2:2:4), Dim{:test2}(3:5)))
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

@dim Tst

@testset "dim2key" begin
    @test dim2key(X()) == :X
    @test dim2key(Dim{:x}) == :x
    @test dim2key(Tst()) == :Tst
    @test dim2key(Dim{:test}()) == :test 
end

@testset "key2dim" begin
    @test key2dim(:test) == Dim{:test}()
    @test key2dim(:X) == X()
    @test key2dim(:x) == Dim{:x}()
    @test key2dim(:Ti) == Ti()
    @test key2dim(:ti) == Dim{:ti}()
    @test key2dim(:Tst) == Tst()
end

@testset "dimstride" begin
    dimz = (X(), Y(), Dim{:test}())
    da = DimArray(ones(3, 2, 3), dimz, :data)
    @test dimstride(da, X()) == 1
    @test dimstride(da, Y()) == 3
    @test dimstride(da, Dim{:test}()) == 6
    @test_throws ArgumentError dimstride(nothing, X())
end
