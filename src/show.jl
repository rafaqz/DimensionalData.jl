function Base.summary(io::IO, A::AbstractDimArray{T,N}) where {T,N}
    if N == 0  
        print(io, "0-dimensional ")
    elseif N == 1
        print(io, size(A, 1), "-element ")
    else
        print(io, join(size(A), "×"), " ")
    end
    print(io, string(nameof(typeof(A)), "{$T,$N}"))
end

function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray{T,N}) where {T,N}
    lines = 0
    summary(io, A)
    print_name(io, name(A))
    lines += print_dims(io, mime, dims(A))
    !(isempty(dims(A)) || isempty(refdims(A))) && println(io)
    lines += print_refdims(io, mime, refdims(A))
    println(io)

    # Printing the array data is optional, subtypes can 
    # show other things here instead.
    ds = displaysize(io)
    ioctx = IOContext(io, :displaysize => (ds[1] - lines, ds[2]))
    show_after(ioctx, mime, A)

    return nothing
end

function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    print(io, nameof(typeof(stack)))
    print_dims(io, mime, dims(stack))
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
                print_dimname(io, dim)
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
            printstyled(io, "\nwith metadata "; color=:light_black)
            show(io, mime, md)
        end
    end

    # Show anything else subtypes want to append
    show_after(io, mime, stack)

    return nothing
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

Base.show(io::IO, mime::MIME"text/plain", lookup::AutoLookup) = nothing

Base.show(io::IO, mime::MIME"text/plain", lookup::NoLookup) = print(io, "NoLookup")

function Base.show(io::IO, mime::MIME"text/plain", lookup::Transformed)
    show_compact(io, mime, lookup)
    print_dimval(io, mime, f(lookup))
    print(io, " ")
    show_compact(io, mime, dim(lookup))
end

function Base.show(io::IO, mime::MIME"text/plain", lookup::AbstractSampled)
    show_compact(io, mime, lookup)
    print_dimval(io, mime, parent(lookup))
    print(io, " ")
    print_order(io, lookup)
    print(io, " ")
    print_span(io, lookup)
    print(io, " ")
    print_sampling(io, lookup)
end

function Base.show(io::IO, mime::MIME"text/plain", lookup::AbstractCategorical)
    show_compact(io, mime, lookup)
    print_dimval(io, mime, parent(lookup))
    print(io, " ")
    print_order(io, lookup)
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

function Base.show(io::IO, mime::MIME"text/plain", dims::DimTuple)
    ctx = IOContext(io, :compact=>true)
    if all(x -> !(x isa AbstractArray) || (x isa NoLookup), map(val, dims))
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

function Base.show(io::IO, mime::MIME"text/plain", lookups::Tuple{<:Lookup,Vararg{<:Lookup}})
    length(lookups) > 0 || return 0
    ctx = IOContext(io, :compact=>true)
    if all(l -> l isa NoLookup, lookups)
        for l in lookups[1:end-1]
            show(ctx, mime, l)
            print(io, ", ")
        end
        show(ctx, mime, lookups[end])
        return 0
    else # Dims get a line each
        lines = 3
        haskey(io, :inset) && print(io, "\n")
        inset = get(io, :inset, "")
        for l in lookups[1:end-1]
            print(io, inset)
            show(ctx, mime, l)
            print(io, ",")
            lines += 2 # Often they wrap
            print(io, "\n")
        end
        print(io, inset)
        show(ctx, mime, lookups[end])
        return lines
    end
end

# compact version for dimensions and lookups
show_compact(io::IO, mime, dim::Dimension{Colon}) = print_dimname(io, dim)
show_compact(io::IO, mime, dim::Dimension{<:NoLookup}) = print_dimname(io, dim)
function show_compact(io::IO, mime, dim::Dimension)
    nm = nameof(typeof(dim))
    nchars = length(string(nm))
    print_dimname(io, dim)
    print_dimval(io, mime, val(dim), nchars)
end
function show_compact(io::IO, mime, dim::Dim)
    color = dimcolor(io)
    print_dimname(io, dim)
    nchars = 5 + length(string(name(dim)))
    print_dimval(io, mime, val(dim), nchars)
end
show_compact(io, mime, lookup::Lookup) = print(io, nameof(typeof(lookup)))


# Semi-interface methods for adding addional `show` text
# for AbstractDimArray/AbstractDimStack subtypes
# TODO actually document in the interface
show_after(io, mime, stack::DimStack) = nothing
show_after(io::IO, mime, A::AbstractDimArray) = print_array(io, mime, parent(A))

# Showing the array is optional for AbstractDimArray
# `print_array` must be called from `show_after`.
function print_array(io::IO, mime, A::AbstractArray{T,0}) where T
    print(_print_array_ctx(io, T), "\n", A[])
end
function print_array(io::IO, mime, A::AbstractArray{T,1}) where T
    Base.print_matrix(_print_array_ctx(io, T), A)
end
function print_array(io::IO, mime, A::AbstractArray{T,2}) where T
    Base.print_matrix(_print_array_ctx(io, T), A)
end
function print_array(io::IO, mime, A::AbstractArray{T,N}) where {T,N}
    o = ones(Int, N-2)
    frame = A[:, :, o...]
    onestring = join(o, ", ")
    println(io, "[:, :, $(onestring)]")
    Base.print_matrix(_print_array_ctx(io, T), frame)
    nremaining = prod(size(A, d) for d=3:N) - 1
    nremaining > 0 && print(io, "\n[and ", nremaining," more slices...]")
end

function _print_array_ctx(io, T)
    IOContext(io, :compact=>true, :limit=>true, :typeinfo=>T)
end

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
# print a name of something, in yellow
function print_name(io::IO, name)
    if !(name == Symbol("") || name isa NoName)
        printstyled(io, string(" ", name); color=:yellow)
    end
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
function print_dimval(io, mime, lookup::Lookup, nchars=0)
    (lookup isa AutoLookup) || print(io, " ")
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

print_order(io, lookup) = print(io, nameof(typeof(order(lookup))))
print_span(io, lookup) = print(io, nameof(typeof(span(lookup))))
print_sampling(io, lookup) = print(io, nameof(typeof(sampling(lookup))))
function print_metadata(io, lookup)
    metadata(lookup) isa NoMetadata && return nothing
    print(io, nameof(typeof(metadata(lookup))))
end

dimcolor(io) = get(io, :is_ref_dim, false) ? :magenta : :red
