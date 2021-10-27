
Base.show(io::IO, mime::MIME"text/plain", lookup::AutoLookup) = nothing

Base.show(io::IO, mime::MIME"text/plain", lookup::NoLookup) = print(io, "NoLookup")

function Base.show(io::IO, mime::MIME"text/plain", lookup::Transformed)
    show_compact(io, mime, lookup)
    print_dimval(io, mime, f(lookup))
    print(io, " ")
    show_compact(io, mime, dim(lookup))
end

function Base.show(io::IO, mime::MIME"text/plain", lookup::AbstractSampled)
    show_compact(io, mime, lookup)
    print_dimval(io, mime, parent(lookup))
    print(io, " ")
    print_order(io, lookup)
    print(io, " ")
    print_span(io, lookup)
    print(io, " ")
    print_sampling(io, lookup)
end

function Base.show(io::IO, mime::MIME"text/plain", lookup::AbstractCategorical)
    show_compact(io, mime, lookup)
    print_dimval(io, mime, parent(lookup))
    print(io, " ")
    print_order(io, lookup)
end

function Base.show(io::IO, mime::MIME"text/plain", lookups::Tuple{<:LookupArray,Vararg{<:LookupArray}})
    length(lookups) > 0 || return 0
    ctx = IOContext(io, :compact=>true)
    if all(l -> l isa NoLookup, lookups)
        for l in lookups[1:end-1]
            show(ctx, mime, l)
            print(io, ", ")
        end
        show(ctx, mime, lookups[end])
        return 0
    else # Dims get a line each
        lines = 3
        haskey(io, :inset) && print(io, "\n")
        inset = get(io, :inset, "")
        for l in lookups[1:end-1]
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

show_compact(io, mime, lookup::LookupArray) = print(io, nameof(typeof(lookup)))

print_order(io, lookup) = print(io, nameof(typeof(order(lookup))))
print_span(io, lookup) = print(io, nameof(typeof(span(lookup))))
print_sampling(io, lookup) = print(io, nameof(typeof(sampling(lookup))))
function print_metadata(io, lookup)
    metadata(lookup) isa NoMetadata && return nothing
    print(io, nameof(typeof(metadata(lookup))))
end
