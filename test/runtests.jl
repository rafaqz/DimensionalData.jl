using DimensionalData, Documenter, Aqua

if VERSION >= v"1.5.0"
    Aqua.test_all(DimensionalData)
    Aqua.test_project_extras(DimensionalData)
    Aqua.test_stale_deps(DimensionalData)
end

include("methods.jl")
include("utils.jl")
include("matmul.jl")
include("dimension.jl")
include("interface.jl")
include("primitives.jl")
include("array.jl")
include("broadcast.jl")
include("mode.jl")
include("selector.jl")
include("set.jl")
include("tables.jl")
include("prettyprinting.jl")
if !Sys.iswindows()
    include("plotrecipes.jl")

    # Test documentation
    if VERSION >= v"1.5.0"
        docsetup = quote
            using DimensionalData, Random
            Random.seed!(1234)
        end
        DocMeta.setdocmeta!(DimensionalData, :DocTestSetup, docsetup; recursive=true)
        doctest(DimensionalData)
    end

end
