
function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray{T,N}) where {T,N}
    lines = 4
    printstyled(io, string(nameof(typeof(A)), "{$T,$N}"); color=:blue)
    _printname(io, name(A))
    lines += _printdims(io, mime, dims(A))
    lines += _printrefdims(io, mime, refdims(A))
    print(io, "and data: \n")
    ds = displaysize(io)
    ioctx = IOContext(io, :displaysize => (ds[1] - lines, ds[2]))
    _show_array(ioctx, mime, parent(A))
end

function Base.show(io::IO, mime::MIME"text/plain", dim::Dimension)
    get(io, :compact, false) && return _show_compact(io::IO, dim)

    printstyled(io, nameof(typeof(dim)); color=:red)
    print(io, " : ")
    printstyled(io, name(dim); color=:light_yellow)
    printstyled(io, " Dimension "; color=:light_yellow)
    printstyled(io, "\n  val: ")
    _printdimval(io, val(dim))

    if !(mode(dim) isa AutoMode)
        printstyled(io, "\n  mode: ")
        show(io, mime, mode(dim))
    end
    if !(metadata(dim) isa NoMetadata)
        printstyled(io, "\n  metadata: ")
        show(io, mime, metadata(dim))
    end
    println(io)
    show(io, mime, typeof(dim))
end

function Base.show(io::IO, mime::MIME"text/plain", metadata::Metadata{N}) where N
    print(io, "Metadata")
    if N !== Nothing
        print(io, "{")
        show(io, N)
        print(io, "}")
    end
    print(io, " of ")
    show(io, mime, val(metadata))
end
Base.show(io::IO, mime::MIME"text/plain", mode::IndexMode) = _printmode(io, mode)

function Base.show(io::IO, mime::MIME"text/plain", mode::AbstractSampled)
    _printmode(io, mode)
    print(io, " - ")
    _printorder(io, mode)
    print(io, " ")
    _printspan(io, mode)
    print(io, " ")
    _printsampling(io, mode)
end

function Base.show(io::IO, mime::MIME"text/plain", mode::AbstractCategorical)
    _printmode(io, mode)
    print(io, " - ")
    _printorder(io, mode)
end

# short printing version for dimensions
function _show_compact(io::IO, dim::Dimension)
    printstyled(io, nameof(typeof(dim)); color=:red)
    if name(dim) != nameof(typeof(dim))
        print(io, " (")
        printstyled(io, name(dim); color=:grey)
        print(io, ")")
    end
    _printdimproperties(io, dim)
end
function _show_compact(io::IO, dim::Dim)
    printstyled(io, "Dim{:$(name(dim))}"; color=:red)
    _printdimproperties(io, dim)
end

function _printname(io::IO, name)
    if !(name == Symbol("") || name isa NoName)
        print(io, " (")
        printstyled(io, string(name); color=:light_yellow)
        print(io, ")")
    end
end

# Note GeoData uses these
function _printdims(io::IO, mime, dims)
    length(dims) > 0 || return 0
    ctx = IOContext(io, :compact=>true)
    print(io, " with dimensions: ")

    # No mode, print one one line 
    if all(m -> m isa NoIndex, mode(dims))
        for d in dims[1:end-1]
            show(ctx, mime, d)
            print(io, ", ")
        end
        show(ctx, mime, dims[end])
        print(io, " ")
        return 0
    else # Dims get a line each
        lines = 1
        println(io)
        for d in dims
            print(io, "  ")
            show(ctx, mime, d)
            println(io)
            lines += 1
        end
        return lines
    end
end

function _printrefdims(io::IO, mime, refdims)
    lines = 0
    if !isempty(refdims)
        print(io, "and referenced dimensions:\n")
        lines += 1
        for d in refdims
            print(io, "  ")
            show(IOContext(io, :compact=>true), mime, d)
            println(io)
            lines += 1
        end
    end
    lines
end

function _printdimproperties(io, dim)
    mode(dim) isa NoIndex && return nothing
    print(io, ": ")
    _printdimval(io, val(dim))
    if !(mode(dim) isa AutoMode)
        print(io, " (")
        show(io, MIME"text/plain"(), mode(dim))
        print(io, ")")
    end
    return nothing
end

_printdimval(io, A::AbstractArray) = _printlimited(io, A)
_printdimval(io, A::AbstractRange) = print(io, A)
_printdimval(io, x) = print(io, x)

function _printlimited(io, v::AbstractVector)
    s = string(eltype(v))*"["
    if length(v) > 5
        svals = "$(v[1]), $(v[2]), …, $(v[end-1]), $(v[end])"
    else
        svals = join((string(va) for va in v), ", ")
    end
    print(io, s*svals*"]")
end

_printmode(io, mode) = print(io, nameof(typeof(mode)))
_printorder(io, mode) = print(io, nameof(typeof(order(mode))))
_printspan(io, mode) = print(io, nameof(typeof(span(mode))))
_printsampling(io, mode) = print(io, nameof(typeof(sampling(mode))))

# Thanks to Michael Abbott for the following function
function _show_array(io::IO, mime, A::AbstractArray{T,0}) where T
    Base.show(_ioctx(io, T), mime, A)
end
function _show_array(io::IO, mime, A::AbstractArray{T,1}) where T
    Base.show(_ioctx(io, T), mime, A)
end
function _show_array(io::IO, mime, A::AbstractArray{T,2}) where T
    Base.print_matrix(_ioctx(io, T), A)
end
function _show_array(io::IO, mime, A::AbstractArray{T,N}) where {T,N}
    o = ones(Int, N-2)
    frame = A[:, :, o...]
    onestring = join(o, ", ")
    println(io, "[:, :, $(onestring)]")
    Base.print_matrix(_ioctx(io, T), frame)
    print(io, "\n[and ", prod(size(A,d) for d=3:N) - 1," more slices...]")
end

function _ioctx(io, T)
    IOContext(io, :compact=>true, :limit=>true, :typeinfo=>T)
end
