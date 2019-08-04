basetype(x) = basetype(typeof(x))
basetype(t::Type) = t.name.wrapper
