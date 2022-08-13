function Base.summary(io::IO, A::AbstractDimArray{T,N}) where {T,N}
    if N == 0  
        print(io, "0-dimensional ")
    elseif N == 1
        print(io, size(A, 1), "-element ")
    else
        print(io, join(size(A), "×"), " ")
    end
    print(io, string(nameof(typeof(A)), "{$T,$N}"))
end

function Base.show(io::IO, mime::MIME"text/plain", A::AbstractDimArray{T,N}) where {T,N}
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
function print_array(io::IO, mime, A::AbstractDimArray{T,N}) where {T,N}
    o = ntuple(x -> firstindex(A, x + 2), N-2)
    frame = view(A, :, :, o...)
    onestring = join(o, ", ")
    println(io, "[:, :, $(onestring)]")
    Base.print_matrix(_print_array_ctx(io, T), frame)
    nremaining = prod(size(A, d) for d=3:N) - 1
    nremaining > 0 && printstyled(io, "\n[and ", nremaining," more slices...]"; color=:light_black)
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

# Labelled matrix printing is modified from AxisKeys.jl, thanks @mcabbot
function Base.print_matrix(io::IO, A::AbstractDimArray)
    h, w = displaysize(io)
    wn = w ÷ 3 # integers take 3 columns each when printed, floats more

    A_dims = if ndims(A) == 1
        f1, l1, s1 = firstindex(A, 1), lastindex(A, 1), size(A, 1)
        itop =    s1 < h ? (f1:l1) : (f1:f1 + (h ÷ 2) - 1)
        ibottom = s1 < h ? (1:0)   : (f1 + s1 - (h ÷ 2) - 1:f1 + s1 - 1)
        labels = vcat(ShowWith.(lookup(A, 1)[itop]), ShowWith.(lookup(A, 1))[ibottom])
        vals = vcat(parent(A)[itop], parent(A)[ibottom])
        hcat(labels, vals)
    else
        f1, f2 = firstindex(A, 1), firstindex(A, 2)
        l1, l2 = lastindex(A, 1), lastindex(A, 2)
        s1, s2 = size(A)
        itop    = s1 < h  ? (f1:l1)     : (f1:h ÷ 2 + f1 - 1)
        ibottom = s1 < h  ? (f1:f1 - 1) : (f1 + s1 - h ÷ 2 - 1:f1 + s1 - 1)
        ileft   = s2 < wn ? (f2:l2)     : (f2:f2 + wn ÷ 2 - 1)
        iright  = s2 < wn ? (f2:f2 - 1) : (f2 + s2 - wn ÷ 2:f2 + s2 - 1)

        topleft = collect(A[itop, ileft])
        bottomleft = collect(A[ibottom, ileft])
        if !(lookup(A, 1) isa NoLookup)
            topleft = hcat(ShowWith.(lookup(A,1)[itop]), topleft)
            bottomleft = hcat(ShowWith.(lookup(A, 1)[ibottom]), bottomleft)
        end

        leftblock = vcat(topleft, bottomleft)
        rightblock = vcat(collect(A[itop, iright]), collect(A[ibottom, iright]))
        bottomblock = hcat(leftblock, rightblock)

        if lookup(A, 2) isa NoLookup
            bottomblock
        else
            toplabels = ShowWith.(lookup(A, 2))[ileft], ShowWith.(lookup(A, 2))[iright]
            toprow = if lookup(A, 1) isa NoLookup
                vcat(toplabels...)
            else
                vcat(ShowWith(0, hide=true), toplabels...)
            end |> permutedims
            vcat(toprow, bottomblock)
        end
    end
    Base.print_matrix(io, A_dims)
end

struct ShowWith{T,NT} <: AbstractString
    val::T
    hide::Bool
    nt::NT
    function ShowWith(val; hide::Bool=false, kw...)
        new{typeof(val),typeof(values(kw))}(val, hide, values(kw))
    end
end
function Base.show(io::IO, x::ShowWith; kw...)
    s = sprint(show, MIME"text/plain"(), x.val; context=io, kw...)
    s1 = x.hide ? " "^length(s) : s
    printstyled(io, s1; color=:light_black, x.nt...)
end
Base.alignment(io::IO, x::ShowWith) = Base.alignment(io, x.val)
Base.length(x::ShowWith) = length(string(x.val))
Base.ncodeunits(x::ShowWith) = ncodeunits(string(x.val))
Base.print(io::IO, x::ShowWith) = printstyled(io, string(x.val); x.nt...)
