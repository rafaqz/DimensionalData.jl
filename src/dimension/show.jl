
function Base.show(io::IO, mime::MIME"text/plain", dims::DimTuple)
    ctx = IOContext(io, :compact=>true)
    if all(map(d -> !(val(d) isa AbstractArray) || (val(d) isa NoLookup), dims))
        for d in dims[1:end-1]
            show(ctx, mime, d)
            print(io, ", ")
        end
        show(ctx, mime, dims[end])
        return 0
    else # Dims get a line each
        haskey(io, :inset) && print(io, "\n")
        inset = get(io, :inset, "")
        lines = 3
        for d in dims[1:end-1]
            print(io, inset)
            show(ctx, mime, d)
            print(io, ",")
            lines += 2 # Often they wrap
            print(io, "\n")
        end
        print(io, inset)
        show(ctx, mime, dims[end])
        return lines
    end
end
function Base.show(io::IO, mime::MIME"text/plain", dim::Dimension)
    get(io, :compact, false) && return show_compact(io::IO, mime, dim)
    # printstyled(io, nameof(typeof(dim)); color=_dimcolor(io))
    print_dimname(io, dim)
    print_dimval(io, mime, val(dim))
end
function Base.show(io::IO, mime::MIME"text/plain", dim::Dimension{Colon})
    print_dimname(io, dim)
end

# compact version for dimensions and lookups
show_compact(io::IO, mime, dim::Dimension{Colon}) = print_dimname(io, dim)
function show_compact(io::IO, mime, dim::Dimension)
    # Print to a buffer and count lengths
    buf = IOBuffer()
    print_dimname(buf, dim)
    nchars = length(String(take!(buf)))
    print_dimval(buf, mime, val(dim), nchars)
    nvalchars = length(String(take!(buf)))
    # Actually print to IO
    print_dimname(io, dim)
    if nvalchars > 0
        print_dimval(io, mime, val(dim), nchars)
    end
end

dimcolor(io) = get(io, :is_ref_dim, false) ? :magenta : :red

# print dims with description string and inset
function print_dims(io::IO, mime, dims::Tuple)
    if isempty(dims) 
        print(io, ": ")
        return 0
    end
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
function print_dimname(io, dim::Dim)
    color = dimcolor(io)
    printstyled(io, "Dim{"; color=color)
    printstyled(io, string(":", name(dim)); color=:yellow)
    printstyled(io, "}"; color=color)
end
function print_dimname(io, dim::Dimension)
    printstyled(io, DD.dim2key(dim); color = dimcolor(io))
end


# print the dimension/lookup value

function print_dimval(io, mime, val, nchars=0)
    val isa Colon || print(io, " ")
    printstyled(io, val; color=:cyan)
end
print_dimval(io, mime, lookup::NoLookup, nchars=0) = nothing
print_dimval(io, mime, lookup::Union{AutoLookup,NoLookup}, nchars=0) = print(io, " ")
function print_dimval(io, mime, lookup::LookupArray, nchars=0)
    print(io, " ")
    ctx = IOContext(io, :nchars=>nchars)
    show(ctx, mime, lookup)
end
function print_dimval(io, mime, A::AbstractRange, nchars=0)
    print(io, " ")
    printstyled(io, A; color=:cyan)
end
function print_dimval(io, mime, v::AbstractVector, nchars=0)
    print(io, " ")
    # Maximum 2 values for dates
    vals = if length(v) > 2 && eltype(v) <: Dates.TimeType
        "$(v[1]), …, $(v[end])"
    # Maximum 4 values for other types 
    elseif length(v) > 5
        "$(v[1]), $(v[2]), …, $(v[end-1]), $(v[end])"
    else
        join((string(va) for va in v), ", ")
    end
    printstyled(io, string(eltype(v)) * "[" * vals * "]"; color=:cyan)
end
