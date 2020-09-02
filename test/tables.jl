using DimensionalData, Tables, Test, DataFrames

using DimensionalData: key2dim, dimkey, DimTable, DimColumn, dimstride

@dim Tst

da = DimArray(ones(3, 2, 3), (X([:a, :b, :c]), Y([10.0, 20.0]), Dim{:test}(1.0:1.0:3.0)))

@testset "dimkey" begin
    @test dimkey(X()) == :X
    @test dimkey(Tst()) == :Tst
    @test dimkey(Dim{:test}()) == :test 
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
    @inferred dimstride(da, X())
end

@testset "DimArray Tables interface" begin
    @test Tables.istable(da) == true
    @test Tables.columnaccess(da) == true
    @test Tables.rowaccess(da) == false
    @test Tables.columnnames(da) == (:X, :Y, :test, :value)

    s = Tables.schema(da)
    @test s.names == (:X, :Y, :test, :value)
    @test s.types == (Symbol, Float64, Float64, Float64)

    t = Tables.columns(da)
    @test t isa DimTable
    @test Tables.columnnames(t) == (:X, :Y, :test, :value)
    @test dims(t) == dims(da)
end

@testset "DimColumn" begin
    c = DimColumn(dims(da, Y), dims(da))
    @test length(c) == length(da)
    @test size(c) == (length(da),)
    @test axes(c) == (Base.OneTo(length(da)),) 
    @test vec(c) == Array(c) == Vector(c) == 
        repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)

    cX = DimColumn(dims(da, X), dims(da))
    @test vec(cX) == Array(cX) == Vector(cX) == repeat([:a, :b, :c], 6)
end

@testset "DataFrame conversion" begin
    @time df = DataFrame(DimensionalData.DimTable(da); copycols=true)
    @test names(df) == ["X", "Y", "test", "value"]

    @test Tables.getcolumn(da, 1) == Tables.getcolumn(da, :X) == 
        repeat([:a, :b, :c], 6)
    @test Tables.getcolumn(da, 2) == Tables.getcolumn(da, :Y) == 
        repeat([10.0, 10.0, 10.0, 20.0, 20.0, 20.0], 3)
    @test Tables.getcolumn(da, 3) == Tables.getcolumn(da, :test) == 
        vcat(repeat([1.0], 6), repeat([2.0], 6), repeat([3.0], 6))
    @test Tables.getcolumn(da, 4) == Tables.getcolumn(da, :value) == ones(3 * 2 * 3)
end
