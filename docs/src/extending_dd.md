```@meta
Description = "Extend DimensionalData.jl - create custom array types, stacks,
lookups and dimensions by implementing a small set of interface methods in
Julia"
```

# Extending DimensionalData

Nearly everything in DimensionalData.jl is designed to be extended by other
packages: array types, stacks, lookups and dimensions are all open for
extension.

There are two quite different ways to give your own data a dimensional,
selector-aware interface:

1. **Wrap your array in a `DimArray`/`DimStack`.** If you have a custom
   `AbstractArray` (lazy, computed, disk-backed, compressed, sparse, ...) and
   you just want named dimensions, `At`/`Near`/interval selectors, keyword
   indexing and dimensional slicing on top of it, you just hand it to the stock
   `DimArray` constructor. This is by far the easier path and is the right
   choice most of the time. `SparseDimArrays.jl` is an example.

2. **Subtype `AbstractDimArray` (or `AbstractDimStack`).** Choose this only when
   you need a *distinct type* — because you carry extra fields (a CRS, chunking,
   a `missingval`, cleanup handles), want custom `show`, custom `name`/`label`
   behaviour, or want your type to be dispatched on throughout an ecosystem.
   `Raster` and `YAXArray` are examples. This path requires you to implement a
   small interface, described below.

The rest of this page covers both paths, then the shared building blocks
([`dims`](@ref), [`rebuild`](@ref), [`format`](@ref DimensionalData.format)),
and finally how to add custom **dimensions**, **lookups** and **stacks**, and
how to test your implementation with Interfaces.jl.

See [Integrations](@ref) for a list of packages that extend DimensionalData.jl.

## Strategy 1: wrap a custom array in `DimArray`

A `DimArray` is a thin wrapper: a parent `AbstractArray` plus a tuple of
`Dimension`s. It delegates every element read to `parent(A)` after translating
selectors and keywords into plain positional indices, and it rebuilds a new
`DimArray` around the result of slicing the parent. That means **your array type
needs to know nothing about dimensions, lookups or selectors** — you only need
to implement the standard `AbstractArray` interface, exactly as you would for
any array:

- `Base.size(A)` — return the size as a tuple.
- `Base.getindex(A, I::Vararg{Int,N})` — scalar element access.

Here is a complete, self-contained example: a dictionary-backed sparse array
that stores only the non-default cells and returns a fill value for the rest. It
has no dependency on and no knowledge of DimensionalData:

```julia
struct DictArray{T,N} <: AbstractArray{T,N}
    d::Dict{NTuple{N,Int},T}   # only the stored cells
    sz::NTuple{N,Int}
    fill::T                    # value for every absent cell
end

Base.size(A::DictArray) = A.sz
Base.getindex(A::DictArray{T,N}, I::Vararg{Int,N}) where {T,N} = get(A.d, I, A.fill)
```

To give it named dimensions and selector indexing, wrap it in a `DimArray`:

```julia
using DimensionalData

backing = DictArray{Float64,2}(Dict((1,1) => 10.0, (2,3) => 20.0), (3, 4), NaN)
A = DimArray(backing, (X([:a, :b, :c]), Y(10:10:40)))
```

From here everything a normal `DimArray` does works, driven entirely by
DimensionalData:

```julia
A[X=At(:b), Y=At(30)]   # => 20.0            (scalar lookup)
A[X=At(:b)]             # => a 1-D DimArray over Y
A[Y=20 .. 40]           # => a DimArray, sliced by interval
collect(A)              # => a dense Matrix{Float64}
parent(A)               # => your DictArray back again
```

A few things worth knowing about this path:

- **You do not call [`format`](@ref DimensionalData.format).** The `DimArray`
  constructor calls it for you on the dimensions you pass. It also checks that
  each dimension's length matches the corresponding array axis, so an incorrect
  cube shape is caught at construction.
- **Reach your own state through `parent`.** After wrapping, `parent(A)` returns
  your original object, so you can still get at any custom fields or methods it
  has (`parent(A).d` above).
