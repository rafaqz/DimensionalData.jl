using DimensionalData.Dimensions: dimcolors, dimsymbols, print_dims

function Base.summary(io::IO, A::AbstractDimArray{T,N}) where {T,N}
    if N > 1
        print_sizes(io, size(A))
        print(io, ' ')
    else
        print(io, Base.dims2string(size(A)), " ")
    end
    print(io, string(nameof(typeof(A)), "{$T,$N}"))
    print_name(io, name(A))
end

function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray{T,N}) where {T,N}
    lines, maxlen, width = print_top(io, mime, A)
    m, _ = print_metadata_block(io, mime, metadata(A); width, maxlen=min(width, maxlen))
    lines += m

    # Printing the array data is optional, subtypes can
    # show other things here instead.
    ds = displaysize(io)
    ioctx = IOContext(io, :displaysize => (ds[1] - lines, ds[2]))
    show_after(ioctx, mime, A; maxlen)
    return nothing
end

function print_top(io, mime, A; bottom_border=metadata(A) isa Union{Nothing,NoMetadata})
    lines = 4
    _, width = displaysize(io)
    upchar = maxlen = min(width, length(sprint(summary, A)) + 2)
    printstyled(io, '╭', '─'^maxlen, '╮'; color=:light_black)
    println(io)
    printstyled(io, "│ "; color=:light_black)
    summary(io, A)
    printstyled(io, " │"; color=:light_black)
    p = sprint(mime, dims(A)) do args...
        print_dims_block(args...; upchar=maxlen, bottom_border, width, maxlen)
    end
    maxlen = max(maxlen, maximum(length, split(p, '\n')))
    p = sprint(mime, metadata(A)) do args...
        print_metadata_block(args...; width, maxlen)
    end
    maxlen = max(maxlen, maximum(length, split(p, '\n')))
    n, maxlen = print_dims_block(io, mime, dims(A); upchar, width, bottom_border, maxlen)
    lines += n
    return lines, maxlen, width
end

function print_sizes(io, size;
    colors=map(dimcolors, ntuple(identity, length(size)))
)
    foreach(enumerate(size[1:end-1])) do (n, s)
        printstyled(io, s; color=colors[n])
        print(io, '×')
    end
    printstyled(io, last(size); color=colors[length(size)])
end

function print_dims_block(io, mime, dims; bottom_border=true, upchar, width, maxlen)
    lines = 0
    if !isempty(dims)
        # if all(l -> l isa NoLookup, lookup(dims))
            # printstyled(io, '├', '─'^(upchar), '┴', '─'^max(0, (maxlen - 7 - upchar)), " dims ┐"; color=:light_black)
            # print(io, ' ')
            # lines += print_dims(io, mime, dims)
        # else
            dim_string = sprint(print_dims, mime, dims)
            maxlen = min(width - 2, max(maxlen, maximum(length, split(dim_string, '\n'))))
            println(io)
            printstyled(io, '├', '─'^(upchar), '┴', '─'^max(0, (maxlen - 7 - upchar)), " dims ┐"; color=:light_black)
            println(io)
            lines += print_dims(io, mime, dims)
            println(io)
            lines += 2
        # end
    end
    return lines, maxlen
end

function print_metadata_block(io, mime, metadata; maxlen=0, width)
    lines = 0
    if !(metadata isa NoMetadata)
        metadata_print = split(sprint(show, mime, metadata), "\n")
        maxlen = min(width-2, max(maxlen, maximum(length, metadata_print)))
        printstyled(io, '├', '─'^max(0, maxlen - 10), " metadata ┤"; color=:light_black)
        println(io)
        print(io, "  ")
        show(io, mime, metadata)
        println(io)
        lines += length(metadata_print) + 3
    end
    return lines, maxlen
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

Most likely you always want to close the box with:

'''julia
printstyled(io, '└', '─'^maxlen, '┘'; color=:light_black)
'''
"""
function show_after(io::IO, mime, A::AbstractDimArray; maxlen, kw...)
    printstyled(io, '└', '─'^maxlen, '┘'; color=:light_black)
    println(io)
    print_array(io, mime, A)
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
        printstyled(io, string(" ", name); color=dimcolors(100))
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
    lu = lookups[1]
    labels = vcat(map(showblack, parent(lu)[itop]), map(showblack, parent(lu))[ibottom])
    vals = map(showdefault, vcat(A[itop], A[ibottom]))
    A_dims = hcat(labels, vals)
    Base.print_matrix(io, A_dims)
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

    topleft = map(showdefault, A[itop, ileft])
    bottomleft = A[ibottom, ileft]
    if !(lu1 isa NoLookup)
        topleft = hcat(map(show1, parent(lu1)[itop]), topleft)
        bottomleft = hcat(map(show1, parent(lu1)[ibottom]), bottomleft)
    end

    leftblock = vcat(parent(topleft), parent(bottomleft))
    rightblock = vcat(A[itop, iright], A[ibottom, iright])
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
showblack(x) = ShowWith(x, :nothing, 242)
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
