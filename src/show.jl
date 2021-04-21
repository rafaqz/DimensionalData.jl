
function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray{T,N}) where {T,N}
    lines = 4
    printstyled(io, string(nameof(typeof(A)), "{$T,$N}"); color=:blue)
    _printname(io, name(A))
    lines += _printdims(io, mime, dims(A))
    lines += _printrefdims(io, mime, refdims(A))
    println(io)
    ds = displaysize(io)
    ioctx = IOContext(io, :displaysize => (ds[1] - lines, ds[2]))
    _show_array(ioctx, mime, parent(A))
end

function Base.show(io::IO, mime::MIME"text/plain", dim::Dimension)
    get(io, :compact, false) && return _show_compact(io::IO, dim)

    printstyled(io, nameof(typeof(dim)); color=_dimcolor(io))
    if dim isa Dim
        printstyled(io, "{"; color=:red)
        printstyled(io, string(":", name(dim)); color=:yellow)
        printstyled(io, "}"; color=:red)
    else
        if nameof(typeof(dim)) != name(dim)
            _printname(io, name(dim))
        end
    end
    print(io, ": ")
    printstyled(io, "\n  val: ")
    _printdimindex(io, val(dim))

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
    printstyled(io, nameof(typeof(dim)); color=_dimcolor(io))
    _printdimval(io, dim)
    if name(dim) != nameof(typeof(dim))
        print(io, " (")
        print(io, name(dim))
        print(io, ")")
    end
    _printdimproperties(io, dim)
end
function _show_compact(io::IO, dim::Dim)
    color = _dimcolor(io)
    printstyled(io, "Dim{"; color=color)
    printstyled(io, string(":", name(dim)); color=:yellow)
    printstyled(io, "}"; color=color)
    _printdimval(io, dim)
    _printdimproperties(io, dim)
end

function _printdimval(io, dim::Dimension)
    if get(io, :show_dim_val, false)
        color = _dimcolor(io)
        printstyled(io, "("; color=color)
        printstyled(io, val(dim); color=:cyan)
        printstyled(io, ")"; color=color)
    end
end

_dimcolor(io) = get(io, :is_ref_dim, false) ? :magenta : :red

function _printname(io::IO, name)
    if !(name == Symbol("") || name isa NoName)
        print(io, " (")
        printstyled(io, string(name); color=:yellow)
        print(io, ")")
    end
end

# Note GeoData uses these
function _printdims(io::IO, mime, dims::Tuple)
    isempty(dims) && return 0
    print(io, " with dimensions: ")
    return _layout_dims(io, mime, dims)
end

function _printrefdims(io::IO, mime, refdims::Tuple)
    isempty(refdims) && return 0
    print(io, "and reference dimensions: ")
    ctx = IOContext(io, :is_ref_dim=>true, :show_dim_val=>true)
    lines = _layout_dims(ctx, mime, refdims)
    return lines + 1
end

function _layout_dims(io, mime, dims::Tuple)
    ctx = IOContext(io, :compact=>true)
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

function _printdimproperties(io, dim::Dimension)
    mode(dim) isa NoIndex && return nothing
    print(io, ": ")
    _printdimindex(io, val(dim))
    if !(mode(dim) isa AutoMode)
        print(io, " (")
        show(io, MIME"text/plain"(), mode(dim))
        print(io, ")")
    end
    return nothing
end

_printdimindex(io, x) = print(io, x)
_printdimindex(io, A::AbstractRange) = printstyled(io, A; color=:cyan)
function _printdimindex(io, v::AbstractVector)
    s = string(eltype(v)) * "["
    svals = 
    if length(v) > 2 && eltype(v) <: Dates.TimeType
        "$(v[1]), …, $(v[end])"
    elseif length(v) > 5
        "$(v[1]), $(v[2]), …, $(v[end-1]), $(v[end])"
    else
        join((string(va) for va in v), ", ")
    end
    printstyled(io, s * svals * "]"; color=:cyan)
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