- **Selectors and rebuilding are free.** `At`, `Near`, `..` intervals, keyword
  indexing, `view`, `set`, `cat`, `broadcast` and friends are all implemented by
  DimensionalData against the parent's plain indices. Dropping a dimension with
  a scalar index, and moving that dimension into `refdims`, is handled for you.

### Performance: specialise non-scalar indexing (optional)

With only scalar `getindex` defined, a non-scalar read such as `A[X=At(:b)]`
falls back to Julia's generic `AbstractArray` machinery, which fills the result
by calling your scalar `getindex` once per output element. That is always
*correct*, but for a backing store where a whole slice can be produced far more
cheaply than element-by-element (a sparse table, a compressed block, a remote
chunk), you can specialise the array-valued `getindex` methods that
DimensionalData will call on the parent:

```julia
Base.getindex(A::DictArray, I::Vararg{Union{Integer,AbstractVector{<:Integer},Colon},N}) where {N}
    # ... build and return a dense Array for this index combination ...
end
```

When you specialise these, follow the standard `Array` convention so that
`DimArray` can rebuild the result's dimensions correctly: an `Integer` index
**drops** that axis, while a range, vector or `Colon` **keeps** it. (Julia's
`dropdims` on the dropped axes is the simplest way to get this right.) You never
have to touch the dimensions yourself — returning an array with the right number
of axes is enough.

### Multiple layers: wrap in a `DimStack`

If several arrays share the same dimensions (for example, columns derived from
one underlying source), wrap them in a `DimStack` in exactly the same way. Each
layer can be any `AbstractArray`, including your custom type:

```julia
other_backing = DictArray{Float64,2}(Dict((1,1) => 1.0, (2,3) => 5.0), (3, 4), 0.0)

layers = (mean = backing, count = other_backing)   # both DictArrays, same shape
st = DimStack(layers, (X([:a, :b, :c]), Y(10:10:40)))

st.mean               # a DimArray view of one layer
st[X=At(:b)]          # slices every layer together, returns a DimStack
st[X=At(:b), Y=At(30)]  # fully scalar selector => a NamedTuple of values
```

## Strategy 2: subtype `AbstractDimArray`

Subtype `AbstractDimArray` when you need your own concrete type rather than a
`DimArray` — typically to carry extra fields or to be dispatched on across a
package ecosystem. `AbstractDimArray{T,N,D,A}` is itself an `AbstractArray{T,N}`,
so your type is an array; `D` is the dimensions tuple type and `A` the parent
array type.

### The minimal recipe

The following is the *complete* set of things a custom `AbstractDimArray` must
provide. This example passes DimensionalData's own interface tests:

```julia
using DimensionalData
import DimensionalData as DD

struct MyArray{T,N,D<:Tuple,R<:Tuple,A<:AbstractArray{T,N},Na,Me} <: AbstractDimArray{T,N,D,A}
    data::A       # the parent array
    dims::D       # a Tuple of Dimensions
    refdims::R    # a Tuple of Dimensions (often ())
    name::Na      # a Symbol, or NoName()
    metadata::Me  # any Dict-like, or NoMetadata()
end

# 1. An outer constructor that calls `format` on the dims.
function MyArray(data::AbstractArray, dims::Tuple;
                 refdims=(), name=DD.NoName(), metadata=DD.NoMetadata())
    MyArray(data, DD.format(dims, data), refdims, name, metadata)
end

# 2. The positional `rebuild` method. This one is *not* auto-generated.
DD.rebuild(A::MyArray, data, dims, refdims, name, metadata) =
    MyArray(data, dims, refdims, name, metadata)
```

That is all. `At`/`Near`/interval selection, keyword indexing, slicing,
dimension dropping into `refdims`, `set`, `cat`, broadcasting and printing now
all work.

Three points are doing the real work here, and each is easy to get subtly wrong:

- **The parent field.** `AbstractDimArray` defines `parent(A) = A.data`, so
  naming the parent field `data` makes `parent`, `size`, `iterate` and scalar
  indexing work automatically. If you name it something else, define
  `Base.parent(A::MyArray) = getfield(A, :yourfield)`.

