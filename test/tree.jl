using DimensionalData, Test

xdim, ydim = X(1:10), Y(1:15)
a = rand(xdim, ydim)
b = rand(Float32, xdim, ydim)
c = rand(Int, xdim, ydim)
st = DimStack((; a, b, c))

dt = DimensionalData.DimTree(st)
@test dt.b === st.b

DimensionalData.setgroup(dt, :g1, dt)
DimensionalData.setgroup(dt, :g2, st)

dims(DimStack(DimensionalData.groups(dt, :g2)))
 === 
st

DimensionalData.groups(dt)
