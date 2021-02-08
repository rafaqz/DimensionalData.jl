using DimensionalData, Test

@testset "Name" begin
    @test Name(:x) === Name{:x}()
    @test Symbol(Name(:x)) === :x
    @test string(Name(:x)) === "x"
    @test Name(Name(:x)) === Name(:x)
    @test convert(String, Name(:x)) === "x"
end

@testset "NoName" begin
    @test Symbol(NoName()) === Symbol("")
    @test string(NoName()) === ""
    @test Name(NoName()) === NoName()
    @test convert(String, NoName()) === ""
end

