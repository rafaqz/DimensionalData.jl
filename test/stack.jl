using DimensionalData, Test, LinearAlgebra, Statistics, ConstructionBase

using DimensionalData: data
using DimensionalData: Sampled, Categorical, AutoLookup, NoLookup, Transformed,
    Regular, Irregular, Points, Intervals, Start, Center, End,
    Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered, layers

A = [1.0 2.0 3.0;
     4.0 5.0 6.0]
x, y, z = X([:a, :b]), Y(10.0:10.0:30.0; metadata=Dict()), Z()
dimz = x, y
da1 = DimArray(A, (x, y); name=:one, metadata=Metadata())
da2 = DimArray(Float32.(2A), (x, y); name=:two)
da3 = DimArray(Int.(3A), (x, y); name=:three)
da4 = DimArray(cat(4A, 5A, 6A, 7A; dims=3), (x, y, z); name=:extradim)

s = DimStack((da1, da2, da3))
mixed = DimStack(da1, da2, da4)

@testset "constructors" begin
    @test DimStack((one=A, two=2A, three=3A), dimz) == s
    @test DimStack(da1, da2, da3) == s
    @test DimStack((one=da1, two=da2, three=da3), dimz) == s
end

@testset "ConstructionBase" begin
    s1 = ConstructionBase.setproperties(s, (one=da1, two=da2, three=da1))
    @test s1.three == s.one
    @test s1.two == s.two
    @test s1.one == s.one
end

@testset "interface methods" begin
    @test dims(s) == dims(da1)
    @test dims(s, X) == x
    @test refdims(s) === ()
    @test metadata(mixed) == NoMetadata()
    @test metadata(mixed, (X, Y, Z)) == (NoMetadata(), Dict(), NoMetadata())
end

@testset "symbol key indexing" begin
    da1x = s[:one]
    @test parent(da1x) === parent(da1)
    @test typeof(da1x) === typeof(da1)
end

@testset "getproperty" begin
    @test propertynames(s) == (:one, :two, :three)
    @test hasproperty(s, :one)
    da1x = s.one
    @test parent(da1x) === parent(da1)
    @test typeof(da1x) === typeof(da1)
end

@testset "broadcast over layer" begin
    s[:one] .*= 2
    s[:one] ./= 2
end

@testset "low level base methods" begin
    @test keys(data(s)) == (:one, :two, :three)
    @test keys(data(mixed)) == (:one, :two, :extradim)
    @test eltype(mixed) === (one=Float64, two=Float32, extradim=Float64)
    @test haskey(s, :one) == true
    @test haskey(s, :zero) == false
    @test length(s) == 3 # length is as for NamedTuple
    @test size(mixed) === (2, 3, 4) # size is as for Array
    @test size(mixed, Y) === 3
    @test size(mixed, 3) === 4
    @test axes(mixed) == (Base.OneTo(2), Base.OneTo(3), Base.OneTo(4))
    @test eltype(axes(mixed)) <: Dimensions.DimUnitRange
    @test dims(axes(mixed)) == dims(mixed)
    @test axes(mixed, X) == Base.OneTo(2)
    @test dims(axes(mixed, X)) == dims(mixed, X)
    @test axes(mixed, 2) == Base.OneTo(3)
    @test dims(axes(mixed, 2)) == dims(mixed, 2)
    @test first(s) == da1 # first/last are for the NamedTuple
    @test last(s) == da3
    @test NamedTuple(s) == (one=da1, two=da2, three=da3)
end

@testset "similar" begin
    @test all(map(similar(mixed), mixed) do s, m
        dims(s) == dims(m) && dims(s) !== dims(m) && eltype(s) === eltype(m)
    end)
    @test all(map(==(Int), eltype(similar(s, Int))))
    st2 = similar(mixed, Bool, x, y)
    @test dims(st2) == (x, y)
    @test dims(st2) !== (x, y)
    @test dims(st2[:one]) == (x, y)
    @test dims(st2[:one]) !== (x, y)
    @test all(map(==(Bool), eltype(st2)))
end

