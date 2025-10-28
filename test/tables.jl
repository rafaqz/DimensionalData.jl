using DataFrames
using Dates
using DimensionalData
using IteratorInterfaceExtensions
using Random
using TableTraits
using Tables
using Test

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
            @testset for (i, (col, dim, col_eltype)) in enumerate(
                zip(col_names, col_dims, col_eltypes),
            )
                @test col_vals[i] == Tables.getcolumn(da, col) == Tables.getcolumn(ds, col) ==
                    Tables.getcolumn(da, i) == Tables.getcolumn(ds, i)

                if !isnothing(dim)
                    @test col_vals[i] == Tables.getcolumn(da, dim) ==
                        Tables.getcolumn(ds, dim) == Tables.getcolumn(da, typeof(dim)) ==
                        Tables.getcolumn(ds, typeof(dim))
                end
            end
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
    b = DimArray(rand(32, 32, 3), (X, Y, Dim{:band}))
    t1 = DimTable(a, mergedims=(:X, :Y) => :geometry)
    t2 = DimTable(a, mergedims=(:X, :Y, :Z) => :geometry) # Merge missing dimension
    t3 = DimTable(a, mergedims=(X, :Y, Ti) => :dimensions) # Mix symbols and dimensions
    t4 = DimTable(b, mergedims=(:X, :Y) => :geometry) # Test DimArray
    @test Tables.columnnames(t1) == (:Ti, :geometry, :layer1, :layer2, :layer3)
    @test Tables.columnnames(t2) == (:Ti, :geometry, :layer1, :layer2, :layer3)
    @test Tables.columnnames(t3) == (:dimensions, :layer1, :layer2, :layer3)
    @test Tables.columnnames(t4) == (:band, :geometry, :value)
end

@testset "Materialize from table" begin
    a = DimArray(rand(UInt8, 100, 100), (X(100:-1:1), Y(-250:5:249)))
    b = DimArray(rand(Float32, 100, 100), (X(100:-1:1), Y(-250:5:249)))
    c = DimArray(rand(Float64, 100, 100), (X(100:-1:1), Y(-250:5:249)))
    ds = DimStack((a=a, b=b, c=c))
    t = DataFrame(ds)
    t1 = Random.shuffle(t)
    t2 = filter(r -> r.Y != -250, t)
    t3 = copy(t1)
    t3.X .+= rand(nrow(t1)) .* 1e-7 # add some random noise to check if precision works

    tabletypes = (Tables.rowtable, Tables.columntable, DataFrame)

    for type in tabletypes
        t = type(t)
        t1 = type(t1)
        t2 = type(t2)
        t3 = type(t3)
        @testset "All dimensions passed (using $type)" begin
            # Restore DimArray from shuffled table
            for table = (t1, t3)
                @test all(DimArray(table, dims(ds)) .== a)
                @test all(DimArray(table, dims(ds), name="a") .== a)
                @test all(DimArray(table, dims(ds), name="b") .== b)
                @test all(DimArray(table, dims(ds), name="c") .== c)
            end

            # Restore DimArray from table with missing rows
            @test all(DimArray(t2, dims(ds), name="a")[Y(2:100)] .== a[Y(2:100)])
            @test all(DimArray(t2, dims(ds), name="b")[Y(2:100)] .== b[Y(2:100)])
            @test all(DimArray(t2, dims(ds), name="c")[Y(2:100)] .== c[Y(2:100)])
            @test DimArray(t2, dims(ds), name="a")[Y(1)] .|> ismissing |> all
            @test DimArray(t2, dims(ds), name="b")[Y(1)] .|> ismissing |> all
            @test DimArray(t2, dims(ds), name="c")[Y(1)] .|> ismissing |> all
            @test DimArray(t2, dims(ds), name="a")[Y(2:100)] .|> ismissing .|> (!) |> all
            @test DimArray(t2, dims(ds), name="b")[Y(2:100)] .|> ismissing .|> (!) |> all
            @test DimArray(t2, dims(ds), name="c")[Y(2:100)] .|> ismissing .|> (!) |> all

            # Restore DimStack from shuffled table
            restored_stack = DimStack(t1, dims(ds))
            @test all(restored_stack.a .== ds.a)
            @test all(restored_stack.b .== ds.b)
            @test all(restored_stack.c .== ds.c)

            # Restore DimStack from table with missing rows
            restored_stack = DimStack(t2, dims(ds))
            @test all(restored_stack.a[Y(2:100)] .== ds.a[Y(2:100)])
            @test all(restored_stack.b[Y(2:100)] .== ds.b[Y(2:100)])
            @test all(restored_stack.c[Y(2:100)] .== ds.c[Y(2:100)])
            @test restored_stack.a[Y(1)] .|> ismissing |> all
            @test restored_stack.b[Y(1)] .|> ismissing |> all
            @test restored_stack.c[Y(1)] .|> ismissing |> all
            @test restored_stack.a[Y(2:100)] .|> ismissing .|> (!) |> all
            @test restored_stack.b[Y(2:100)] .|> ismissing .|> (!) |> all
            @test restored_stack.c[Y(2:100)] .|> ismissing .|> (!) |> all
        end

        @testset "Dimensions automatically detected (using $type)" begin
            da3 = DimArray(t)
            # Awkward test, see https://github.com/rafaqz/DimensionalData.jl/issues/953
            # If Dim{:X} == X then we can just test for equality
            @test lookup(dims(da3, :X)) == lookup(dims(a, X))
            @test lookup(dims(da3, :Y)) == lookup(dims(a, Y))
            @test parent(da3) == parent(a)

            for table in (t1, t3)
                da = DimArray(table)
                @test parent(da[X = At(100:-1:1), Y = At(-250:5:249)]) == parent(a)
                ds_ = DimStack(table)
                @test keys(ds_) == (:a, :b, :c)
                @test parent(ds_.a[X = At(100:-1:1), Y = At(-250:5:249)]) == parent(a)
 
            end
        end

        @testset "Dimensions partially specified (using $type)" begin
            for table in (t1, t3)
                # setting the order returns ordered dimensions
                da = DimArray(table, (X(Sampled(order = ReverseOrdered())), Y(Sampled(order=ForwardOrdered()))))
                @test dims(da, X) == dims(a, X)
                @test dims(da, Y) == dims(a, Y)
            end
            # passing in dimension types works
            @test DimArray(t, (X, Y)) == a
            @test parent(DimArray(t, (:X, Y))) == parent(a)
            @test parent(DimArray(t, (:X, :Y))) == parent(a)
            # passing in dimensions works for unconventional dimension names
            A = rand(dimz, name = :a)
            table = type(A)
            @test DimArray(table, (X, Y(Sampled(span = Irregular())), :test)) == A
            # Specifying dimensions types works even if it's illogical.
            dat = DimArray(t, (X(Sampled(span = Irregular(), order = Unordered())), Y(Categorical())))
            x, y = dims(dat)
            @test !isregular(x)
            @test !isordered(x)
            @test iscategorical(y)
            @test isordered(y) # this is automatically detected
        end
    end
