using DimensionalData, Test, Unitful
using DimensionalData: identify

@testset "identify IndexMode" begin
   @testset "identify Categorical from Auto" begin
        @test identify(Auto(), X, [:a, :b]) == Categorical(Unordered())
        @test identify(Auto(), X, ["a", "b"]) == Categorical(Unordered())
        @test identify(Auto(), X, ['b', 'a']) == Categorical(Unordered())
        @test identify(Auto(Ordered(index=ReverseIndex())), X, ['b', 'a']) == 
            Categorical(Ordered(index=ReverseIndex()))
    end

    @testset "identify Categorical" begin
        @test identify(Categorical(), X, [1, 2]) == Categorical(Unordered())
    end

    @testset "identify Sampled Order, Span and Sampling from Auto" begin
        @testset "identify vectors" begin
            @test identify(Auto(), X, [1, 2, 3, 4, 5]) ==
                Sampled(Ordered(), Irregular(), Points())
            @test identify(Auto(), X, [5, 4, 3, 2, 1]) ==
                Sampled(Ordered(index=ReverseIndex()), Irregular(), Points())
            @test identify(Auto(), X, [500, 3, 7, 99, 1]) ==
                Sampled(Unordered(), Irregular(), Points())
            # test something random that will break `issorted`
            @test identify(Auto(), X, [X(), Y(), Z()]) ==
                Sampled(Unordered(), Irregular(), Points())
        end
        @testset "identify range" begin
            @test identify(Auto(), X, 1:2:10) ==
                Sampled(Ordered(), Regular(2), Points())
            @test identify(Auto(), X, 10:-2:1) ==
                Sampled(Ordered(ReverseIndex(), ForwardArray(), ForwardRelation()), 
                        Regular(-2), Points())
        end
    end

    @testset "identify Sampled" begin
        @testset "identify Locus" begin
            @test identify(Sampled(sampling=Intervals()), X, 1:2:9) ==
                Sampled(Ordered(), Regular(2), Intervals(Center()))
            @test identify(Sampled(sampling=Intervals()), Ti, 1:2:9) ==
                Sampled(Ordered(), Regular(2), Intervals(Start()))
        end
        @testset "identify Regular span step" begin
            @test identify(Sampled(span=Regular()), X, 1:2:9) ==
                Sampled(Ordered(), Regular(2), Points())
            @test identify(Sampled(span=Regular()), X, 9:-2:1) ==
                Sampled(Ordered(index=ReverseIndex()), Regular(-2), Points())
            @test identify(Sampled(span=Regular(1)), X, [1, 2, 3]) ==
                Sampled(Ordered(), Regular(1), Points())
            @test_throws ArgumentError identify(Sampled(span=Regular()), X, [1, 2, 3])
        end
        @testset "identify Irregular span step" begin
            # TODO clarify this. For `Points` the bounds in
            # Irregular aren't used so `nothing` is a reasonable value.
            # for `Intervals` they are used, and will return `(nothing, nothing)`
            # from `bounds`. After slicing the `bounds` will be correct, so 
            # it may be fine to leave this behaviour up to the user.
            @test identify(Sampled(span=Irregular()), X, [2, 4, 8]) ==
                Sampled(Ordered(), Irregular((nothing, nothing)), Points())
        end
    end

end
