function Base.summary(io::IO, stack::AbstractDimStack)
    print_sizes(io, size(stack))
    print(io, ' ')
    print(io, nameof(typeof(stack)))
end

function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    lines, maxlen, width = print_top(io, mime, stack; bottom_border=false)
    print_layers_block(io, mime, stack; maxlen, width, bottom_border=metadata(stack) isa Union{Nothing,NoMetadata})
    print_metadata_block(io, mime, metadata(stack); width, maxlen=min(width-2, maxlen))

    # Show anything else subtypes want to append
    show_after(io, mime, stack; maxlen)
    return nothing
end

function print_metadata_block(io, mime, metadata; maxlen=0, width)
    lines = 0
    if !(metadata isa NoMetadata)
        metadata_print = split(sprint(show, mime, metadata), "\n")
        maxlen = min(width-2, max(maxlen, maximum(length, metadata_print)))
        printstyled(io, '├', '─'^(maxlen - 10), " metadata ┤"; color=:light_black)
        println(io)
        print(io, "  ")
        show(io, mime, metadata)
        println(io)
        println(io)
        lines += length(metadata_print) + 3
    end
    return lines, maxlen
end

function print_layers_block(io, mime, stack; maxlen, width, bottom_border=true)
    roundedtop = maxlen == 0
    layers = DD.layers(stack)
    lines = 0
    keylen = if length(keys(layers)) == 0
        0
    else
        reduce(max, map(length ∘ string, collect(keys(layers))))
    end
    for key in keys(layers)
        maxlen = min(width - 2, max(maxlen, length(sprint(print_layer, stack, key, keylen))))
    end
    if roundedtop
        printstyled(io, '┌', '─'^(maxlen - 8), " layers ┐"; color=:light_black)
    else
        printstyled(io, '├', '─'^(maxlen - 8), " layers ┤"; color=:light_black)
    end
    println(io)
    for key in keys(layers)
        print_layer(io, stack, key, keylen)
    end
    return lines
end

function print_layer(io, stack, key, keylen)
    layer = stack[key]
    pkey = rpad(key, keylen)
    printstyled(io, "  :$pkey", color=dimcolors(100))
    print(io, string(" ", eltype(layer)))
    field_dims = DD.dims(layer)
    n_dims = length(field_dims)
    colors = map(dimcolors, dimnum(stack, field_dims))
    printstyled(io, " dims: "; color=:light_black)
    if n_dims > 0
        for (i, (dim, color)) in enumerate(zip(field_dims, colors))
            Dimensions.print_dimname(IOContext(io, :dimcolor => color), dim)
            i != length(field_dims) && print(io, ", ")
        end
        print(io, " (")
        print_sizes(io, size(field_dims); colors)
        print(io, ')')
    end
    print(io, '\n')
end

function show_after(io, mime, stack::DimStack; maxlen)
    printstyled(io, '└', '─'^maxlen, '┘'; color=:light_black)
end
