using DimensionalData.Dimensions: dimcolors, dimsymbols, print_dims

# Base show
function Base.summary(io::IO, A::AbstractDimArray{T,N}) where {T,N}
    print_ndims(io, size(A))
    print(io, string(nameof(typeof(A)), "{$T,$N}"))
    print_name(io, name(A))
end

# Fancy show for text/plain
function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray{T,N}) where {T,N}
    lines, maxlen = show_main(io, mime, A::AbstractDimArray)
    # Printing the array data is optional, subtypes can
    # show other things here instead.
    ds = displaysize(io)
    ioctx = IOContext(io, :displaysize => (ds[1] - lines, ds[2]))
    show_after(ioctx, mime, A; maxlen)
    return nothing
end
# Defer simple 2-arg show to the parent array
Base.show(io::IO, A::AbstractDimArray) = show(io, parent(A))

"""
    show_main(io::IO, mime, A::AbstractDimArray; maxlen, kw...)
    show_main(io::IO, mime, A::AbstractDimStack; maxlen, kw...)

Interface methods for adding the main part of `show`

At the least, you likely want to call:

'''julia
print_top(io, mime, A)
'''

But read the DimensionalData.jl `show.jl` code for details.
"""
function show_main(io, mime, A::AbstractDimArray)
    lines_t, maxlen, width = print_top(io, mime, A)
    lines_m, maxlen = print_metadata_block(io, mime, metadata(A); width, maxlen=min(width, maxlen))
    return lines_t + lines_m, maxlen
end

"""
    show_after(io::IO, mime, A::AbstractDimArray; maxlen, kw...)
    show_after(io::IO, mime, A::AbstractDimStack; maxlen, kw...)

Interface methods for adding addional `show` text
for AbstractDimArray/AbstractDimStack subtypes.

*Always include `kw` to avoid future breaking changes*

Additional keywords may be added at any time.

Note - a anssi box is left unclosed. This method needs to close it,
or add more. `maxlen` is the maximum length of the inner text.

Most likely you always want to at least close the show blocks with:

'''julia
print_block_close(io, maxlen)
'''

But read the DimensionalData.jl `show.jl` code for details.
"""
function show_after(io::IO, mime, A::AbstractDimArray; maxlen, kw...)
    print_block_close(io, maxlen)
    ndims(A) > 0 && println(io)
    print_array(io, mime, A)
end


function print_ndims(io, size::Tuple)
    if length(size) > 1
        print_sizes(io, size)
        print(io, ' ')
    else
        print(io, Base.dims2string(size), " ")
    end
end

function print_top(io, mime, A)
    lines = 4
    _, width = displaysize(io)
    maxlen = min(width - 2, length(sprint(summary, A)) + 2)
    printstyled(io, '╭', '─'^maxlen, '╮'; color=:light_black)
    println(io)
    printstyled(io, "│ "; color=:light_black)
    summary(io, A)
    printstyled(io, " │"; color=:light_black)
    n, maxlen = print_dims_block(io, mime, dims(A); width, maxlen)
    lines += n
    return lines, maxlen, width
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

function print_dims_block(io, mime, dims; width, maxlen)
    lines = 0
    if isempty(dims)
        println(io)
        printed = false
        newmaxlen = maxlen
    else
        println(io)
        dim_lines = split(sprint(print_dims, mime, dims), '\n')
        newmaxlen = min(width - 2, max(maxlen, maximum(length, dim_lines)))
        print_block_top(io, "dims", maxlen, newmaxlen)
        lines += print_dims(io, mime, dims)
        println(io)
        lines += 2
        printed = true
    end
    return lines, newmaxlen, printed
end

function print_metadata_block(io, mime, metadata; maxlen=0, width, firstblock=false)
    lines = 0
    if metadata isa NoMetadata
        newmaxlen = maxlen
    else
        metadata_lines = split(sprint(show, mime, metadata), "\n")
        newmaxlen = min(width-2, max(maxlen, maximum(length, metadata_lines)))
        print_block_separator(io, "metadata", maxlen, newmaxlen)
        println(io)
        print(io, "  ")
        show(io, mime, metadata)
        println(io)
        lines += length(metadata_lines) + 3
    end
    return lines, newmaxlen
