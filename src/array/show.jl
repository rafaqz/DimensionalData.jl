using DimensionalData.Dimensions: dimcolors, dimsymbols, print_dims

# Base show
function Base.summary(io::IO, A::AbstractBasicDimArray{T,N}) where {T,N}
    print_ndims(io, size(A))
    print_type(io, A)
    print_name(io, name(A))
end

# Fancy show for text/plain
function Base.show(io::IO, mime::MIME"text/plain", A::AbstractBasicDimArray{T,N}) where {T,N}
    lines, blockwidth = show_main(io, mime, A::AbstractBasicDimArray)
    # Printing the array data is optional, subtypes can
    # show other things here instead.
    ds = displaysize(io)
    ctx = IOContext(io, :blockwidth => blockwidth, :displaysize => (ds[1] - lines, ds[2]))
    show_after(ctx, mime, A)
    return nothing
end
# Defer simple 2-arg show to the parent array
Base.show(io::IO, A::AbstractDimArray) = show(io, parent(A))
    
Base.print_matrix(io::IO, A::AbstractBasicDimArray) =
    Base.print_matrix(io, LazyLabelledPrintMatrix(A))


"""
    show_main(io::IO, mime, A::AbstractDimArray)
    show_main(io::IO, mime, A::AbstractDimStack)

Interface methods for adding the main part of `show`

At the least, you likely want to call:

```julia
print_top(io, mime, A)
```

But read the DimensionalData.jl `show.jl` code for details.
"""
function show_main(io, mime, A::AbstractBasicDimArray)
    lines_t, blockwidth, displaywidth = print_top(io, mime, A)
    lines_m, blockwidth = print_metadata_block(io, mime, metadata(A); blockwidth, displaywidth)
    return lines_t + lines_m, blockwidth
end

"""
    show_after(io::IO, mime, A::AbstractDimArray)
    show_after(io::IO, mime, A::AbstractDimStack)

Interface methods for adding additional `show` text
for AbstractDimArray/AbstractDimStack subtypes.

*Always include `kw` to avoid future breaking changes*

Additional keywords may be added at any time.


`blockwidth` is passed in context

```julia
blockwidth = get(io, :blockwidth, 10000)
```

Note - a ANSI box is left unclosed. This method needs to close it,
or add more. `blockwidth` is the maximum length of the inner text.

Most likely you always want to at least close the show blocks with:

```julia
print_block_close(io, blockwidth)
```

But read the DimensionalData.jl `show.jl` code for details.
"""
function show_after(io::IO, mime, A::AbstractBasicDimArray)
    blockwidth = get(io, :blockwidth, 0)
    print_block_close(io, blockwidth)
    ndims(A) > 0 && println(io)
    print_array(io, mime, A)
end

function print_ndims(io, size::Tuple; 
    colors=map(dimcolors, ntuple(identity, length(size)))
)
    if length(size) > 1
        print_sizes(io, size; colors)
        print(io, ' ')
    elseif length(size) == 1
        printstyled(io, Base.dims2string(size), " "; color=first(colors))
    else
        print(io, Base.dims2string(size), " ")
    end
end

print_type(io, x::AbstractArray{T,N}) where {T,N} = print(io, string(nameof(typeof(x)), "{$T,$N}"))
print_type(io, x) = print(io, string(nameof(typeof(x))))

function print_top(io, mime, A)
    _, displaywidth = displaysize(io)
    blockwidth = min(displaywidth - 2, textwidth(sprint(summary, A)) + 2)
    printstyled(io, '╭', '─'^blockwidth, '╮'; color=:light_black)
    println(io)
    printstyled(io, "│ "; color=:light_black)
    summary(io, A)
    printstyled(io, " │"; color=:light_black)
    println(io)
    n, blockwidth = print_dims_block(io, mime, dims(A); displaywidth, blockwidth)
    lines = 2 + n
    return lines, blockwidth, displaywidth
end

function print_sizes(io, size;
    colors=map(dimcolors, ntuple(identity, length(size)))
)
    if !isempty(size)
        foreach(enumerate(size[1:end-1])) do (n, s)
            printstyled(io, s; color=colors[n])
            print(io, '×')
        end
        printstyled(io, last(size); color=colors[length(size)])
    end
