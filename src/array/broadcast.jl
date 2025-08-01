import Base.Broadcast: BroadcastStyle, DefaultArrayStyle, Style, AbstractArrayStyle

const STRICT_BROADCAST_CHECKS = Ref(true)
const STRICT_BROADCAST_DOCS = """
With `strict=true` we check [`Lookup`](@ref) [`Order`](@ref) and values 
before brodcasting, to ensure that dimensions match closely. 

An exception to this rule is when dimension are of length one, 
as these is ignored in broadcasts.

We always check that dimension names match in broadcasts.
If you don't want this either, explicitly use `parent(A)` before
broadcasting to remove the `AbstractDimArray` wrapper completely.
"""

"""
    strict_broadcast()

Check if strict broadcasting checks are active.

$STRICT_BROADCAST_DOCS
"""
strict_broadcast() = STRICT_BROADCAST_CHECKS[]

"""
    strict_broadcast!(x::Bool)

Set global broadcasting checks to `strict`, or not for all `AbstractDimArray`.

$STRICT_BROADCAST_DOCS
"""
strict_broadcast!(x::Bool) = STRICT_BROADCAST_CHECKS[] = x

# This is a `BroadcastStyle` for AbstractAbstractDimArray's
# It preserves the dimension names.
# `S` should be the `BroadcastStyle` of the wrapped type.
# Copied from NamedDims.jl (thanks @oxinabox).
struct DimensionalStyle{S <: AbstractArrayStyle, N} <: AbstractArrayStyle{N} end
DimensionalStyle{S}() where {S<:AbstractArrayStyle{N}} where N = DimensionalStyle{S, N}()
DimensionalStyle(::S) where {S} = DimensionalStyle{S}()
DimensionalStyle{S}(::Val{N}) where {S,N} = DimensionalStyle{S{N}, N}()
DimensionalStyle{S,M}(v::Val{N}) where {S<:AbstractArrayStyle,M,N} = DimensionalStyle(S(v))
DimensionalStyle(::Val{N}) where N = DimensionalStyle{DefaultArrayStyle{N}, N}()
function DimensionalStyle(a::BroadcastStyle, b::BroadcastStyle)
    inner_style = BroadcastStyle(a, b)
    # if the inner style is Unknown then so is the outer style
    if inner_style isa Unknown
        return Unknown()
    else
        return DimensionalStyle(inner_style)
    end
end

function BroadcastStyle(::Type{<:AbstractDimArray{T,N,D,A}}) where {T,N,D,A}
    inner_style = typeof(BroadcastStyle(A))
    return DimensionalStyle{inner_style}()
end

BroadcastStyle(::DimensionalStyle, ::Base.Broadcast.Unknown) = Unknown()
BroadcastStyle(::Base.Broadcast.Unknown, ::DimensionalStyle) = Unknown()
BroadcastStyle(::DimensionalStyle{A}, ::DimensionalStyle{B}) where {A, B} = DimensionalStyle(A(), B())
BroadcastStyle(::DimensionalStyle{A}, b::Style) where {A} = DimensionalStyle(A(), b)
BroadcastStyle(a::Style, ::DimensionalStyle{B}) where {B} = DimensionalStyle(a, B())
BroadcastStyle(::DimensionalStyle{A}, b::Style{Tuple}) where {A} = DimensionalStyle(A(), b)
BroadcastStyle(a::Style{Tuple}, ::DimensionalStyle{B}) where {B} = DimensionalStyle(a, B())
# We need to implement copy because if the wrapper array type does not
@inline function Broadcast.instantiate(bc::Broadcasted{<:DimensionalStyle{S}}) where S
    A = _firstdimarray(bc)
    A isa Nothing && return Broadcast.instantiate(Broadcasted(S, bc.f, bc.args, axes)) # no dimarrays, so remove the wrapper
    bdims = _broadcasted_dims(bc)
    if bc.axes isa Nothing
        _comparedims_broadcast(A, bdims...)
        axes = Base.Broadcast.combine_axes(map(_unwrap_broadcasted, bc.args)...)
        ds = Dimensions.promotedims(bdims...; skip_length_one=true)
        length(axes) == length(ds) || 
            throw(ArgumentError("Number of broadcasted dimensions $(length(axes)) larger than $(ds)"))
        axes = map(Dimensions.DimUnitRange, axes, ds)
    else # bc already has axes which might have dimensions, e.g. when assigning to a DimArray
        axes = bc.axes
        Base.Broadcast.check_broadcast_axes(axes, bc.args...)
        ds = dims(axes)
        isnothing(ds) ? _comparedims_broadcast(A, bdims...) : _comparedims_broadcast(A, ds, bdims...)
    end
    return Broadcasted(bc.style, bc.f, bc.args, axes)
