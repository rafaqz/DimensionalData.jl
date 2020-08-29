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

da = DimArray(ones(3, 3), (X([:a, :b, :c]), Dim{:test}(1.0:1.0:3.0)))
@test Tables.istable(da) == true
@test Tables.columnaccess(da) == true
@test Tables.rowaccess(da) == false
@test Tables.columnnames(da) == (:X, :test, :value)

s = Tables.schema(da)
@test s.names == (:X, :test, :value)
@test s.types == (Symbol, Float64, Float64)

t = Tables.columns(da)
@test t isa DimTable
Tables.columnnames(t)
@test dims(t) == dims(da)

c = DimColumn(dims(da, :test), da)
@test length(c) == length(da)
@test size(c) == (length(da),)
@test axes(c) == (Base.OneTo(length(da)),) 
@test vec(c) == Array(c) == Vector(c) == [1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0]

cX = DimColumn(dims(da, X), da)
@test vec(cX) == Array(cX) == Vector(cX) == [:a, :b, :c, :a, :b, :c, :a, :b, :c]

@time df = DataFrame(DimensionalData.DimTable(da); copycols=true)
@test names(df) == ["X", "test", "value"]

@test Tables.getcolumn(da, 1) == Tables.getcolumn(da, :X) == 
    [:a, :b, :c, :a, :b, :c, :a, :b, :c] 
@test Tables.getcolumn(da, 2) == Tables.getcolumn(da, :test) == 
    [1.0, 1.0, 1.0, 2.0, 2.0, 2.0, 3.0, 3.0, 3.0]
@test Tables.getcolumn(da, 3) == Tables.getcolumn(da, :value) == 
    [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
