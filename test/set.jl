using DimensionalData, Test

a = [1 2; 3 4]
dimz = (X((143.0, 145.0); mode=Sampled(order=Ordered()), metadata=Dict(:meta => "X")),
        Y((-38.0, -36.0); mode=Sampled(order=Ordered()), metadata=Dict(:meta => "Y")))
da = DimArray(a, dimz, :test)

a2 = [1 2 3 4
      3 4 5 6
      4 5 6 7]
dimz2 = (Dim{:row}(10.0:10.0:30.0), Dim{:column}(-2:1.0:1.0))
da2 = DimArray(a2, dimz2, :test2)

ds = DimDataset(da2, DimArray(2a2, dimz2, :test3))


@testset " Array fields" begin
    @test name(set(da2, :newname)) == :newname
    @test_throws ArgumentError parent(set(da2, [9 9; 9 9])) == [9 9; 9 9]
    @test parent(set(da2, fill(9, 3, 4))) == fill(9, 3, 4)
end

@testset "DimDataset dims" begin
    @test typeof(dims(set(ds, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(ds, :column => Ti(), :row => Z()))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(ds, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(ds, row=X, column=Z))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(ds, (row=Y(), column=X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(ds, row=X(), column=Z()))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(ds, row=:row2, column=:column2))) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test index(set(ds, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
end

@testset "DimArray dims" begin
    @test typeof(dims(set(da2, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da, X => Ti(), Y => Z()))) <: Tuple{<:Ti,<:Z}
    @test typeof(dims(set(da, X=:a, Y=:b))) <: Tuple{<:Dim{:a},<:Dim{:b}}
    @test typeof(dims(set(da2, :column => Ti(), :row => Z()))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(da2, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da2, row=X, column=Z))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, (row=Y(), column=X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da2, row=X(), column=Z()))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, row=:row2, column=:column2))) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test index(set(da2, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
end

@testset "Array dim index" begin
    @test index(set(da2, :column => [:a, :b, :c, :d], :row => 4:6)) == 
        (4:6, [:a, :b, :c, :d])
    @test index(set(da2, :column => Val((:a, :b, :c, :d)), :row => Val((4:6...,)))) == 
        ((4:6...,), (:a, :b, :c, :d))
    @test index(set(da2, :column => 10:5:20, :row => 4:6)) == (4:6, 10:5:20)
    @test step.(span(dims(set(da2, :column => 10:5:20, :row => 4:6)))) == (1, 5)
end

@testset "Array dim mode" begin
    @test mode(set(da2, :column => NoIndex(), :row => Sampled(sampling=Intervals(Center())))) == 
        (Sampled(Ordered(), Regular(10.0), Intervals(Center())), NoIndex())
    @test mode(set(da2, column=NoIndex())) == 
        (Sampled(Ordered(), Regular(10.0), Points()), NoIndex())
    @test order(set(da2, (Unordered(), Ordered(array=ReverseArray())))) == 
        (Unordered(), Ordered(array=ReverseArray()))
    @test span(set(da2, row=Irregular(10, 12), column=Regular(9.9))) == 
        (Irregular(10, 12), Regular(9.9))
    @test_throws ArgumentError set(da2, (End(), Center()))
    @test mode(set(da2, :column => NoIndex(), :row => Sampled())) == 
        (Sampled(Ordered(), Regular(10.0), Points()), NoIndex())

    interval_da = set(da, (Intervals(), Intervals()))
    @test sampling(interval_da) == (Intervals(), Intervals())
    @test locus(set(interval_da, X(End()), Y(Center()))) == (End(), Center())
    @test locus(set(interval_da, X=>End(), Y=>Center())) == (End(), Center())
    @test locus(set(interval_da, X=End, Y=Center)) == (End(), Center())

    @test sampling(set(da, (X(Intervals(End())), Y(Intervals(Start()))))) == 
        (Intervals(End()), Intervals(Start()))
    @test mode(set(da, X=NoIndex(), Y=Categorical())) == 
        (NoIndex(), Categorical())
    @test order(set(da, Y(Unordered()))) == (Ordered(), Unordered())
end

@testset "metadata" begin
    @test metadata(set(X(), Dict(:a=>1, :b=>2))) == Dict(:a=>1, :b=>2)
    dax = set(da, X(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax), X) == Dict(:a=>1, :b=>2)
    @test metadata(dims(dax), Y) == Dict(:meta => "Y") 
    dax = set(da, X(; metadata=Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, X)) == Dict(:a=>1, :b=>2)

    dax = set(da2, row=Dict(:a=>1, :b=>2))
    @test metadata(dims(dax, :row)) == Dict(:a=>1, :b=>2)
    dax = set(da2, column=Dict(:a=>1, :b=>2))
    @test metadata(dims(dax, :column)) == Dict(:a=>1, :b=>2)
end

@testset "all dim fields" begin
    dax = set(da, X(20:-10:10; mode=Sampled(), metadata=Dict(:a=>1, :b=>2)))
    x = dims(dax, X)
    order(x)
    @test val(x) == 20:-10:10
    @test order(x) == Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())
    @test span(x) == Regular(-10)
    @test mode(x) == Sampled(Ordered(ReverseIndex(), ForwardArray(), ForwardRelation()), Regular(-10), Points())
    @test metadata(x) == Dict(:a=>1, :b=>2) 
end