end

function Base.similar(bc::Broadcasted{DimensionalStyle{S,N}}, ::Type{T}) where {S,N,T}
    A = _firstdimarray(bc)
    rebuild(A, data = similar(_unwrap_broadcasted(bc), T), dims = dims(axes(bc)))
end

@inline Base.copyto!(dest::AbstractArray, bc::Broadcasted{<:DimensionalStyle{S}}) where S = 
    Base.copyto!(dest, _unwrap_broadcasted(bc))

"""
    @d broadcast_expression options

Dimensional broadcast macro extending Base Julia
broadcasting to work with missing and permuted dimensions.

Will permute and reshape singleton dimensions
so that all [`AbstractDimArray`](@ref) in a broadcast will
broadcast over matching dimensions.

It is possible to pass options as the second argument of 
the macro to control the behaviour, as a single assignment
or as a NamedTuple. Options names must be written explicitly,
not passed in namedtuple variable.

# Options

- `dims`: Pass a Tuple of `Dimension`s, `Dimension` types or `Symbol`s
    to fix the dimension order of the output array. Otherwise dimensions
    will be in order of appearance. If dims with lookups are passed, these will 
    be applied to the returned array with  `set`.
- `strict`: `true` or `false`. Check that all lookup values match explicitly.

All other keywords are passed to `DimensionalData.rebuild`. This means
`name`, `metadata`, etc for the returned array can be set here, 
or for example `missingval` in Rasters.jl.

# Example

```julia
using DimensionalData
da1 = ones(X(3))
da2 = fill(2, Y(4), X(3))

@d da1 .* da2
@d da1 .* da2 .+ 5 dims=(Y, X)
@d da1 .* da2 .+ 5 (dims=(Y, X), strict=false, name=:testname)
```

## Use with `@.`

`@d` does not imply `@.`. You need to specify each broadcast. 
But `@.` can be used with `@d` as the _inner_ macro.

```julia
using DimensionalData
da1 = ones(X(3))
da2 = fill(2, Y(4), X(3))

@d @. da1 * da2
# Use parentheses around `@.` if you need to pass options
@d (@. da1 * da2 .+ 5) dims=(Y, X)
```

"""
macro d(expr::Expr, options::Union{Expr,Nothing}=nothing)
    options_dict, options_expr = _process_d_macro_options(options)
    broadcast_expr, var_list = _find_broadcast_vars(expr)
    var_list_assignments = map(var_list) do (name, expr)
        Expr(:(=), name, expr)
    end
    vars_expr = esc(Expr(:tuple, map(first, var_list)...))
    var_list_expr = esc(Expr(:block, var_list_assignments...))
    dims_expr = if haskey(options_dict, :dims)
        order_dims = options_dict[:dims]
        quote
            order_dims = $order_dims
            found_dims = _find_dims(vars)
            all(hasdim(order_dims, found_dims)) || 
                throw(ArgumentError("order $(basedims(order_dims)) dont match dimensions found in arrays $(basedims(found_dims))"))
            dims = $DimensionalData.dims(found_dims, order_dims)
        end
    else
        quote
            dims = _find_dims(vars)
        end
    end
    quote
        let
            options = $options_expr
            $var_list_expr
            vars = $vars_expr
            $dims_expr
            $broadcast_expr
        end
    end
end
macro d(sym::Symbol, options::Union{Expr,Nothing}=nothing)
    esc(sym)