end

function print_dims_block(io, mime, dims; displaywidth, blockwidth, label="dims", kw...)
    lines = 0
    if isempty(dims)
        printed = false
        new_blockwidth = blockwidth
    else
        dim_lines = split(sprint(print_dims, mime, dims), '\n')
        new_blockwidth = max(blockwidth, min(displaywidth - 2, maximum(textwidth, dim_lines)))
        lines += print_block_top(io, label, blockwidth, new_blockwidth)
        ctx = IOContext(io, :dim_brackets=>false)
        lines += print_dims(ctx, mime, dims; kw...)
        println(io)
        lines += 1
        printed = true
    end
    return lines, new_blockwidth, printed
end

function print_metadata_block(io, mime, metadata; blockwidth=0, displaywidth)
    lines = 0
    if metadata isa NoMetadata
        new_blockwidth = blockwidth
    else
        metadata_lines = split(sprint(show, mime, metadata), "\n")
        new_blockwidth = min(displaywidth-2, max(blockwidth, maximum(length, metadata_lines) + 4))
        new_blockwidth = print_block_separator(io, "metadata", blockwidth, new_blockwidth)
        println(io)
        print(io, "  ")
        show(io, mime, metadata)
        println(io)
        lines += length(metadata_lines) + 2
    end
    return lines, new_blockwidth
end

# Block lines

function print_block_top(io, label, prev_width, new_width)
    corner = (new_width > prev_width) ? '┐' : '┤'
    top_line = if new_width > prev_width
        string(
            '├', '─'^(prev_width), '┴', 
            '─'^max(0, (new_width - textwidth(label) - 3 - prev_width)), 
            ' ', label, ' ', corner
        )
    else
        string('├', '─'^max(0, new_width - textwidth(label) - 2), ' ', label, ' ', corner)
    end
    printstyled(io, top_line; color=:light_black)
    println(io)
    lines = 1
    return lines
end

function print_block_separator(io, label, prev_width, new_width=prev_width)
    if new_width > prev_width 
        line = string('├', '─'^max(0, prev_width), '┴', '─'^max(0, new_width - prev_width - textwidth(label) - 3) )
        corner = '┐'
    else
        line = string('├', '─'^max(0, new_width - textwidth(label) - 2))
        corner = '┤'
    end
    full = string(line, ' ', label, ' ', corner)
    printstyled(io, full; color=:light_black)
    return length(full) - 2
end

function print_block_close(io, blockwidth)
    closing_line = string('└', '─'^blockwidth, '┘')
    printstyled(io, closing_line; color=:light_black)
end

# Showing the array is optional for AbstractDimArray
# `print_array` must be called from `show_after`.
function print_array(io::IO, mime, A::AbstractBasicDimArray{T,0}) where T
    print(_print_array_ctx(io, T), "\n", A[])
end
function print_array(io::IO, mime, A::AbstractBasicDimArray{T,1}) where T
    Base.print_matrix(_print_array_ctx(io, T), A)
end
function print_array(io::IO, mime, A::AbstractBasicDimArray{T,2}) where T
    Base.print_matrix(_print_array_ctx(io, T), A)
end
function print_array(io::IO, mime, A::AbstractBasicDimArray{T,3}) where T
    i3 = firstindex(A, 3)
    frame = view(A, :, :, i3)

    _print_indices_vec(io, i3)
    Base.print_matrix(_print_array_ctx(io, T), frame)
end
function print_array(io::IO, mime, A::AbstractBasicDimArray{T,N}) where {T,N}
    o = ntuple(x -> firstindex(A, x + 2), N-2)
    frame = view(A, :, :, o...)

    _print_indices_vec(io, o...)
    Base.print_matrix(_print_array_ctx(io, T), frame)
end

function _print_indices_vec(io, o...)
    print(io, "[")
    printstyled(io, ":"; color=dimcolors(1))
    print(io, ", ")
    printstyled(io, ":"; color=dimcolors(2))
    foreach(enumerate(o)) do (i, fi)
        print(io, ", ")
        printstyled(io, fi; color=dimcolors(i + 2))
    end
    println(io, "]")
end

function _print_array_ctx(io, T)
    IOContext(io, :compact=>true, :typeinfo=>T)
