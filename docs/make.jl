using Documenter, DimensionalData

makedocs(
    modules = [DimensionalData],
    sitename = "DimensionalData.jl",
)

deploydocs(
    repo = "github.com/rafaqz/DimensionalData.jl.git",
)