end

# Process the options named tuple passed to the @d macro
# returning a Dict of options, and an expression that makes
# a NamedTuple of options
_process_d_macro_options(::Nothing) = Dict{Symbol,Any}(), :(nothing)
function _process_d_macro_options(options::Expr)
    options_dict = Dict{Symbol,Any}()
    if options.head == :tuple
        if options.args[1].head == :parameters
            # Keyword syntax `(; dims=..., strict=false)
            for arg in options.args[1].args
                arg.head == :kw || throw(ArgumentError("Malformed options in $options"))
                options_dict[arg.args[1]] = esc(arg.args[2])
            end
        else
            # Tuple syntax `(dims=..., strict=false)`
            for arg in options.args
                arg.head == :(=) || throw(ArgumentError("Malformed options in $options"))
                options_dict[arg.args[1]] = esc(arg.args[2])
            end
        end
    elseif options.head == :(=)
        # Single assignment `strict=false`
        options_dict[options.args[1]] = esc(options.args[2])
    end

    options_params = Expr(:parameters)
    for (k, v) in options_dict
        push!(options_params.args, Expr(:kw, k, v))
    end
    options_expr = Expr(:tuple, options_params) 

    return options_dict, options_expr
end

# Handle existing variable names
_find_broadcast_vars(sym::Symbol)::Tuple{Expr,Vector{Pair{Symbol,Any}}} = 
    esc(sym), Pair{Symbol,Any}[]
# Handle e.g. 1 in the expression
function _find_broadcast_vars(x)::Tuple{Expr,Vector{Pair{Symbol,Any}}}
    var = Symbol(gensym(), :_d)
    esc(var), Pair{Symbol,Any}[var => x]
end
# Walk the broadcast expression, finding broadcast arguments and 
# pulling them out of the main broadcast into separate variables. 
# This lets us get `dims` from all of them and use it to reshape 
# and permute them so they all match.
function _find_broadcast_vars(expr::Expr)::Tuple{Expr,Vector{Pair{Symbol,Any}}}
    # Integrate with dot macro
    if expr.head == :macrocall && expr.args[1] == Symbol("@__dot__")
        return _find_broadcast_vars(Base.Broadcast.__dot__(expr.args[3]))
    end
    mdb = :($DimensionalData._maybe_dimensional_broadcast)
    arg_list = Pair{Symbol,Any}[]

    # Dot broadcast syntax `f.(x)`
    if expr.head == :. && !(expr.args[2] isa QuoteNode) # function dot broadcast
        mdb_args = map(expr.args[2].args) do arg
            if arg isa Expr && arg.head == :parameters
                arg
            else
                var = Symbol(gensym(), :_d)
                expr1, arg_list1 = _find_broadcast_vars(arg)
                out = if isempty(arg_list1)
                    push!(arg_list, var => arg)
                    esc(var)
                else
                    append!(arg_list, arg_list1)
                    expr1
                end
                Expr(:call, mdb, out, :dims, :options)
            end
        end
        expr2 = Expr(expr.head, esc(expr.args[1]), Expr(:tuple, mdb_args...))
        return expr2, arg_list
    # Dot assignment broadcast syntax `x .= ...`
    elseif !isnothing(match(r"\..*=", string(expr.head)))
        # Destination array
        dest_var = Symbol(gensym(), :_d)
        push!(arg_list, dest_var => expr.args[1])
        mdb_dest_expr = Expr(:call, mdb, esc(dest_var), :dims, :options)
        # Source expression
        expr2, arg_list2 = _find_broadcast_vars(expr.args[2])
        source_expr = if isempty(arg_list2)
            var2 = Symbol(gensym(), :_d)
            push!(arg_list, var2 => expr.args[2])
            esc(var2)
        else
            append!(arg_list, arg_list2)
            expr2
        end
        mbd_source_expr = Expr(:call, mdb, source_expr, :dims, :options)
        return Expr(expr.head, mdb_dest_expr, mbd_source_expr), arg_list
    # Infix broadcast syntax `x .* y`
    elseif expr.head == :call && string(expr.args[1])[1] == '.'
        mdb_args = map(expr.args[2:end]) do arg
            var = Symbol(gensym(), :_d)
            expr1, arg_list1 = _find_broadcast_vars(arg)
            out = if isempty(arg_list1)
                push!(arg_list, var => arg)
                esc(var)
            else
                append!(arg_list, arg_list1)
                expr1
            end
            Expr(:call, mdb, out, :dims, :options)
        end
        expr2 = Expr(expr.head, expr.args[1], mdb_args...)
        return expr2, arg_list
    else # Not part of the broadcast, just return it
        expr2 = esc(expr)
        return expr2, arg_list
    end