@testset "merge" begin
    @test layers(s) === (; s...)
    @test layers(s) === (; one=da1, s[(:two,)]..., (three=da3,)...)
    @test layers(s) === (; (one=da1,)..., two=da2, s[(:three,)]...)
    @test typeof(s) === typeof(merge(s[(:one,:two)], (three=da3,)))
    @test s === merge(s[(:one,)], (two=da2, three=da3))
    @test merge(mixed) === mixed
    @test keys(merge(mixed, s)) == (:one, :two, :extradim, :three)
    @test keys(merge(s, mixed)) == (:one, :two, :three, :extradim)
    @test keys(merge(s, (:new=>da4,))) == (:one, :two, :three, :new)
end

@testset "setindex" begin
    s12 = DimStack((da1, da2))
    @test s === Base.setindex(s12, da3, :three)
    s423 = DimStack((one=da4, two=da2, three=da3))
    @test s === Base.setindex(s423, da1, :one)
end

@testset "copy and friends" begin
    sc = copy(s)
    @test sc == s
    @test dims(sc) == dims(s)
    @test metadata(sc) == metadata(s)
    sdc = deepcopy(s)
    @test sdc == s
    @test dims(sdc) == dims(s)
    @test metadata(sdc) == metadata(s)
    s2 = zero(s)
    @test s2[:one] == [0.0 0.0 0.0; 0.0 0.0 0.0]
    # This should do nothing
    sr = read(s)
    @test sr === s
end

@testset "copy!" begin
    dest_A = zero(da1)
    @test dest_A !== da1
    copy!(dest_A, s[:one])
    @test dest_A == s[:one]
    dest_s = zero(s)
    @test dest_s !== s
    copy!(dest_s, s)
    @test dest_s == s
end

@testset "cat" begin
    x2 = X([:c, :d])
    da1 = DimArray(A, (x2, y); name=:one, metadata=Metadata())
    da2 = DimArray(Float32.(2A), (x2, y); name=:two)
    da3 = DimArray(Int.(3A), (x2, y); name=:three)
    s2 = DimStack((da1, da2, da3))

    s_cat = cat(s, s2; dims=X())
    @test s_cat[:one] == cat(parent(s[:one]), parent(s2[:one]); dims=1)
end

@testset "eachslice" begin
    xs = (X, :X, x, 1)
    xs2 = (xs..., map(tuple, xs)...)
    ys = (Y, :Y, y, 2)
    ys2 = (ys..., map(tuple, ys)...)
    zs = (Z, :Z, z, 3)
    zs2 = (zs..., map(tuple, zs)...)

    @testset "type-inferrable due to const-propagation" begin
        f(x, dims) = eachslice(x; dims=dims)
        @testset for dims in (x, y, z, (x,), (y,), (z,), (x, y), (y, z), (x, y, z))
            @inferred f(mixed, dims)
        end
    end

    @testset "error thrown if dimensions invalid" begin
        @test_throws DimensionMismatch eachslice(mixed; dims=4)
        @test_throws DimensionMismatch eachslice(mixed; dims=Ti)
        @test_throws DimensionMismatch eachslice(mixed; dims=Dim{:x})
    end

    @testset "slice over X dimension" begin
        @testset for dims in xs2
            @test eachslice(mixed; dims=dims) isa Base.Generator
            slices = map(identity, eachslice(mixed; dims=dims))
            @test slices isa DimArray{<:DimStack,1}
            slices2 = map(l -> view(mixed, X(At(l))), lookup(Dimensions.dims(mixed, x)))
            @test slices == slices2
        end
    end

    @testset "slice over Y dimension" begin
        @testset for dims in ys2
            @test eachslice(mixed; dims=dims) isa Base.Generator
            slices = map(identity, eachslice(mixed; dims=dims))
            @test slices isa DimArray{<:DimStack,1}
            slices2 = map(l -> view(mixed, Y(At(l))), lookup(y))
            @test slices == slices2
        end
    end

    @testset "slice over Z dimension" begin
        @testset for dims in zs2
            @test eachslice(mixed; dims=dims) isa Base.Generator
            slices = map(identity, eachslice(mixed; dims=dims))
            @test slices isa DimArray{<:DimStack,1}
            slices2 = map(l -> view(mixed, Z(l)), axes(mixed, z))
            @test slices == slices2
        end
    end

    @testset "slice over combinations of Z and Y dimensions" begin
        @testset for dims in Iterators.product(zs, ys)
            # mixtures of integers and dimensions are not supported
            rem(sum(d -> isa(d, Int), dims), length(dims)) == 0 || continue
            @test eachslice(mixed; dims=dims) isa Base.Generator
            slices = map(identity, eachslice(mixed; dims=dims))
            @test slices isa DimArray{<:DimStack,2}
            slices2 = map(
                l -> view(mixed, Z(l[1]), Y(l[2])),
                Iterators.product(axes(mixed, z), axes(mixed, y)),
            )
            @test slices == slices2
        end
    end
