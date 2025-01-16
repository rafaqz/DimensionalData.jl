using DimensionalData, Test, Extents

xdim, ydim = X(1:10), Y(1:15)
a = rand(xdim, ydim)
b = rand(Float32, xdim, ydim)
c = rand(Int, xdim, ydim)
st = DimStack((; a, b, c))

dt = DimensionalData.DimTree(st)
@test dt.b === st.b

DimensionalData.setgroup(dt, :g1, dt)
DimensionalData.setgroup(dt, :g2, st)
      
@test extent(dt) == Extent(X = (1, 10), Y = (1, 15))

# We get an identical DimStack back out after conversion to/from DimTree
@test DimStack(DimensionalData.groups(dt, :g1)) === 
      DimStack(DimensionalData.groups(dt, :g2)) === st

dt_sliced = dt[X(Between(2, 4))]