using DimensionalData, Test 
using DimensionalData.Lookups, DimensionalData.Dimensions

using DimensionalData.Lookups: _set
using DimensionalData: layerdims

a = [1 2; 3 4]
dimz = (X(143.0:2.0:145.0; lookup=Sampled(order=ForwardOrdered()), metadata=Metadata(Dict(:meta => "X"))),
        Y(-38.0:2.0:-36.0; lookup=Sampled(order=ForwardOrdered()), metadata=Metadata(Dict(:meta => "Y"))))
da = DimArray(a, dimz; name=:test)
interval_da = set(da, X => Intervals(), Y => Intervals())

a2 = [1 2 3 4
      3 4 5 6
      4 5 6 7]
dimz2 = (Dim{:row}(10.0:10.0:30.0), Dim{:column}(-2:1.0:1.0))
da2 = DimArray(a2, dimz2; name=:test2)

s = DimStack(da2, DimArray(2a2, dimz2; name=:test3))

@testset "Array fields" begin
    @test parent(set(da2, fill(9, 3, 4))) == fill(9, 3, 4)
    # A differently sized array can't be set
    @test_throws DimensionMismatch parent(set(da2, [9 9; 9 9]))
end

@testset "DimStack fields" begin
    @test_throws ArgumentError set(s, (x=a2, y=3a2))
    @test_throws DimensionMismatch set(s, (test2=a2, test3=hcat(a2, a2)))
    s2 = set(s, (test2=a2, test3=3a2))
    @test keys(s2) == (:test2, :test3)
    @test values(s2) == (a2, 3a2)
end