end

# A wrapper AbstractDimArray only to be used in @d broadcasts. 
# It should never escape
# options are both for broadcast tweaks and for keywords to the new DimArray
struct BroadcastOptionsDimArray{T,N,D<:Tuple,A<:AbstractBasicDimArray{T,N,D},O} <: AbstractDimArray{T,N,D,A}
    data::A
    options::O
    function BroadcastOptionsDimArray(
        data::A, options::O
    ) where {A<:AbstractDimArray{T,N,D},O} where {T,N,D}
        new{T,N,D,A,O}(data, options)
    end
end

# Get keywords from options
_rebuild_kw(A::BroadcastOptionsDimArray) = _rebuild_kw(; broadcast_options(A)...)
_rebuild_kw(; dims=nothing, strict=nothing, kw...) = kw

# Forward DD methods to the parent array
dims(A::BroadcastOptionsDimArray) = dims(parent(A))
refdims(A::BroadcastOptionsDimArray) = refdims(parent(A))
name(A::BroadcastOptionsDimArray) = name(parent(A))
metadata(A::BroadcastOptionsDimArray) = metadata(parent(A))

# Rebuild returns the parent AbstractDimArray rebuilt with options keywords. 
# Dimensions are updated with `set` if there is a dims keyword
function rebuild(A::BroadcastOptionsDimArray; kw...) 
    A1 = rebuild(parent(A); kw..., _rebuild_kw(A)...) 
    D = get(broadcast_options(A), :dims, nothing)
    if D isa DimTuple 
        return set(A1, broadcast_options(A).dims...)
    else
        return A1
    end
end
rebuild(A::BroadcastOptionsDimArray, args...) = rebuild(parent(A), args...) 
@inline function rebuild(
    A::BroadcastOptionsDimArray, data, dims::Tuple=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A),
)
    rebuild(A; data, dims, refdims, name, metadata, _rebuild_kw(A)...)
end

# Get the options NamedTuple from BroadcastOptionsDimArray
broadcast_options(_) = NamedTuple()
broadcast_options(A::BroadcastOptionsDimArray) = A.options



# Utils

# Run comparedims with settings depending on stictness
@inline function _comparedims_broadcast(A, dims...)
    isstrict = _is_strict(A)
    comparedims(dims...; 
        ignore_length_one=isstrict, order=isstrict, val=isstrict, length=false
    )
end

# Check if a broadcast is strict, or use the global setting
_is_strict(A::AbstractArray) = _is_strict(broadcast_options(A))
function _is_strict(options::NamedTuple) 
    if haskey(options, :strict)
        options[:strict]
    else
        strict_broadcast()
    end
end

# Recursively unwraps `AbstractDimArray`s and `DimensionalStyle`s.
# replacing the `AbstractDimArray`s with the wrapped array,
# and `DimensionalStyle` with the wrapped `BroadcastStyle`.
function _unwrap_broadcasted(bc::Broadcasted{<:DimensionalStyle{S}}) where {S}
    innerargs = map(_unwrap_broadcasted, bc.args)
    return Broadcasted{S}(bc.f, innerargs)
end
_unwrap_broadcasted(x) = x
_unwrap_broadcasted(nda::AbstractDimArray) = parent(nda)
_unwrap_broadcasted(boda::BroadcastOptionsDimArray) = parent(parent(boda))

