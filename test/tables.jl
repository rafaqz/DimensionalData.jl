using DimensionalData, IteratorInterfaceExtensions, TableTraits, Tables, Test, DataFrames

using DimensionalData.Lookups, DimensionalData.Dimensions
using DimensionalData: DimTable, DimExtensionArray

x = X([:a, :b, :c])
y = Y([10.0, 20.0])
z = Z([3, 8])
d = Dim{:test}(1.0:1.0:3.0)
dimz = x, y, d
da2 = DimArray(fill(2, (3, 2, 3)), dimz; name=:data2)

@testset "DimArray Tables interface" begin
    @testset for dim_ref in ((), (z,))
        ref_names = name(dim_ref)
        ref_num = length(dim_ref)
        ref_size = prod(length, dim_ref; init=1)
        da = DimArray(ones(3, 2, 3), dimz; name=:data, refdims=dim_ref)

        nrows = prod(size(da)) * ref_size
        col_names = (:X, :Y, :test, ref_names..., :data)
        col_names_no_ref = (:X, :Y, :test, :data)
        col_eltypes = (Symbol, Float64, Float64, map(eltype, dim_ref)..., Float64)
        col_eltypes_no_ref = (Symbol, Float64, Float64, Float64)
        dim_vals = vec(collect(Iterators.product(dimz..., dim_ref...)))
        col_vals = [getindex.(dim_vals, i) for i in eachindex(first(dim_vals))]
        push!(col_vals, ones(nrows))

        ds = DimStack(da)
        t = DimTable(ds; refdims=dim_ref)
        @test t isa DimTable
        @test dims(t) === dims(da)
        @test parent(t) === ds
        t2 = Tables.columns(ds)
        @test t2 isa DimTable
        if isempty(dim_ref)
            @test Tables.columnnames(t2) == Tables.columnnames(t)
        end

        @test Tables.columns(t) === t
        @test length(t[:X]) == length(t[:Y]) == length(t[:test]) == nrows

        @test Tables.istable(typeof(t)) == Tables.istable(t) ==
            Tables.istable(typeof(da)) == Tables.istable(da) ==
            Tables.istable(typeof(ds)) == Tables.istable(ds) == true
        @test Tables.columnaccess(t) == Tables.columnaccess(da) ==
            Tables.columnaccess(ds) == true
        @test Tables.rowaccess(t) == Tables.rowaccess(ds) == Tables.rowaccess(ds) == false
        @test Tables.columnnames(t) == col_names

        alldims = combinedims(dims(ds), dim_ref)
        col_dims = (alldims..., fill(nothing, length(col_names) - length(alldims))...)
        @testset for (i, (col, dim, col_eltype)) in enumerate(
            zip(col_names, col_dims, col_eltypes),
        )
            col_val = Tables.getcolumn(t, i)
            @test col_val == Tables.getcolumn(t, col) == col_vals[i]

            if !isnothing(dim)
                @test col_val == Tables.getcolumn(t, dim)
            end
        end
        @test_throws ArgumentError Tables.getcolumn(t, :NotAColumn)
        @test_throws BoundsError Tables.getcolumn(t, length(col_names) + 1)

        sa = Tables.schema(da)
        sds = Tables.schema(ds)
        st = Tables.schema(t)

        @testset "consistency of DimStack and DimArray Tables interfaces" begin
            @test Tables.columnnames(da) == Tables.columnnames(ds) == sa.names == sds.names == col_names_no_ref
            @test sa.types == sds.types == col_eltypes_no_ref
            @test Tables.columntable(da) == Tables.columntable(ds)
        end

        isempty(dim_ref) || continue
        @testset "DimTable interface with no refdims consistent with DimStack/DimArray Tables interfaces" begin
            @test sa.names == col_names
            @test sa.types == col_eltypes
            @test Tables.columntable(da) == Tables.columntable(t)
        end
    end
end

da = DimArray(ones(3, 2, 3), dimz; name=:data)
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
