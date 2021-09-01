using DimensionalData, Test 
using DimensionalData: _set, AutoSampling

a = [1 2; 3 4]
dimz = (X((143.0, 145.0); mode=Sampled(order=Ordered()), metadata=Metadata(Dict(:meta => "X"))),
        Y((-38.0, -36.0); mode=Sampled(order=Ordered()), metadata=Metadata(Dict(:meta => "Y"))))
da = DimArray(a, dimz; name=:test)

a2 = [1 2 3 4
      3 4 5 6
      4 5 6 7]
dimz2 = (Dim{:row}(10.0:10.0:30.0), Dim{:column}(-2:1.0:1.0))
da2 = DimArray(a2, dimz2; name=:test2)

s = DimStack(da2, DimArray(2a2, dimz2; name=:test3))

@testset " Array fields" begin
    @test name(set(da2, :newname)) == :newname
    @test name(set(da2, Name(:newname))) == Name{:newname}()
    @test name(set(da2, NoName())) == NoName()
    @test metadata(set(da2, Metadata(Dict(:testa => "test")))).val == Dict(:testa => "test")
    @test parent(set(da2, fill(9, 3, 4))) == fill(9, 3, 4)
    # A differently sized array can't be set
    @test_throws ArgumentError parent(set(da2, [9 9; 9 9])) == [9 9; 9 9]
end

@testset "DimStack fields" begin
    @test_throws ArgumentError set(s, (x=a2, y=3a2))
    @test_throws ArgumentError set(s, (test2=a2, test3=hcat(a2, a2)))
    s2 = set(s, (test2=a2, test3=3a2))
    @test keys(s2) == (:test2, :test3)
    @test values(s2) == (a2, 3a2)
    @test metadata(set(s, Metadata(Dict(:testa => "test")))).val == Dict(:testa => "test")
end

