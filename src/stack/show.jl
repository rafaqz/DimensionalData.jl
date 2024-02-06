function Base.summary(io::IO, stack::AbstractDimStack)
    print_ndims(io, size(stack))
    print(io, nameof(typeof(stack)))
end

function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    lines, maxlen, width= print_top(io, mime, stack; bottom_border=false)
    bottom_border = metadata(stack) isa Union{Nothing,NoMetadata}
    maxlen = print_layers_block(io, mime, stack; maxlen, width, bottom_border)
    _, maxlen = print_metadata_block(io, mime, metadata(stack); width, maxlen=min(width-2, maxlen))

    # Show anything else subtypes want to append
    show_after(io, mime, stack; maxlen)
    return nothing
end

function print_layers_block(io, mime, stack; maxlen, width, bottom_border=true)
    layers = DD.layers(stack)
    keylen = if length(keys(layers)) == 0
        0
    else
        reduce(max, map(length ∘ string, collect(keys(layers))))
    end
    newmaxlen = maxlen
    for key in keys(layers)
        newmaxlen = min(width - 2, max(maxlen, length(sprint(print_layer, stack, key, keylen))))
    end
    # Round the corner if this block is larger and sticks out further
    corner = newmaxlen > maxlen ? '┐' : '┤'
    printstyled(io, '├', '─'^max(0, newmaxlen - 8), " layers $corner"; color=:light_black)
    println(io)
    for key in keys(layers)
        print_layer(io, stack, key, keylen)
    end
    return newmaxlen
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