- **Call [`format`](@ref DimensionalData.format) at construction.** This is not
  optional and it is the most common mistake. `format` turns the values you pass
  (`X(1:3)`, `X([:a,:b])`, a bare `Symbol`, ...) into fully-specified `Lookup`s,
  detecting order and sampling and filling in `Auto*` fields. **Without it,
  selectors like `At` cannot be resolved and indexing recurses into a
  `StackOverflowError`.** Do it in an outer constructor (as above) or in the
  inner constructor; do not skip it.

- **Define the positional `rebuild`.** DimensionalData rebuilds your type after
  every slice by calling
  `rebuild(A, data, dims, refdims, name, metadata)`. There is **no** generic
  positional `rebuild` for `AbstractDimArray` — even the built-in `DimArray`
  defines its own — so you must supply it. If it is missing, slicing and
  selector indexing fail with a `MethodError` or `StackOverflowError`, not a
  clear message.

### What you get for free (and when you don't)

If your struct's field names are exactly `data`, `dims`, `refdims`, `name`,
`metadata`, then:

- `dims(A)`, `refdims(A)`, `name(A)`, `metadata(A)` are all provided by the
  `AbstractDimArray` defaults (they just read the like-named field).
- The **keyword** form `rebuild(A; kw...)` is generated automatically via
  ConstructionBase.jl (it uses your field names), so you don't have to write it.

You still have to write the positional `rebuild` above regardless — the keyword
magic does not cover it.

### When your fields don't match: the `YAXArray` example

If your type stores its state under different field names, or you want custom
behaviour, override the accessors and both `rebuild` forms explicitly. This is
what `YAXArrays.jl` does — its fields are `axes` and `properties`, not `dims`
and `metadata`:

```julia
struct YAXArray{T,N,A<:AbstractArray{T,N},D,Me} <: AbstractDimArray{T,N,D,A}
    axes::D            # the dims
    data::A            # parent (matches the default `parent`)
    properties::Me     # the metadata
    chunks::GridChunks{N}
    cleaner::Vector{CleanMe}
    function YAXArray(axes, data, properties, chunks, cleaner)
        # ... size/shape checks ...
        axes = DD.format(axes, data)      # format, in the inner constructor
        return new{eltype(data),ndims(data),typeof(data),typeof(axes),typeof(properties)}(
            axes, data, properties, chunks, cleaner)
    end
end

# accessors, because the field names differ from the DD defaults
DD.dims(x::YAXArray)     = getfield(x, :axes)
DD.refdims(::YAXArray)   = ()
DD.metadata(x::YAXArray) = getfield(x, :properties)

# both rebuild forms, mapping DD's argument names onto this type's constructor.
# fields the type doesn't keep (refdims, name) are simply ignored.
function DD.rebuild(A::YAXArray, data::AbstractArray, dims::Tuple, refdims::Tuple, name, metadata)
    YAXArray(dims, data, metadata; cleaner=A.cleaner)
end
function DD.rebuild(A::YAXArray; data=parent(A), dims=DD.dims(A), metadata=DD.metadata(A), kw...)
    YAXArray(dims, data, metadata; cleaner=A.cleaner)
end
```

Two things to notice, both generally useful:

- A `rebuild` implementation may **ignore** arguments it has no field for.
  `YAXArray` keeps no `refdims` or `name`, so it drops those arguments. `rebuild`
  is a request to reconstruct with whatever updates the type can honour, not a
  contract to store every field.
- The keyword form swallows unknown keywords with `kw...`. DimensionalData may
  pass keywords your type doesn't use; accept and discard them.

You do **not** need to define `rebuild_pipeline`, override `format` as a method
(only call it), or register with Interfaces.jl for a subtype to work — none of
`Raster`, `YAXArray` or the tests require them. Optional extras a type may add
include `name`/`label` (for plot labels), and `DimensionalData.show_after` (to
append custom content to the default `show`).

## `dims`

