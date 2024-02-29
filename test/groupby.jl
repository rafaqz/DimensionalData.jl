using DimensionalData, Test, Dates, Statistics, IntervalSets

using DimensionalData.Dimensions
using DimensionalData.LookupArrays
const DD = DimensionalData

days = DateTime(2000):Day(1):DateTime(2000, 12, 31)
A = DimArray((1:6) * (1:366)', (X(1:0.2:2), Ti(days)))
st = DimStack((a=A, b=A, c=A[X=1]))

@testset "manual groupby comparisons" begin
    # Group by month and even/odd Y axis values
    months = DateTime(2000):Month(1):DateTime(2000, 12, 31)
    manualmeans = map(months) do m
        mean(A[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1])
    end
    @test mean.(groupby(A, Ti=>month)) == manualmeans
    manualmeans_st = map(months) do m
        mean(st[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1])
    end
    @test mean.(groupby(st, Ti=>month)) == manualmeans_st

    manualsums = mapreduce(hcat, months) do m
        vcat(sum(A[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1 .. 1.5]), 
             sum(A[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1.5 .. 2])
        )
    end |> permutedims
    gb_sum = sum.(groupby(A, Ti=>month, X => >(1.5)))
    @test dims(gb_sum, Ti) == Ti(Sampled([1:12...], ForwardOrdered(), Irregular((nothing, nothing)), Points(), NoMetadata()))
    @test typeof(dims(gb_sum, X)) == typeof(X(Sampled(BitVector([false, true]), ForwardOrdered(), Irregular((nothing, nothing)), Points(), NoMetadata())))
    @test gb_sum == manualsums

    manualsums_st = mapreduce(hcat, months) do m
        vcat(sum(st[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1 .. 1.5]), 
             sum(st[Ti=dayofyear(m):dayofyear(m)+daysinmonth(m)-1, X=1.5 .. 2])
        )
    end |> permutedims
    gb_sum_st = sum.(groupby(st, Ti=>month, X => >(1.5))) 
    @test dims(gb_sum_st, Ti) == Ti(Sampled([1:12...], ForwardOrdered(), Irregular((nothing, nothing)), Points(), NoMetadata()))
    @test typeof(dims(gb_sum_st, X)) == typeof(X(Sampled(BitVector([false, true]), ForwardOrdered(), Irregular((nothing, nothing)), Points(), NoMetadata())))
    @test gb_sum_st == manualsums_st

    @test_throws ArgumentError groupby(st, Ti=>month, Y=>isodd)
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
end

@testset "dimension matching groupby" begin
    dates = DateTime(2000):Month(1):DateTime(2000, 12, 31)
    xs = 1.0:1:3.0
    B = rand(X(xs; sampling=Intervals(Start())), Ti(dates; sampling=Intervals(Start())))
    gb = groupby(A, B)
    @test size(gb) === size(B) === size(mean.(gb))
    @test dims(gb) === dims(B) === dims(mean.(gb))
    manualmeans = mapreduce(hcat, intervals(dates)) do d
        map(intervals(xs)) do x
            mean(A[X=x, Ti=d])
        end
    end
    @test all(collect(mean.(gb)) .=== manualmeans)
    @test all(
              mean.(gb) .=== manualmeans
             )
end

