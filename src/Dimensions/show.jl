# Symbols and colors
function dimsymbol(i) 
    symbols = ['↓', '→', '↗', '⬔', '◩', '⬒', '⬓', '■']
    symbols[min(i, length(symbols))]
end
function dimcolor(i::Int)
    # colors = [203, 37, 162, 106, 67, 173, 91]
    # colors = [110, 216, 223, 218, 153, 79, 185, 142, 253]
    # colors = reverse([61, 153, 73, 29, 143, 186, 174, 132, 133])
    # colors = [61, 153, 73, 29, 143, 186, 174, 132, 133]
    # colors = [67, 210, 71, 185, 117, 132, 249]
    colors = [209, 32, 81, 204, 249, 166, 37]
    c = rem(i - 1, length(colors)) + 1
    colors[c]
end
dimcolor(io::IO) = get(io, :dimcolor, dimcolor(1))

@deprecate dimcolors(x) dimcolor(x) false
@deprecate dimsymbols(x) dimsymbol(x) false

# Base methods

Base.show(io::IO, dims::DimTuple) = show_dims(io, MIME"text/plain"(), dims)
Base.show(io::IO, mime::MIME"text/plain", dims::DimTuple) = show_dims(io, mime, dims)
function Base.show(io::IO, mime::MIME"text/plain", dim::Dimension)
    get(io, :compact, false) && return show_compact(io, mime, dim)
    # Print the dimension name
    print_dimname(io, dim)
    # Print whitespace after dim name, unless the val is not shown
    dimname_len = get(io, :dimname_len, 0)
    this_dimname_len = length(string(name(dim)))
    print(io, repeat(" ", max(0, dimname_len - this_dimname_len)))
    # Print the dimension value
    print_dimval(io, mime, val(dim))
end
function Base.show(io::IO, ::MIME"text/plain", 
    dim::Dimension{<:Union{AbstractNoLookup,AutoLookup,Colon}}
)
    print_dimname(io, dim)
end

function show_dims(io::IO, mime::MIME"text/plain", dims::DimTuple;
    colors=map(x -> get(io, :dimcolor, dimcolor(x)), ntuple(identity, length(dims)))
)
    ctx = IOContext(io, :compact => true)
    # Add whitespace inset
    inset = get(io, :inset, "")
    print(io, inset)
    # Print brackets
    brackets = get(io, :dim_brackets, true)
    brackets && print(io, '(')
    if all(map(d -> !(parent(d) isa AbstractArray) || (parent(d) isa AbstractNoLookup), dims))
        # No lookups, dims all go on one line
        dc = colors[1]
        # Print the first dim
        printstyled(io, dimsymbol(1), ' '; color=dc)
        show(IOContext(ctx, :dimcolor => dc, :dimname_len => 0), mime, first(dims))
        # Print the rest of the dims
        foreach(enumerate(Base.tail(dims))) do (i, d)
            n = i + 1
            print(io, ", ")
            dc = colors[n]
            printstyled(io, dimsymbol(n), ' '; color=dc)
            show(IOContext(ctx, :dimcolor => dc, :dimname_len => 0), mime, d)
        end
        # Maybe close brackets
        brackets && print(io, ')')
        return 0
    else 
        # Dims get a line each
        lines = 3
        # Print the first dim
        dc = colors[1]
        printstyled(io, dimsymbol(1), ' '; color=dc)
        # Get the maximum dim name length
        max_name_len = maximum(length ∘ string ∘ name, dims) 
        # Update context with colors and name length
        dim_ctx = IOContext(ctx, :dimcolor => dc, :dimname_len=> max_name_len)
        # Show the dim 
        show(dim_ctx, mime, first(dims))
        lines += 1
        # Print the rest of the dims
        map(Base.tail(dims), ntuple(x -> x + 1, length(dims) - 1)) do d, n
            lines += 1
            s = dimsymbol(n)
            print(io, ",\n", inset)
            dc = colors[n]
            printstyled(io, s, ' '; color=dc)
            dim_ctx = IOContext(ctx, :dimcolor => dc, :dimname_len => max_name_len)
            show(dim_ctx, mime, d)
        end
        # Maybe close brackets
        brackets && print(io, ')')
        return lines
    end
end

# compact version for dimensions
show_compact(io::IO, mime, dim::Dimension{Colon}) = print_dimname(io, dim)
function show_compact(io::IO, mime, dim::Dimension)
    # Print to a buffer and count lengths
    buf = IOBuffer()
    ctx = IOContext(buf, :compact => true)
    print_dimname(ctx, dim)
    nchars = length(String(take!(buf)))
    print_dimval(ctx, mime, parent(dim), nchars)
    nvalchars = length(String(take!(buf)))
    # Actually print to IO
    print_dimname(io, dim)
    if nvalchars > 0
        print_dimval(io, mime, val(dim), nchars)
    end
end

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
print_dimname(io, dim::Dimension) = printstyled(io, name(dim); color=dimcolor(io))

# print the dimension value
function print_dimval(io, mime, val, nchars=0)
    val isa Colon || print(io, " ")
    printstyled(io, val; color=get(io, :dimcolor, 1))
end
print_dimval(io, mime, lookup::AbstractArray, nchars=0) =
    Lookups.print_lookup_values(io, mime, lookup, nchars)
print_dimval(io, mime, lookup::AbstractArray{<:Any,0}, nchars=0) =
    printstyled(io, " ", lookup; color=get(io, :dimcolor, 1))
print_dimval(io, mime, lookup::Union{AutoLookup,AbstractNoLookup}, nchars=0) = print(io, "")
function print_dimval(io, mime, lookup::Lookup, nchars=0)
    print(io, " ")
    ctx = IOContext(io, :nchars=>nchars)
    show(ctx, mime, lookup)
end
