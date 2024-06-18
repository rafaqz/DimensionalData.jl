using DimensionalData, IteratorInterfaceExtensions, TableTraits, Tables, Test, DataFrames

using DimensionalData.Lookups, DimensionalData.Dimensions
using DimensionalData: DimTable, DimExtensionArray

x = X([:a, :b, :c])
y = Y([10.0, 20.0])
d = Dim{:test}(1.0:1.0:3.0)
dimz = x, y, d
da = DimArray(ones(3, 2, 3), dimz; name=:data)
da2 = DimArray(fill(2, (3, 2, 3)), dimz; name=:data2)

@testset "DimArray Tables interface" begin
    ds = DimStack(da)
    t = Tables.columns(ds)
    @test t isa DimTable
    @test dims(t) === dims(da)
    @test parent(t) === ds

    @test Tables.columns(t) === t
    @test length(t[:X]) == length(t[:Y]) == length(t[:test]) == 18

    @test Tables.istable(typeof(t)) == Tables.istable(t) ==
          Tables.istable(typeof(da)) == Tables.istable(da) ==
          Tables.istable(typeof(ds)) == Tables.istable(ds) == true
    @test Tables.columnaccess(t) == Tables.columnaccess(da) == Tables.columnaccess(ds) == true
    @test Tables.rowaccess(t) == Tables.rowaccess(ds) == Tables.rowaccess(ds) == false
    @test Tables.columnnames(t) == Tables.columnnames(da) == Tables.columnnames(ds) == (:X, :Y, :test, :data)

    sa = Tables.schema(da)
    sds = Tables.schema(ds)
    st = Tables.schema(t)
    @test sa.names == sds.names == st.names == (:X, :Y, :test, :data)
    @test sa.types == sds.types == st.types == (Symbol, Float64, Float64, Float64)

    @test Tables.getcolumn(t, 1) == Tables.getcolumn(t, :X) == Tables.getcolumn(t, X) ==
          Tables.getcolumn(ds, 1) == Tables.getcolumn(ds, :X) == Tables.getcolumn(ds, X) ==
          Tables.getcolumn(da, 1) == Tables.getcolumn(da, :X) == Tables.getcolumn(da, X) ==
          Tables.getcolumn(da, 1)[:] == repeat([:a, :b, :c], 6)
    @test Tables.getcolumn(t, 2) == Tables.getcolumn(t, :Y) ==
          Tables.getcolumn(da, 2) == Tables.getcolumn(da, :Y) ==
          Tables.getcolumn(ds, 2) == Tables.getcolumn(ds, :Y) ==
          Tables.getcolumn(ds, 2)[:] == repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test Tables.getcolumn(t, 3) == Tables.getcolumn(t, :test) ==
          Tables.getcolumn(da, 3) == Tables.getcolumn(da, :test) ==
          Tables.getcolumn(ds, 3) == Tables.getcolumn(ds, :test) ==
          Tables.getcolumn(ds, 3)[:] == vcat(repeat([1.0], 6), repeat([2.0], 6), repeat([3.0], 6))
    @test Tables.getcolumn(t, 4) == Tables.getcolumn(t, :data) ==
          Tables.getcolumn(da, 4) == Tables.getcolumn(da, :data) ==
          Tables.getcolumn(ds, 4) == Tables.getcolumn(ds, :data) ==
          Tables.getcolumn(ds, 4)[:] == ones(3 * 2 * 3)
    @test Tables.getcolumn(t, Float64, 4, :data) == ones(3 * 2 * 3)
    @test Tables.getcolumn(t, Float64, 2, :Y) == Tables.getcolumn(da, Float64, 2, :Y) ==
          Tables.getcolumn(ds, Float64, 2, :Y) ==
          Tables.getcolumn(ds, Float64, 2, :Y)[:] == repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test_throws ArgumentError Tables.getcolumn(t, :NotAColumn)
    @test_throws BoundsError Tables.getcolumn(t, 5)
end

@testset "DimArray TableTraits interface" begin
    ds = DimStack(da)
    t = DimTable(ds)
    for x in (da, ds, t)
        x = da
        @test IteratorInterfaceExtensions.isiterable(x)
        @test TableTraits.isiterabletable(x)
        @test collect(Tables.namedtupleiterator(x)) == collect(IteratorInterfaceExtensions.getiterator(x))
    end
end

