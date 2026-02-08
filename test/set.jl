using DimensionalData, Test 
using DimensionalData.Lookups, DimensionalData.Dimensions

using DimensionalData: unsafe_set
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
da2slice = set(da2[:,1], name=:onedim)
sslice  = DimStack(da2, DimArray(2a2, dimz2; name=:test3), da2slice)
smix = DimStack(da, da2)
ssame = DimStack(da, set(da, X=>Z))

@testset "set DimArray parent" begin
    a = fill(9, 3, 4)
    @test parent(set(da2, a)) === a
    # A differently sized array can't be set
    a_bad = [9 9; 9 9]
    @test_throws DimensionMismatch parent(set(da2, a_bad))
    @test parent(unsafe_set(da2, a_bad)) === a_bad
end

@testset "set DimStack parent" begin
    s2 = set(s, (test2=zero(a2), test3=3a2))
    s3 = unsafe_set(s, (test2=zero(a2), test3=3a2))
    @test keys(s2) == keys(s3) == (:test2, :test3)
    @test parent(s2) == parent(s3) == (test2=zero(a2), test3=3a2)
    @test_throws ArgumentError set(s, (x=a2,))
    @test_throws ArgumentError set(s, (x=a2, y=3a2))
    @test_throws DimensionMismatch set(s, (test2=a2, test3=hcat(a2, a2)))
    @testset "set subset of layers" begin
        a = ones(size(a2))
        @test parent(set(s, (; test2=a))) === (; test2=a, test3=parent(s).test3)
        @test parent(unsafe_set(s, (; test2=a))) === (; test2=a)
    end
end

