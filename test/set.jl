using DimensionalData, Test

a = [1 2; 3 4]
dimz = (X((143.0, 145.0); mode=Sampled(order=Ordered()), metadata=DimMetadata(Dict(:meta => "X"))),
        Y((-38.0, -36.0); mode=Sampled(order=Ordered()), metadata=DimMetadata(Dict(:meta => "Y"))))
da = DimArray(a, dimz, :test)

a2 = [1 2 3 4
      3 4 5 6
      4 5 6 7]
dimz2 = (Dim{:row}(10.0:10.0:30.0), Dim{:column}(-2:1.0:1.0))
da2 = DimArray(a2, dimz2, :test2)

ds = DimDataset(da2, DimArray(2a2, dimz2, :test3))


@testset " Array fields" begin
    @test name(set(da2, :newname)) == :newname
    @test metadata(set(da2, ArrayMetadata(Dict(:testa => "test")))).val == Dict(:testa => "test")
    @test parent(set(da2, fill(9, 3, 4))) == fill(9, 3, 4)
    # A differently sized array can't be set
    @test_throws ArgumentError parent( set(da2, [9 9; 9 9])) == [9 9; 9 9]
end

@testset "DimDataset fields" begin
    ds2 = set(ds, (x=a2, y=3a2))
    @test keys(ds2) == (:x, :y)
    @test values(ds2) == (a2, 3a2)
    @test metadata(set(ds, StackMetadata(Dict(:testa => "test")))).val == Dict(:testa => "test")
end

@testset "DimDataset Dimension" begin
    @test typeof(dims(set(ds, row=X, column=Z))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(ds, row=X(), column=Z()))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(ds, row=:row2, column=:column2))) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test typeof(dims(set(ds, :column => Ti(), :row => Z))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(ds, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(ds, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test index(set(ds, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
end

@testset "DimArray dim Dimension" begin
    @test typeof(dims(set(da, X=:a, Y=:b))) <: Tuple{<:Dim{:a},<:Dim{:b}}
    @test typeof(dims(set(da2, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da, X => Ti(), Y => Z()))) <: Tuple{<:Ti,<:Z}
    @test typeof(dims(set(da2, :column => Ti(), :row => Z()))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(da2, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da2, row=X, column=Z))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, row=X(), column=Z()))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, row=:row2, column=:column2))) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test index(set(da2, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
end

@testset "Dimension index" begin
    @test index(set(da2, :column => [:a, :b, :c, :d], :row => 4:6)) == 
        (4:6, [:a, :b, :c, :d])
    @test index(set(da2, column=Val((:a, :b, :c, :d)), row=Val((4:6...,)))) == 
        ((4:6...,), (:a, :b, :c, :d))
    @test index(set(ds, :column => 10:5:20, :row => 4:6)) == (4:6, 10:5:20)
    @test step.(span(set(da2, :column => 10:5:20, :row => 4:6))) == (1, 5)
end

@testset "dim mode" begin
    @test mode(set(da2, :column => NoIndex(), :row => Sampled(sampling=Intervals(Center())))) == 
        (Sampled(Ordered(), Regular(10.0), Intervals(Center())), NoIndex())
    @test mode(set(da2, column=NoIndex())) == 
        (Sampled(Ordered(), Regular(10.0), Points()), NoIndex())
    @test span(set(da2, row=Irregular(10, 12), column=Regular(9.9))) == 
        (Irregular(10, 12), Regular(9.9))
    @test_throws ArgumentError set(da2, (End(), Center()))
    @test mode(set(da2, :column => NoIndex(), :row => Sampled())) == 
        (Sampled(Ordered(), Regular(10.0), Points()), NoIndex())

    interval_da = set(da, X=Intervals(), Y=Intervals())
    @test sampling(interval_da) == (Intervals(), Intervals())
    @test locus(set(interval_da, X(End()), Y(Center()))) == (End(), Center())
    @test locus(set(interval_da, X=>End(), Y=>Center())) == (End(), Center())
    @test locus(set(interval_da, X=End, Y=Center)) == (End(), Center())
    @test locus(set(da, Y=Center())) == (Center(), Center())

    @test sampling(set(da, (X(Intervals(End())), Y(Intervals(Start()))))) == 
        (Intervals(End()), Intervals(Start()))
    @test mode(set(da, X=NoIndex(), Y=Categorical())) == 
        (NoIndex(), Categorical())
    uda = set(da, Y(Unordered()))
    @test order(uda) == (Ordered(), Unordered(ForwardRelation()))
    @test order(set(uda, Y=ReverseRelation())) == (Ordered(), Unordered(ReverseRelation()))
end

@testset "order" begin
    @test order(ArrayOrder, set(da, X=ReverseArray)) == (ReverseArray(), ForwardArray())
    @test relation(set(da, Y(ReverseRelation())), Y) == ReverseRelation()
end


@testset "metadata" begin
    @test metadata(set(X(), DimMetadata(Dict(:a=>1, :b=>2)))).val == Dict(:a=>1, :b=>2)
    dax = set(da, X(DimMetadata(Dict(:a=>1, :b=>2))))
    @test metadata(dims(dax), X).val == Dict(:a=>1, :b=>2)
    @test metadata(dims(dax), Y).val == Dict(:meta => "Y") 
    dax = set(da, X(; metadata=DimMetadata(Dict(:a=>1, :b=>2))))
    @test metadata(dims(dax, X)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, row=DimMetadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, :row)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, column=DimMetadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, :column)).val == Dict(:a=>1, :b=>2)
end

@testset "all dim fields" begin
    dax = set(da, X(20:-10:10; mode=Sampled(), metadata=DimMetadata(Dict(:a=>1, :b=>2))))
    x = dims(dax, X)
    @test val(x) == 20:-10:10
    @test order(x) == Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())
    @test span(x) == Regular(-10)
    @test mode(x) == Sampled(Ordered(ReverseIndex(), ForwardArray(), ForwardRelation()), Regular(-10), Points())
    @test metadata(x).val == Dict(:a=>1, :b=>2) 
end

@testset "errors with set" begin
    @test_throws ArgumentError set(da, Sampled())
    @test_throws ArgumentError set(da, X=7)
    @test_throws ArgumentError DimensionalData._set(dims(da, X), X(7))
end