end

# Block lines

function print_block_top(io, label, prevmaxlen, newmaxlen)
    corner = (newmaxlen > prevmaxlen) ? '┐' : '┤'
    block_line = if newmaxlen > prevmaxlen
        string('─'^(prevmaxlen), '┴', '─'^max(0, (newmaxlen - length(label) - 3 - prevmaxlen)), ' ', label, ' ')
    else
        string('─'^max(0, newmaxlen - length(label) - 2), ' ', label, ' ')
    end
    printstyled(io, '├', block_line, corner; color=:light_black)
    println(io)
end

function print_block_separator(io, label, prevmaxlen, newmaxlen)
    corner = (newmaxlen > prevmaxlen) ? '┐' : '┤'
    printstyled(io, '├', '─'^max(0, newmaxlen - length(label) - 2), ' ', label, ' ', corner; color=:light_black)
end

function print_block_close(io, maxlen)
    printstyled(io, '└', '─'^maxlen, '┘'; color=:light_black)
end

# Showing the array is optional for AbstractDimArray
# `print_array` must be called from `show_after`.
function print_array(io::IO, mime, A::AbstractDimArray{T,0}) where T
    print(_print_array_ctx(io, T), "\n", A[])
end
function print_array(io::IO, mime, A::AbstractDimArray{T,1}) where T
    Base.print_matrix(_print_array_ctx(io, T), A)
end
function print_array(io::IO, mime, A::AbstractDimArray{T,2}) where T
    Base.print_matrix(_print_array_ctx(io, T), A)
end
function print_array(io::IO, mime, A::AbstractDimArray{T,3}) where T
    i3 = firstindex(A, 3)
    frame = view(parent(A), :, :, i3)

    _print_indices_vec(io, i3)
    _print_matrix(_print_array_ctx(io, T), frame, lookup(A, (1, 2)))
end
function print_array(io::IO, mime, A::AbstractDimArray{T,N}) where {T,N}
    o = ntuple(x -> firstindex(A, x + 2), N-2)
    frame = view(A, :, :, o...)

    _print_indices_vec(io, o...)
    _print_matrix(_print_array_ctx(io, T), frame, lookup(A, (1, 2)))
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

Base.print_matrix(io::IO, A::AbstractDimArray) = _print_matrix(io, parent(A), lookup(A))
# Labelled matrix printing is modified from AxisKeys.jl, thanks @mcabbot
function _print_matrix(io::IO, A::AbstractArray{<:Any,1}, lookups::Tuple)
    f1, l1, s1 = firstindex(A, 1), lastindex(A, 1), size(A, 1)
    if get(io, :limit, false)
        h, _ = displaysize(io)
        itop =    s1 < h ? (f1:l1) : (f1:f1 + (h ÷ 2) - 1)
        ibottom = s1 < h ? (1:0)   : (f1 + s1 - (h ÷ 2) - 1:f1 + s1 - 1)
    else
        itop    = f1:l1
        ibottom = 1:0
    end
    top = Array{eltype(A)}(undef, length(itop))
    copyto!(top, CartesianIndices(top), A, CartesianIndices(itop))
    bottom = Array{eltype(A)}(undef, length(ibottom)) 
    copyto!(bottom, CartesianIndices(bottom), A, CartesianIndices(ibottom))
    vals = vcat(A[itop], A[ibottom])
    lu = only(lookups)
    if lu isa NoLookup
        Base.print_matrix(io, vals)
    else
        labels = vcat(map(show1, parent(lu)[itop]), map(show1, parent(lu))[ibottom])
        Base.print_matrix(io, hcat(labels, vals))
    end
    return nothing
