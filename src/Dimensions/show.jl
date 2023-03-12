
function Base.show(io::IO, mime::MIME"text/plain", dims::DimTuple)
    ctx = IOContext(io, :compact=>true)
    if all(map(d -> !(parent(d) isa AbstractArray) || (parent(d) isa NoLookup), dims))
        show(ctx, mime, first(dims))
        map(Base.tail(dims)) do d
            print(io, ", ")
            show(ctx, mime, d)
        end
        println(io)
        return 0
    else # Dims get a line each
        haskey(io, :inset) && println(io)
        inset = get(io, :inset, "")
        lines = 3
        print(io, inset)
        show(ctx, mime, first(dims))
        lines += 2 # Often they wrap
        map(Base.tail(dims)) do d
            print(io, ",")
            lines += 2 # Often they wrap
            print(io, "\n")
            print(io, inset)
            show(ctx, mime, d)
        end
        println(io)
        return lines
    end
end
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

dimcolor(io) = get(io, :is_ref_dim, false) ? :magenta : :red

# print dims with description string and inset
function print_dims(io::IO, mime, dims::Tuple{})
    @nospecialize io mime dims
    print(io, ": ")
    return 0
end
function print_dims(io::IO, mime, dims::Tuple)
    @nospecialize io mime dims
    printstyled(io, " with dimensions: "; color=:light_black)
    ctx = IOContext(io, :inset => "  ")
    return show(ctx, mime, dims)
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
function print_dimname(io::IO, dim::Dim)
    color = dimcolor(io)
    printstyled(io, "Dim{"; color=color)
    printstyled(io, string(":", name(dim)); color=:yellow)
    printstyled(io, "}"; color=color)
end
function print_dimname(io, dim::Dimension)
    printstyled(io, dim2key(dim); color = dimcolor(io))
end


# print the dimension value
function print_dimval(io, mime, val, nchars=0)
    val isa Colon || print(io, " ")
    printstyled(io, val; color=:cyan)
end
function print_dimval(io, mime, lookup::AbstractArray, nchars=0) 
    LookupArrays.print_index(io, mime, lookup, nchars)
end
print_dimval(io, mime, lookup::Union{AutoLookup,NoLookup}, nchars=0) = print(io, "")
function print_dimval(io, mime, lookup::LookupArray, nchars=0)
    print(io, " ")
    ctx = IOContext(io, :nchars=>nchars)
    show(ctx, mime, lookup)
end