Any object with dimensions must return a `Tuple` of constructed `Dimension`s
from `dims(obj)`, like `(X(), Y())`. For an `AbstractDimArray` whose field is
named `dims`, the default `dims(A) = A.dims` already does this.

### `Dimension` axes

Dimensions returned from `dims` hold a [`Lookup`](@ref) — or, in some cases,
just an `AbstractArray` (as with `DimIndices`). When attached to a
multi-dimensional object, each lookup must be the *same length* as the array
axis it describes, and `eachindex(A, i)` and `eachindex(dim)` must return the
same values. In particular, if the array uses OffsetArrays.jl axes, the lookup
the dimension wraps must use the same axes.

### `dims` keywords

For any function that takes a dimension argument, an extending object should
accept any of `Dimension`, `Type{<:Dimension}`, `Symbol`, `Val{:Symbol}`,
`Val{<:Type{<:Dimension}}`, or a plain `Integer`. You almost never have to
handle this yourself: as long as `dims(obj)` is implemented, `DD.dims(obj, d)`
returns the matching dimension and `DD.dimnum(obj, d)` returns the matching
`Int`, for any of those inputs.

## `rebuild`

`rebuild` reconstructs an immutable object with some fields replaced. It is more
flexible than plain ConstructionBase.jl reconstruction because an implementation
may accept and then discard fields it doesn't store (see the `YAXArray` example
above).

The signatures are:

```julia
rebuild(obj, args...)   # positional
rebuild(obj; kw...)     # keyword
```

