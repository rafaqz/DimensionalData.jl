using DimensionalData, Tables, Test, DataFrames

using DimensionalData: dimtypeof, dimkey, DimTable, DimColumn

@test dimtypeof(:test) == Dim{:test} 
@test dimtypeof(:X) == X
@test dimtypeof(:Ti) == Ti
@dim Tst
@test dimtypeof(:Tst) == Tst

@test dimkey(X()) == :X
@test dimkey(Tst()) == :Tst
@test dimkey(Dim{:test}()) == :test 

da = DimArray(rand(3, 3), (X([:a, :b, :c]), Dim{:test}(1.0:1.0:3.0)))
@test Tables.istable(da) == true
@test Tables.columnaccess(da) == true
@test Tables.rowaccess(da) == false

cols = Tables.columns(da)
@test cols isa DimTable
Tables.columnnames(cols)

c = DimColumn(dims(da, :test), da)
@test length(c) == length(da)
@test size(c) == (length(da),)
@test axes(c) == (Base.OneTo(length(da)),) 
@test vec(c) == Array(dc) == Vector(dc) == [1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0]

dcX = DimColumn(dims(da, X), da)
@test vec(dcX) == Array(dcX) == Vector(dcX) == [:a, :b, :c, :a, :b, :c, :a, :b, :c]

@time df = DataFrame(DimensionalData.DimTable(da); copycols=true)
@test names(df) == ["X", "test", "value"]


Tables.schema(da)
Tables.columnnames(da)
Tables.getcolumn(da, 1)
Tables.getcolumn(da, 2)
Tables.getcolumn(da, 3)
Tables.getcolumn(da, :X)
Tables.getcolumn(da, :test)
Tables.getcolumn(da, :value)
