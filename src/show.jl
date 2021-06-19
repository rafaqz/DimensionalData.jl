function Base.summary(io::IO, A::AbstractDimArray{T,N}) where {T,N}
    if N == 0  
        print(io, "0-dimensional ")
    elseif N == 1
        print(io, size(A, 1), "-element ")
    else
        print(io, join(size(A), "×"), " ")
    end
    printstyled(io, string(nameof(typeof(A)), "{$T,$N}"); color=:blue)
end

function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray{T,N}) where {T,N}
    lines = 0
    summary(io, A)
    _printname(io, name(A))
    lines += _printdims(io, mime, dims(A))
    !(isempty(dims(A)) || isempty(refdims(A))) && println(io)
    lines += _printrefdims(io, mime, refdims(A))
    println(io)
    ds = displaysize(io)
    ioctx = IOContext(io, :displaysize => (ds[1] - lines, ds[2]))

    # Printing the array data is optional, subtypes can 
    # show other things here instead.
    show_after(ioctx, mime, A)

    return nothing
end

function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    printstyled(io, nameof(typeof(stack)), color=:blue)
    _printdims(io, mime, dims(stack))
    nlayers = length(keys(stack))
    layers_str = nlayers == 1 ? "layer" : "layers"
    printstyled(io, "\nand "; color=:light_black) 
    print(io, "$nlayers $layers_str:\n")
    maxlen = reduce(max, map(length ∘ string, keys(stack)))
    for key in keys(stack)
        layer = stack[key]
        pkey = rpad(key, maxlen)
        printstyled(io, "  :$pkey", color=:yellow)
        print(io, string(" ", eltype(layer)))
        field_dims = DD.dims(layer)
        n_dims = length(field_dims)
        printstyled(io, " dims: "; color=:light_black)
        if n_dims > 0
            for (d, dim) in enumerate(field_dims)
                _show_dimname(io, dim)
                d != length(field_dims) && print(io, ", ")
            end
            print(io, " (")
            for (d, dim) in enumerate(field_dims)
                print(io, "$(length(dim))")
                d != length(field_dims) && print(io, '×')
            end
            print(io, ')')
        end
        print(io, '\n')
    end

    md = metadata(stack)
    if !(md isa NoMetadata)
        n_metadata = length(md)
        if n_metadata > 0
            printstyled(io, "\nwith "; color=:light_black)
            show(io, mime, md)
        end
    end

    # Show anything else subtypes want to append
    show_after(io, mime, stack)

    return nothing
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
    printstyled(io, "\n  val: "; color=:light_black)
    _printdimindex(io, val(dim))

    if !(mode(dim) isa AutoMode)
        printstyled(io, "\n  mode: "; color=:light_black)
        show(io, mime, mode(dim))
    end
    if !(metadata(dim) isa NoMetadata)
        printstyled(io, "\n  metadata: "; color=:light_black)
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
    printstyled(io, " of "; color=:light_black)
    show(io, mime, val(metadata))
end
Base.show(io::IO, mime::MIME"text/plain", mode::IndexMode) = _printmode(io, mode)

function Base.show(io::IO, mime::MIME"text/plain", mode::AbstractSampled)
    _printmode(io, mode)
    print(io, ": ")
    _printorder(io, mode)
    print(io, " ")
    _printspan(io, mode)
    print(io, " ")
    _printsampling(io, mode)
end

function Base.show(io::IO, mime::MIME"text/plain", mode::AbstractCategorical)
    _printmode(io, mode)
    print(io, ": ")
    _printorder(io, mode)
end

# Semi-interface methods for adding addional `show` text
# for AbstractDimArray/AbstractDimStack subtypes
# TODO actually document in the interface
show_after(io, mime, stack::DimStack) = nothing
show_after(io::IO, mime, A::AbstractDimArray) = show_array(io, mime, parent(A))

# Showing the array is optional for AbstractDimArray
# `show_array` must be called from `show_after`.
function show_array(io::IO, mime, A::AbstractArray{T,0}) where T
    print(_ioctx(io, T), "\n", A[])
end
function show_array(io::IO, mime, A::AbstractArray{T,1}) where T
    Base.print_matrix(_ioctx(io, T), A)
end
function show_array(io::IO, mime, A::AbstractArray{T,2}) where T
    Base.print_matrix(_ioctx(io, T), A)
