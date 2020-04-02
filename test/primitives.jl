using DimensionalData, Test

using DimensionalData: val, basetypeof, slicedims, dims2indices, formatdims, mode,
      @dim, reducedims, XDim, YDim, ZDim, Forward

dimz = (X(), Y())

@testset "permutedims" begin
    @test permutedims((Y(1:2), X(1)), dimz) == (X(1), Y(1:2))
    @test permutedims((X(1),), dimz) == (X(1), nothing)
    @test permutedims((Y(), X()), dimz) == (X(:), Y(:))
    @test permutedims([Y(), X()], dimz) == (X(:), Y(:))
    @test permutedims((Y, X),     dimz) == (X, Y)
    @test permutedims([Y, X],     dimz) == (X, Y)
    @test permutedims(dimz, (Y(), X())) == (Y(:), X(:))
    @test permutedims(dimz, [Y(), X()]) == (Y(:), X(:))
    @test permutedims(dimz, (Y, X)    ) == (Y(:), X(:))
    @test permutedims(dimz, [Y, X]    ) == (Y(:), X(:))
end

a = [1 2 3; 4 5 6]
da = DimensionalArray(a, (X((143, 145)), Y((-38, -36))))
dimz = dims(da)

@testset "slicedims" begin
    @test slicedims(dimz, (1:2, 3)) == 
        ((X(LinRange(143,145,2), Sampled(span=Regular(2.0)), nothing),),
         (Y(-36.0, Sampled(span=Regular(1.0)), nothing),))
    @test slicedims(dimz, (2:2, :)) == 
        ((X(LinRange(145,145,1), Sampled(span=Regular(2.0)), nothing), 
          Y(LinRange(-38.0,-36.0, 3), Sampled(span=Regular(1.0)), nothing)), ())
    @test slicedims((), (1:2, 3)) == ((), ())
end

@testset "dims2indices" begin
    emptyval = Colon()
    @test DimensionalData._dims2indices(mode(dimz[1]), dimz[1], Y, Nothing) == Colon()
    @test dims2indices(dimz, (Y(),), emptyval) == (Colon(), Colon())
    @test dims2indices(dimz, (Y(1),), emptyval) == (Colon(), 1)
    # Time is just ignored if it's not in dims. Should this be an error?
    @test dims2indices(dimz, (Ti(4), X(2))) == (2, Colon())
    @test dims2indices(dimz, (Y(2), X(3:7)), emptyval) == (3:7, 2)
    @test dims2indices(dimz, (X(2), Y([1, 3, 4])), emptyval) == (2, [1, 3, 4])
    @test dims2indices(da, (X(2), Y([1, 3, 4])), emptyval) == (2, [1, 3, 4])
    emptyval=()
    @test dims2indices(dimz, (Y,), emptyval) == ((), Colon())
    @test dims2indices(dimz, (Y, X), emptyval) == (Colon(), Colon())
    @test dims2indices(da, X, emptyval) == (Colon(), ())
    @test dims2indices(da, (1:3, [1, 2, 3]), emptyval) == (1:3, [1, 2, 3])
    @test dims2indices(da, 1, emptyval) == (1, )
end

@testset "dims2indices with Transformed" begin
    tdimz = Dim{:trans1}(nothing; mode=Transformed(X())), 
            Dim{:trans2}(nothing, mode=Transformed(Y())), 
            Ti(1:1)
    @test dims2indices(tdimz, (X(1), Y(2), Ti())) == (1, 2, Colon())
    @test dims2indices(tdimz, (Dim{:trans1}(1), Dim{:trans2}(2), Ti())) == (1, 2, Colon())
end

@testset "dimnum" begin
    @test dimnum(da, X) == 1
    @test dimnum(da, Y()) == 2
    @test dimnum(da, (Y, X())) == (2, 1)
    @test_throws ArgumentError dimnum(da, Ti) == (2, 1)
end

