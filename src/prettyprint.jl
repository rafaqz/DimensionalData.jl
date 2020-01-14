# Credit to Sebastian Pfitzner for `printlimited`
function printlimited(io, x; Δx = 0, Δy = 0)
    sz = displaysize(io)
    ctx = IOContext(io, :limit => true, :compact => true,
    :displaysize => (sz[1]-Δy, sz[2]-Δx))
    Base.print(ctx, x)
end

function Base.show(io::IO, A::AbDimArray)
    l = label(A) != "" ? label(A) : nameof(typeof(A))
    printstyled(io, l; color=:magenta)
    print(io, " with dimensions:\n")
    for d in dims(A)
        print(io, " ", d, "\n")
    end
    if !isempty(refdims(A))
        print(io, "and referenced dimensions:\n")
        for d in refdims(A)
            print(io, " ", d, "\n")
        end
    end
    print(io, "and")
    printstyled(io, " data: "; color=:green)
    show(IOContext(io, :compact => true), MIME("text/plain"), data(A))
end

Base.show(io::IO, ::MIME"text/plain", A::AbDimArray) = show(io, A)

# Full printing version for dimensions
function Base.show(io::IO, ::MIME"text/plain", dim::AbDim)
    print(io, "dimension ")
    printstyled(io, name(dim); color=:red)
    printstyled(io, "\nval: "; color=:green)
    printlimited(io, val(dim); Δx = 5)
    printstyled(io, "\ngrid: "; color=:yellow)
    show(io, grid(dim))
    printstyled(io, "\nmetadata: "; color=:blue)
    show(io, metadata(dim))
    printstyled(io, "\ntype: "; color=:cyan)
    show(io, typeof(dim))
end

# short printing version for dimensions
function Base.show(io::IO, dim::AbDim)
    printstyled(io, name(dim), ": "; color=:red)
    Δx = length(string(nameof(typeof(dim)))) + 2
    printlimited(io, val(dim); Δx = Δx)
end