@testset "set DimStack Dimension type" begin
    s1 = set(s, :row => X, :column => Z)
    @test typeof(dims(s1)) <: Tuple{<:X,<:Z}
    @test layerdims(s1) == (; test2=(X(), Z()), test3=(X(), Z()))
    @test typeof(dims(set(s, :row => X(), :column => Z()))) <: Tuple{<:X,<:Z}
    # This should throw but doesn't at the moment.
    #@test_throws ArgumentError set(smix, :row => X, :column => Z)
    s1 = set(s, :row => :row2, :column => :column2)
    @test typeof(dims(s1)) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test layerdims(s1) == (; test2=(Dim{:row2}(), Dim{:column2}()), test3=(Dim{:row2}(), Dim{:column2}()))
    s1 = set(ssame, :Z=>X)
    @test typeof(dims(s1)) <: Tuple{<:X,<:Y}
    
    @test typeof(dims(set(s, :column => Ti(), :row => Z))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(s, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(s, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test lookup(set(s, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
    @test lookup(set(s, Dim{:row}([:x, :y, :z])), :row) isa Sampled
end

@testset "set DimArray Dimension type" begin
    @test typeof(dims(set(da, X => :a, Y => :b))) <: Tuple{<:Dim{:a},<:Dim{:b}}
    @test typeof(dims(set(da2, Dim{:row}(Y()), Dim{:column}(X())))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da, X => Ti(), Y => Z()))) <: Tuple{<:Ti,<:Z}
    @test typeof(dims(set(da2, :column => Ti(), :row => Z()))) <: Tuple{<:Z,<:Ti}
    @test typeof(dims(set(da2, (Dim{:row}(Y), Dim{:column}(X))))) <: Tuple{<:Y,<:X}
    @test typeof(dims(set(da2, :row=>X, :column=>Z))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, :row=>X(), :column=>Z()))) <: Tuple{<:X,<:Z}
    @test typeof(dims(set(da2, :row=>:row2, :column=>:column2))) <: Tuple{<:Dim{:row2},<:Dim{:column2}}
    @test lookup(set(da2, Dim{:row}([:x, :y, :z])), :row) == [:x, :y, :z] 
end

@testset "set Lookup values" begin
    dimz3 = (Dim{:row}(10.0:10.0:30.0), Dim{:column}(2.0:-1.0:-1.0))
    da3 = DimArray(a2, dimz3; name=:test2)
    @testset "Order maintained" begin
        c = [8, 4, 2, 1]
        r = 4:6
        da_set = set(da3, :column => c, :row => r)
        da_uset = unsafe_set(da3, :column => c, :row => r)
        @test parent.(lookup(da_uset)) === parent.(lookup(da_set)) === (r, c)
        @test order(da_set) == order(da_uset) == (ForwardOrdered(), ReverseOrdered())
        @test sampling(da_set) == sampling(da_uset) == (Points(), Points())
        @test span(da_set) == (Regular(1), Irregular((nothing, nothing)))
        @test span(da_uset) === (Regular(10.0), Regular(-1.0))
    end
    @testset "Order reversed" begin
        c = [1, 2, 4, 8]
        r = 6:-1:4
        da_set = set(da3, :column => c, :row => r)
        da_uset = unsafe_set(da3, :column => c, :row => r)
        @test parent.(lookup(da_uset)) === parent.(lookup(da_set)) === (r, c)
        @test sampling(da_set) == sampling(da_uset) == (Points(), Points())
        @test span(da_set) == (Regular(-1), Irregular((nothing, nothing)))
        @test span(da_uset) === (Regular(10.0), Regular(-1.0))
        @test order(da_set) == (ReverseOrdered(), ForwardOrdered())
        @test order(da_uset) == (ForwardOrdered(), ReverseOrdered())
    end
    @testset "Ordered to Unordered" begin
        c = [8, 2, 4, 1]
        r = [6, 4, 5]
        da_set = set(da3, :column => c, :row => r)
        da_uset = unsafe_set(da3, :column => c, :row => r)
        @test parent.(lookup(da_uset)) === parent.(lookup(da_set)) === (r, c)
        @test sampling(da_set) == sampling(da_uset) == (Points(), Points())
        @test span(da_set) == (Irregular((nothing, nothing)), Irregular((nothing, nothing)))
        @test span(da_uset) === (Regular(10.0), Regular(-1.0))
        @test order(da_set) == (Unordered(), Unordered())
        @test order(da_uset) == (ForwardOrdered(), ReverseOrdered())
    end
    @testset "Unordered to Ordered" begin
        # First define the unordered DimArray
        c = [8, 2, 4, 1]
        r = [6, 4, 5]
        da4 = set(da3, :column => c, :row => r)
        c = 8:-2:2
        r = 4:6
        da_set = set(da4, :column => c, :row => r)
        da_uset = unsafe_set(da4, :column => c, :row => r)
        @test parent.(lookup(da_uset)) === parent.(lookup(da_set)) === (r, c)
        @test order(da_set) == (ForwardOrdered(), ReverseOrdered())
        @test order(da_uset) == (Unordered(), Unordered())
        @test sampling(da_set) == sampling(da_uset) == (Points(), Points())
        @test span(da_set) == (Regular(1), Regular(-2))
        @test span(da_uset) == (Irregular((nothing, nothing)), Irregular((nothing, nothing)))
    end
end

@testset "Dimension index" begin
    @test lookup(set(da2, :column => [:a, :b, :c, :d], :row => 4:6)) == 
        (4:6, [:a, :b, :c, :d])
    @test lookup(set(s, :column => 10:5:20, :row => 4:6)) == (4:6, 10:5:20)
    @test step.(span(set(da2, :column => 10:5:20, :row => 4:6))) == (1, 5)
end

@testset "set Lookup" begin
    @testset "to NoLookup" begin
        @test lookup(set(dims(da2), NoLookup())) == 
            (NoLookup(Base.OneTo(3)), NoLookup(Base.OneTo(4)))
        @test lookup(set(da2, NoLookup())) == 
            (NoLookup(Base.OneTo(3)), NoLookup(Base.OneTo(4)))
    end
    @test lookup(set(da2, Categorical)) == 
        (Categorical(10.0:10.0:30.0, ForwardOrdered(), NoMetadata()), 
         Categorical(-2.0:1.0:1.0, ForwardOrdered(), NoMetadata())) 
    @test lookup(set(da2, :column => NoLookup(), :row => Sampled(sampling=Intervals(Center())))) == 
        (Sampled(10.0:10.0:30.0, ForwardOrdered(), Regular(10.0), Intervals(Center()), NoMetadata()), NoLookup(Base.OneTo(4)))
    @test lookup(set(da2, Dim{:column}(NoLookup()))) == 
        (Sampled(10.0:10.0:30.0, ForwardOrdered(), Regular(10.0), Points(), NoMetadata()), NoLookup(Base.OneTo(4)))
    cat_da2 = set(da2, Categorical)
    cat_da2_sample = set(da2, Sampled)
    @test cat_da2_sample == da2
    @test lookup(set(da2, :column => NoLookup(), :row => Sampled())) == 
        (Sampled(10.0:10.0:30.0, ForwardOrdered(), Regular(10.0), Points(), NoMetadata()), NoLookup(Base.OneTo(4)))
    cat_da = set(da, X=>NoLookup(), Y=>Categorical())
    @test lookup(cat_da) ==
        (NoLookup(Base.OneTo(2)), Categorical(-38.0:2.0:-36.0, ForwardOrdered(), NoMetadata())) 
    # cat_da = set(da, X=NoLookup(), Y=Categorical())
    # @test lookup(cat_da) == 
    #     (NoLookup(Base.OneTo(2)), Categorical(-38.0:2.0:-36.0, ForwardOrdered(), NoMetadata())) 
    cat_da_m = set(dims(cat_da, Y), X(DimensionalData.AutoValues(); metadata=Dict()))
    @test cat_da_m isa X
    @test metadata(cat_da_m) == Dict()
end
 
@testset "set Span" begin
    @test set(Regular(), AutoSpan()) == Regular()
    @test set(Regular(), Irregular()) == Irregular()
    @test set(Irregular(), Regular()) == Regular()

    @test set(Sampled(), Irregular()) == Sampled(; span=Irregular())
    @test set(Sampled(), Regular()) == Sampled(; span=Regular())
    @test set(Sampled(1:2:10), Regular()) == Sampled(1:2:10; span=Regular(2))
    @test set(Sampled([3, 6, 9, 12]), Regular()) == Sampled([3, 6, 9, 12]; span=Regular(3))

    @test span(set(da2, Irregular)) ==
        (Irregular((10.0, 30.0)), Irregular((-2.0, 1.0)))
    @test span(set(da2, Regular)) == (Regular(10.0), Regular(1.0))
    # TODO: should this error? the span step doesn't match the index step
    @test span(set(da2, :row=>Irregular(10, 12), :column=>Regular(9.9))) == 
        (Irregular(10, 12), Regular(9.9))
end

@testset "set Locus" begin
    @test locus(set(interval_da, X(End()), Y(Center()))) == (End(), Center())
    @test locus(set(interval_da, X => End(), Y => Center())) == (End(), Center())
    @test set(set(interval_da, End), Center) == interval_da
    @test set(set(interval_da, Start()), Center) == interval_da
    @test locus(set(da, Y=>Center())) == (Center(), Center())
    @test set(Points(), Intervals()) == Intervals(Center())
    @test set(Intervals(Center()), Start()) == Intervals(Start())
    @test set(Intervals(Center()), AutoLocus()) == Intervals(Center())
    @test set(Points(), Center()) == Points()
    @test_throws ArgumentError set(Points(), Start())
    @test_throws ArgumentError set(Points(), End())
end

@testset "set Sampling" begin
    @test sampling(interval_da) == (Intervals(Center()), Intervals(Center()))
    @test sampling(set(da, (X(Intervals(End())), Y(Intervals(Start()))))) == 
        (Intervals(End()), Intervals(Start())) 
    @test set(Sampled(), AutoSampling()) == Sampled()
    @test set(Sampled(), Intervals) == Sampled(; sampling=Intervals())
    @test set(Points(), AutoSampling()) == Points()
    @test set(AutoSampling(), Intervals()) == Intervals()
    @test set(AutoSampling(), AutoSampling()) == AutoSampling()
end

@testset "set Order" begin
    a = [1 2 3; 4 5 6; 7 8 9]
    dimz = (X(Sampled(100.0:10.0:120.0; metadata=Metadata(Dict(:meta => "X")))),
            Y(Categorical([:a, :b, :c]; metadata=Metadata(Dict(:meta => "Y")))))
    da_o = DimArray(a, dimz; name=:test)
    @testset "new Order is taken" begin
        @test set(ForwardOrdered(), Unordered()) == Unordered()
    end
    @testset "old Order is kep for AutoOrder" begin
        @test set(ReverseOrdered(), AutoOrder()) == ReverseOrdered()
    end
    @testset "Unordered does not affect parent" begin
        uda = set(da_o, Unordered())
        uuda = unsafe_set(da_o, Unordered())
        # Span is unchanged - it describes spacing, not ordering
        @test span(uda) == span(uuda) == (Regular(10.0), NoSpan())
        @test order(uda) == order(uuda) == (Unordered(), Unordered())
        @test parent(uda) == parent(uuda) == parent(da_o)
        @test lookup(uda) == (100.0:10.0:120.0, [:a, :b, :c])
        @test lookup(uuda) == (100.0:10.0:120.0, [:a, :b, :c])
    end
    @testset "Ordered reverses ordered parent" begin
        uda = set(da_o, Unordered())  # define uda in this scope
        rda = set(da_o, ReverseOrdered())
        urda = unsafe_set(uda, ReverseOrdered())
        @test order(rda) == (ReverseOrdered(), ReverseOrdered())
        @test lookup(rda) == (120.0:-10.0:100.0, [:c, :b, :a])
        @test lookup(urda) == (100.0:10.0:120.0, [:a, :b, :c])  # unsafe_set doesn't change lookup values
        @test parent(rda) == parent(reverse(da_o; dims=(X, Y)))
        @test parent(urda) == parent(da_o)
    end
    @testset "Ordered sorts unordered parent" begin
        da_u = set(da_o[X=[2, 3, 1], Y=[3, 1, 2]], Unordered())
        fda = set(da_u, ForwardOrdered())
        ufda = unsafe_set(da_u, ForwardOrdered())
        rda = set(da_u, ReverseOrdered())
        urda = unsafe_set(da_u, ReverseOrdered())
        @test order(fda) == order(ufda) == (ForwardOrdered(), ForwardOrdered())
        @test order(rda) == order(urda) == (ReverseOrdered(), ReverseOrdered())
        @test lookup(fda) == (100.0:10.0:120.0, [:a, :b, :c])
        @test lookup(rda) == (120.0:-10.0:100.0, [:c, :b, :a])
        @test map(parent, lookup(ufda)) == map(parent, lookup(urda)) == ([110.0, 120.0, 100.0], [:c, :a, :b])
        @test parent(fda) == parent(da_o)
        @test parent(rda) == parent(reverse(da_o; dims=(X, Y)))
        @test parent(ufda) == parent(urda) == parent(da_u)
    end
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

@testset "set metadata" begin
    @test metadata(set(Sampled(), Metadata(Dict(:a=>1, :b=>2)))).val == Dict(:a=>1, :b=>2)
    dax = set(da, X => Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax), X).val == Dict(:a=>1, :b=>2)
    @test metadata(dims(dax), Y).val == Dict(:meta => "Y") 
    dax = set(da, X => Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, X)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, :row=>Metadata(Dict(:a=>1, :b=>2)))
    @test metadata(dims(dax, :row)).val == Dict(:a=>1, :b=>2)
    dax = set(da2, :column=>Dict(:a=>1, :b=>2))
    @test metadata(dims(dax, :column)) == Dict(:a=>1, :b=>2)
