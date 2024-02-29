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
        Lookups.$f(x::Dimension) = $f(val(x))
        Lookups.$f(::Nothing) = false
        Lookups.$f(xs::DimTuple) = all(map($f, xs))
        Lookups.$f(x::Any) = $f(dims(x))
        Lookups.$f(x::Any, ds) = $f(dims(x, ds))
    end
end