end
# print a name of something, in yellow
function print_name(io::IO, name)
    if !(name == Symbol("") || name isa NoName)
        printstyled(io, string(" ", name); color=dimcolors(7))
    end
end

# A wrapper to show objects with dimension colors or arrows
struct ShowWith <: AbstractString
    val::Any
    mode::Symbol
    color::Union{Int,Symbol}
end
ShowWith(val; mode=:nothing, color=:light_black) = ShowWith(val, mode, color)

showrowlabel(x) = ShowWith(x, :nothing, dimcolors(1))
showcollabel(x) = ShowWith(x, :nothing, dimcolors(2))
showarrows() = ShowWith(1.0, :print_arrows, :nothing)

function Base.show(io::IO, mime::MIME"text/plain", x::ShowWith; kw...)
    if x.mode == :print_arrows
        printstyled(io, dimsymbols(1); color=dimcolors(1))
        print(io, " ")
        printstyled(io, dimsymbols(2); color=dimcolors(2))
    else
        s = sprint(show, mime, x.val; context=io, kw...)
        printstyled(io, s; color=x.color)
    end
end
function Base.show(io::IO, x::ShowWith)
    printstyled(io, string(x.val); color = x.color, hidden = x.mode == :hide)
end

function Base.alignment(io::IO, x::ShowWith)
    # Base bug means we need to special-case this
    if x.val isa DateTime
        0, textwidth(sprint(print, x.val))
    else
        Base.alignment(io, x.val)
    end
end
function Base.print(io::IO, x::ShowWith)
    printstyled(io, string(x.val); color = x.color, hidden = x.mode == :hide)
end

Base.iterate(x::ShowWith) = iterate(string(x.val))
Base.iterate(x::ShowWith, i::Int) = iterate(string(x.val), i::Int)

# A lazy array wrapper to print lookup values as an extra row and/or column
struct LazyLabelledPrintMatrix{A,LL,LT} <: AbstractArray{Any,2}
    data::A
    rowlabels::LL
    collabels::LT
end
function LazyLabelledPrintMatrix(A::AbstractBasicDimArray{<:Any,1})
    LazyLabelledPrintMatrix(parent(A), lookup(A, 1), lookup(A, 1))
end
function LazyLabelledPrintMatrix(A::AbstractBasicDimArray{<:Any,2})
    LazyLabelledPrintMatrix(parent(A), lookup(A, 1), lookup(A, 2))
end

function Base.size(A::LazyLabelledPrintMatrix)
    n = ndims(A.data)
    if n == 1
        return length(A.data), A.rowlabels isa NoLookup ? 1 : 2
    else
        labelsize = A.collabels isa NoLookup ? 0 : 1, A.rowlabels isa NoLookup ? 0 : 1
        return map(+, labelsize, size(A.data))
    end
end

@propagate_inbounds function Base.getindex(A::LazyLabelledPrintMatrix, i::Integer, j::Integer)
    @boundscheck checkbounds(A, i, j)
    oi = i + firstindex(A.data, 1) - 1
    if ndims(A.data) == 1 
        if A.rowlabels isa NoLookup
            A.data[oi]
        else
            if j == 1
                showrowlabel(A.rowlabels[oi])
            elseif j == 2
                A.data[oi]
            end
        end
    else # N == 2
        oj = j + firstindex(A.data, 2) - 1
        if A.rowlabels isa NoLookup
            if A.collabels isa NoLookup
                A.data[oi, oj]
            else
                if i == 1
                    showcollabel(A.collabels[oj])
                else # i > 1
                    A.data[oi - 1, oj]
                end
            end
        else # !(A.rowlabels isa NoLookup)
            if A.collabels isa NoLookup
                if j == 1
                    showrowlabel(A.rowlabels[oi])
                else # j > 1
                    A.data[oi, oj - 1]
                end
            else
                if j == 1
                    if i == 1
                        showarrows()
                    else # i > 1
                        showrowlabel(A.rowlabels[oi - 1])
                    end
                else # j > 1
                    if i == 1
                        showcollabel(A.collabels[oj - 1])
                    else # i > 1
                        A.data[oi - 1, oj - 1]
                    end
                end
            end
        end
    end
end
