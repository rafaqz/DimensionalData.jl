# Base show
function Base.summary(io::IO, stack::AbstractDimStack)
    print_ndims(io, size(stack))
    print(io, nameof(typeof(stack)))
end

function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    # Show main blocks - summar, dims, layers, metadata
    _, blockwidth = show_main(io, mime, stack)
    # Show anything else subtypes want to append
    ctx = IOContext(io, :blockwidth => blockwidth)
    show_after(ctx, mime, stack)
    return nothing
end

# Show customisation interface
function show_main(io, mime, stack::AbstractDimStack)
    lines, blockwidth, displaywidth = print_top(io, mime, stack)
    blockwidth = print_layers_block(io, mime, stack; blockwidth, displaywidth)
    _, blockwidth = print_metadata_block(io, mime, metadata(stack); displaywidth, blockwidth=min(displaywidth-2, blockwidth))
end

function show_after(io, mime, stack::AbstractDimStack)
    blockwidth = get(io, :blockwidth, 0)
    print_block_close(io, blockwidth)
end

# Show blocks
function print_layers_block(io, mime, stack; blockwidth, displaywidth)
    layers = DD.layers(stack)
    keylen = if length(keys(layers)) == 0
        0
    else
        reduce(max, map(length ∘ string, collect(keys(layers))))
    end
    newblockwidth = blockwidth
    for key in keys(layers)
        newblockwidth = min(displaywidth - 2, max(blockwidth, length(sprint(print_layer, stack, key, keylen))))
    end
    print_block_separator(io, "layers", blockwidth, newblockwidth)
    println(io)
    for key in keys(layers)
        print_layer(io, stack, key, keylen)
    end
    return newblockwidth
end

function print_layer(io, stack, key, keylen)
    layer = stack[key]
    pkey = rpad(key, keylen)
    printstyled(io, "  :$pkey", color=dimcolors(7))
    printstyled(io, " eltype: "; color=:light_black)
    print(io, string(eltype(layer)))
    field_dims = DD.dims(layer)
    n_dims = length(field_dims)
    colors = map(dimcolors, dimnum(stack, field_dims))
    printstyled(io, " dims: "; color=:light_black)
    if n_dims > 0
        for (i, (dim, color)) in enumerate(zip(field_dims, colors))
            Dimensions.print_dimname(IOContext(io, :dimcolor => color), dim)
            i != length(field_dims) && print(io, ", ")
        end
        printstyled(io, " size: "; color=:light_black)
        print_sizes(io, size(field_dims); colors)
    end
    print(io, '\n')
end