end

@testset "all lookup fields updated" begin
    md = Metadata(Dict(:a=>1, :b=>2))
    dax = set(da, X(20:-10:10; metadata=md))
    x = dims(dax, X)
    @test order(x) === ReverseOrdered()
    @test span(x) === Regular(-10)
    @test lookup(x) == Sampled(20:-10:10, ReverseOrdered(), Regular(-10), Points(), md)
    @test parent(lookup(x)) === 20:-10:10
    @test metadata(x).val == Dict(:a=>1, :b=>2) 
    @test lookup(x) == Sampled(20:-10:10, ReverseOrdered(), Regular(-10), Points(), md)

    # Or not with `unsafe_set`...
    da_uset = DimensionalData.unsafe_set(da, X(20:-10:10; metadata=md));
    x = dims(da_uset, X)
    @test order(x) === ForwardOrdered()
    @test span(x) === Regular(2.0)
    @test metadata(x).val == Dict(:a=>1, :b=>2) 
    @test lookup(x) == Sampled(20:-10:10, ForwardOrdered(), Regular(2.0), Points(), md)
end

@testset "reordering with set" begin
    # set changes the data, order and span
    @test parent(set(da, ForwardOrdered)) === parent(da)
    @test parent(set(da, ReverseOrdered)) == parent(reverse(da; dims=(X, Y)))
    @test span(set(da, ReverseOrdered)) === map(reverse, span(da))
    # unsafe_set does not change the data or span  
    @test parent(unsafe_set(da, ForwardOrdered)) === parent(unsafe_set(da, ReverseOrdered)) === parent(da)
    @test span(unsafe_set(da, ForwardOrdered)) === span(unsafe_set(da, ReverseOrdered)) === span(da)
    # But it changes the order
    @test order(unsafe_set(da, ForwardOrdered)) === (ForwardOrdered(), ForwardOrdered())
    @test order(unsafe_set(da, ReverseOrdered)) === (ReverseOrdered(), ReverseOrdered())
    # Setting Unordered is the same for set and unsafe_set
    @test set(da, Unordered) === unsafe_set(da, Unordered)
    @test parent(set(da, Unordered)) == parent(unsafe_set(da, Unordered)) == da
    @test order(set(da, Unordered)) == order(unsafe_set(da, Unordered)) == (Unordered(), Unordered())
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

