function dimsymbols(i) 
    symbols = ['↓', '→', '↗', '⬔', '◩', '⬒', '⬓', '■']
    symbols[min(i, length(symbols))]
end
function dimcolors(i)
    # colors = [203, 37, 162, 106, 67, 173, 91]
    # colors = [110, 216, 223, 218, 153, 79, 185, 142, 253]
    # colors = reverse([61, 153, 73, 29, 143, 186, 174, 132, 133])
    # colors = [61, 153, 73, 29, 143, 186, 174, 132, 133]
    # colors = [67, 210, 71, 185, 117, 132, 249]
    colors = [209, 32, 81, 204, 249, 166, 37]
    c = rem(i - 1, length(colors)) + 1
    colors[c]
end

function show_dims(io::IO, mime::MIME"text/plain", dims::DimTuple;
    colors=map(x -> get(io, :dimcolor, dimcolors(x)), ntuple(identity, length(dims)))
)
    ctx = IOContext(io, :compact => true)
    inset = get(io, :inset, "")
    brackets = get(io, :dim_brackets, true)
    print(io, inset)
    brackets && print(io, '(')
    if all(map(d -> !(parent(d) isa AbstractArray) || (parent(d) isa AbstractNoLookup), dims))
        dc = colors[1]
        printstyled(io, dimsymbols(1), ' '; color=dc)
        show(IOContext(ctx, :dimcolor => dc, :dimname_len => 0), mime, first(dims))
        foreach(enumerate(Base.tail(dims))) do (i, d)
            n = i + 1
            print(io, ", ")
            dc = colors[n]
            printstyled(io, dimsymbols(n), ' '; color=dc)
            show(IOContext(ctx, :dimcolor => dc, :dimname_len => 0), mime, d)
        end
        brackets && print(io, ')')
        return 0
    else # Dims get a line each
        lines = 3
        dc = colors[1]
        printstyled(io, dimsymbols(1), ' '; color=dc)
        maxname = maximum(length ∘ string ∘ name, dims) 
        dim_ctx = IOContext(ctx, :dimcolor => dc, :dimname_len=> maxname)
        show(dim_ctx, mime, first(dims))
        lines += 1
        map(Base.tail(dims), ntuple(x -> x + 1, length(dims) - 1)) do d, n
            lines += 1
            s = dimsymbols(n)
            print(io, ",\n", inset)
            dc = colors[n]
            printstyled(io, s, ' '; color=dc)
            dim_ctx = IOContext(ctx, :dimcolor => dc, :dimname_len => maxname)
            show(dim_ctx, mime, d)
        end
        brackets && print(io, ')')
        return lines
    end
end

Base.show(io::IO, dims::DimTuple) = show_dims(io, MIME"text/plain"(), dims)
Base.show(io::IO, mime::MIME"text/plain", dims::DimTuple) = show_dims(io, mime, dims)
function Base.show(io::IO, mime::MIME"text/plain", dim::Dimension)
    get(io, :compact, false) && return show_compact(io, mime, dim)
    print_dimname(io, dim)
    print_dimval(io, mime, val(dim))
end
function Base.show(io::IO, mime::MIME"text/plain", dim::Dimension{Colon})
    print_dimname(io, dim)
end

# compact version for dimensions
show_compact(io::IO, mime, dim::Dimension{Colon}) = print_dimname(io, dim)
function show_compact(io::IO, mime, dim::Dimension)
    # Print to a buffer and count lengths
    buf = IOBuffer()
    print_dimname(buf, dim)
    nchars = length(String(take!(buf)))
    print_dimval(buf, mime, parent(dim), nchars)
    nvalchars = length(String(take!(buf)))
    # Actually print to IO
    print_dimname(io, dim)
    if nvalchars > 0
        print_dimval(io, mime, val(dim), nchars)
    end
end

dimcolor(io) = get(io, :dimcolor, dimcolors(1))

# print dims with description string and inset
function print_dims(io::IO, mime, dims::Tuple{}; kw...)
    @nospecialize io mime dims
    print(io, ": ")
    return 0
end
function print_dims(io::IO, mime, dims::Tuple; kw...)
    ctx = IOContext(io, :inset => "  ")
    return show_dims(ctx, mime, dims; kw...)
end
# print refdims with description string and inset
function print_refdims(io::IO, mime, refdims::Tuple)
    if isempty(refdims) 
        return 0
    end
    printstyled(io, "and reference dimensions: "; color=:light_black)
    ctx = IOContext(io, :inset => "  ", :is_ref_dim=>true, :show_dim_val=>true)
    lines = show(ctx, mime, refdims)
    return lines
end
# print a dimension name
function print_dimname(io, dim::Dimension)
    dimname_len = get(io, :dimname_len, 0)
    printstyled(io, rpad(name(dim), dimname_len); color=dimcolor(io))
end


# print the dimension value
function print_dimval(io, mime, val, nchars=0)
    val isa Colon || print(io, " ")
    printstyled(io, val; color=get(io, :dimcolor, 1))
end
function print_dimval(io, mime, lookup::AbstractArray, nchars=0) 
    Lookups.print_index(io, mime, lookup, nchars)
end
print_dimval(io, mime, lookup::Union{AutoLookup,AbstractNoLookup}, nchars=0) = print(io, "")
function print_dimval(io, mime, lookup::Lookup, nchars=0)
    print(io, " ")
    ctx = IOContext(io, :nchars=>nchars)
    show(ctx, mime, lookup)
end
