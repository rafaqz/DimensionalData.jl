using DimensionalData, Test, Dates, Statistics, IntervalSets

using DimensionalData.Dimensions
using DimensionalData.Lookups
const DD = DimensionalData

days = DateTime(2000):Day(1):DateTime(2000, 12, 31)
A = DimArray((1:6) * (1:366)', (X(1:0.2:2), Ti(days)))
st = DimStack((a=A, b=A, c=A[X=1]))

@testset "group eltype matches indexed values" begin
    da = rand(X(1:10), Y(1:10))
    grps = groupby(da, X => isodd)
    @test first(grps) isa eltype(grps) # false
end

@testset "groupby name is set" begin
    da = rand(X(1:10), Y(1:10))
    grps = groupby(da, X=>isodd, name="isodd")
    @test name(grps) == "isodd"
end
@testset "manual groupby comparisons" begin
    # Group by month and even/odd Y axis values
    months = DateTime(2000):Month(1):DateTime(2000, 12, 31)
    manualmeans = map(months) do m
        mean(A[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1])
    end
    @test mean.(groupby(A, Ti=>month)) == manualmeans
    combinedmeans = combine(mean, groupby(A, Ti=>month))
    @test combinedmeans isa DimArray
    @test combinedmeans == manualmeans
    manualmeans_st = map(months) do m
        mean(st[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1])
    end
    @test mean.(groupby(st, Ti=>month)) == manualmeans_st
    combinedmeans_st = combine(mean, groupby(st, Ti=>month))
    @test combinedmeans_st isa DimStack{(:a, :b, :c), @NamedTuple{a::Float64, b::Float64, c::Float64}}
    @test collect(combinedmeans_st) == manualmeans_st

    manualsums = mapreduce(hcat, months) do m
        vcat(sum(A[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1 .. 1.5]), 
             sum(A[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1.5 .. 2])
        )
    end |> permutedims
    gb_sum = sum.(groupby(A, Ti=>month, X => >(1.5)))
    @test dims(gb_sum, Ti) == Ti(Sampled([1:12...], ForwardOrdered(), Irregular((nothing, nothing)), Points(), NoMetadata()))
    @test typeof(dims(gb_sum, X)) ==
        X{Sampled{Bool, DimensionalData.HiddenVector{Bool, BitVector, Vector{Vector{Int64}}}, ForwardOrdered, Irregular{Tuple{Nothing, Nothing}}, Points, NoMetadata}}
    @test gb_sum == manualsums
    combined_sum = combine(sum, groupby(A, Ti=>month, X => >(1.5)))
    @test collect(combined_sum) == manualsums

    manualsums_st = mapreduce(hcat, months) do m
        vcat(sum(st[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1 .. 1.5]), 
             sum(st[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1.5 .. 2])
        )
    end |> permutedims
    gb_sum_st = sum.(groupby(st, Ti=>month, X => >(1.5))) 
    @test dims(gb_sum_st, Ti) == Ti(Sampled([1:12...], ForwardOrdered(), Irregular((nothing, nothing)), Points(), NoMetadata()))
    @test gb_sum_st == manualsums_st
    combined_sum_st = combine(sum, groupby(st, Ti=>month, X => >(1.5)))
    @test collect(combined_sum_st) == manualsums_st

    @test_throws ArgumentError groupby(st, Ti=>month, Y=>isodd)
end

@testset "partial reductions in combine" begin
    months = DateTime(2000):Month(1):DateTime(2000, 12, 31)
    using BenchmarkTools
    manualmeans = cat(map(months) do m
        mean(A[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1]; dims=Ti)
    end...; dims=Ti(collect(1:12)))
    combinedmeans = combine(mean, groupby(A, Ti()=>month); dims=Ti())
    @test combinedmeans == manualmeans
end

@testset "bins" begin
    seasons = DateTime(2000):Month(3):DateTime(2000, 12, 31)
    manualmeans = map(seasons) do s
        range = dayofyear(s):dayofyear(s)+daysinmonth(s)+daysinmonth(s+Month(1))+daysinmonth(s+Month(2))-1
        mean(A[Ti=range])
    end
    @test mean.(groupby(A, Ti=>Bins(month, ranges(1:3:12)))) == manualmeans
    @test mean.(groupby(A, Ti=>Bins(month, intervals(1:3:12)))) == manualmeans
    @test mean.(groupby(A, Ti=>Bins(month, 4))) == manualmeans
    @test combine(mean, groupby(A, Ti=>Bins(month, ranges(1:3:12)))) == manualmeans
    @test mean.(groupby(A, Ti=>CyclicBins(month; cycle = 12, step = 3))) == manualmeans
    @test CyclicBins(; step = 3, cycle = 12) === CyclicBins(identity; step = 3, cycle = 12)
end

@testset "dimension matching groupby" begin
    dates = DateTime(2000):Month(1):DateTime(2000, 12, 31)
    xs = 1.0:1:3.0
    B = rand(X(xs; sampling=Intervals(Start())), Ti(dates; sampling=Intervals(Start())))
    gb = groupby(A, B)
    @test size(gb) === size(B) === size(mean.(gb))
    @test parent(lookup(gb, X)) == parent(lookup(B, X)) == parent(lookup(mean.(gb), X))
    manualmeans = mapreduce(hcat, intervals(dates)) do d
        map(intervals(xs)) do x
            mean(A[X=x, Ti=d])
        end
    end
    @test isequal(collect(mean.(gb)), manualmeans)
    @test isequal(mean.(gb), manualmeans)
    @test isequal(combine(mean, gb), manualmeans)
end

@testset "broadcast_dims runs after groupby" begin
    dimlist = (
        Ti(Date("2021-12-01"):Day(1):Date("2022-12-31")),
        X(range(1, 10, length=10)),
        Y(range(1, 5, length=15)),
        Dim{:Variable}(["var1", "var2"])
    )
    data = rand(396, 10, 15, 2)
    A = DimArray(data, dimlist)
    month_length = DimArray(daysinmonth, dims(A, Ti))
    g_tempo = DimensionalData.groupby(month_length, Ti => seasons(; start=December))
    sum_days = sum.(g_tempo, dims=Ti)
    @test sum_days isa DimArray
    weights = map(./, g_tempo, sum_days)
    @test sum_days isa DimArray
    G = DimensionalData.groupby(A, Ti=>seasons(; start=December))
    G_w = broadcast_dims.(*, weights, G)
    @test G_w isa DimArray
    @test G_w[1] isa DimArray
end
