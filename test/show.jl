using DimensionalData, Test, Dates

# define dims with both long name and Type name
@dim Lon "Longitude"
@dim Lat "Latitude"

@testset "prettyprinting" begin

    timespan = DateTime(2001):Month(1):DateTime(2001,12)
    t = Ti(timespan)
    x = Lon(Vector(0.5:10.0:359.5))
    y = Lat(Vector{Union{Float32, Missing}}(-89.5:10.0:89.5))
    z = Z('a':'d')
    d = (x, y, z, t)

    A = DimArray(rand(length.(d)...), d)
    a = DimArray(rand(length(x), length(y)), (x,y))
    B = DimArray(rand(length(x)), (x,))

    s1 = sprint(show, A)
    s2 = sprint(show, x)
    s3 = sprint(show, MIME("text/plain"), x)

    @test occursin("DimArray", s1)
    for s in (s1, s2, s3)
        @test occursin("Lon", s)
        @test occursin("Longitude", s)
    end

    # Test again but now with labelled array A
    A = DimArray(rand(length.(d)...), d, :test)
    s1 = sprint(show, A)
    @test occursin("test", s1)

    # Does it propagate after indexing?
    F = A[Ti(1:4)]
    s2 = sprint(show, F)
    @test occursin("test", s2)

    # Does it propagate after e.g. reducing operations?
    G = sum(A; dims = Ti)
    s3 = sprint(show, G)
    @test occursin("test", s3)

    # It should NOT propagate after binary operations
    B = DimArray(rand(length.(d)...), d, :test2)
    C = A .+ B
    s4 = sprint(show, C)
    @test !occursin("test", s4)

    # Test that broadcasted setindex! retains name
    D = DimArray(ones(length.(d)...), d, :olo)
    @. D = A + B
    s5 = sprint(show, D)
    @test occursin("olo", s5)
end
