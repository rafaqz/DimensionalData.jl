function Base.show(io::IO, mime::MIME"text/plain", stack::AbstractDimStack)
    print(io, nameof(typeof(stack)))
    Dimensions.print_dims(io, mime, dims(stack))
    nlayers = length(keys(stack))
    layers_str = nlayers == 1 ? "layer" : "layers"
    printstyled(io, "\nand "; color=:light_black) 
    print(io, "$nlayers $layers_str:\n")
    maxlen = reduce(max, map(length ∘ string, collect(keys(stack))))
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
                Dimensions.print_dimname(io, dim)
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

show_after(io, mime, stack::DimStack) = nothing
