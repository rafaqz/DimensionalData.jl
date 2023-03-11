
SnoopPrecompile.@precompile_all_calls begin
    for f in (zeros, ones, falses, trues, rand)
        A = [1.0 2.0 3.0; 4.0 5.0 6.0]
        x, y, z = X([:a, :b]), Y(10.0:10.0:30.0; metadata=Dict()), Z()
        dimz = x, y
        f(A) = A[X=1]
        da1 = DimArray(A, (x, y); name=:one)
        da2 = DimArray(Float32.(2A), (x, y); name=:two)
        da3 = DimArray(Int.(3A), (x, y); name=:three)
        da4 = DimArray(cat(4A, 5A, 6A, 7A; dims=3), (x, y, z); name=:exteradim)
        show(stdout, MIME"text/plain"(), da1)
        show(stdout, MIME"text/plain"(), da2)
        show(stdout, MIME"text/plain"(), da3)
        show(stdout, MIME"text/plain"(), da4)
        st = DimStack(da1, da2)
        show(stdout, MIME"text/plain"(), st)
        st = DimStack(da1, da2, da3)
        show(stdout, MIME"text/plain"(), st)
        st = DimStack(da1, da2, da3, da4)
        show(stdout, MIME"text/plain"(), st)
    end
end
