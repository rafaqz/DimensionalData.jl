using DimensionalData, Test

@testset "Name" begin
    @test Name(:x) == Name{:x}()
    @test Symbol(Name(:x)) == :x
    @test string(Name(:x)) == "x"
end

@testset "NoName" begin
    @test Symbol(NoName()) == Symbol("")
    @test string(NoName()) == ""
end