@testset "set with keyword arguments" begin
    @testset "set DimArray name" begin
        da_named = set(da; name=:newname)
        @test DimensionalData.name(da_named) === :newname
        @test parent(da_named) === parent(da)
        @test dims(da_named) === dims(da)
    end
    @testset "set DimArray data via keyword" begin
        newdata = fill(99, size(da))
        da_new = set(da; data=newdata)
        @test parent(da_new) === newdata
        @test dims(da_new) === dims(da)
    end
    @testset "set DimArray multiple keywords" begin
        newdata = fill(99, size(da))
        da_new = set(da; data=newdata, name=:updated)
        @test parent(da_new) === newdata
        @test DimensionalData.name(da_new) === :updated
    end
    @testset "set DimStack name" begin
        # Stacks don't have a single name, but we can test other keywords work
        s_new = set(s; metadata=Dict(:info => "test"))
        @test metadata(s_new) == Dict(:info => "test")
    end
end

@testset "_detect_step" begin
    using DimensionalData.Lookups: _detect_step
    @testset "AbstractRange" begin
        @test _detect_step(1:10) == 1
        @test _detect_step(1:2:10) == 2
        @test _detect_step(10:-1:1) == -1
        @test _detect_step(1.0:0.5:5.0) == 0.5
    end
    @testset "Regular Vector" begin
        @test _detect_step([1, 2, 3, 4]) == 1.0
        @test _detect_step([0.0, 0.5, 1.0, 1.5]) == 0.5
        @test _detect_step([10.0, 8.0, 6.0, 4.0]) == -2.0
    end
    @testset "Irregular Vector" begin
        @test _detect_step([1, 2, 4, 8]) === nothing
        @test _detect_step([1.0, 2.0, 2.5, 3.0]) === nothing
    end
    @testset "AutoValues" begin
        @test _detect_step(Lookups.AutoValues()) === Lookups.AutoStep()
    end
