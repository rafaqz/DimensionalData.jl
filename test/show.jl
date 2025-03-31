using DimensionalData, Test, Dates
using DimensionalData.Lookups, DimensionalData.Dimensions
using DimensionalData: LazyLabelledPrintMatrix, ShowWith, showrowlabel, showcollabel, showarrows

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

@testset "LazyLabelledPrintMatrix" begin
    A = LazyLabelledPrintMatrix(zeros(X(5)))
    @test size(A) == (5, 1)
    @test collect(A) == [0.0 0.0 0.0 0.0 0.0]'
    A = LazyLabelledPrintMatrix(zeros(X(10:10:50)) .+ (1.0:1:5.0))
    @test size(A) == (5, 2)
    @test collect(A) == [
        showrowlabel(10) 1.0
        showrowlabel(20) 2.0
        showrowlabel(30) 3.0
        showrowlabel(40) 4.0
        showrowlabel(50) 5.0
    ]
    A = LazyLabelledPrintMatrix(zeros(X(5), Y(10:10:30)))
    @test size(A) == (6, 3)
    @test collect(A) == [
         showcollabel(10) showcollabel(20) showcollabel(30)
         0.0              0.0              0.0
         0.0              0.0              0.0
         0.0              0.0              0.0
         0.0              0.0              0.0
         0.0              0.0              0.0
    ]
    A = LazyLabelledPrintMatrix(zeros(X(1:5), Y(3)))
    @test size(A) == (5, 4)
    @test collect(A) == [
         showrowlabel(1) 0.0              0.0              0.0
         showrowlabel(2) 0.0              0.0              0.0
         showrowlabel(3) 0.0              0.0              0.0
         showrowlabel(4) 0.0              0.0              0.0
         showrowlabel(5) 0.0              0.0              0.0
    ]
    A = LazyLabelledPrintMatrix(zeros(X(1:5), Y(10:10:30)))
    @test size(A) == (6, 4)
    @test collect(A) == [
         showarrows()    showcollabel(10) showcollabel(20) showcollabel(30)
         showrowlabel(1) 0.0              0.0              0.0
         showrowlabel(2) 0.0              0.0              0.0
         showrowlabel(3) 0.0              0.0              0.0
         showrowlabel(4) 0.0              0.0              0.0
         showrowlabel(5) 0.0              0.0              0.0
    ]
end

@testset "dims" begin
    sv = sprint(show, MIME("text/plain"), X())
    @test occursin("X", sv)
    sv = sprint(show, MIME("text/plain"), X(fill(0)))
    @test occursin("X", sv)
    sv = sprint(show, MIME("text/plain"), X(1:5))
    @test occursin("X", sv)
end

@testset "show lookups" begin
    cl = Categorical([:a, :b]; order=Unordered())
    sv = sprint(show, MIME("text/plain"), cl)
    @test occursin("Categorical", sv)
    @test occursin("Unordered", sv)
    @test occursin("wrapping:", sv)
    @test occursin(sprint(show, MIME("text/plain"), parent(cl)), sv)
    sl = Sampled(1:2; order=ForwardOrdered(), span=Regular(), sampling=Points())
    sv = sprint(show, MIME("text/plain"), sl)
    @test occursin("Sampled", sv)
    @test occursin("Ordered", sv)
    @test occursin("Regular", sv)
    @test occursin("Points", sv)
    @test occursin("wrapping:", sv)
    @test occursin(sprint(show, MIME("text/plain"), parent(sl)), sv)
    sv = sprint(show, MIME("text/plain"), NoLookup())
    @test occursin("NoLookup", sv)
    # Lookup tuple
    ls = lookup(ds)
    sv = sprint(show, MIME("text/plain"), ls)
    @test occursin("Categorical", sv)
    @test occursin("Sampled", sv)
    sv = sprint(show, MIME("text/plain"), Transformed(identity))
    @test occursin("Transformed", sv)
    nds = (X(NoLookup(Base.OneTo(10))), Y(NoLookup(Base.OneTo(5))))
    sv = sprint(show, MIME("text/plain"), nds)
    @test sv == "(↓ X, → Y)"
end
@testset "BeginEnd" begin
    lplus = Begin+6
    slp = sprint(show, MIME("text/plain"), lplus)
    @test slp == "(Begin+6)"
    lplusr = 6+Begin
    slpr = sprint(show, MIME("text/plain"), lplusr)
    @test slpr == "(6+Begin)"
    ldiv = div(End,2)
    sld = sprint(show, MIME("text/plain"), ldiv)
    @test sld == "(End÷2)"
    ldivnest = (End÷2) +1
    sldn = sprint(show, MIME("text/plain"), ldivnest)
    @test sldn == "((End÷2)+1)"
    berange = Begin:(End-1)
    sber = sprint(show, MIME("text/plain"), berange)
    @test sber == "Begin:(End-1)"
    bserange = Begin:3:End
    sbser = sprint(show, MIME("text/plain"), bserange)
    @test sbser == "Begin:3:End"
    lmax = max(3,Begin)
    slmax = sprint(show, MIME("text/plain"), lmax)
    @test slmax == "max(3, Begin)"
    lmax = max(Begin,3)
    slmax = sprint(show, MIME("text/plain"), lmax)
    @test slmax == "max(Begin, 3)"
    lmin = min(3,Begin)
    slmin = sprint(show, MIME("text/plain"), lmin)
    @test slmin == "min(3, Begin)"
    lmin = min(Begin,3)
    slmin = sprint(show, MIME("text/plain"), lmin)
    @test slmin == "min(Begin, 3)"
end

@testset "arrays" begin
    d, str = Lat(), "Lat"
    for (d, str) in ((Ti(), "Ti"), (Lat(), "Lat"), (Lon(), "Lon"), (:n, "n"), (Z(), "Z")) 
        s1 = sprint(show, MIME("text/plain"), A)
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

    # Test higher-dimensional data.
    D = DimArray(rand(2, 2, 2), (x = [(1, 1), (1, 2)], y = ['a', 'b'], z = [2, "b"]))
    sv = sprint(show, MIME("text/plain"), D)
    @test occursin('a', sv) && occursin('b', sv)
    @test occursin("(1, 1)", sv) && occursin("(1, 2)", sv)
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