@testset "reducedims" begin
    @test reducedims((X(3:4; mode=Sampled(;span=Regular(1))), 
                      Y(1:5; mode=Sampled(;span=Regular(1)))), (X, Y)) == 
                     (X([4], Sampled(;span=Regular(2)), nothing), 
                      Y([3], Sampled(;span=Regular(5)), nothing))
    @test reducedims((X(3:4; mode=Sampled(Ordered(), Regular(1), Intervals(Start()))), 
                      Y(1:5; mode=Sampled(Ordered(), Regular(1), Intervals(End())))), (X, Y)) ==
        (X([3], Sampled(Ordered(), Regular(2), Intervals(Start())), nothing), 
         Y([5], Sampled(Ordered(), Regular(5), Intervals(End())), nothing))

    @test reducedims((X(3:4; mode=Sampled(sampling=Intervals(Center()), span=Irregular(2.5, 4.5), )),
                      Y(1:5; mode=Sampled(sampling=Intervals(Center()), span=Irregular(0.5, 5.5), ))), (X, Y))[1] ==
                     (X([4], Sampled(sampling=Intervals(Center()), span=Irregular(2.5, 4.5)), nothing),
                      Y([3], Sampled(sampling=Intervals(Center()), span=Irregular(0.5, 5.5)), nothing))[1]
    @test reducedims((X(3:4; mode=Sampled(sampling=Intervals(Start()), span=Irregular(3, 5))),
                      Y(1:5; mode=Sampled(sampling=Intervals(End()  ), span=Irregular(0, 5)))), (X, Y))[1] ==
                     (X([3], Sampled(sampling=Intervals(Start()), span=Irregular(3, 5)), nothing),
                      Y([5], Sampled(sampling=Intervals(End()  ), span=Irregular(0, 5)), nothing))[1]

    @test reducedims((X(3:4; mode=Sampled(sampling=Points(), span=Irregular())), 
                      Y(1:5; mode=Sampled(sampling=Points(), span=Irregular()))), (X, Y)) ==
        (X([4], Sampled(span=Irregular()), nothing), 
         Y([3], Sampled(span=Irregular()), nothing))
    @test reducedims((X(3:4; mode=Sampled(sampling=Points(), span=Regular(1))), 
                      Y(1:5; mode=Sampled(sampling=Points(), span=Regular(1)))), (X, Y)) ==
        (X([4], Sampled(span=Regular(2)), nothing), 
         Y([3], Sampled(span=Regular(5)), nothing))

    @test reducedims((X([:a,:b]; mode=Categorical()), 
                      Y(["1","2","3","4","5"]; mode=Categorical())), (X, Y)) ==
                     (X([:combined]; mode=Categorical()), 
                      Y(["combined"]; mode=Categorical()))
end

@testset "dims" begin
    @test dims(da, X) isa X
    @test dims(da, (X, Y)) isa Tuple{<:X,<:Y}
    @test dims(dims(da), Y) isa Y
    @test dims(dims(da), 1) isa X
    @test dims(dims(da), (2, 1)) isa Tuple{<:Y,<:X}
    @test dims(dims(da), (2, Y)) isa Tuple{<:Y,<:Y}
    @test dims(da, ()) == ()
    @test_throws ArgumentError dims(da, Ti)
    x = dims(da, X)
    @test dims(x) == x
end

@testset "hasdim" begin
    @test hasdim(da, X) == true
    @test hasdim(da, Ti) == false
    @test hasdim(dims(da), Y) == true
    @test hasdim(dims(da), (X, Y)) == (true, true)
    @test hasdim(dims(da), (X, Ti)) == (true, false)
    # Abstract
    @test hasdim(dims(da), (XDim, YDim)) == (true, true)
    # TODO : should this actually be (true, false) ?
    # Do we remove the second one for hasdim as well?
    @test hasdim(dims(da), (XDim, XDim)) == (true, true)
    @test hasdim(dims(da), (ZDim, YDim)) == (false, true)
    @test hasdim(dims(da), (ZDim, ZDim)) == (false, false)
end

@testset "setdims" begin
    A = setdims(da, X(LinRange(150,152,2)))
    @test val(dims(dims(A), X())) == LinRange(150,152,2)
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
            (Sampled(span=Regular(2)), 
             Sampled(span=Regular(1)))
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

