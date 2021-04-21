using DimensionalData, Test, Dates

# define dims with both long name and Type name
@dim Lon "Longitude"
@dim Lat "Latitude"

@testset "prettyprinting" begin

    timespan = DateTime(2001):Month(1):DateTime(2001,12)
    t = Ti([timespan...])
    x = Lon(Vector(0.5:10.0:359.5))
    y = Lat(Vector{Union{Float32, Missing}}(-89.5:10.0:89.5))
    n = Dim{:n}(Base.OneTo(10); mode=NoIndex())
    z = Z('a':'d')
    d = (x, y, z, t, n)
    A = DimArray(rand(length.(d)...), d; refdims=(Dim{:refdim}(1),))
    B = DimArray(rand(length(x)), (x,))
    C = DimArray(rand(Bool, 100, 100), (X, Y))

    for (d, str) in ((Ti(), "Ti"), (Lat(), "Lat"), (Lon(), "Lon"), (:n, ":n"), (Z(), "Z")) s1 = sprint(show, MIME("text/plain"), A)
        s2 = sprint(show, MIME("text/plain"), dims(A, d))
        s3 = sprint(show, MIME("text/plain"), dims(A, d))
        @test occursin("DimArray", s1)
        for s in (s1, s2, s3)
            @test occursin(str, s)
            @test occursin(str, s)
        end
    end

    # Test again but now with labelled array A
    A = DimArray(rand(length.(d)...), d, :test)
    s1 = sprint(show, MIME("text/plain"), A)
    @test occursin("test", s1)

    # Does it propagate after indexing?
    F = A[Ti(1:4)]
    s2 = sprint(show, MIME("text/plain"), F)
    @test occursin("test", s2)

    # Does it propagate after e.g. reducing operations?
    G = sum(A; dims = Ti)
    s3 = sprint(show, MIME("text/plain"), G)
    @test occursin("test", s3)

    # It should NOT propagate after binary operations
    B = DimArray(rand(length.(d)...), d, :test2)
    C = A .+ B
    s4 = sprint(show, MIME("text/plain"), C)
    @test !occursin("test", s4)

    # Test that broadcasted setindex! retains name
    D = DimArray(ones(length.(d)...), d, :olo)
    @. D = A + B
    s5 = sprint(show, MIME("text/plain"), D)
    @test occursin("olo", s5)

    # Test zero dim show
    D = DimArray([x for x in 1], (), :zero)
    sz = sprint(show, MIME("text/plain"), D)
    @test occursin("zero", sz)

    # Test vector show
    D = DimArray(ones(length(t)), t, :vec)
    sv = sprint(show, MIME("text/plain"), D)
    @test occursin("vec", sv)

    sv = sprint(show, MIME("text/plain"), X())
    @test occursin("X", sv)

    @testset "show modes" begin
        sv = sprint(show, MIME("text/plain"), Categorical(Unordered()))
        @test occursin("Categorical", sv)
        @test occursin("Unordered", sv)
        sv = sprint(show, MIME("text/plain"), Sampled(Ordered(), Regular(), Points()))
        @test occursin("Sampled", sv)
        @test occursin("Ordered", sv)
        @test occursin("Regular", sv)
        @test occursin("Points", sv)
        sv = sprint(show, MIME("text/plain"), NoIndex())
        @test occursin("NoIndex", sv)
    end

end
