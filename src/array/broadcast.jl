import Base.Broadcast: BroadcastStyle, DefaultArrayStyle, Style


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
    bdims = _broadcasted_dims(bc)
    comparedims(bdims...; ignore_length_one=true, order=true, val=true, msg=Dimensions.Throw())
    dims = Dimensions.promotedims(bdims...; skip_length_one=true)
    A = _firstdimarray(bc)
    data = copy(_unwrap_broadcasted(bc))
    return if A isa Nothing || dims isa Nothing || !(data isa AbstractArray)
        data
    elseif data isa AbstractDimArray
        rebuild(A, parent(data), format(dims, data), refdims(A), Symbol(""))
    else
        rebuild(A, data, format(dims, data), refdims(A), Symbol(""))
    end
end

function Base.copyto!(dest::AbstractArray, bc::Broadcasted{DimensionalStyle{S}}) where S
    comparedims(_broadcasted_dims(bc)...; ignore_length_one=true, order=true)
    copyto!(dest, _unwrap_broadcasted(bc))
    return dest
end

@inline function Base.Broadcast.materialize!(dest::AbstractDimArray, bc::Base.Broadcast.Broadcasted{<:Any})
    # Need to check whether the dims are compatible in dest, 
    # which are already stripped when sent to copyto!
    comparedims(dims(dest), _broadcasted_dims(bc)...; ignore_length_one=true, order=true)
    style = DimensionalData.DimensionalStyle(Base.Broadcast.combine_styles(parent(dest), bc))
    Base.Broadcast.materialize!(style, parent(dest), bc)
    return dest
end



function Base.similar(bc::Broadcast.Broadcasted{DimensionalStyle{S}}, ::Type{T}) where {S,T}
    A = _firstdimarray(bc)
    rebuildsliced(A, similar(_unwrap_broadcasted(bc), T, axes(bc)...), axes(bc), Symbol(""))
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

"""
    @d broadcast_expression options

Dimensional broadcast macro.

Will permute and and singleton dimensions
so that all `AbstractDimArray` in the broadcast will
broadcast their matching dimensions.

It is possible to pass options as the second argument of 
the macro to control the behaviour, as a single assignment
or as a NamedTuple. Options names must be written explicitly,
not passed in namedtuple variable.

# Options

- `dims`: Pass a Tuple of `Dimension`s, `Dimension` types or `Symbol`s
    to fix the dimension order of the output array. Otherwise dimensions
    will be in order of appearance.
- `strict`: `true` or `false`. Check that all lookup values match explicitly.

# Example

```julia
da1 = ones(X(3))
da2 = fill(2, Y(4), X(3))

@d da1 .* da2
@d da1 .* da2 .+ 5 dims=(Y, X)
```

"""
macro d(expr::Expr, options::Union{Expr,Nothing}=nothing)
    options_dict = _process_d_macro_options(options)
    broadcast_expr, var_list = _wrap_broadcast_vars(expr)
    var_list_assignments = map(var_list) do (name, expr)
        Expr(:(=), name, expr)
    end
    vars_expr = Expr(:tuple, map(first, var_list)...)
    var_list_expr = Expr(:block, var_list_assignments...)
    dims_expr = if haskey(options_dict, :dims)
        order_dims = options_dict[:dims]
        quote
            order_dims = $order_dims
            found_dims = _find_dims(vars)
            all(hasdim(order_dims, found_dims)) || throw(ArgumentError("order $(basedims(order_dims)) dont match dimensions found in arrays $(basedims(found_dims))"))
            dims = $DimensionalData.dims(found_dims, order_dims)
        end
    else
        :(dims = _find_dims(vars))
    end
    quote
        let
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

_process_d_macro_options(::Nothing) = Dict{Symbol,Any}()
function _process_d_macro_options(options::Expr)
    options_dict = Dict{Symbol,Any}()
    if options.head == :tuple
        if options.args[1].head == :parameters
            # Keyword syntax (; order=...
            for arg in options.args[1].args
                arg.head == :kw || throw(ArgumentError("malformed options"))
                options_dict[arg.args[1]] = esc(arg.args[2])
            end
        else
            # Tuple syntax (order=...
            for arg in options.args
                arg.head == :(=) || throw(ArgumentError("malformed options"))
                options_dict[arg.args[1]] = esc(arg.args[2])
            end
        end
    elseif options.head == :(=)
        # Single assignmen order=...
        options_dict[options.args[1]] = esc(options.args[2])
    end

    return options_dict
end

_wrap_broadcast_vars(sym::Symbol) = esc(sym), Expr[]
function _wrap_broadcast_vars(expr::Expr)
    arg_list = Pair{Symbol,Expr}[]
    if expr.head == :. # function dot broadcast
        if expr.args[2] isa Expr
            tuple_args = map(expr.args[2].args) do arg
                if arg isa Expr
                    expr1, arg_list1 = _wrap_broadcast_vars(arg)
                    append!(arg_list, arg_list1)
                    expr1
                else
                    var = Symbol(gensym(), :var)
                    push!(arg_list, var => esc(arg))
                    Expr(:call, :_maybe_dimensional_broadcast, var, :dims)
                end
            end
            expr2 = Expr(expr.head, esc(expr.args[1]), Expr(:tuple, tuple_args...))
            return expr2, arg_list
        end
    elseif expr.head == :call && string(expr.args[1])[1] == '.' # infix broadcast
        args = map(expr.args[2:end]) do arg
            if arg isa Expr
                expr1, arg_list1 = _wrap_broadcast_vars(arg)
                append!(arg_list, arg_list1)
                expr1
            else
                var = Symbol(gensym(), :var)
                push!(arg_list, var => esc(arg))
                Expr(:call, :_maybe_dimensional_broadcast, var, :dims)
            end
        end
        expr2 = Expr(expr.head, expr.args[1], args...)
        return expr2, arg_list
    else # Not part of the broadcast, just wrap return it
        expr2 = esc(expr)
        return expr2, arg_list
    end
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

_maybe_dimensional_broadcast(x, _) = x
function _maybe_dimensional_broadcast(A::AbstractBasicDimArray, dest_dims) 
    len1s = basedims(otherdims(dest_dims, dims(A)))
    # Reshape first to avoid a ReshapedArray wrapper if possible
    A1 = _maybe_insert_length_one_dims(A, dest_dims)
    # Then permute and reorder
    A2 = _maybe_lazy_permute(A1, dest_dims)
    # Then rebuild with the new data and dims
    data = parent(A2)
    return rebuild(A; data, dims=format(dims(A2), data))
end
_maybe_dimensional_broadcast(d::Dimension, dims) = 
    _maybe_dimensional_broadcast(DimArray(parent(d), d), dims)

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
    A1 = rebuild(A, newdata, format(newdims, newdata))
    return A1
end
