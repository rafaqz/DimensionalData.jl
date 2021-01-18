using DimensionalData, Test

@testset "Metadata" begin
    nt = (a="test1", b="test2")
    d = (:a=>"test1", :b=>"test2")
    @test val(DimMetadata(nt)) isa NamedTuple
    @test val(DimMetadata(d)) isa Dict
    @test val(DimMetadata()) isa Dict
    @test DimMetadata(nt) == DimMetadata(; nt...)
    @test DimMetadata(d) == DimMetadata(d...) == DimMetadata(Dict(d))

    for md in (DimMetadata(; nt...), ArrayMetadata(; nt...), StackMetadata(; nt...),
               DimMetadata(d...), ArrayMetadata(d...), StackMetadata(d...))
        @test length(md) == 2
        @test haskey(md, :a)
        @test haskey(md, :c) == false 
        @test get(md, :a, nothing) == "test1" 
        @test md[:a] == "test1" 
        @test md[:b] == "test2" 
        if val(md) isa Dict
            @test [x for x in md] == [:a=>"test1", :b=>"test2"]
            @test all(keys(md) .== [:a, :b])
            @test eltype(md) == Pair{Symbol,String}
        else
            @test [x for x in md] == ["test1", "test2"]
            @test keys(md) == (:a, :b)
            @test eltype(md) == String
        end
    end
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
