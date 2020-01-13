function Base.show(io::IO, A::AbDimArray)
    l = label(A) != "" ? label(A) : nameof(typeof(A))
    printstyled(io, l; color=:magenta)
    print(io, " with dimensions:\n")
    for d in dims(A)
        print(io, "  ", d, "\n")
    end
    if !isempty(refdims(A))
        print(io, " and referenced dimensions:\n")
        for d in refdims(A)
            print(io, "  ", d, "\n")
        end
    end
    print(io, "and")
    printstyled(io, " data:\n"; color=:green)
    show(IOContext(io, :compact => true), MIME("text/plain"), data(A))
end

Base.show(io::IO, ::MIME"text/plain", A::AbDimArray) = show(io, A)

function Base.show(io::IO, ::MIME"text/plain", dim::AbDim)
    printstyled(io, name(dim), ": "; color=:red)
    show(io, typeof(dim))
    printstyled(io, "\nval: "; color=:green)
    show(io, val(dim))
    printstyled(io, "\ngrid: "; color=:yellow)
    show(io, grid(dim))
    printstyled(io, "\nmetadata: "; color=:blue)
    show(io, metadata(dim))
end

function Base.show(io::IO, dim::AbDim)
    printstyled(io, name(dim), ": "; color=:red)
    print(io, val(dim))
end
