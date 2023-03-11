
Base.show(io::IO, mime::MIME"text/plain", lookup::AutoLookup) = nothing

Base.show(io::IO, mime::MIME"text/plain", lookup::NoLookup) = print(io, "NoLookup")

function Base.show(io::IO, mime::MIME"text/plain", lookup::Transformed)
    show_compact(io, mime, lookup)
    show(io, mime, f(lookup))
    print(io, " ")
    ctx = IOContext(io, :compact=>true)
    show(ctx, mime, dim(lookup))
end

function Base.show(io::IO, mime::MIME"text/plain", lookup::LookupArray)
    show_compact(io, mime, lookup)
    get(io, :compact, false) && print_index(io, mime, parent(lookup))
    show_properties(io, mime, lookup)
    if !get(io, :compact, false) 
        println(io)
        printstyled(io, "wrapping: "; color=:light_black)
        Base.show(io, mime, parent(lookup))
    end
end

show_properties(io::IO, mime, lookup) = show_properties(io, lookup)
function show_properties(io::IO, lookup::AbstractSampled)
    print(io, " ")
    print_order(io, lookup)
    print(io, " ")
    print_span(io, lookup)
    print(io, " ")
    print_sampling(io, lookup)
end

function show_properties(io::IO, lookup::AbstractCategorical)
    print(io, " ")
    print_order(io, lookup)
end

function Base.show(io::IO, mime::MIME"text/plain", lookups::Tuple{LookupArray,Vararg{LookupArray}})
    length(lookups) > 0 || return 0
    ctx = IOContext(io, :compact=>true)
    if all(l -> l isa NoLookup, lookups)
        for l in lookups[begin:end-1]
            show(ctx, mime, l)
            print(io, ", ")
        end
        show(ctx, mime, lookups[end])
        return 0
    else # Dims get a line each
        lines = 3
        haskey(io, :inset) && print(io, "\n")
        inset = get(io, :inset, "")
        for l in lookups[begin:end-1]
            print(io, inset)
            show(ctx, mime, l)
            print(io, ",")
            lines += 2 # Often they wrap
            print(io, "\n")
        end
        print(io, inset)
        show(ctx, mime, lookups[end])
        return lines
    end
end

function show_compact(io, mime, lookup::LookupArray)
    print(io, nameof(typeof(lookup)))
    print(io, "{")
    print(io, string(eltype(lookup)))
    print(io, "}")
end

print_order(io, lookup) = print(io, nameof(typeof(order(lookup))))
print_span(io, lookup) = print(io, nameof(typeof(span(lookup))))
print_sampling(io, lookup) = print(io, nameof(typeof(sampling(lookup))))
function print_metadata(io, lookup)
    metadata(lookup) isa NoMetadata && return nothing
    print(io, nameof(typeof(metadata(lookup))))
end

function print_index(io, mime, A::AbstractRange, nchars=0)
    print(io, " ")
    printstyled(io, A; color=:cyan)
end
function print_index(io, mime, v::AbstractVector, nchars=0)
    print(io, " ")
    # Maximum 2 values for dates
    vals = if length(v) > 2 && eltype(v) <: Dates.TimeType
        "$(v[begin]), …, $(v[end])"
    # Maximum 4 values for other types 
    elseif length(v) > 5
        "$(v[begin]), $(v[begin+1]), …, $(v[end-1]), $(v[end])"
    else
        join((repr(va) for va in v), ", ")
    end
    printstyled(io, string(string(eltype(v)), "[", string(vals), "]"); color=:cyan)
end