@testset "DataFrame conversion" begin
    ds = DimStack(da, da2)
    @time t = DimTable(ds)
    @time df = DataFrame(t; copycols=true)
    @test names(df) == ["X", "Y", "test", "data", "data2"]
    @test Tables.columntype(df, :X) == Symbol
    @test Tables.columntype(df, :data) == Float64
    @test Tables.columntype(df, :data2) == Int

    @test Tables.getcolumn(df, 1)[:] == Tables.getcolumn(df, :X)[1:18] ==
        repeat([:a, :b, :c], 6)
    @test Tables.getcolumn(t, 2) == Tables.getcolumn(df, :Y) ==
        repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test Tables.getcolumn(df, 3) == Tables.getcolumn(df, :test) ==
        vcat(repeat([1.0], 6), repeat([2.0], 6), repeat([3.0], 6))
    @test Tables.getcolumn(t, 4) == Tables.getcolumn(t, :data) ==
        ones(3 * 2 * 3)
    @test Tables.getcolumn(t, 5) == Tables.getcolumn(t, :data2) ==
        fill(2, 3 * 2 * 3)
end

@testset "Mixed size" begin
    da1 = DimArray(reshape(11:28, (3, 2, 3)), (x, y, d); name=:data1)
    da2 = DimArray(reshape(1.0:6.0, (2, 3)), (y, d); name=:data2)
    ds = DimStack(da1, da2)
    @time t = DimTable(ds)
    @time df = DataFrame(t; copycols=true)
    @test names(df) == ["X", "Y", "test", "data1", "data2"]
    @test Tables.columntype(df, :X) == Symbol
    @test Tables.columntype(df, :data1) == Int
    @test Tables.columntype(df, :data2) == Float64

    @test Tables.getcolumn(df, 1)[:] == Tables.getcolumn(df, :X)[1:18] ==
        repeat([:a, :b, :c], 6)
    @test Tables.getcolumn(t, 2) == Tables.getcolumn(df, :Y) ==
        repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test Tables.getcolumn(df, 3) == Tables.getcolumn(df, :test) ==
        vcat(repeat([1.0], 6), repeat([2.0], 6), repeat([3.0], 6))
    @test Tables.getcolumn(t, 4) == Tables.getcolumn(t, :data1) == 11:28
    @test Tables.getcolumn(t, 5) == Tables.getcolumn(t, :data2) == vcat(([x, x, x] for x in 1.0:6.0)...)
end

@testset "dim methods" begin
    ds = DimStack(da)
    @test dims(ds) == dims(da)
    @test lookup(ds) == lookup(dims(da))
end

@testset "one dimension tables" begin
    a = DimVector(1:3, x; name=:a)
    b = DimVector(4:6, x; name=:b)
    s = DimStack((a, b))
    @test Tables.columntable(a) == (X=[:a, :b, :c], a=1:3,)
    @test Tables.columntable(s) == (X=[:a, :b, :c], a=1:3, b=4:6)
end

@testset "zero dimension tables" begin
    a = DimArray(fill(1), (); name=:a);
    b = DimArray(fill(2), (); name=:b);
    ds = DimStack((a, b))
    @test Tables.columntable(a) == (a = [1],)
    @test Tables.columntable(ds) == (a = [1], b = [2])
end

@testset "DimTable layersfrom" begin
    a = DimArray(rand(32, 32, 5, 3), (X,Y,Dim{:band},Ti))
    t1 = DimTable(a)
    t2 = DimTable(a, layersfrom=Dim{:band})
    @test Tables.columnnames(t1) == (:X, :Y, :band, :Ti, :value)
    @test Tables.columnnames(t2) == (:X, :Y, :Ti, :band_1, :band_2, :band_3, :band_4, :band_5)
    @test length(t1.X) == (32 * 32 * 5 * 3)
    @test length(t2.X) == (32 * 32 * 3)
end

@testset "DimTable mergelayers" begin
    a = DimStack([DimArray(rand(32, 32, 3), (X,Y,Ti)) for _ in 1:3])
    b = DimArray(rand(32, 32, 3), (X,Y,Dim{:band}))
    t1 = DimTable(a, mergedims=(:X,:Y)=>:geometry)
    t2 = DimTable(a, mergedims=(:X,:Y,:Z)=>:geometry) # Merge missing dimension
    t3 = DimTable(a, mergedims=(X,:Y,Ti)=>:dimensions) # Mix symbols and dimensions
    t4 = DimTable(b, mergedims=(:X,:Y)=>:geometry) # Test DimArray
    @test Tables.columnnames(t1) == (:Ti, :geometry, :layer1, :layer2, :layer3)
    @test Tables.columnnames(t2) == (:Ti, :geometry, :layer1, :layer2, :layer3)
    @test Tables.columnnames(t3) == (:dimensions, :layer1, :layer2, :layer3)
    @test Tables.columnnames(t4) == (:band, :geometry, :value)
end