end

@testset "map" begin
    @test values(map(a -> a .* 2, s)) == values(DimStack(2da1, 2da2, 2da3))
    @test dims(map(a -> a .* 2, s)) == dims(DimStack(2da1, 2da2, 2da3))
    @test map(a -> a[1], s) == (one=1.0, two=2.0, three=3.0)
    @test values(map(a -> a .* 2, s)) == values(DimStack(2da1, 2da2, 2da3))
    @test map(+, s, s, s) == map(a -> a .* 3, s)
    @test_throws ArgumentError map(+, s, mixed)
    @test map((s, a) -> s => a[1], (one="one", two="two", three="three"), s) == (one="one" => 1.0, two="two" => 2.0, three="three" => 3.0)
end

@testset "methods with no arguments" begin
    @testset "permuting methods" begin
        @test data(permutedims(s)) == 
            (one=[1.0 4.0; 2.0 5.0; 3.0 6.0],
             two=[2.0 8.0; 4.0 10.0; 6.0 12.0],
             three=[3.0 12.0; 6.0 15.0; 9.0 18.0])
        @test adjoint(s) == DimStack(adjoint(da1), adjoint(da2), adjoint(da3))
        @test transpose(s) == DimStack(transpose(da1), transpose(da2), transpose(da3))
        @test Transpose(s) == DimStack(Transpose(da1), Transpose(da2), Transpose(da3))
        @test data(rotl90(s)) ==
            (one=[3.0 6.0;  2.0 5.0;  1.0 4.0],
             two=[6.0f0 12.0f0; 4.0f0 10.0f0; 2.0f0 8.0],
           three=[9 18; 6 15; 3 12])
        @test rotl90(s) == DimStack(rotl90(da1), rotl90(da2), rotl90(da3))
        @test rotr90(s) == DimStack(rotr90(da1), rotr90(da2), rotr90(da3))
        @test rot180(s) == DimStack(rot180(da1), rot180(da2), rot180(da3))
    end

    @test cor(s) isa DimStack
    @test cov(s) isa DimStack

    @test inv(s[1:2, 1:2]) isa DimStack

    @testset "reducing methods" begin
        @test sum(s) === (one=21.0, two=42.0f0, three=63)
        @test prod(s) === (one=720.0, two=46080.0f0, three=524880)
        @test Base.minimum(s) === (one=1.0, two=2.0f0, three=3)
        @test maximum(s) === (one=6.0, two=12.0f0, three=18)
        @test extrema(s) === (one=(1.0, 6.0), two=(2.0f0, 12.0f0), three=(3, 18))
        @test mean(s) === (one=3.5, two=7.0f0, three=10.5)
        @test std(s) === (one=1.8708286933869707, two=3.7416575f0, three=5.612486080160912)
        @test var(s) === (one=3.5, two=14.0f0, three=31.5)
        @test median(s) === (one=3.5, two=7.0f0, three=10.5)
    end
end

@testset "methods with a dims keyword argument" begin
    @testset "reducing methods" begin
        sum_ = sum(s; dims=X)
        @test sum_  == DimStack(sum(da1; dims=X), sum(da2; dims=X), sum(da3; dims=X))
        @test dims(sum_) == (X(Categorical([:combined]; order=ForwardOrdered())), dims(da1, Y))
        @test prod(s; dims=X) == DimStack(prod(da1; dims=X), prod(da2; dims=X), prod(da3; dims=X))
        @test dims(maximum(s; dims=X)) == 
            dims(DimStack(maximum(da1; dims=X), maximum(da2; dims=X), maximum(da3; dims=X)))
        @test minimum(s; dims=X) == DimStack(minimum(da1; dims=X), minimum(da2; dims=X), minimum(da3; dims=X))
        @test mean(s; dims=X()) == DimStack(mean(da1; dims=X), mean(da2; dims=X), mean(da3; dims=X))
        @test std(s; dims=X) == DimStack(std(da1; dims=X), std(da2; dims=X), std(da3; dims=X))
        @test var(s; dims=X) == DimStack(var(da1; dims=X), var(da2; dims=X), var(da3; dims=X))
        @test median(s; dims=X) == DimStack(median(da1; dims=X), median(da2; dims=X), median(da3; dims=X))
        @test mean(mixed; dims=X) == DimStack((mean(da1; dims=X), mean(da2; dims=X), mean(da4; dims=X)))
        @test mean(mixed; dims=Y) == DimStack((mean(da1; dims=Y), mean(da2; dims=Y), mean(da4; dims=Y)))
        @test mean(mixed; dims=Z) == DimStack((da1, da2, mean(da4; dims=Z)))
    end

    @testset "dim duplicating methods" begin
        @test cor(s; dims=X) isa DimStack
        @test cov(s; dims=X) isa DimStack
    end

    @testset "dim dropping methods" begin
        @test DimensionalData.layers(dropdims(s[X([1])]; dims=X)) == 
            (one=DimArray([1.0, 2.0, 3.0], dims(da1, Y)), 
             two=DimArray([2.0, 4.0, 6.0], dims(da1, Y)),
             three=DimArray([3.0, 6.0, 9.0], dims(da1, Y)))
    end

