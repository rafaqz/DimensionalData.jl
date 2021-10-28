using DimensionalData, Test, Unitful
using DimensionalData: format, _format
using Base: OneTo

using DimensionalData: Sampled, Categorical, AutoLookup, NoLookup, Transformed,
    Regular, Irregular, Points, Intervals, Start, Center, End,
    Metadata, NoMetadata, ForwardOrdered, ReverseOrdered, Unordered

struct Unsortable
    val::Int
end

@testset "format LookupArray" begin
   @testset "format Categorical from AutoLookup" begin
        A = [:a, :b]
        @test format(AutoLookup(A), X, OneTo(2)) === Categorical(A, ForwardOrdered(), NoMetadata())
        A = [:a, :c, :b]
        @test format(AutoLookup(A), X, OneTo(3)) === Categorical(A, Unordered(), NoMetadata())
        A = ["a", "b"]
        @test format(AutoLookup(A), X, OneTo(2)) === Categorical(A, ForwardOrdered(), NoMetadata())
        A = ['b', 'a']
        @test format(A, X, OneTo(2)) === Categorical(A, ReverseOrdered(), NoMetadata())
        A = ['b', 'a']
        @test format(AutoLookup(A; order=ReverseOrdered()), X, OneTo(2)) ==
            Categorical(A, ReverseOrdered(), NoMetadata())
        # Mixed types are Categorical Unordered
        A = ['b', 2]
        @test format(AutoLookup(A; order=ReverseOrdered()), X, OneTo(2)) ==
            Categorical(A; order=Unordered())
    end

    @testset "format Categorical order" begin
        A = [1, 2]
        @test format(Categorical(A, order=ForwardOrdered()), X, OneTo(2)) ===
            Categorical(A, ForwardOrdered(), NoMetadata())
        @test format(Categorical(A), X, OneTo(2)) ==
            Categorical(A, Unordered(), NoMetadata())
    end

    @testset "format Sampled Order, Span and Sampling from AutoLookup" begin
        @testset "format vectors" begin
            A = [1, 2, 3, 4, 5]
            @test format(A, X, OneTo(5)) ===
                Sampled(A, ForwardOrdered(), Irregular(nothing, nothing), Points(), NoMetadata())
            A = [5, 4, 3, 2, 1]
            @test format(A, X, OneTo(5)) ===
                Sampled(A, ReverseOrdered(), Irregular(nothing, nothing), Points(), NoMetadata())
            A = [500, 3, 7, 99, 1]
            @test format(A, X, OneTo(5)) ===
                Sampled(A, Unordered(), Irregular(nothing, nothing), Points(), NoMetadata())
        end
    end

    @testset "format Sampled" begin
        @testset "format Locus" begin
            @test format(Sampled(1:2:9; sampling=Intervals()), X, OneTo(5)) ===
                Sampled(1:2:9, ForwardOrdered(), Regular(2), Intervals(Center()), NoMetadata())
            @test format(Sampled(1:2:9; span=Regular(), sampling=Intervals()), Ti, OneTo(5)) ===
                Sampled(1:2:9, ForwardOrdered(), Regular(2), Intervals(Start()), NoMetadata())
        end
        @testset "format Regular span step" begin
            @test format(Sampled(1:2:9; span=Regular()), X, OneTo(5)) ===
                Sampled(1:2:9, ForwardOrdered(), Regular(2), Points(), NoMetadata())
            @test format(Sampled(9:-2:1; span=Regular()), X, OneTo(5)) ===
                Sampled(9:-2:1, ReverseOrdered(), Regular(-2), Points(), NoMetadata())
            A = [1, 2, 3]
            @test format(Sampled(A; span=Regular(1)), X, OneTo(3)) ===
                Sampled(A, ForwardOrdered(), Regular(1), Points(), NoMetadata())
            @test format(Sampled(A; span=Irregular()), X, OneTo(3)) ===
                Sampled(A, ForwardOrdered(), Irregular(nothing, nothing), Points(), NoMetadata())
            @test_throws ArgumentError format(X(Sampled([1, 2, 3], span=Regular())), OneTo(3))
            @test_throws ArgumentError format(X(Sampled(1:4; span=Regular(2))), OneTo(4))
        end
        @testset "format Irregular span step" begin
            # TODO clarify this. For `Points` the bounds in
            # Irregular aren't used so `nothing` is a reasonable value.
            # for `Intervals` they are used, and will return `(nothing, nothing)`
            # from `bounds`. After slicing the `bounds` will be correct, so
            # it may be fine to leave this behaviour up to the user.
            A = [2, 4, 8]
            @test format(Sampled(A; span=Irregular()), X, OneTo(3)) ===
                Sampled(A, ForwardOrdered(), Irregular((nothing, nothing)), Points(), NoMetadata())
        end
    end

    @testset "An unsortable index is Unordered" begin
        A = [Unsortable(1), Unsortable(2)]
        @test format(A, X, OneTo(2)) ===
            Sampled(A, Unordered(), Irregular(nothing, nothing), Points(), NoMetadata())
    end

end