end

@testset "DimTable preservedims" begin
    x, y, t = X(1.0:32.0), Y(1.0:10.0), Ti(DateTime.([2001, 2002, 2003]))
    st = DimStack([rand(x, y, t; name) for name in [:a, :b, :c]])
    A = rand(x, y, Dim{:band}(1:3); name=:vals)
    t1 = DimTable(st, preservedims=(X, Y))
    a3 = Tables.getcolumn(t1, :a)[3]
    @test Tables.columnnames(t1) == propertynames(t1) == (:Ti, :a, :b, :c)
    @test a3 == st.a[Ti=3]
    @test dims(a3) == dims(st, (X, Y))
    t2 = DimTable(A; preservedims=:band)
    val10 = Tables.getcolumn(t2, :vals)[10]
    @test Tables.columnnames(t2) == propertynames(t2) == (:X, :Y, :vals)
    @test val10 == A[X(10), Y(1)]
    @test dims(val10) == dims(A, (:band,))
    @testset "preservedims with mergedims" begin
        t3 = DimTable(A; mergedims=(X, Y) => :geometry, preservedims=:band)
        @test only(dims(t3)) isa Dim{:geometry}
        @test Tables.getcolumn(t2, :vals)[1] isa DimArray
    end
end

@testset "DimTable NamedTuple" begin
    @testset "Vector of NamedTuple" begin
        da = DimArray([(; a=1.0f0i, b=2.0i) for i in 1:10], X)
        t = DimTable(da)
        s = Tables.schema(t)
        @test s.names == (:X, :a, :b)
        @test s.types == (Int, Float32, Float64)
        @test all(t.a .=== 1.0f0:10.0f0)
        @test all(t.b .=== 2.0:2.0:20.0)
    end

    @testset "Matrix of NamedTuple" begin
        da = [(; a=1.0f0x*y, b=2.0x*y) for x in X(1:10), y in Y(1:5)]
        t = DimTable(da);
        s = Tables.schema(t)
        @test s.names == (:X, :Y, :a, :b)
        @test s.types == (Int, Int, Float32, Float64)
        @test all(t.a .=== reduce(vcat, [1.0f0y:y:10.0f0y for y in 1:5]))
        @test all(t.b .=== reduce(vcat, [2.0y:2.0y:20.0y for y in 1:5]))
    end
    @testset "Matrix of NamedTuple with preservedims" begin
        da = [(; a=1.0f0x*y, b=2.0x*y) for x in X(1:10), y in Y(1:5)]
        t = DimTable(da; preservedims=X);
        s = Tables.schema(t)
        @test s.names == (:Y, :a, :b)
        @test s.types[1] <: Int
        @test s.types[2] <: DimVector
        @test s.types[2] <: DimVector
        @test all(t.a .== [[1.0f0x*y for x in X(1:10)] for y in Y(1:5)])
        @test all(t.b .== [[2.0x*y for x in X(1:10)] for y in Y(1:5)])
    end
end
