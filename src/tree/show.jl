# Base show
function Base.summary(io::IO, tree::AbstractDimTree)
    print(io, nameof(typeof(tree)))
end

function Base.show(io::IO, mime::MIME"text/plain", tree::AbstractDimTree)
    blockwidth = show_main(io, mime, tree)
    ctx = IOContext(io, :blockwidth => blockwidth)
    show_branches(ctx, mime, tree)
    show_after(ctx, mime, tree)
    return nothing
end

# Show customisation interface
function show_main(io, mime, tree::AbstractDimTree)
    lines, blockwidth, displaywidth = print_top(io, mime, tree)
    if !isempty(data(tree))
        blockwidth = print_layers_block(io, mime, tree; blockwidth, displaywidth)
    end
    _, blockwidth = print_metadata_block(io, mime, metadata(tree); 
        displaywidth, blockwidth=min(displaywidth-2, blockwidth)
    )
    return blockwidth
end

function show_branches(io, mime, tree::AbstractDimTree)
    blockwidth = get(io, :blockwidth, 0)
    if !isempty(branches(tree))
        blockwidth = print_block_separator(io, "branches", blockwidth, blockwidth)
        println(io)
        for key in keys(branches(tree))
            print_branch(io, branches(tree)[key], key)
        end
    end
    return blockwidth
end

function print_branch(io, branch::AbstractDimTree, key::Symbol; tab="  ", indent="    ")
    pkey = ":" * rpad(key, _keylen(keys(branch)))
    print(io, tab)
    printstyled(io, pkey, color=dimcolor(7))
    field_dims = DD.dims(branch)
    if !isempty(field_dims)
        colors = map(dimcolor, eachindex(field_dims))
        printstyled(io, " dims: "; color=:light_black)
        for (i, (dim, color)) in enumerate(zip(field_dims, colors))
            Dimensions.print_dimname(IOContext(io, :dimcolor => color), dim)
            i != length(field_dims) && print(io, ", ")
        end
        printstyled(io, " size: "; color=:light_black)
        print_sizes(io, size(field_dims); colors)
        if !isempty(keys(branch))
            printstyled(io, " layers: "; color=:light_black)
            printstyled(io, join(map(k -> string(":", k), keys(branch)), ", "); color=dimcolor(7))
        end
    end
    # Print the branches of the branch
    ks = collect(keys(branches(branch)))
    println(io)
    if length(ks) > 0
        for key1 in ks[1:end-1]
            printstyled(io, indent, "├─ "; color=:light_black)
            print_branch(io, branches(branch)[key1], key1; tab="", indent=indent * "│    ")
        end
        printstyled(io, indent, "└─ "; color=:light_black)
        print_branch(io, branches(branch)[last(ks)], last(ks); tab="", indent=indent * "    ")
    end
end

function show_after(io, mime, tree::AbstractDimTree)
    blockwidth = get(io, :blockwidth, 0)
    print_block_close(io, blockwidth)
end