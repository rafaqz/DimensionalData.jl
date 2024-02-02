
# Interfaces.jl interface

function rebuild_all(A)
    # argument version
    A1 = rebuild(A, parent(A), dims(A), refdims(A), name(A), metadata(A))
    # keyword version, will work magically using ConstructionBase.jl if you use the same fieldnames.
    # If not, define it and remap these names to your fields.
    A2 = rebuild(A; data=parent(A), dims=dims(A), refdims=refdims(A), name=name(A), metadata=metadata(A))
    # all should be identical. If any fields are not used, they will always be `nothing` or `()` for `refdims`
    return parent(A) === parent(A1) === parent(A2) &&
        dims(A) === dims(A1) === dims(A2) &&
        refdims(A) === refdims(A1) === refdims(A2) &&
        metadata(A) === metadata(A1) === metadata(A2) &&
        name(A) === name(A1) === name(A2)
end


array_tests = (;
    mandatory = (
        dims = (
            "defines a `dims` method" => A -> dims(A) isa Tuple{Vararg{Dimension}},
            # "dims are updated on getindex" => A -> dims(view(A, rebuild(first(dims(A)), 1))),
        ),
        refdims_base = "`refdims` returns a tuple of Dimension or empty" => A -> refdims(A) isa Tuple{Vararg{Dimension}},
        ndims = "number of dims matches dimensions of array" => A -> length(dims(A)) == ndims(A),
        size = "length of dims matches dimensions of array" => A -> map(length, dims(A)) == size(A),
        rebuild=rebuild_all,
        rebuild_parent = A -> parent(rebuild(A, parent(A))) == parent(A),
        rebuild_dims = A -> dims(rebuild(A, parent(A), dims(A))) == dims(A),
        rebuild_parent_kw = A -> parent(rebuild(A; data=parent(A))) == parent(A),
        rebuild_dims_kw = A -> dims(rebuild(A; dims=dims(A))) == dims(A),
        getindex_dims = A -> dims(rebuild(A; dims=dims(A))) == dims(A),
    ),
    optional = (;
        refdims = (
            "refdims are updated in args rebuild" =>
              A -> refdims(rebuild(A, parent(A), dims(A), refdims(A))) == refdims(A),
            "refdims are updated in kw rebuild" =>
              A -> refdims(rebuild(A; refdims=refdims(A))) == refdims(A),
            "dropped dimensions are added to refdims" =>
                  A -> refdims(view(A, rebuild(first(dims(A)), 1))) isa Tuple{<:Dimension},
        ),
        name = (
            "rebuild updates name in arg rebuild" =>
                A -> DD.name(rebuild(A, parent(A), DD.dims(A), DD.refdims(A), DD.name(A))) === DD.name(A),
            "rebuild updates name in kw rebuild" =>
                A -> DD.name(rebuild(A; name=DD.name(A))) === DD.name(A),
        ),
        metadata = (
            "rebuild updates metadata in arg rebuild" => 
                A -> metadata(rebuild(A, parent(A), DD.dims(A), refdims(A), name(A), metadata(A))) === metadata(A),
            "rebuild updates metadata in kw rebuild" => 
                A -> metadata(rebuild(A; metadata=metadata(A))) === metadata(A),
        )
    )
) 

stack_tests = (;
    mandatory = (
        dims = (
            "defines a `dims` method" => A -> dims(A) isa Tuple{Vararg{Dimension}},
            # "dims are updated on getindex" => A -> dims(view(A, rebuild(first(dims(A)), 1))),
        ),
        refdims_base = "`refdims` returns a tuple of Dimension or empty" => A -> refdims(A) isa Tuple{Vararg{Dimension}},
        ndims = "number of dims matches dimensions of array" => A -> length(dims(A)) == ndims(A),
        size = "length of dims matches dimensions of array" => A -> map(length, dims(A)) == size(A),
        rebuild=rebuild_all,
        rebuild_parent = A -> parent(rebuild(A, parent(A))) == parent(A),
        rebuild_dims = A -> dims(rebuild(A, parent(A), dims(A))) == dims(A),
        rebuild_parent_kw = A -> parent(rebuild(A; data=parent(A))) == parent(A),
        rebuild_dims_kw = A -> dims(rebuild(A; dims=dims(A))) == dims(A),
    ),
    optional = (;
        refdims = (
            "refdims are updated in args rebuild" =>
              A -> refdims(rebuild(A, parent(A), dims(A), refdims(A))) == refdims(A),
            "refdims are updated in kw rebuild" =>
              A -> refdims(rebuild(A; refdims=refdims(A))) == refdims(A),
            "dropped dimensions are added to refdims" =>
                  A -> refdims(view(A, rebuild(first(dims(A)), 1))) isa Tuple{<:Dimension},
        ),
        name = (
            "rebuild updates name in arg rebuild" =>
                A -> DD.name(rebuild(A, parent(A), DD.dims(A), DD.refdims(A), DD.name(A))) === DD.name(A),
            "rebuild updates name in kw rebuild" =>
                A -> DD.name(rebuild(A; name=DD.name(A))) === DD.name(A),
        ),
        metadata = (
            "rebuild updates metadata in arg rebuild" => 
                A -> metadata(rebuild(A, parent(A), DD.dims(A), refdims(A), name(A), metadata(A))) === metadata(A),
            "rebuild updates metadata in kw rebuild" => 
                A -> metadata(rebuild(A; metadata=metadata(A))) === metadata(A),
        )
    )
) 


const array_docs = """
Pass constructed AbstractDimArrays as test data. 

They must not be zero dimensional, and should test at least 1, 2, and 3 dimensions.
"""

const stack_docs = """
Pass constructed AbstractDimArrays as test data. 

They must not be zero dimensional, and should test at least 1, 2, and 3 dimensions.
"""

Interfaces.@interface DimArrayInterface AbstractDimArray array_tests array_docs
Interfaces.@interface DimStackInterface AbstractDimStack stack_tests stack_docs


# Interfaces.jl implementations

Interfaces.@implements DimArrayInterface{(:refdims,:name,:metadata)} DimArray [rand(X(10), Y(10)), zeros(Z(10))]
Interfaces.@implements DimStackInterface{(:refdims,:name,:metadata)} DimStack [DimStack(zeros(Z(10))), DimStack(rand(X(10), Y(10))), DimStack(rand(X(10), Y(10)), rand(X(10)))]