end
_print_matrix(io::IO, A::AbstractDimArray, lookups::Tuple) = _print_matrix(io, parent(A), lookups)
function _print_matrix(io::IO, A::AbstractArray, lookups::Tuple)
    lu1, lu2 = lookups
    f1, f2 = firstindex(lu1), firstindex(lu2)
    l1, l2 = lastindex(lu1), lastindex(lu2)
    if get(io, :limit, false)
        h, w = displaysize(io)
        wn = w ÷ 3 # integers take 3 columns each when printed, floats more
        s1, s2 = size(A)
        itop    = s1 < h  ? (f1:l1)     : (f1:h ÷ 2 + f1 - 1)
        ibottom = s1 < h  ? (f1:f1 - 1) : (f1 + s1 - h ÷ 2 - 1:f1 + s1 - 1)
        ileft   = s2 < wn ? (f2:l2)     : (f2:f2 + wn ÷ 2 - 1)
        iright  = s2 < wn ? (f2:f2 - 1) : (f2 + s2 - wn ÷ 2:f2 + s2 - 1)
    else
        itop    = f1:l1
        ibottom = f1:f1-1
        ileft   = f2:l2
        iright  = f2:f2-1
    end

    # A bit convoluted so it plays nice with GPU arrays
    topleft = Matrix{eltype(A)}(undef, map(length, (itop, ileft)))
    copyto!(topleft, CartesianIndices(topleft), A, CartesianIndices((itop, ileft)))
    bottomleft= Matrix{eltype(A)}(undef, map(length, (ibottom, ileft))) 
    copyto!(bottomleft, CartesianIndices(bottomleft), A, CartesianIndices((ibottom, ileft)))
    if !(lu1 isa NoLookup)
        topleft = hcat(map(show1, parent(lu1)[itop]), topleft)
        bottomleft = hcat(map(show1, parent(lu1)[ibottom]), bottomleft)
    end
    leftblock = vcat(topleft, bottomleft)
    topright = Matrix{eltype(A)}(undef, map(length, (itop, iright)))
    copyto!(topright, CartesianIndices(topright), A, CartesianIndices((itop, iright)))
    bottomright= Matrix{eltype(A)}(undef, map(length, (ibottom, iright))) 
    copyto!(bottomright, CartesianIndices(bottomright), A, CartesianIndices((ibottom, iright)))
    rightblock = vcat(topright, bottomright)
    bottomblock = hcat(leftblock, rightblock)

    A_dims = if lu2 isa NoLookup
        map(showdefault, bottomblock)
    else
        toplabels = map(show2, parent(lu2)[ileft]), map(show2, parent(lu2)[iright])
        toprow = if lu1 isa NoLookup
            vcat(toplabels...)
        else
            vcat(showarrows(), toplabels...)
        end |> permutedims
        vcat(toprow, map(showdefault, bottomblock))
    end

    Base.print_matrix(io, A_dims)
    return nothing
end

struct ShowWith <: AbstractString
    val::Any
    mode::Symbol
    color::Union{Int,Symbol}
end
ShowWith(val; mode=:nothing, color=:light_black) = ShowWith(val, mode, color)
function Base.show(io::IO, mime::MIME"text/plain", x::ShowWith; kw...)
    if x.mode == :print_arrows
        printstyled(io, dimsymbols(1); color=dimcolors(1))
        print(io, " ")
        printstyled(io, dimsymbols(2); color=dimcolors(2))
    elseif x.mode == :hide
        print(io, " ")
    else
        s = sprint(show, mime, x.val; context=io, kw...)
        printstyled(io, s; color=x.color)
    end
end
showdefault(x) = ShowWith(x, :nothing, :default)
show1(x) = ShowWith(x, :nothing, dimcolors(1))
show2(x) = ShowWith(x, :nothing, dimcolors(2))
showhide(x) = ShowWith(x, :hide, :nothing)
showarrows() = ShowWith(1.0, :print_arrows, :nothing)

Base.alignment(io::IO, x::ShowWith) = Base.alignment(io, x.val)
Base.length(x::ShowWith) = length(string(x.val))
Base.ncodeunits(x::ShowWith) = ncodeunits(string(x.val))
function Base.print(io::IO, x::ShowWith)
    printstyled(io, string(x.val); color = x.color, hidden = x.mode == :hide)
end
function Base.show(io::IO, x::ShowWith)
    printstyled(io, string(x.val); color = x.color, hidden = x.mode == :hide)
end

Base.iterate(x::ShowWith) = iterate(string(x.val))
Base.iterate(x::ShowWith, i::Int) = iterate(string(x.val), i::Int)
