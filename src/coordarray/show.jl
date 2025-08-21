# Extend Base.show to display coordinate information

function Base.show(io::IO, mime::MIME"text/plain", A::CoordArray)
    lines, blockwidth, istop = show_main(io, mime, A::AbstractBasicDimArray)
    # Add coordinate block
    coord_lines, blockwidth, istop = print_coord_block(io, mime, coords(A); 
        blockwidth, displaywidth=displaysize(io)[2], separatorwidth=blockwidth, istop
    )
    lines += coord_lines
    
    # Printing the array data is optional, subtypes can
    # show other things here instead.
    ds = displaysize(io)
    ctx = IOContext(io, 
        :blockwidth => blockwidth, 
        :displaysize => (ds[1] - lines, ds[2]), 
        :isblocktop => istop
    )
    show_after(ctx, mime, A)
    return nothing
end

function print_coord_block(io, mime, coordinates; 
    blockwidth=0, displaywidth, separatorwidth=blockwidth, istop=false, label="coords"
)
    lines = 0
    if isempty(coordinates)
        new_blockwidth = blockwidth
        stilltop = istop
    else
        # Calculate the maximum width needed for coordinate display
        coord_lines = []
        for (name, coord) in pairs(coordinates)
            coord_str = if isa(coord, AbstractDimArray)
                dim_names = join([string(nameof(typeof(d))) for d in dims(coord)], ", ")
                "  $name: ($dim_names) $(summary(coord))"
            else
                "  $name: $(summary(coord))"
            end
            push!(coord_lines, coord_str)
        end
        
        coord_width = maximum(textwidth, coord_lines)
        new_blockwidth = max(blockwidth, min(displaywidth - 2, coord_width))
        new_blockwidth = print_block_separator(io, label, separatorwidth, new_blockwidth; istop)
        println(io)
        
        # Print each coordinate
        for coord_line in coord_lines
            println(io, coord_line)
            lines += 1
        end
        
        lines += 2  # for separator and final newline
        stilltop = false
    end
    return lines, new_blockwidth, stilltop
end