end

@testset "Sampling transitions" begin
    pts_da = da  # da has Points sampling
    int_da = interval_da  # interval_da has Intervals sampling

    @testset "Points to Intervals" begin
        # Setting Intervals on Points should work
        da_int = set(pts_da, X => Intervals(Center()), Y => Intervals(Start()))
        @test sampling(da_int) == (Intervals(Center()), Intervals(Start()))
        @test order(da_int) == order(pts_da)
    end
    @testset "Intervals to Points" begin
        # Setting Points on Intervals should work
        da_pts = set(int_da, X => Points(), Y => Points())
        @test sampling(da_pts) == (Points(), Points())
        @test order(da_pts) == order(int_da)
    end
    @testset "Locus shifting with Intervals" begin
        # Start, Center, End should shift lookup values appropriately
        start_da = set(int_da, Start())
        center_da = set(start_da, Center())
        end_da = set(start_da, End())
        @test locus(start_da) == (Start(), Start())
        @test locus(center_da) == (Center(), Center())
        @test locus(end_da) == (End(), End())
        # Round-trip should give same result
        @test set(end_da, Start()) ≈ start_da
    end
end

@testset "set with Explicit span" begin
    # Create a lookup with known bounds
    sampled = Sampled(1.0:3.0, ForwardOrdered(), Regular(1.0), Intervals(Center()), NoMetadata())
    dim_explicit = set(X(sampled), Explicit())
    @test span(dim_explicit) isa Explicit
    @test sampling(dim_explicit) isa Intervals
end

@testset "Categorical order detection" begin
    cat_lookup = Categorical([:z, :a, :m], Unordered(), NoMetadata())
    # Setting ForwardOrdered should sort the categorical
    sorted = set(cat_lookup, ForwardOrdered())
    @test order(sorted) == ForwardOrdered()
    @test parent(sorted) == [:a, :m, :z]

    # Setting ReverseOrdered should reverse-sort
    rsorted = set(cat_lookup, ReverseOrdered())
    @test order(rsorted) == ReverseOrdered()
    @test parent(rsorted) == [:z, :m, :a]
end

@testset "checkaxis" begin
    using DimensionalData.Dimensions: checkaxis
    d = X(1:5)
    @test checkaxis((d,), (Base.OneTo(5),)) == true
    @test_throws DimensionMismatch checkaxis((d,), (Base.OneTo(3),))
end

@testset "AutoValues handling" begin
    # AutoValues should be preserved (no-op)
    @test set(da, Lookups.AutoValues()) === da
    @test unsafe_set(da, Lookups.AutoValues()) === da
end

@testset "set dimension then lookup in one call" begin
    # Setting both dimension type and lookup properties together
    da_both = set(da, X => Ti(Sampled(sampling=Intervals(Start()))))
    @test dims(da_both, 1) isa Ti
    @test sampling(dims(da_both, 1)) == Intervals(Start())
end
