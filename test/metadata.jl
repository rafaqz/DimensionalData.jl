using DimensionalData, Test

@testset "Metadata" begin
    nt = (a="test1", units="km")
    d = (:a=>"test1", :units=>"km")
    @test val(Metadata(nt)) isa NamedTuple
    @test val(Metadata(d)) isa Dict
    @test val(Metadata()) isa Dict
    @test Metadata(nt) == Metadata(; nt...)
    @test Metadata(d) == Metadata(d...) == Metadata(Dict(d))
    dm = Metadata(d)
    dm[:c] = "added metadata"
    @test dm[:c] == "added metadata"
    @test units(nothing) === nothing
    @test units(NoMetadata()) === nothing

    for md in (Metadata(; nt...), Metadata{:Test}(; nt...), Dict(pairs(nt)))
        @test units(md) == "km"
        @test length(md) == 2
        @test haskey(md, :a)
        @test haskey(md, :c) == false 
        @test get(md, :a, nothing) == "test1" 
        @test md[:a] == "test1" 
        @test md[:units] == "km" 
        if md isa Dict || val(md) isa Dict
            @test [x for x in md] == [:a=>"test1", :units=>"km"]
            @test all(keys(md) .== [:a, :units])
            @test eltype(md) == Pair{Symbol,String}
            @test iterate(md) == (:a => "test1", 2)
            @test iterate(md, 2) == (:units => "km", 3)
        else
            @test [x for x in md] == ["test1", "km"]
            @test keys(md) == (:a, :units)
            @test eltype(md) == String
            @test iterate(md) == ("test1", 2)
            @test iterate(md, 2) == ("km", 3)
        end
        @test iterate(md, 3) == nothing
        @test Base.IteratorSize(md) == Base.HasLength()
        @test Base.IteratorEltype(md) == Base.HasEltype()
    end

    @test_throws ArgumentError Metadata{:Test}(:a => "1"; units="km")
end

@testset "NoMetadata" begin
    @test val(NoMetadata()) == NamedTuple()
    @test keys(NoMetadata()) == ()
    @test haskey(NoMetadata(), :a) == false
    @test get(NoMetadata(), :a, :x) == :x
    @test length(NoMetadata()) == 0
    @test [x for x in NoMetadata()] == []
end

@testset "metadatadict" begin
    @test DimensionalData.metadatadict(Dict("a"=>"A", "b"=>"B")) == Dict(:a=>"A", :b=>"B")
end
