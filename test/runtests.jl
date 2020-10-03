using DimensionalData, Documenter, Aqua

if VERSION >= v"1.5.0"
    Aqua.test_all(DimensionalData)
    Aqua.test_project_extras(DimensionalData)
    Aqua.test_stale_deps(DimensionalData)
end

include("dimension.jl")
include("interface.jl")
include("primitives.jl")
include("array.jl")
include("dataset.jl")
include("broadcast.jl")
include("mode.jl")
include("selector.jl")
include("set.jl")
include("methods.jl")
include("utils.jl")
include("matmul.jl")
include("tables.jl")
include("prettyprinting.jl")

if Sys.islinux()
    # Unfortunately this can hang on other platforms.
    # Maybe ram use of all the plots on the small CI machine? idk
    include("plotrecipes.jl")
end

# Test documentation
if VERSION >= v"1.5.0"
    docsetup = quote
        using DimensionalData, Random
        Random.seed!(1234)
    end
    DocMeta.setdocmeta!(DimensionalData, :DocTestSetup, docsetup; recursive=true)
    doctest(DimensionalData; fix=true)
end
