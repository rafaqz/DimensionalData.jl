function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    buffer = IOBuffer()
    context = IOContext(buffer, :color=>true)
    print(context, nameof(typeof(stack)))
    Dimensions.print_dims(context, mime, dims(stack))
    nlayers = length(keys(stack))
    layers_str = nlayers == 1 ? "layer" : "layers"
    printstyled(context, "\nand "; color=:light_black) 
    print(context, "$nlayers $layers_str:\n")
    maxlen = reduce(max, map(length ∘ string, collect(keys(stack))))
    for key in keys(stack)
        layer = stack[key]
        pkey = rpad(key, maxlen)
        printstyled(context, "  :$pkey", color=:yellow)
        print(context, string(" ", eltype(layer)))
        field_dims = DD.dims(layer)
        n_dims = length(field_dims)
        printstyled(context, " dims: "; color=:light_black)
        if n_dims > 0
            for (d, dim) in enumerate(field_dims)
                Dimensions.print_dimname(context, dim)
                d != length(field_dims) && print(context, ", ")
            end
            print(context, " (")
            for (d, dim) in enumerate(field_dims)
                print(context, "$(length(dim))")
                d != length(field_dims) && print(context, '×')
            end
            print(context, ')')
        end
        print(context, '\n')
    end

    md = metadata(stack)
    if !(md isa NoMetadata)
        n_metadata = length(md)
        if n_metadata > 0
            printstyled(context, "\nwith metadata "; color=:light_black)
            show(context, mime, md)
        end
    end

    # Show anything else subtypes want to append
    show_after(context, mime, stack)

    seek(buffer, 0)
    write(io, buffer)

    return nothing
end

show_after(io, mime, stack::DimStack) = nothing