The keyword version is generated automatically by
[ConstructionBase.jl](https://github.com/JuliaObjects/ConstructionBase.jl) as
long as your object's field names match the ones DimensionalData uses. For an
`AbstractDimArray` those are `data`, `dims`, `refdims`, `name`, `metadata`; for
an `AbstractDimStack`, `data`, `dims`, `refdims`, `layerdims`, `metadata`,
`layermetadata`. If your fields differ, define the keyword `rebuild` yourself.

The positional version is **not** generated automatically for array and stack
types — you must define it (see [Strategy 2: subtype `AbstractDimArray`](@ref)
above). For `AbstractDimArray` it must accept
`rebuild(A, data, dims, refdims, name, metadata)`; DimensionalData calls it (and
shorter positional forms that forward to it) on every slice. For `Dimension`,
`Lookup` and `Selector`, the single-argument positional form is the natural one
to use, as there is only one field to update.

## `format`

When constructing an `AbstractDimArray` or `AbstractDimStack`,
[`DimensionalData.format`](@ref) must be called on the `dims` tuple together with
the parent array:

```julia
format(dims, array)
```

This lets DimensionalData detect lookup properties, fill in missing lookup
fields, pass keywords from a `Dimension` to the detected `Lookup` constructor,
and accept the wider range of dimension inputs (tuples of `Symbol`, of `Type`,
etc.). The way you signal that something must be inferred is by leaving an `Auto`
type in place, such as [`AutoOrder`](@ref) or `AutoSampling`; `format` replaces
it with a concrete value guessed from the data.

If you follow [Strategy 1: wrap a custom array in `DimArray`](@ref) the
stock constructor calls `format` for you. If you follow
[Strategy 2: subtype `AbstractDimArray`](@ref) you must call it yourself in
your constructor. **Not calling `format` in the outer constructor of an
`AbstractDimArray` has undefined behaviour** — in practice, selector indexing
will recurse into a `StackOverflowError`.

When you define a *new lookup type* (see below), you also need to define
`DimensionalData.format` for it, so that a bare set of values wrapped in a
dimension can be promoted to your lookup.

## Custom dimensions

The `X`, `Y`, `Z`, `Ti` and `Dim{:name}` dimensions cover most needs, and you
can always make an ad-hoc named dimension with `Dim{:MyName}`. To define a
first-class dimension *type* — with its own name, plot label, and (optionally)
axis role — use the [`@dim`](@ref) macro:

```julia
using DimensionalData
using DimensionalData: @dim, XDim, YDim

@dim Lon XDim "Longitude"
@dim Lat YDim "Latitude"

Lon(10:10:180)   # constructs a dimension just like X or Y
```

The optional second argument is the supertype. The default is
`YourDim <: Dimension`, but choosing `XDim`, `YDim`, `ZDim` or `TimeDim` opts
your dimension into the layout and dispatch that those abstract types drive — for
example, `<: YDim` is plotted on the Y axis and `<: XDim` on the X axis. The
third argument is a human-readable label used in plots and printing when the type
name is an abbreviation.

## Custom lookups

A [`Lookup`](@ref) stores a dimension's index values and describes how to search
them: its `order`, `span`, `sampling`, and how selectors resolve against it. You
can add new lookup types, usually by subtyping one of the existing abstract
lookups — `AbstractSampled`, `AbstractCategorical`, or `Lookup` itself — so you
inherit its selector behaviour and only specialise what differs. For example,
`Rasters.Projected` is a lookup that additionally knows its coordinate reference
system but otherwise behaves like a regular `Sampled` lookup.

When you create a lookup type you must define `DimensionalData.format` for it, so
that values wrapped in a dimension are promoted into your lookup during
construction (this is the lookup-side counterpart of the array-side `format`
call). If your lookup adds fields, define `rebuild` for it as well; the keyword
form comes free from ConstructionBase.jl when your field names match, and the
single-argument positional form updates the wrapped data.

## Custom stacks

`AbstractDimStack` is the multi-layer counterpart of `AbstractDimArray`: a set of
named layers that share dimensions. As with arrays, prefer wrapping in the stock
`DimStack` ([Strategy 1: wrap a custom array in `DimArray`](@ref)) unless
you need a distinct type. `RasterStack` and `ArviZ.Dataset` are examples of the
subtyping route.

A subtyped stack implements the same interface as an array, with layer-aware
additions. Its positional `rebuild` accepts
`rebuild(A, data, dims, refdims, layerdims, metadata, layermetadata)`, and it
must define `layerdims` (which dimensions each layer uses — layers may span
different subsets of the stack's dimensions). Everything said above about
`format`, the parent field, ignoring unused arguments, and the free keyword
`rebuild` applies equally.

Note that a container of dimensional arrays does **not** have to be an
`AbstractDimStack`. YAXArrays.jl, for instance, keeps its multi-variable
`Dataset` as a plain struct holding `YAXArray`s rather than subtyping
`AbstractDimStack`. Subtype only if you want the full stack interface and
dispatch; otherwise a plain container that reaches into DimensionalData where it
needs to is perfectly fine.

## Interfaces.jl interface testing

DimensionalData defines explicit, testable Interfaces.jl interfaces,
`DimArrayInterface` and `DimStackInterface`, that check exactly the methods
described above (that `dims` returns a dimension tuple, that both `rebuild` forms
round-trip every field, that dimensions update on `getindex`, and so on). Running
them against your type is the quickest way to confirm your implementation is
complete.

::: tabs

== array

This is the implementation definition for `DimArray`:

````@ansi interfaces
using DimensionalData, Interfaces
@implements DimensionalData.DimArrayInterface{(:refdims,:name,:metadata)} DimArray [rand(X(10), Y(10)), zeros(Z(10))]
````

The type-parameter tuple, `(:refdims, :name, :metadata)` here, lists the
*optional* components your type supports; drop any your type doesn't store. The
array data passed must not be zero-dimensional and should cover at least 1, 2 and
3 dimensions. See the [`DimensionalData.DimArrayInterface`](@ref) docs for
options. Test it with:

````@ansi interfaces
Interfaces.test(DimensionalData.DimArrayInterface)
````

== stack

The implementation definition for `DimStack`:

````@ansi interfaces
@implements DimensionalData.DimStackInterface{(:refdims,:metadata)} DimStack [DimStack(zeros(Z(10))), DimStack(rand(X(10), Y(10))), DimStack(rand(X(10), Y(10)), rand(X(10)))]
````

See the [`DimensionalData.DimStackInterface`](@ref) docs for options. We can test it with:

````@ansi interfaces
Interfaces.test(DimensionalData.DimStackInterface)
````

:::
