"""
    mergedims(old_dims => new_dim) => Dimension
Return a dimension `new_dim` whose indices are a [`MergedLookup`](@ref) of the indices of
`old_dims`.
"""
function mergedims((old_dims, new_dim)::Pair)
    data = vec(DimPoints(_astuple(old_dims)))
    return rebuild(basedims(new_dim), MergedLookup(data, old_dims))
end

"""
    mergedims(dims, old_dims => new_dim, others::Pair...) => dims_new
If dimensions `old_dims`, `new_dim`, etc. are found in `dims`, then return new `dims_new`
where all dims in `old_dims` have been combined into a single dim `new_dim`.
The returned dimension will keep only the name of `new_dim`. Its coords will be a
[`MergedLookup`](@ref) of the coords of the dims in `old_dims`. New dimensions are always
placed at the end of `dims_new`. `others` contains other dimension pairs to be merged.
# Example
````jldoctest
julia> ds = (X(0:0.1:0.4), Y(10:10:100), Ti([0, 3, 4]));
julia> mergedims(ds, Ti => :time, (X, Y) => :space)
Dim{:time} MergedLookup{Tuple{Int64}} Tuple{Int64}[(0,), (3,), (4,)] Ti,
Dim{:space} MergedLookup{Tuple{Float64, Int64}} Tuple{Float64, Int64}[(0.0, 10), (0.1, 10), …, (0.3, 100), (0.4, 100)] X, Y
````
"""
function mergedims(all_dims, dim_pairs::Pair...)
    # filter out dims completely missing
    dim_pairs = map(x -> _filter_dims(all_dims, first(x)) => last(x), dim_pairs)
    dim_pairs_complete = filter(dim_pairs) do (old_dims,)
        dims_present = dims(all_dims, _astuple(old_dims))
        isempty(dims_present) && return false
        all(hasdim(dims_present, old_dims)) || throw(ArgumentError(
            "Not all dimensions $old_dims found in $(map(basetypeof, all_dims))"
        ))
        return true
    end
    isempty(dim_pairs_complete) && return all_dims
    dim_pairs_concrete = map(dim_pairs_complete) do (old_dims, new_dim)
        return dims(all_dims, _astuple(old_dims)) => new_dim
    end
    # throw error if old dim groups overlap
    old_dims_tuples = map(first, dim_pairs_concrete)
    if !dimsmatch(_cat_tuples(old_dims_tuples...), combinedims(old_dims_tuples...))
        throw(ArgumentError("Dimensions to be merged are not all unique"))
    end
    return _mergedims(all_dims, dim_pairs_concrete...)
end

"""
    mergedims(A::AbstractDimArray, dim_pairs::Pair...) => AbstractDimArray
Return a new array whose dimensions are the result of [`mergedims(dims(A), dim_pairs)`](@ref).
"""
function mergedims(A::AbstractDimArray, dim_pairs::Pair...)
    isempty(dim_pairs) && return A
    all_dims = dims(A)
    dims_new = mergedims(all_dims, dim_pairs...)
    dimsmatch(all_dims, dims_new) && return A
    dims_perm = _unmergedims(dims_new, map(last, dim_pairs))
    Aperm = PermutedDimsArray(A, dims_perm)
    data_merged = reshape(data(Aperm), map(length, dims_new))
    rebuild(A, data_merged, dims_new)
end

"""
    mergedims(ds::AbstractDimStack, dim_pairs::Pair...) => AbstractDimStack
Return a new stack where `mergedims(A, dim_pairs...)` has been applied to each layer `A` of
`ds`.
"""
function mergedims(ds::AbstractDimStack, dim_pairs::Pair...)
    isempty(dim_pairs) && return ds
    vals = map(A -> mergedims(A, dim_pairs...), values(ds))
    rebuild_from_arrays(ds, vals)
end

"""
    unmergedims(merged_dims)
Return the unmerged dimensions from a tuple of merged dimensions. However, the order of the original dimensions are not necessarily preserved.
"""
function unmergedims(merged_dims)
    reduce(map(dims, merged_dims), init=Tuple([])) do acc, x
        x isa Tuple ? (acc..., x...) : (acc..., x)
    end
end

"""
    unmergedims(A::AbstractDimArray, original_dims) => AbstractDimArray
Return a new array whose dimensions are restored to their original prior to calling [`mergedims(A, dim_pairs)`](@ref).
"""
function unmergedims(A::AbstractDimArray, original_dims)
    merged_dims = dims(A)
    unmerged_dims = unmergedims(merged_dims)
    reshaped = reshape(data(A), size(unmerged_dims))
    permuted = permutedims(reshaped, dimnum(unmerged_dims, original_dims))
    return DimArray(permuted, original_dims)
end

"""
    unmergedims(s::AbstractDimStack, original_dims) => AbstractDimStack
Return a new stack whose dimensions are restored to their original prior to calling [`mergedims(s, dim_pairs)`](@ref).
"""
function unmergedims(s::AbstractDimStack, original_dims)
    return map(A -> unmergedims(A, original_dims), s)
end

function _mergedims(all_dims, dim_pair::Pair, dim_pairs::Pair...)
    old_dims, new_dim = dim_pair
    dims_to_merge = dims(all_dims, _astuple(old_dims))
    merged_dim = mergedims(dims_to_merge => new_dim)
    all_dims_new = (otherdims(all_dims, dims_to_merge)..., merged_dim)
    isempty(dim_pairs) && return all_dims_new
    return _mergedims(all_dims_new, dim_pairs...)
end

function _unmergedims(all_dims, merged_dims)
    _merged_dims = dims(all_dims, merged_dims)
    unmerged_dims = map(all_dims) do d
        hasdim(_merged_dims, d) || return _astuple(d)
        return dims(lookup(d))
    end
    return _cat_tuples(unmerged_dims...)
end

_unmergedims(all_dims, dim_pairs::Pair...) = _cat_tuples(replace(all_dims, dim_pairs...))

_cat_tuples(tuples...) = mapreduce(_astuple, (x, y) -> (x..., y...), tuples)

_filter_dims(alldims, dims) = filter(dim -> hasdim(alldims, dim), dims)