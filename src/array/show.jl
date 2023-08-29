function Base.summary(io::IO, A::AbstractDimArray{T,0}) where {T}
    print(io, "0-dimensional ")
    print(io, string(nameof(typeof(A)), "{$T,0}"))
end
function Base.summary(io::IO, A::AbstractDimArray{T,1}) where {T}
    print(io, size(A, 1), "-element ")
    print(io, string(nameof(typeof(A)), "{$T,1}"))
end
function Base.summary(io::IO, A::AbstractDimArray{T,N}) where {T,N}
    print(io, join(size(A), "×"), " ")
    print(io, string(nameof(typeof(A)), "{$T,$N}"))
end

function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray)
    lines = 0
    summary(io, A)
    print_name(io, name(A))
    lines += Dimensions.print_dims(io, mime, dims(A))
    !(isempty(dims(A)) || isempty(refdims(A))) && println(io)
    lines += Dimensions.print_refdims(io, mime, refdims(A))
    println(io)

    # Printing the array data is optional, subtypes can 
    # show other things here instead.
    ds = displaysize(io)
    ioctx = IOContext(io, :displaysize => (ds[1] - lines, ds[2]))
    show_after(ioctx, mime, A)
    return nothing
end


# Semi-interface methods for adding addional `show` text
# for AbstractDimArray/AbstractDimStack subtypes
# TODO actually document in the interface
show_after(io::IO, mime, A::AbstractDimArray) = print_array(io, mime, A)

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
    println(io, "[:, :, $i3]")
    _print_matrix(_print_array_ctx(io, T), frame, lookup(A, (1, 2)))
    nremaining = size(A, 3) - 1
    nremaining > 0 && printstyled(io, "\n[and $nremaining more slices...]"; color=:light_black)
end
function print_array(io::IO, mime, A::AbstractDimArray{T,N}) where {T,N}
    o = ntuple(x -> firstindex(A, x + 2), N-2)
    frame = view(A, :, :, o...)
    onestring = join(o, ", ")
    println(io, "[:, :, $(onestring)]")
    _print_matrix(_print_array_ctx(io, T), frame, lookup(A, (1, 2)))
    nremaining = prod(size(A, d) for d=3:N) - 1
    nremaining > 0 && printstyled(io, "\n[and $nremaining more slices...]"; color=:light_black)
end

function _print_array_ctx(io, T)
    IOContext(io, :compact=>true, :limit=>true, :typeinfo=>T)
end
# print a name of something, in yellow
function print_name(io::IO, name)
    if !(name == Symbol("") || name isa NoName)
        printstyled(io, string(" ", name); color=:yellow)
    end
end

Base.print_matrix(io::IO, A::AbstractDimArray) = _print_matrix(io, parent(A), lookup(A))
# Labelled matrix printing is modified from AxisKeys.jl, thanks @mcabbot
function _print_matrix(io::IO, A::AbstractArray{<:Any,1}, lookups::Tuple)
    h, w = displaysize(io)
    lu = lookups[1]
    wn = w ÷ 3 # integers take 3 columns each when printed, floats more
    f1, l1, s1 = firstindex(A, 1), lastindex(A, 1), size(A, 1)
    itop =    s1 < h ? (f1:l1) : (f1:f1 + (h ÷ 2) - 1)
    ibottom = s1 < h ? (1:0)   : (f1 + s1 - (h ÷ 2) - 1:f1 + s1 - 1)
    labels = vcat(map(showblack, parent(lu)[itop]), map(showblack, parent(lu))[ibottom])
    vals = map(showdefault, vcat(A[itop], A[ibottom]))
    A_dims = hcat(labels, vals)
    Base.print_matrix(io, A_dims)
    return nothing
end
_print_matrix(io::IO, A::AbstractDimArray, lookups::Tuple) = _print_matrix(io, parent(A), lookups) 
function _print_matrix(io::IO, A::AbstractArray, lookups::Tuple)
    lu1, lu2 = lookups
    h, w = displaysize(io)
    wn = w ÷ 3 # integers take 3 columns each when printed, floats more
    f1, f2 = firstindex(lu1), firstindex(lu2)
    l1, l2 = lastindex(lu1), lastindex(lu2)
    s1, s2 = size(A)
    itop    = s1 < h  ? (f1:l1)     : (f1:h ÷ 2 + f1 - 1)
    ibottom = s1 < h  ? (f1:f1 - 1) : (f1 + s1 - h ÷ 2 - 1:f1 + s1 - 1)
    ileft   = s2 < wn ? (f2:l2)     : (f2:f2 + wn ÷ 2 - 1)
    iright  = s2 < wn ? (f2:f2 - 1) : (f2 + s2 - wn ÷ 2:f2 + s2 - 1)

    topleft = map(showdefault, A[itop, ileft])
    bottomleft = A[ibottom, ileft]
    if !(lookups[1] isa NoLookup)
        topleft = hcat(map(showblack, parent(lu1)[itop]), topleft)
        bottomleft = hcat(map(showblack, parent(lu1)[ibottom]), bottomleft)
    end

    leftblock = vcat(parent(topleft), parent(bottomleft))
    rightblock = vcat(A[itop, iright], A[ibottom, iright])
    bottomblock = hcat(leftblock, rightblock)

    A_dims = if lu2 isa NoLookup
        map(showdefault, bottomblock)
    else
        toplabels = map(showblack, parent(lu2)[ileft]), map(showblack, parent(lu2)[iright])
        toprow = if lu1 isa NoLookup
            vcat(toplabels...)
        else
            vcat(showhide(0), toplabels...)
        end |> permutedims
        vcat(toprow, map(showdefault, bottomblock))
    end
    Base.print_matrix(io, A_dims)
    return nothing
end

struct ShowWith <: AbstractString
    val::Any
    hide::Bool
    color::Symbol
end
ShowWith(val; hide=false, color=:light_black) = ShowWith(val; hide, color)
function Base.show(io::IO, mime::MIME"text/plain", x::ShowWith; kw...)
    s = sprint(show, mime, x.val; context=io, kw...)
    s1 = x.hide ? " "^length(s) : s
    printstyled(io, s1; color=x.color)
end
showdefault(x) = ShowWith(x, false, :default)
showblack(x) = ShowWith(x, false, :light_black)
showhide(x) = ShowWith(x, true, :nothing)

Base.alignment(io::IO, x::ShowWith) = Base.alignment(io, x.val)
Base.length(x::ShowWith) = length(string(x.val))
Base.ncodeunits(x::ShowWith) = ncodeunits(string(x.val))
Base.print(io::IO, x::ShowWith) = printstyled(io, string(x.val))
Base.iterate(x::ShowWith) = iterate(string(x.val))
Base.iterate(x::ShowWith, i::Int) = iterate(string(x.val), i::Int)
