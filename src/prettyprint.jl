function printlimited(io, v::AbstractVector)
    s = string(eltype(v))*"["
    if length(v) > 5
        svals = "$(v[1]), $(v[2]), …, $(v[end-1]), $(v[end])"
    else
        svals = join((string(va) for va in v), ", ")
    end
    print(io, s*svals*"]")
end

# Thanks to Michael Abbott for the following function
function custom_show_nd(io::IO, A::AbstractArray{T, N}) where {T,N}
    o = ones(Int, length(size(A))-2)
    frame = A[:, :, o...]
    onestring = join(o, ", ")
    println(io, "[:, :, $(onestring)]")
    Base.print_matrix(IOContext(io, :compact => true, :limit=>true), frame)
    print(io, "\n[and ", prod(size(A,d) for d=3:N) - 1," more slices...]")
end

custom_show_nd(io::IO, A::AbstractArray{T, 2}) where {T} =
Base.print_matrix(IOContext(io, :compact => true, :limit=>true), A)

custom_show_nd(io::IO, A::AbstractArray{T, 1}) where {T} =
Base.show(IOContext(io, :compact => true, :limit=>true), A)

# Full printing version for dimensions
function Base.show(io::IO, ::MIME"text/plain", dim::AbDim)
    print(io, "dimension ")
    printstyled(io, name(dim); color=:red)
    if name(dim) ≠ string(nameof(typeof(dim)))
        print(io, " (type ")
        printstyled(io, nameof(typeof(dim)); color=:red)
        print(io, ")")
    end
    print(io, ": ")

    printstyled(io, "\nval: "; color=:green)
    _printdimval(io, val(dim))
    printstyled(io, "\ngrid: "; color=:yellow)
    show(io, grid(dim))
    printstyled(io, "\nmetadata: "; color=:blue)
    show(io, metadata(dim))
    printstyled(io, "\ntype: "; color=:cyan)
    show(io, typeof(dim))
end

# short printing version for dimensions
function Base.show(io::IO, dim::AbDim)
    printstyled(io, name(dim); color=:red)
    if name(dim) ≠ string(nameof(typeof(dim)))
        print(io, " (type ")
        printstyled(io, nameof(typeof(dim)); color=:red)
        print(io, ")")
    end
    print(io, ": ")

    _printdimval(io, val(dim))
end

_printdimval(io, A::AbstractArray) = printlimited(io, A)
_printdimval(io, x) = print(io, x)

# printing for DimensionalArray
function Base.show(io::IO, A::AbDimArray)
    l = nameof(typeof(A))
    printstyled(io, nameof(typeof(A)); color=:blue)
    if label(A) != ""
        print(io, " (named ")
        printstyled(io, label(A); color=:blue)
        print(io, ")")
    end

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
    dataA = data(A)
    print(io, summary(dataA), "\n")
    custom_show_nd(io, data(A))
end

Base.show(io::IO, ::MIME"text/plain", A::AbDimArray) = show(io, A)
