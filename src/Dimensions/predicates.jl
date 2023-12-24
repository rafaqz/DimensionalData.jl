for f in (
    :issampled,
    :iscategorical,
    :iscyclic,
    :isintervals,
    :ispoints,
    :isregular,
    :isexplicit,
    :isstart,
    :iscenter,
    :isend,
    :isordered,
    :isforward,
    :isreverse,
)
    @eval begin
        LookupArrays.$f(x::Dimension) = $f(val(x))
        LookupArrays.$f(::Nothing) = false
        LookupArrays.$f(xs::DimTuple) = all(map($f, xs))
        LookupArrays.$f(x::Any) = $f(dims(x))
        LookupArrays.$f(x::Any, ds) = $f(dims(x, ds))
    end
end