@testset "DimStack Dimension" begin
    s1 = set(s, :row => X, :column => Z)
    @test typeof(dims(s1)) <: Tuple{<:X,<:Z}
    @test layerdims(s1) == (; test2=(X(), Z()), test3=(X(), Z()))
    @test typeof(dims(set(s, :row => X(), :column => Z()))) <: Tuple{<:X,<:Z}
    s1 = set(s, :row => :row2, :column => :column2)
    @test typeof(dims(s1)) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test layerdims(s1) == (; test2=(Dim{:row2}(), Dim{:column2}()), test3=(Dim{:row2}(), Dim{:column2}()))
    @test typeof(dims(set(s, :column => Ti(), :row => Z))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(s, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(s, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test lookup(set(s, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
    @test lookup(set(s, Dim{:row}([:x, :y, :z])), :row) isa Sampled
end

@testset "DimArray Dimension" begin
    @test typeof(dims(set(da, X => :a, Y => :b))) <: Tuple{<:Dim{:a},<:Dim{:b}}
    @test typeof(dims(set(da2, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da, X => Ti(), Y => Z()))) <: Tuple{<:Ti,<:Z}
    @test typeof(dims(set(da2, :column => Ti(), :row => Z()))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(da2, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da2, :row=>X, :column=>Z))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, :row=>X(), :column=>Z()))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, :row=>:row2, :column=>:column2))) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test index(set(da2, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
end

@testset "Dimension index" begin
    @test index(set(da2, :column => [:a, :b, :c, :d], :row => 4:6)) == 
        (4:6, [:a, :b, :c, :d])
    @test index(set(s, :column => 10:5:20, :row => 4:6)) == (4:6, 10:5:20)
    @test step.(span(set(da2, :column => 10:5:20, :row => 4:6))) == (1, 5)
end

@testset "dim lookup" begin
    @test lookup(set(dims(da2), NoLookup())) == 
         (NoLookup(Base.OneTo(3)), NoLookup(Base.OneTo(4)))
    @test lookup(set(da2, NoLookup())) == 
         (NoLookup(Base.OneTo(3)), NoLookup(Base.OneTo(4)))
    @test lookup(set(da2, Categorical)) == 
        (Categorical(10.0:10.0:30.0, ForwardOrdered(), NoMetadata()), 
         Categorical(-2.0:1.0:1.0, ForwardOrdered(), NoMetadata())) 
    @test lookup(set(da2, :column => NoLookup(), :row => Sampled(sampling=Intervals(Center())))) == 
        (Sampled(10.0:10.0:30.0, ForwardOrdered(), Regular(10.0), Intervals(Center()), NoMetadata()), NoLookup(Base.OneTo(4)))
    @test lookup(set(da2, Dim{:column}(NoLookup()))) == 
        (Sampled(10.0:10.0:30.0, ForwardOrdered(), Regular(10.0), Points(), NoMetadata()), NoLookup(Base.OneTo(4)))
    @test lookup(set(da2, :column => NoLookup(), :row => Sampled())) == 
        (Sampled(10.0:10.0:30.0, ForwardOrdered(), Regular(10.0), Points(), NoMetadata()), NoLookup(Base.OneTo(4)))
    cat_da = set(da, X=>NoLookup(), Y=>Categorical())
    @test index(cat_da) == 
        (NoLookup(Base.OneTo(2)), Categorical(-38.0:2.0:-36.0, Unordered(), NoMetadata())) 
    cat_da_m = set(dims(cat_da, Y), X(DimensionalData.AutoValues(); metadata=Dict()))
    @test cat_da_m isa X
    @test metadata(cat_da_m) == Dict()
 
    @testset "span" begin
        @test span(set(da2, Irregular)) ==
            (Irregular((10.0, 30.0)), Irregular((-2.0, 1.0)))
        @test span(set(da2, Regular)) == (Regular(10.0), Regular(1.0))
        # TODO: should this error? the span step doesn't match the index step
        @test span(set(da2, :row=>Irregular(10, 12), :column=>Regular(9.9))) == 
            (Irregular(10, 12), Regular(9.9))
        @test set(Sampled(), AutoSpan()) == Sampled()
        @test set(Sampled(), Irregular()) == Sampled(; span=Irregular())
        @test set(Sampled(), Regular()) == Sampled(; span=Regular())
        @test set(Sampled(1:2:10), Regular()) == Sampled(1:2:10; span=Regular(2))
    end

    @testset "locus" begin
        @test locus(set(interval_da, X(End()), Y(Center()))) == (End(), Center())
        @test locus(set(interval_da, X=>End(), Y=>Center())) == (End(), Center())
        @test locus(set(da, Y=>Center())) == (Center(), Center())
        @test set(Points(), Intervals()) == Intervals(Center())
        @test set(Intervals(Center()), Start()) == Intervals(Start())
        @test set(Intervals(Center()), AutoLocus()) == Intervals(Center())
        @test set(Points(), Center()) == Points()
        @test_throws ArgumentError set(Points(), Start())
        @test_throws ArgumentError set(Points(), End())
    end

    @testset "sampling" begin
        @test sampling(interval_da) == (Intervals(Center()), Intervals(Center()))
        @test sampling(set(da, (X(Intervals(End())), Y(Intervals(Start()))))) == 
            (Intervals(End()), Intervals(Start())) 
        @test set(Sampled(), AutoSampling()) == Sampled()
        @test set(Sampled(), Intervals) == Sampled(; sampling=Intervals())
        @test set(Points(), AutoSampling()) == Points()
        @test set(AutoSampling(), Intervals()) == Intervals()
        @test set(AutoSampling(), AutoSampling()) == AutoSampling()
    end

    @testset "order" begin
        uda = set(da, Y(Unordered()))
        @test order(uda) == (ForwardOrdered(), Unordered())
        @test order(set(uda, X => ReverseOrdered())) == (ReverseOrdered(), Unordered())
    end

    # issue #478
    @testset "tuple dims and/or Symbol/Dim{Colon}/Colon replacement" begin
        @test set(Dim{:foo}(), :bar) === Dim{:bar}()
        @test set(Dim{:foo}(2:11), :bar) === Dim{:bar}(2:11)
        @test set(Dim{:foo}(), Dim{:bar}()) === Dim{:bar}()
        @test set(Dim{:foo}(2:11), Dim{:bar}()) === Dim{:bar}(2:11)
        @test set(Dim{:foo}(Lookups.Sampled(2:11)), Dim{:bar}(Lookups.Sampled(0:9))) ===
            set(set(Dim{:foo}(Lookups.Sampled(2:11)), :bar), Lookups.Sampled(0:9))
        @test set((Dim{:foo}(),), :foo => :bar) === (Dim{:bar}(),)
        @test set((Dim{:foo}(2:11),), :foo => :bar) === (Dim{:bar}(2:11),)
        @test set(dimz, :X => :foo, :Y => :bar) ===
            (set(dims(dimz, :X), :foo), set(dims(dimz, :Y), :bar))
    end
end

@testset "metadata" begin
    @test metadata(set(Sampled(), Metadata(Dict(:a=>1, :b=>2)))).val == Dict(:a=>1, :b=>2)
    dax = set(da, X => Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax), X).val == Dict(:a=>1, :b=>2)
    @test metadata(dims(dax), Y).val == Dict(:meta => "Y") 
    dax = set(da, X => Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, X)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, :row=>Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, :row)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, :column=>Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, :column)).val == Dict(:a=>1, :b=>2)
end

@testset "all lookup fields updated" begin
    md = Metadata(Dict(:a=>1, :b=>2))
    dax = set(da, X(20:-10:10; metadata=md))
    x = dims(dax, X)
    @test parent(lookup(x)) === 20:-10:10
    @test order(x) === ReverseOrdered()
    @test span(x) === Regular(-10)
    @test lookup(x) == Sampled(20:-10:10, ReverseOrdered(), Regular(-10), Points(), md)
    @test metadata(x).val == Dict(:a=>1, :b=>2) 
end

@testset "errors with set" begin
    @test_throws ArgumentError set(dims(da, X), X(7))
    @test_throws ArgumentError set(da, notafield=Sampled())
end

# @testset "_set nothing" begin
#     @test _set(nothing, nothing) == nothing
#     @test _set(1, nothing) == 1
#     @test _set(nothing, 2) == 2
# end
