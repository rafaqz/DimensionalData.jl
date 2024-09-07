import Base.Broadcast: BroadcastStyle, DefaultArrayStyle, Style

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
struct DimensionalStyle{S <: BroadcastStyle} <: AbstractArrayStyle{Any} end
DimensionalStyle(::S) where {S} = DimensionalStyle{S}()
DimensionalStyle(::S, ::Val{N}) where {S,N} = DimensionalStyle(S(Val(N)))
DimensionalStyle(::Val{N}) where N = DimensionalStyle{DefaultArrayStyle{N}}()
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
# support setindex then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{DimensionalStyle{S}}) where S
    A = _firstdimarray(bc)
    data = copy(_unwrap_broadcasted(bc))

    A isa Nothing && return data # No AbstractDimArray

    bdims = _broadcasted_dims(bc)
    _comparedims_broadcast(A, bdims...)

    data isa AbstractArray || return data # result is a scalar

    # unwrap AbstractDimArray data
    data = data isa AbstractDimArray ? parent(data) : data
    dims = format(Dimensions.promotedims(bdims...; skip_length_one=true), data)
    return rebuild(A; data, dims, refdims=refdims(A), name=Symbol(""))
end

function Base.copyto!(dest::AbstractArray, bc::Broadcasted{DimensionalStyle{S}}) where S
    _comparedims_broadcast(_firstdimarray(bc), _broadcasted_dims(bc)...)
    copyto!(dest, _unwrap_broadcasted(bc))
end

@inline function Base.Broadcast.materialize!(dest::AbstractDimArray, bc::Base.Broadcast.Broadcasted{<:Any})
    # Need to check whether the dims are compatible in dest, 
    # which are already stripped when sent to copyto!
    _comparedims_broadcast(dest, dims(dest), _broadcasted_dims(bc)...)
    style = DimensionalData.DimensionalStyle(Base.Broadcast.combine_styles(parent(dest), bc))
    Base.Broadcast.materialize!(style, parent(dest), bc)
    return dest
end

function Base.similar(bc::Broadcast.Broadcasted{DimensionalStyle{S}}, ::Type{T}) where {S,T}
    A = _firstdimarray(bc)
    rebuildsliced(A, similar(_unwrap_broadcasted(bc), T, axes(bc)...), axes(bc), Symbol(""))
end


"""
    @d broadcast_expression options

Dimensional broadcast macro extending Base Julia
broadcasting to work with missing and permuted dimensions.

Will permute and resshape singleton dimensions
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
da1 = ones(X(3))
da2 = fill(2, Y(4), X(3))

@d da1 .* da2
@d da1 .* da2 .+ 5 dims=(Y, X)
@d da1 .* da2 .+ 5 (dims=(Y, X), strict=false, name=:testname)
```

"""
macro d(expr::Expr, options::Union{Expr,Nothing}=nothing)
    options_dict, options_expr = _process_d_macro_options(options)
    broadcast_expr, var_list = _wrap_broadcast_vars(expr)
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
        :(dims = _find_dims(vars))
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

_wrap_broadcast_vars(sym::Symbol) = esc(sym), Pair{Symbol,Any}[]
function _wrap_broadcast_vars(expr::Expr)
    if expr.head == :macrocall && expr.args[1] == Symbol("@__dot__")
        return _wrap_broadcast_vars(Base.Broadcast.__dot__(expr.args[3]))
    end
    mdb = :($DimensionalData._maybe_dimensional_broadcast)
    arg_list = Pair{Symbol,Any}[]
    if expr.head == :. # function dot broadcast
        if expr.args[2] isa Expr
            wrapped_args = map(expr.args[2].args) do arg
                var = Symbol(gensym(), :_d)
                out = if arg isa Expr
                    expr1, arg_list1 = _wrap_broadcast_vars(arg)
                    append!(arg_list, arg_list1)
                    expr1
                else
                    arg1 = arg
                    push!(arg_list, var => arg1)
                    esc(var)
                end
                Expr(:call, mdb, out, :dims, :options)
            end
            expr2 = Expr(expr.head, esc(expr.args[1]), Expr(:tuple, wrapped_args...))
            return expr2, arg_list
        end
    elseif expr.head == :call && string(expr.args[1])[1] == '.' # infix broadcast
        wrapped_args = map(expr.args[2:end]) do arg
            var = Symbol(gensym(), :_d)
            out = if arg isa Expr
                expr1, arg_list1 = _wrap_broadcast_vars(arg)
                append!(arg_list, arg_list1)
                expr1
            else
                push!(arg_list, var => arg)
                esc(var)
            end
            Expr(:call, mdb, out, :dims, :options)
        end
        expr2 = Expr(expr.head, expr.args[1], wrapped_args...)
        return expr2, arg_list
    else # Not part of the broadcast, just return it
        expr2 = esc(expr)
        return expr2, arg_list
    end
end

# Only to be used in @d broadcasts, should never escape
struct BroadcastOptionsDimArray{T,N,D<:Tuple,A<:AbstractArray{T,N},O} <: AbstractDimArray{T,N,D,A}
    data::A
    options::O
    function BroadcastOptionsDimArray(
        data::A, options::O
    ) where {A<:AbstractDimArray{T,N},O} where {T,N}
        D = typeof(dims(data))
        new{T,N,D,A,O}(data, options)
    end
end

_rebuild_kw(A::BroadcastOptionsDimArray) = _rebuild_kw(; broadcast_options(A)...)
_rebuild_kw(; dims=nothing, strict=nothing, kw...) = kw

# Forward DD methods to the parent array
dims(A::BroadcastOptionsDimArray) = dims(parent(A))
refdims(A::BroadcastOptionsDimArray) = refdims(parent(A))
name(A::BroadcastOptionsDimArray) = name(parent(A))
metadata(A::BroadcastOptionsDimArray) = metadata(parent(A))

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
    # Use the keyword syntax to deal with options keywords
    # This lets keywords we don't know about get to extending AbstractDimArrays
    # Option keywords override the original parent DimArray properties.
    rebuild(A; 
        data, dims, refdims, name, metadata, _rebuild_keywords(A)...
    )
end

broadcast_options(_) = NamedTuple()
broadcast_options(A::BroadcastOptionsDimArray) = A.options



# Utils

@inline function _comparedims_broadcast(A, dims...)
    isstrict = _is_strict(A)
    comparedims(dims...; 
        ignore_length_one=isstrict, order=isstrict, val=isstrict, length=false
    )
end

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
function _unwrap_broadcasted(bc::Broadcasted{DimensionalStyle{S}}) where S
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

_maybe_dimensional_broadcast(x, _, _) = x
function _maybe_dimensional_broadcast(A::AbstractBasicDimArray, dest_dims, options) 
    len1s = basedims(otherdims(dest_dims, dims(A)))
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


@inline function _find_dims((A, args...)::Tuple{<:AbstractBasicDimArray,Vararg})::DimTupleOrEmpty
    expanded = _find_dims(args)
    if expanded === ()
        dims(A)
    else
        (dims(A)..., otherdims(expanded, dims(A))...)
    end
end
@inline _find_dims((d, args...)::Tuple{<:Dimension,Vararg}) =
    (d, otherdims(_find_dims(args), (d,)))
@inline _find_dims(::Tuple{}) = ()
@inline _find_dims((_, args...)::Tuple) = _find_dims(args)