@testset "DimStack Dimension" begin
    @test typeof(dims(set(s, row=X, column=Z))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(s, row=X(), column=Z()))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(s, row=:row2, column=:column2))) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test typeof(dims(set(s, :column => Ti(), :row => Z))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(s, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(s, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test index(set(s, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
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
    @test index(set(s, :column => 10:5:20, :row => 4:6)) == (4:6, 10:5:20)
    @test step.(span(set(da2, :column => 10:5:20, :row => 4:6))) == (1, 5)
end

@testset "dim mode" begin
    interval_da = set(da, X=Intervals(), Y=Intervals())
    @test mode(set(da2, :column => NoIndex(), :row => Sampled(sampling=Intervals(Center())))) == 
        (Sampled(Ordered(), Regular(10.0), Intervals(Center())), NoIndex())
    @test mode(set(da2, column=NoIndex())) == 
        (Sampled(Ordered(), Regular(10.0), Points()), NoIndex())
    @test mode(set(da2, :column => NoIndex(), :row => Sampled())) == 
        (Sampled(Ordered(), Regular(10.0), Points()), NoIndex())
    @test mode(set(da, X=NoIndex(), Y=Categorical())) == (NoIndex(), Categorical()) 

    @testset "span" begin
        # TODO: should this error? the span step doesn't match the index step
        @test span(set(da2, row=Irregular(10, 12), column=Regular(9.9))) == 
            (Irregular(10, 12), Regular(9.9))
        @test _set(Sampled(), AutoSpan()) == Sampled()
        @test _set(Sampled(), Irregular()) == Sampled(AutoOrder(), Irregular(), AutoSampling())
    end

    @testset "locus" begin
        @test_throws ArgumentError set(da2, (End(), Center()))
        @test locus(set(interval_da, X(End()), Y(Center()))) == (End(), Center())
        @test locus(set(interval_da, X=>End(), Y=>Center())) == (End(), Center())
        @test locus(set(interval_da, X=End, Y=Center)) == (End(), Center())
        @test locus(set(da, Y=Center())) == (Center(), Center())
        @test _set(Intervals(Center()), Start()) == Intervals(Start())
        @test _set(Intervals(Center()), AutoLocus()) == Intervals(Center())
        @test _set(Points(), Center()) == Points()
        @test_throws ArgumentError _set(Points(), Start())
        @test_throws ArgumentError _set(Points(), End())
    end

    @testset "sampling" begin
        @test sampling(interval_da) == (Intervals(), Intervals())
        @test sampling(set(da, (X(Intervals(End())), Y(Intervals(Start()))))) == 
            (Intervals(End()), Intervals(Start())) 
        @test _set(Sampled(), AutoSampling()) == Sampled()
        @test _set(Sampled(), Intervals()) == Sampled(AutoOrder(), AutoSpan(), Intervals())
        @test _set(Points(), AutoSampling()) == Points()
        @test _set(AutoSampling(), Intervals()) == Intervals()
        @test _set(AutoSampling(), AutoSampling()) == AutoSampling()
    end

    @testset "order" begin
        uda = set(da, Y(Unordered()))
        @test order(uda) == (Ordered(), Unordered(ForwardRelation()))
        @test order(set(uda, Y=ReverseRelation())) == (Ordered(), Unordered(ReverseRelation()))
        @test order(ArrayOrder, set(da, X=ReverseArray)) == (ReverseArray(), ForwardArray())
        @test relation(set(da, Y(ReverseRelation())), Y) == ReverseRelation()
        @test order(set(X(), AutoOrder())) == AutoOrder()
        @test indexorder(set(X(; mode=Sampled(order=Ordered())), ReverseIndex())) == ReverseIndex()
        @test arrayorder(set(X(; mode=Sampled(order=Ordered())), ReverseArray())) == ReverseArray()
        @test arrayorder(set(X(; mode=Sampled(order=Ordered())), ReverseArray())) == ReverseArray()
        @test indexorder(_set(Ordered(), ReverseIndex())) == ReverseIndex()
        @test arrayorder(_set(Ordered(), ReverseArray())) == ReverseArray()
        @test relation(_set(Ordered(), ReverseRelation())) == ReverseRelation()
        @test relation(_set(Unordered(), ReverseRelation())) == ReverseRelation()
        @test_throws ArgumentError _set(Unordered(), ReverseIndex())
        @test_throws ArgumentError _set(Unordered(), ReverseArray())
        @test _set(Sampled(), Ordered()) == Sampled(Ordered(), AutoSpan(), AutoSampling()) 
        @test _set(Sampled(; order=Unordered()), AutoOrder()) == Sampled(Unordered(), AutoSpan(), AutoSampling()) 
    end
end


@testset "metadata" begin
    @test metadata(set(X(), Metadata(Dict(:a=>1, :b=>2)))).val == Dict(:a=>1, :b=>2)
    dax = set(da, X(Metadata(Dict(:a=>1, :b=>2))))
    @test metadata(dims(dax), X).val == Dict(:a=>1, :b=>2)
    @test metadata(dims(dax), Y).val == Dict(:meta => "Y") 
    dax = set(da, X(; metadata=Metadata(Dict(:a=>1, :b=>2))))
    @test metadata(dims(dax, X)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, row=Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, :row)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, column=Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, :column)).val == Dict(:a=>1, :b=>2)
    @test metadata(set(da, NoMetadata())) == NoMetadata()
    @test metadata(set(da, NoMetadata)) == NoMetadata()
end

@testset "all dim fields" begin
    dax = set(da, X(20:-10:10; mode=Sampled(), metadata=Metadata(Dict(:a=>1, :b=>2))))
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
    @test_throws ArgumentError _set(dims(da, X), X(7))
    @test_throws ArgumentError set(da, notadimname=Sampled())
end

@testset "_set nothing" begin
    @test _set(nothing, nothing) == nothing
    @test _set(1, nothing) == 1
    @test _set(nothing, 2) == 2
end
