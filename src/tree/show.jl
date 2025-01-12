# Base show
function Base.summary(io::IO, tree::AbstractDimTree)
    print(io, nameof(typeof(tree)))
end

function Base.show(io::IO, mime::MIME"text/plain", tree::AbstractDimTree)
    blockwidth = show_main(io, mime, tree)
    ctx = IOContext(io, :blockwidth => blockwidth)
    show_branches(ctx, mime, tree)
    show_trunk(ctx, mime, tree)
    show_after(ctx, mime, tree)
    return nothing
end

# Show customisation interface
function show_main(io, mime, tree::AbstractDimTree)
    lines, blockwidth, displaywidth = print_top(io, mime, tree)
    blockwidth = print_layers_block(io, mime, tree; blockwidth, displaywidth)
    _, blockwidth = print_metadata_block(io, mime, metadata(tree); 
        displaywidth, blockwidth=min(displaywidth-2, blockwidth)
    )
    return blockwidth
end

function show_branches(io, mime, tree::AbstractDimTree)
    blockwidth = get(io, :blockwidth, 0)
    if !isempty(groups(tree))
        newblockwidth = print_block_separator(io, "branches", blockwidth, blockwidth)
        println(io)
        for key in keys(groups(tree))
            print_group(io, groups(tree, key), key)
        end
    end
end

function show_trunk(io, mime, tree::AbstractDimTree)
    p = getindex(tree, :parent)
    if !isnothing(p)
        newblockwidth = print_block_separator(io, "branches", blockwidth, blockwidth)
        println(io)
        for key in keys(groups(tree))
            print_group(io, groups(tree, key), key)
        end
    end
end

function print_group(io, group::AbstractDimTree, key)
    pkey = rpad(key, _keylen(keys(group)))
    printstyled(io, "  :$pkey", color=dimcolors(7))
    # printstyled(io, " layers: "; color=:light_black)
    field_dims = DD.dims(group)
    colors = map(dimcolors, eachindex(field_dims))
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

function show_after(io, mime, tree::AbstractDimTree)
    blockwidth = get(io, :blockwidth, 0)
    print_block_close(io, blockwidth)
end