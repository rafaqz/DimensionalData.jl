using Pkg
Pkg.activate(@__DIR__)
using Documenter, DimensionalData
CI = get(ENV, "CI", nothing) == "true"

makedocs(
    modules = [DimensionalData],
    sitename = "DimensionalData.jl",
    format = Documenter.HTML(
        prettyurls = CI,
    ),
    pages = [
        "Introduction" => "index.md",
        "Tutorial" => "tutorial.md"
        "API" => "api.md",
        ],
)

if CI
    deploydocs(
        repo = "github.com/rafaqz/DimensionalData.jl.git",
    )
end
