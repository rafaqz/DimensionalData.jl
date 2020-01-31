using Documenter, DimensionalData
CI = get(ENV, "CI", nothing) == "true"

makedocs(
    modules = [DimensionalData],
    sitename = "DimensionalData.jl",
    format = Documenter.HTML(
        prettyurls = CI,
    ),
)

if CI
    deploydocs(
        repo = "github.com/rafaqz/DimensionalData.jl.git",
    )
end
