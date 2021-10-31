using DimensionalData, Test, Dates
using DimensionalData.LookupArrays, DimensionalData.Dimensions

# define dims with both long name and Type name
@dim Lon "Longitude"
@dim Lat "Latitude"

timespan = DateTime(2001):Month(1):DateTime(2001,12)
t = Ti(timespan)
x = Lon(Vector(0.5:10.0:359.5))
y = Lat(Vector{Union{Float32, Missing}}(-89.5:10.0:89.5))
n = Dim{:n}(NoLookup(Base.OneTo(10)))
z = Z('a':'d')
ds = (x, y, z, t, n)
A = DimArray(rand(length.(ds)...), ds; refdims=(Dim{:refdim}(1),), name=:test)
ds = dims(A)

@testset "dims" begin
    sv = sprint(show, MIME("text/plain"), X())
    @test occursin("X", sv)
end

@testset "show lookups" begin
    sv = sprint(show, MIME("text/plain"), Categorical([:a, :b]; order=Unordered()))
    @test occursin("Categorical", sv)
    @test occursin("Unordered", sv)
    sv = sprint(show, MIME("text/plain"), Sampled(1:2; order=ForwardOrdered(), span=Regular(), sampling=Points()))
    @test occursin("Sampled", sv)
    @test occursin("Ordered", sv)
    @test occursin("Regular", sv)
    @test occursin("Points", sv)
    sv = sprint(show, MIME("text/plain"), NoLookup())
    @test occursin("NoLookup", sv)
    # LookupArray tuple
    ls = lookup(ds)
    sv = sprint(show, MIME("text/plain"), ls)
    @test occursin("Categorical", sv)
    @test occursin("Sampled", sv)
    sv = sprint(show, MIME("text/plain"), Transformed(identity, X()))
    @test occursin("Transformed", sv)
    @test occursin("X", sv)
    nds = (X(NoLookup(Base.OneTo(10))), Y(NoLookup(Base.OneTo(5))))
    sv = sprint(show, MIME("text/plain"), nds)
    @test occursin("X", sv)
    @test occursin("Y", sv)
end

@testset "arrays" begin
    for (d, str) in ((Ti(), "Ti"), (Lat(), "Lat"), (Lon(), "Lon"), (:n, ":n"), (Z(), "Z")) s1 = sprint(show, MIME("text/plain"), A)
        s2 = sprint(show, MIME("text/plain"), dims(A, ds))
        s3 = sprint(show, MIME("text/plain"), dims(A, ds))
        @test occursin("DimArray", s1)
        for s in (s1, s2, s3)
            @test occursin(str, s)
            @test occursin(str, s)
        end
    end

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
    B = DimArray(rand(length.(ds)...), ds; name=:test2)
    C = A .+ B
    s4 = sprint(show, MIME("text/plain"), C)
    @test !occursin("test", s4)

    # Test that broadcasted setindex! retains name
    D = DimArray(ones(length.(ds)...), ds; name=:olo)
    @. D = A + B
    s5 = sprint(show, MIME("text/plain"), D)
    @test occursin("olo", s5)

    # Test zero dim show
    D = DimArray([x for x in 1], (); name=:zero)
    sz = sprint(show, MIME("text/plain"), D)
    @test occursin("zero", sz)

    # Test vector show
    D = DimArray(ones(length(t)), t; name=:vec)
    sv = sprint(show, MIME("text/plain"), D)
    @test occursin("1", sv)
    @test occursin("vec", sv)

    # Test matrix show
    D = ones()
    D = DimArray(ones(X(5), Y(5)); name=:vec)
    sv = sprint(show, MIME("text/plain"), D)
    @test occursin("1", sv)
end

@testset "stack" begin
    st = DimStack(A; metadata=Dict(:x => 1))
    sv = sprint(show, MIME("text/plain"), st)
    @test occursin("DimStack", sv)
    @test occursin("Lon", sv)
    @test occursin("Lat", sv)
    @test occursin("Ti", sv)
    @test occursin("Z", sv)
    @test occursin("test", sv)
    @test occursin(":x => 1", sv)
end
