using DimensionalData, Test, Extents

xdim, ydim = X(1:10), Y(1:15)
a = rand(xdim, ydim)
b = rand(Float32, xdim, ydim)
c = rand(Int, xdim, ydim)
st = DimStack((; a, b, c))

@testset "detlete!, pop!, only" begin
     dt = DimTree()
     dt.m = DimTree()
     dt.m.n = st
     @test_throws ArgumentError only(dt.m.n)
     @test DimStack(dt.m.n) === st
     delete!(dt.m.n, :c)
     @test pop!(dt.m.n, :b) === st.b
     @test only(dt.m.n) === st.a
     @test delete!(dt.m.n) == dt.m
     @test isempty(DimensionalData.branches(dt.m))
end

# We get an identical DimStack back out after conversion to/from DimTree
@testset "DimStack -> DimTree -> DimStack" begin
     dt = DimTree(st)
     dt.b1 = st
     dt.b2 = st
     @test DimStack(dt.b1) === DimStack(dt.b2) === st
end
      
@testset "extent" begin
     dt = DimTree()
     dt.b1 = st
     @test extent(dt) == extent(st)
end

@testset "Indexing matches stack indexing" begin
     dt = DimTree(st)
     dt.b1 = st
     dt.b2 = st
     dt_sliced = view(dt, X=Between(2, 4))
     @test DimStack(dt_sliced) === view(DimStack(dt), X(Between(2, 4)))
     @test DimStack(dt_sliced.b1) === view(DimStack(dt.b1), X(Between(2, 4)))
     @test DimStack(dt_sliced.b2) === view(DimStack(dt.b2), X(Between(2, 4)))
     dt_sliced = getindex(dt, X=Between(2, 4))
     @test DimStack(dt_sliced) == getindex(DimStack(dt), X(Between(2, 4)))
     @test DimStack(dt_sliced.b1) == getindex(DimStack(dt.b1), X(Between(2, 4)))
     @test DimStack(dt_sliced.b2) == getindex(DimStack(dt.b2), X(Between(2, 4)))
end

@testset "Mixed dim branches" begin
     xdim, ydim = map(DimensionalData.format, (X(1:10), Y(1:15)))
     z1, z2 = map(DimensionalData.format, (Z(["A", "B", "C"]), Z(["C", "D"])))
     a = rand(xdim, ydim; name=:a)
     b = rand(Float32, xdim, ydim; name=:b)
     c = rand(Int, xdim, ydim, z1; name=:c)
     d = rand(Int, xdim, z2; name=:d)
     dt = DimTree(a, b)
     dt.z1 = c
     dt.z2 = d
     @test dims(dt) == (xdim, ydim)
     @test dims(dt.z1) == (xdim, ydim, z1)
     @test dims(dt.z2) == (xdim, ydim, z2)
     @testset "Selectors must be shared by branches" begin
          @test dt[Z=At("C")] isa DimTree
          @test_throws DimensionalData.Lookups.SelectorError dt[Z=At("D")]
          # Not clear if this should warn when branches lack dims?
          @test_warn "dims were not found in object" dt[Y=At(10)]
     end
end