# Get the first dimensional array in the broadcast
_firstdimarray(x::Broadcasted) = _firstdimarray(x.args)
_firstdimarray(x::Tuple{<:AbstractDimArray,Vararg}) = x[1]
_firstdimarray(ext::Base.Broadcast.Extruded) = _firstdimarray(ext.x)
function _firstdimarray(x::Tuple{<:Broadcasted,Vararg})
    found = _firstdimarray(x[1])
    if found isa Nothing
        _firstdimarray(tail(x))
    else
        found
    end
end
_firstdimarray(x::Tuple) = _firstdimarray(tail(x))
_firstdimarray(x::Tuple{}) = nothing

# Make sure all arrays have the same dims, and return them
_broadcasted_dims(bc::Broadcasted) = _broadcasted_dims(bc.args...)
_broadcasted_dims(a, bs...) = (_broadcasted_dims(a)..., _broadcasted_dims(bs...)...)
_broadcasted_dims(a::AbstractBasicDimArray) = (dims(a),)
_broadcasted_dims(a) = ()

# If an object is an AbstractBasicDimArray or a Dimension, reshape and permute 
# its dimensions to match the rest of the @d broadcast, otherwise do nothing.
_maybe_dimensional_broadcast(x, _, _) = x
function _maybe_dimensional_broadcast(A::AbstractBasicDimArray, dest_dims, options) 
    # Reshape first to avoid a ReshapedArray wrapper if possible
    A1 = _maybe_insert_length_one_dims(A, dest_dims)
    # Then permute and reorder
    A2 = _maybe_lazy_permute(A1, dest_dims)
    # Then rebuild with the new data and dims
    data = parent(A2)
    A3 = rebuild(A; data, dims=format(dims(A2), data))
    if isnothing(options)
        return A3
    else
        return BroadcastOptionsDimArray(A3, options)
    end
end
_maybe_dimensional_broadcast(d::Dimension, dims, options) = 
    _maybe_dimensional_broadcast(DimArray(parent(d), d), dims, options)

# Permute lazily if we need to
function _maybe_lazy_permute(A::AbstractBasicDimArray, dest)
    if dimsmatch(commondims(dims(A), dims(dest)), commondims(dims(dest), dims(A)))
        A
    else
        PermutedDimsArray(A, commondims(dims(dest), dims(A)))
    end
end

function _maybe_insert_length_one_dims(A::AbstractBasicDimArray, dims)
    if all(hasdim(A, dims)) 
        A 
    else
        _insert_length_one_dims(A, dims)
    end
end
# Insert `Length1NoLookup` and reshape the array where needed so 
# that missing dimensions are not a problem.
function _insert_length_one_dims(A::AbstractBasicDimArray, alldims)
    if basedims(dims(A)) == basedims(dims(A), alldims)
        lengths = map(alldims) do d 
            hasdim(A, d) ? size(A, d) : 1
        end
        newdims = map(alldims) do d 
            hasdim(A, d) ? dims(A, d) : rebuild(d, Lookups.Length1NoLookup())
        end
    else
        odims = otherdims(alldims, DD.dims(A))
        lengths = (size(A)..., map(_ -> 1, odims)...) 
        newdims = (dims(A)..., map(d -> rebuild(d, Lookups.Length1NoLookup()), odims)...)
    end
    newdata = reshape(parent(A), lengths)
    A1 = rebuild(A; data=newdata, dims=format(newdims, newdata))
    return A1
end

# Find dimensions in the list of brodcast arguments
# The returned dimension order is taken from the order dimensions 
# are found, but this algorithm could be improved 
@inline function _find_dims((A, args...)::Tuple{<:AbstractBasicDimArray,Vararg})::DimTupleOrEmpty
    expanded = _find_dims(args)
    if expanded === ()
        dims(A)
    else
        (dims(A)..., otherdims(expanded, dims(A))...)
    end
end
@inline _find_dims((d, args...)::Tuple{<:Dimension,Vararg}) =
    (d, otherdims(_find_dims(args), (d,))...)
@inline _find_dims(::Tuple{}) = ()
@inline _find_dims((_, args...)::Tuple) = _find_dims(args)
