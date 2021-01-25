using DimensionalData, Test, Unitful
using DimensionalData: identify

struct Unsortable 
    val::Int
end

@testset "identify IndexMode" begin
   @testset "identify Categorical from AutoMode" begin
        @test identify(AutoMode(), X, [:a, :b]) == Categorical(Unordered())
        @test identify(AutoMode(), X, ["a", "b"]) == Categorical(Unordered())
        @test identify(AutoMode(), X, ['b', 'a']) == Categorical(Unordered())
        @test identify(AutoMode(Ordered(index=ReverseIndex())), X, ['b', 'a']) == 
            Categorical(Ordered(index=ReverseIndex()))
        # Mixed types are categorical
        @test identify(AutoMode(Ordered(index=ReverseIndex())), X, ['b', 2]) == 
            Categorical(Unordered())
        @test identify(AutoMode(Ordered(index=ReverseIndex())), X, ['b', 2]) == 
            Categorical(Unordered())
    end

    @testset "identify Categorical order" begin
        @test identify(Categorical(Ordered()), X, [1, 2]) == Categorical(Ordered())
        @test identify(Categorical(), X, [1, 2]) == Categorical(Unordered())
    end

    @testset "identify Sampled Order, Span and Sampling from AutoMode" begin
        @testset "identify vectors" begin
            @test identify(AutoMode(), X, [1, 2, 3, 4, 5]) ==
                Sampled(Ordered(), Irregular(), Points())
            @test identify(AutoMode(), X, [5, 4, 3, 2, 1]) ==
                Sampled(Ordered(index=ReverseIndex()), Irregular(), Points())
            @test identify(AutoMode(), X, [500, 3, 7, 99, 1]) ==
                Sampled(Unordered(), Irregular(), Points())
        end
        @testset "identify range" begin
            @test identify(AutoMode(), X, 1:2:10) == Sampled(Ordered(), Regular(2), Points())
            @test identify(AutoMode(), X, 10:-2:1) ==
                Sampled(Ordered(ReverseIndex(), ForwardArray(), ForwardRelation()), 
                        Regular(-2), Points())
        end
    end

    @testset "identify Sampled" begin
        @testset "identify Locus" begin
            @test identify(Sampled(sampling=Intervals()), X, 1:2:9) ==
                Sampled(Ordered(), Regular(2), Intervals(Center()))
            @test identify(Sampled(span=Regular(), sampling=Intervals()), Ti, 1:2:9) ==
                Sampled(Ordered(), Regular(2), Intervals(Start()))
        end
        @testset "identify Regular span step" begin
            @test identify(Regular(), X, 1:2:9) == Regular(2)
            @test identify(Sampled(span=Regular()), X, 1:2:9) ==
                Sampled(Ordered(), Regular(2), Points())
            @test identify(Sampled(span=Regular()), X, 9:-2:1) ==
                Sampled(Ordered(index=ReverseIndex()), Regular(-2), Points())
            @test identify(Sampled(span=Regular(1)), X, [1, 2, 3]) ==
                Sampled(Ordered(), Regular(1), Points())
            @test identify(Sampled(span=Irregular()), X, [1, 2, 3]) ==
                Sampled(Ordered(), Irregular(nothing, nothing), Points())
            @test_throws ArgumentError identify(Regular(), X, Val((1, 2, 3))) 
            @test_throws ArgumentError identify(Regular(2.0), X, 1:3) 
            @test_throws ArgumentError identify(Sampled(span=Regular()), X, [1, 2, 3])
            @test_throws ArgumentError identify(Sampled(span=Regular(2)), X, 1:4)
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

    @testset "An unsortable index is Unordered" begin
        @test identify(AutoMode(), X, [Unsortable(1), Unsortable(2)]) == 
            Sampled(Unordered(), Irregular(), Points())
    end

end
