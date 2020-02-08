using DimensionalData, Test

using DimensionalData: val, basetypeof, slicedims, dims2indices, formatdims, hasdim, setdim,
      @dim, reducedims, dimnum, X, Y, Z, Time, Forward

dimz = (X(), Y())

@testset "permutedims" begin
    @test permutedims((Y(1:2), X(1)), dimz) == (X(1), Y(1:2))
    @test permutedims((X(1),), dimz) == (X(1), nothing)
    @test permutedims((Y(), X()), dimz) == (X(:), Y(:))
    @test permutedims([Y(), X()], dimz) == (X(:), Y(:))
    @test permutedims((Y, X),     dimz) == (X(:), Y(:))
    @test permutedims([Y, X],     dimz) == (X(:), Y(:))
    @test permutedims(dimz, (Y(), X())) == (Y(:), X(:))
    @test permutedims(dimz, [Y(), X()]) == (Y(:), X(:))
    @test permutedims(dimz, (Y, X)    ) == (Y(:), X(:))
    @test permutedims(dimz, [Y, X]    ) == (Y(:), X(:))
end

a = [1 2 3; 4 5 6]
da = DimensionalArray(a, (X((143, 145)), Y((-38, -36))))
dimz = dims(da)

@testset "slicedims" begin
    @test slicedims(dimz, (1:2, 3)) == ((X(LinRange(143,145,2); grid=RegularGrid(step=2.0)),),
                                        (Y(-36.0; grid=RegularGrid(step=1.0)),))
    @test slicedims(dimz, (2:2, :)) == ((X(LinRange(145,145,1); grid=RegularGrid(step=2.0)),
                                         Y(LinRange(-38.0,-36.0,3); grid=RegularGrid(step=1.0))), ())
    @test slicedims((), (1:2, 3)) == ((), ())
end

@testset "dims2indices" begin
    emptyval = Colon()
    @test dims2indices(grid(dimz[1]), dimz[1], Y, Nothing) == Colon()
    @test dims2indices(dimz, (Y(),), emptyval) == (Colon(), Colon())
    @test dims2indices(dimz, (Y(1),), emptyval) == (Colon(), 1)
    # Time is just ignored if it's not in dims. Should this be an error?
    @test dims2indices(dimz, (Time(4), X(2))) == (2, Colon())
    @test dims2indices(dimz, (Y(2), X(3:7)), emptyval) == (3:7, 2)
    @test dims2indices(dimz, (X(2), Y([1, 3, 4])), emptyval) == (2, [1, 3, 4])
    @test dims2indices(da, (X(2), Y([1, 3, 4])), emptyval) == (2, [1, 3, 4])
    emptyval=()
    @test dims2indices(dimz, (Y,), emptyval) == ((), Colon())
    @test dims2indices(dimz, (Y, X), emptyval) == (Colon(), Colon())
    @test dims2indices(da, X, emptyval) == (Colon(), ())
    @test dims2indices(da, (1:3, [1, 2, 3]), emptyval) == (1:3, [1, 2, 3])
    @test dims2indices(da, 1, emptyval) == (1, )
    tdimz = Dim{:trans1}(nothing; grid=TransformedGrid(X())), Dim{:trans2}(nothing, grid=TransformedGrid(Y())), Time(1:1)
    @test dims2indices(tdimz, (X(1), Y(2), Time())) == (1, 2, Colon())
    @test dims2indices(tdimz, (Dim{:trans1}(1), Dim{:trans2}(2), Time())) == (1, 2, Colon())
end

@testset "dimnum" begin
    @test dimnum(da, X) == 1
    @test dimnum(da, Y()) == 2
    @test dimnum(da, (Y, X())) == (2, 1)
    @test_throws ArgumentError dimnum(da, Time) == (2, 1)
end

@testset "reducedims" begin
    @test reducedims((X(3:4; grid=UnknownGrid()), Y(1:5; grid=UnknownGrid())), (X, Y)) ==
            (X(3; grid=UnknownGrid()), Y(1; grid=UnknownGrid()))
    @test reducedims((X(3:4; grid=RegularGrid(;step=1)), 
                      Y(1:5; grid=RegularGrid(;step=1))), (X, Y)) ==
                     (X([3]; grid=RegularGrid(;step=2, sampling=IntervalSampling())), 
                      Y([1]; grid=RegularGrid(;step=5, sampling=IntervalSampling())))
    @test reducedims((X(3:4; grid=BoundedGrid(;locus=Start(), bounds=(3, 5))),
                      Y(1:5; grid=BoundedGrid(;locus=End(), bounds=(0, 5)))), (X, Y))[1] ==
                     (X([3]; grid=BoundedGrid(;sampling=IntervalSampling(), bounds=(3, 5), locus=Start())),
                      Y([5]; grid=BoundedGrid(;sampling=IntervalSampling(), bounds=(0, 5), locus=End())))[1]
    @test reducedims((X(3:4; grid=BoundedGrid(;locus=Center(), bounds=(2.5, 4.5))),
                      Y(1:5; grid=BoundedGrid(;locus=Center(), bounds=(0.5, 5.5)))), (X, Y))[1] ==
                     (X([3.5]; grid=BoundedGrid(;sampling=IntervalSampling(), bounds=(2.5, 4.5), locus=Center())),
                      Y([3.5]; grid=BoundedGrid(;sampling=IntervalSampling(), bounds=(0.5, 5.5), locus=Center())))[1]
    @test reducedims((X(3:4; grid=AlignedGrid()), Y(1:5; grid=AlignedGrid())), (X, Y)) ==
                     (X([3]; grid=AlignedGrid(;sampling=IntervalSampling())), 
                      Y([1]; grid=AlignedGrid(;sampling=IntervalSampling())))
    @test reducedims((X([:a,:b]; grid=CategoricalGrid()), 
                      Y(["1","2","3","4","5"]; grid=CategoricalGrid())), (X, Y)) ==
                     (X([:combined]; grid=CategoricalGrid()), 
                      Y(["combined"]; grid=CategoricalGrid()))
end

@testset "dims" begin
    @test dims(da, X) isa X
    @test dims(da, (X, Y)) isa Tuple{<:X,<:Y}
    @test dims(dims(da), Y) isa Y
    @test dims(dims(da), 1) isa X
    @test dims(dims(da), (2, 1)) isa Tuple{<:Y,<:X}
    @test dims(dims(da), (2, Y)) isa Tuple{<:Y,<:Y}
    @test dims(da, ()) == ()
    @test_throws ArgumentError dims(da, Time)
    x = dims(da, X)
    @test dims(x) == x
end

@testset "hasdims" begin
    @test hasdim(da, X) == true
    @test hasdim(da, Time) == false
    @test hasdim(dims(da), Y) == true
    @test hasdim(dims(da), (X, Y)) == (true, true)
    @test hasdim(dims(da), (X, Time)) == (true, false)
end

@testset "setdim" begin
    A = setdim(da, X(LinRange(150,152,2)))
    @test val(dims(dims(A), X())) == LinRange(150,152,2)
end
