using DimensionalData, Documenter

include("dimension.jl")
include("interface.jl")
include("primitives.jl")
include("array.jl")
include("broadcast.jl")
include("mode.jl")
include("selector.jl")
include("methods.jl")
include("prettyprinting.jl")
if !Sys.iswindows()
    include("plotrecipes.jl")

    # Test documentation
    docsetup = quote
        using DimensionalData, Random
        Random.seed!(1234)
    end
    DocMeta.setdocmeta!(DimensionalData, :DocTestSetup, docsetup; recursive=true)
    doctest(DimensionalData)
end
