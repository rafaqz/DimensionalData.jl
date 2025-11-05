using DimensionalData, Test

using DimensionalData: Name, NoName

@testset "Name" begin
    @test Name(:x) === Name{:x}()
    @test Symbol(Name(:x)) === :x
    @test string(Name(:x)) === "x"
    @test Name(Name(:x)) === Name(:x)
end

@testset "NoName" begin
    @test Symbol(NoName()) === Symbol("")
    @test string(NoName()) === ""
    @test Name(NoName()) === NoName()
end

