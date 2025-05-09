# Base show
function Base.summary(io::IO, stack::AbstractDimStack)
    print_ndims(io, size(stack))
    print(io, nameof(typeof(stack)))
end

function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    # Show main blocks - summary, dims, layers, metadata
    _, blockwidth = show_main(io, mime, stack)
    # Show anything else subtypes want to append
    ctx = IOContext(io, :blockwidth => blockwidth)
    show_after(ctx, mime, stack)
    return nothing
end

# Show customisation interface
function show_main(io, mime, stack::AbstractDimStack)
    displaywidth = displaysize(io)[2]
    iobuf = IOBuffer()
    blockwidth, _ = print_layers_block(iobuf, mime, stack; blockwidth=0, displaywidth)

    lines, blockwidth, displaywidth, separatorwidth, istop = print_top(io, mime, stack; blockwidth, displaywidth)
    blockwidth, separatorwidth = print_layers_block(io, mime, stack; 
        blockwidth, displaywidth, separatorwidth, istop
    )
    _, blockwidth, istop = print_metadata_block(io, mime, metadata(stack); 
        blockwidth=min(displaywidth-2, blockwidth), displaywidth, separatorwidth, istop
    )
end

function show_after(io, mime, stack::AbstractDimStack)
    blockwidth = get(io, :blockwidth, 0)
    print_block_close(io, blockwidth)
end

# Show blocks
function print_layers_block(io, mime, stack; 
    blockwidth, displaywidth, separatorwidth=blockwidth, istop=false
)
    layers = DD.layers(stack)
    newblockwidth = blockwidth
    keylen = _keylen(Base.keys(layers))
    for key in keys(layers)
        mxbw = max(newblockwidth, length(sprint(print_layer, stack, key, keylen)))
        newblockwidth = min(displaywidth - 2, mxbw)
    end
    newblockwidth = print_block_separator(io, "layers", separatorwidth, newblockwidth; istop)
    println(io)
    for key in keys(layers)
        print_layer(io, stack, key, keylen)
    end
    return newblockwidth, newblockwidth
end

function _keylen(keys)
    if isempty(keys)
        0
    else
        reduce(max, map(length ∘ string, collect(keys)))
    end
end

function print_layer(io, stack, key::Symbol, keylen)
    layer = stack[key]
    pkey = rpad(key, keylen)
    printstyled(io, "  :$pkey", color=dimcolors(7))
    printstyled(io, " eltype: "; color=:light_black)
    print(io, string(eltype(layer)))
    field_dims = DD.dims(layer)
    colors = map(dimcolors, dimnum(stack, field_dims))
    printstyled(io, " dims: "; color=:light_black)
    if !isempty(field_dims)
        for (i, (dim, color)) in enumerate(zip(field_dims, colors))
            Dimensions.print_dimname(IOContext(io, :dimcolor => color), dim)
            i != length(field_dims) && print(io, ", ")
        end
        printstyled(io, " size: "; color=:light_black)
        print_sizes(io, size(field_dims); colors)
    end
    print(io, '\n')
end