end

@testset "permuting methods with an argument" begin
    @test permutedims(s, (Y, X)) == 
        DimStack(permutedims(da1, (Y, X)), permutedims(da2, (Y, X)), permutedims(da3, (Y, X)))
    @test PermutedDimsArray(s, (Y(), X())) ==
        DimStack(PermutedDimsArray(da1, (Y, X)), PermutedDimsArray(da2, (Y, X)), PermutedDimsArray(da3, (Y, X)))
    rot = rotl90(s, 1)
    @test rot isa DimStack
    @test typeof(data(rot)) == NamedTuple{(:one, :two, :three),Tuple{Matrix{Float64},Matrix{Float32},Matrix{Int64}}}
    @test data(rot) ==
        (one=[3.0 6.0;  2.0 5.0;  1.0 4.0],
         two=[6.0f0 12.0f0; 4.0f0 10.0f0; 2.0f0 8.0f0],
       three=[9 18; 6 15; 3 12])
    @test rot[:one][X(At(:a)), Y(At(10.0))] == da1[X(At(:a)), Y(At(10.0))]
    @test rotr90(s, 2) == DimStack(rotr90(da1, 2), rotr90(da2, 2), rotr90(da3, 2))
    @test rot180(s, 1) == DimStack(rot180(da1, 1), rot180(da2, 1), rot180(da3, 1))
end

@testset "reducing methods that take a function" begin
    f = x -> 2x
    @test data(minimum(f, s; dims=X)) == 
        (one=[2.0 4.0 6.0], two=[4.0 8.0 12.0], three=[6.0 12.0 18.0])
    @test data(mean(x -> 2x, s; dims=X())) ==
        (one=mean(2da1; dims=X) , two=mean(2da2; dims=X), three=mean(2da3; dims=X))
    @test mean(f, s; dims=X) == DimStack(mean(f, da1; dims=X), mean(f, da2; dims=X), mean(f, da3; dims=X))
    @test reduce(+, s; dims=X) == DimStack(reduce(+, da1; dims=X), reduce(+, da2; dims=X), reduce(+, da3; dims=X))
    @test sum(f, s; dims=X) == DimStack(sum(f, da1; dims=X), sum(f, da2; dims=X), sum(f, da3; dims=X))
    @test prod(f, s; dims=X) == DimStack(prod(f, da1; dims=X), prod(f, da2; dims=X), prod(f, da3; dims=X))
    @test maximum(f, s; dims=X) == DimStack(maximum(f, da1; dims=X), maximum(f, da2; dims=X), maximum(f, da3; dims=X))
    @test extrema(f, s; dims=X) == DimStack(extrema(f, da1; dims=X), extrema(f, da2; dims=X), extrema(f, da3; dims=X))
    @test reduce(+, s) == (one=21.0, two=42.0, three=63.0)
    @test sum(f, s) == (one=42.0, two=84.0, three=126.0)
    @test prod(f, s) == (one=46080., two=2.94912e6, three=3.359232e7)
    @test Base.minimum(f, s) == (one=2.0, two=4.0, three=6.0)
    @test maximum(f, s) == (one=12.0, two=24.0, three=36.0)
    @test extrema(f, s) == (one=(2.0, 12.0), two=(4.0, 24.0), three=(6.0, 36.0))
    @test mean(f, s) == (one=7.0, two=14.0, three=21)
end
