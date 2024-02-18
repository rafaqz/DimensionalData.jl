using DimensionalData, Aqua, SafeTestsets 

if VERSION >= v"1.9.0"
    Aqua.test_ambiguities([DimensionalData, Base, Core])
    Aqua.test_unbound_args(DimensionalData)
    Aqua.test_undefined_exports(DimensionalData)
    Aqua.test_project_extras(DimensionalData)
    Aqua.test_stale_deps(DimensionalData)
    Aqua.test_deps_compat(DimensionalData)
    Aqua.test_project_extras(DimensionalData)
    Aqua.test_stale_deps(DimensionalData)
end

@time @safetestset "interface" begin include("interface.jl") end
@time @safetestset "metadata" begin include("metadata.jl") end
@time @safetestset "name" begin include("name.jl") end
@time @safetestset "dimension" begin include("dimension.jl") end
@time @safetestset "primitives" begin include("primitives.jl") end
@time @safetestset "lookup" begin include("lookup.jl") end
@time @safetestset "selector" begin include("selector.jl") end
@time @safetestset "merged" begin include("merged.jl") end
@time @safetestset "DimUnitRange" begin include("dimunitrange.jl") end
@time @safetestset "format" begin include("format.jl") end

@time @safetestset "array" begin include("array.jl") end
@time @safetestset "stack" begin include("stack.jl") end
@time @safetestset "indexing" begin include("indexing.jl") end
@time @safetestset "methods" begin include("methods.jl") end
@time @safetestset "broadcast" begin include("broadcast.jl") end
@time @safetestset "matmul" begin include("matmul.jl") end
@time @safetestset "dimindices" begin include("dimindices.jl") end
@time @safetestset "set" begin include("set.jl") end
@time @safetestset "tables" begin include("tables.jl") end
@time @safetestset "utils" begin include("utils.jl") end
@time @safetestset "groupby" begin include("groupby.jl") end
@time @safetestset "show" begin include("show.jl") end
@time @safetestset "adapt" begin include("adapt.jl") end
@time @safetestset "ecosystem" begin include("ecosystem.jl") end


if Sys.islinux()
    # Unfortunately this can hang on other platforms.
    # Maybe ram use of all the plots on the small CI machine? idk
    @time @safetestset "plotrecipes" begin include("plotrecipes.jl") end
end
