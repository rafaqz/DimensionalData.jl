
PrecompileTools.@compile_workload begin
    buffer = IOContext(IOBuffer(), :color=>true)
    for f in (zeros, ones, falses, trues, rand)
        x, y, z = X([:a, :b]), Y(10.0:10.0:30.0), Z()
        dimz = x, y
        A = f(x, y)
        da1 = DimArray(A, (x, y); name=:one)
        da2 = DimArray(Float32.(2A), (x, y); name=:two)
        da3 = DimArray(round.(Int, 3A), (x, y); name=:three)
        da4 = DimArray(cat(4A, 5A, 6A, 7A; dims=z); name=:exteradim)
        show(buffer, MIME"text/plain"(), da1)
        show(buffer, MIME"text/plain"(), da2)
        show(buffer, MIME"text/plain"(), da3)
        show(buffer, MIME"text/plain"(), da4)
        st1 = DimStack(da1, da2)
        show(buffer, MIME"text/plain"(), st1)
        st2 = DimStack(da1, da2, da3)
        show(buffer, MIME"text/plain"(), st2)
        st3 = DimStack(da1, da2, da3, da4)
        show(buffer, MIME"text/plain"(), st3)
        mst1 = merge(st1, st2)
        mst2 = merge(st1, st3)
    end
end
