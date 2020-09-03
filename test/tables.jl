using DimensionalData, Tables, Test, DataFrames

using DimensionalData: key2dim, dim2key, DimTable, DimColumn, dimstride

@dim Tst

da = DimArray(
    ones(3, 2, 3), 
    (X([:a, :b, :c]), Y([10.0, 20.0]), Dim{:test}(1.0:1.0:3.0)), 
    "data"
)

@testset "dim2key" begin
    @test dim2key(X()) == :X
    @test dim2key(Tst()) == :Tst
    @test dim2key(Dim{:test}()) == :test 
end

@testset "key2dim" begin
    @test key2dim(:test) == Dim{:test}()
    @test key2dim(:X) == X()
    @test key2dim(:Ti) == Ti()
    @test key2dim(:Tst) == Tst()
end

@testset "dimstride" begin
    @test dimstride(da, X()) == 1
    @test dimstride(da, Y()) == 3
    @test dimstride(da, Dim{:test}()) == 6
end

@testset "DimArray Tables interface" begin
    @test Tables.istable(da) == true
    @test Tables.columnaccess(da) == true
    @test Tables.rowaccess(da) == false

    t = Tables.columns(da)
    @test Tables.columnnames(t) == (:X, :Y, :test, :data)
    @test t isa DimTable
    @test dims(t) == dims(da)
    @test Tables.columns(t) === t
    @test t[:X] isa DimColumn
    @test t[:data] isa Array
    @test length(t[:X]) == length(t[:Y]) == length(t[:test]) == 18

    sa = Tables.schema(da)
    st = Tables.schema(t)
    @test sa.names == st.names == (:X, :Y, :test, :data)
    @test sa.types == st.types == (Symbol, Float64, Float64, Float64)

    @test Tables.getcolumn(t, 1) == Tables.getcolumn(t, :X) == Tables.getcolumn(t, X) == 
        repeat([:a, :b, :c], 6)
    @test Tables.getcolumn(t, 2) == Tables.getcolumn(t, :Y) == 
        repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test Tables.getcolumn(t, 3) == Tables.getcolumn(t, :test) == 
        vcat(repeat([1.0], 6), repeat([2.0], 6), repeat([3.0], 6))
    @test Tables.getcolumn(t, 4) == Tables.getcolumn(t, :data) == 
        ones(3 * 2 * 3)
    @test Tables.getcolumn(t, Float64, 4, :data) == 
        ones(3 * 2 * 3)

end

@testset "DimColumn" begin
    c = DimColumn(dims(da, Y), dims(da))
    @test length(c) == length(da)
    @test size(c) == (length(da),)
    @test axes(c) == (Base.OneTo(length(da)),) 
    @test vec(c) == Array(c) == Vector(c) == 
        repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test c[1] == 10.0
    @test c[4] == 20.0
    @test c[7] == 10.0
    @test c[18] == 20.0
    @test_throws BoundsError c[-1]
    @test_throws BoundsError c[19]

    cX = DimColumn(dims(da, X), dims(da))
    @test vec(cX) == Array(cX) == Vector(cX) == repeat([:a, :b, :c], 6)

end

@testset "DataFrame conversion" begin
    @time t = DimensionalData.DimTable(da)
    @time df = DataFrame(t; copycols=true)
    @test names(df) == ["X", "Y", "test", "data"]
    Tables.columntype(df, :X)
    Tables.columntype(df, :data)

    @test Tables.getcolumn(df, 1) == Tables.getcolumn(df, :X) == 
        repeat([:a, :b, :c], 6)
    @test Tables.getcolumn(t, 2) == Tables.getcolumn(df, :Y) == 
        repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test Tables.getcolumn(df, 3) == Tables.getcolumn(df, :test) == 
        vcat(repeat([1.0], 6), repeat([2.0], 6), repeat([3.0], 6))
    @test Tables.getcolumn(t, 4) == Tables.getcolumn(t, :data) == 
        ones(3 * 2 * 3)
end
