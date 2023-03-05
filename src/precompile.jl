
SnoopPrecompile.@precompile_all_calls begin
    for f in (zeros, ones, falses, trues, rand)
        d1 = f(X(10:10:20), Y(10:10:20))
        d2 = f(X(10.0:10.0:20), Y(10.0:10:20.0), Z(10))
        d3 = f(X(2), Y(2))
        sprint(show, MIME"text/plain"(), d1)
        sprint(show, MIME"text/plain"(), d2)
        sprint(show, MIME"text/plain"(), d3)
    end
    d1 = ones(X(10.0:10:20.0), Y(10.0:10:20.0))
    d2 = falses(X(10.0:10:20.0), Y(10.0:10:20.0))
    st = DimStack(d1, d2)
    sum(st)
    sprint(show, MIME"text/plain"(), st)
end
