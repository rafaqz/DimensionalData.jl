using Test, DimensionalData, Dates

using DimensionalData.Lookups, DimensionalData.Dimensions
const DD = DimensionalData

@testset "predicates on Lookup" begin
    @test DD.issampled(Cyclic(1:10; order=ForwardOrdered(), cycle=10)) == true
    @test DD.issampled(NoLookup()) == false
    @test DD.issampled(Categorical(1:10)) == false
    @test DD.iscategorical(Categorical(1:10)) == true
    @test DD.iscategorical(Sampled(1:10)) == false
    @test DD.iscategorical(Cyclic(1:10; order=ForwardOrdered(), cycle=10)) == false
    @test DD.iscategorical(NoLookup()) == false
    @test DD.iscyclic(Cyclic(1:10; order=ForwardOrdered(), cycle=10)) == true
    @test DD.iscyclic(Sampled(1:10)) == false
    @test DD.iscyclic(NoLookup()) == false
    @test DD.iscyclic(Categorical(1:10)) == false
end

@testset "predicates on Lookup traits" begin
    @test DD.isordered(ForwardOrdered()) == true
    @test DD.isordered(ReverseOrdered()) == true
    @test DD.isordered(Unordered()) == false
    @test DD.isforward(ForwardOrdered()) == true
    @test DD.isforward(ReverseOrdered()) == false
    @test DD.isforward(Unordered()) == false
    @test DD.isreverse(ReverseOrdered()) == true
    @test DD.isreverse(ForwardOrdered()) == false
    @test DD.isreverse(Unordered()) == false
    @test DD.isregular(Regular(1.0)) == true
    @test DD.isregular(Irregular((1.0, 2.0))) == false
    @test DD.isregular(Explicit([1 2])) == false
    @test DD.isexplicit(Explicit([1 2])) == true
    @test DD.isexplicit(Regular(1.0)) == false
    @test DD.isexplicit(Irregular((1, 2))) == false
    @test DD.ispoints(Points()) == true
    @test DD.ispoints(Intervals()) == false
    @test DD.isintervals(Intervals()) == true
    @test DD.isintervals(Points()) == false
    @test DD.isstart(Start()) == true
    @test DD.isstart(Center()) == false
    @test DD.isstart(End()) == false
    @test DD.iscenter(Center()) == true
    @test DD.iscenter(Start()) == false
    @test DD.iscenter(End()) == false
    @test DD.isend(End()) == true
    @test DD.isend(Start()) == false
    @test DD.isend(Center()) == false
end

@testset "predicates on Array or dimensions" begin
    A = rand(X(10:20), Y(10:20))
    for x in (A, dims(A))
        @test DD.issampled(x) == true
        @test DD.iscategorical(x) == false
        @test DD.iscyclic(x) == false
        @test DD.isordered(x) == true
        @test DD.isforward(x) == true
        @test DD.isreverse(x) == false
        @test DD.isregular(x) == true
        @test DD.isexplicit(x) == false
        @test DD.ispoints(x) == true
        @test DD.isintervals(x) == false
        @test DD.isstart(x) == false
        @test DD.iscenter(x) == true
        @test DD.isend(x) == false
    end
end

@testset "predicates on subsets of dimensions" begin
    ds = X(10:20),
         Ti(Cyclic([DateTime(2001), DateTime(2002), DateTime(2003)]; order=ForwardOrdered(), cycle=Year(3), sampling=Intervals(Start()))),
         Y(20:-1:10; sampling=Intervals(End())),
         Dim{:cat}(["a", "z", "b"])
    A = rand(ds)
    @test DD.issampled(A) == false
    @test DD.iscategorical(A) == false
    @test DD.iscyclic(A) == false
    @test DD.isordered(A) == false
    @test DD.isforward(A) == false
    @test DD.isreverse(A) == false
    @test DD.isregular(A) == false
    @test DD.isexplicit(A) == false
    @test DD.ispoints(A) == false
    @test DD.isintervals(A) == false
    @test DD.isstart(A) == false
    @test DD.iscenter(A) == false
    @test DD.isend(A) == false

    @test DD.issampled(A, (X, Y, Ti)) == true
    @test DD.iscategorical(A, :cat) == true
    @test DD.iscyclic(A, Ti) == true
    @test DD.isordered(A, (X, Y, Ti)) == true
    @test DD.isforward(A, (X, Ti)) == true
    @test DD.isreverse(A, Y) == true
    @test DD.isregular(A, (X, Y)) == true
    @test DD.ispoints(A, X) == true
    @test DD.isintervals(A, (Ti, Y)) == true
    @test DD.isstart(A, Ti) == true
    @test DD.iscenter(A, X) == true
    @test DD.isend(A, Y) == true
end
