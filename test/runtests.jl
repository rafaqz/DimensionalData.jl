using DimensionalData, Documenter, Aqua

if VERSION >= v"1.5.0"
    # This is catching some unambiguous constructors for T<:Metadata.
    # Aqua.test_ambiguities([DimensionalData, Base, Core])
    Aqua.test_unbound_args(DimensionalData)
    Aqua.test_undefined_exports(DimensionalData)
    Aqua.test_project_extras(DimensionalData)
    Aqua.test_stale_deps(DimensionalData)
    Aqua.test_deps_compat(DimensionalData)
    Aqua.test_project_toml_formatting(DimensionalData)
    Aqua.test_project_extras(DimensionalData)
    Aqua.test_stale_deps(DimensionalData)
end

include("dimension.jl")
include("interface.jl")
include("primitives.jl")
include("array.jl")
include("stack.jl")
include("broadcast.jl")
include("mode.jl")
include("selector.jl")
include("set.jl")
include("methods.jl")
include("utils.jl")
include("matmul.jl")
include("tables.jl")
include("show.jl")

if Sys.islinux()
    # Unfortunately this can hang on other platforms.
    # Maybe ram use of all the plots on the small CI machine? idk
    include("plotrecipes.jl")
end