end
function show_array(io::IO, mime, A::AbstractArray{T,N}) where {T,N}
    o = ones(Int, N-2)
    frame = A[:, :, o...]
    onestring = join(o, ", ")
    println(io, "[:, :, $(onestring)]")
    Base.print_matrix(_ioctx(io, T), frame)
    nremaining = prod(size(A, d) for d=3:N) - 1
    nremaining > 0 && print(io, "\n[and ", nremaining," more slices...]")
end

function _show_dimname(io, dim::Dim)
    color = DD._dimcolor(io)
    printstyled(io, "Dim{"; color=color)
    printstyled(io, string(":", name(dim)); color=:yellow)
    printstyled(io, "}"; color=color)
end
function _show_dimname(io, dim::Dimension)
    printstyled(io, DD.dim2key(dim); color = DD._dimcolor(io))
end

# short printing version for dimensions
function _show_compact(io::IO, dim::Dimension)
    nm = nameof(typeof(dim))
    nchars = length(string(nm))
    printstyled(io, nm; color=_dimcolor(io))
    if name(dim) != nm
        print(io, " (")
        print(io, name(dim))
        print(io, ")")
        nchars += length(string(name(dim))) + 3
    end
    _printdimproperties(io, dim, nchars)
end
function _show_compact(io::IO, dim::Dim)
    color = _dimcolor(io)
    printstyled(io, "Dim{"; color=color)
    printstyled(io, string(":", name(dim)); color=:yellow)
    printstyled(io, "}"; color=color)
    nchars = 5 + length(string(name(dim)))
    _printdimproperties(io, dim, nchars)
end

_dimcolor(io) = get(io, :is_ref_dim, false) ? :magenta : :red

function _printname(io::IO, name)
    if !(name == Symbol("") || name isa NoName)
        printstyled(io, string(" :", name); color=:yellow)
    end
end

function _printdims(io::IO, mime, dims::Tuple)
    if isempty(dims) 
        print(io, ": ")
        return 0
    end
    printstyled(io, " with dimensions: "; color=:light_black)
    return _layout_dims(io, mime, dims)
end

function _printrefdims(io::IO, mime, refdims::Tuple)
    if isempty(refdims) 
        return 0
    end
    printstyled(io, "and reference dimensions: "; color=:light_black)
    ctx = IOContext(io, :is_ref_dim=>true, :show_dim_val=>true)
    lines = _layout_dims(ctx, mime, refdims)
    return lines
end

function _layout_dims(io, mime, dims::Tuple)
    length(dims) > 0 || return 0
    ctx = IOContext(io, :compact=>true)
    if all(m -> m isa NoIndex, mode(dims))
        for d in dims[1:end-1]
            show(ctx, mime, d)
            print(io, ", ")
        end
        show(ctx, mime, dims[end])
        return 0
    else # Dims get a line each
        lines = 3
        print(io, "\n  ")
        for d in dims[1:end-1]
            show(ctx, mime, d)
            print(io, ",")
            lines += 2 # Often they wrap
            print(io, "\n  ")
        end
        show(ctx, mime, dims[end])
        return lines
    end
end

function _printdimproperties(io, dim::Dimension, nchars)
    mode(dim) isa NoIndex && return nothing
    iobuf = IOBuffer()
    print(io, ": ")
    nchars += 1
    _printdimindex(iobuf, val(dim))
    dimvalstr = String(take!(iobuf)) 
    printstyled(io, dimvalstr; color=:cyan)
    nchars += length(dimvalstr)
    if !(mode(dim) isa AutoMode)
        show(iobuf, MIME"text/plain"(), mode(dim))
        termwidth = displaysize(stdout)[2]
        modestr = String(take!(iobuf))
        if nchars + length(modestr) + 6 > termwidth
            print(io, "\n   ")
        end
        print(io, string(" ", modestr))
    end
    return nothing
end

_printdimindex(io, A) = printstyled(io, A; color=:cyan)
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

function _ioctx(io, T)
    IOContext(io, :compact=>true, :limit=>true, :typeinfo=>T)
end

function Base.show(io::IO, mime::MIME"text/plain", dims::Tuple{<:Dimension,Vararg{<:Dimension}})
    _layout_dims(io, mime, dims)
end
