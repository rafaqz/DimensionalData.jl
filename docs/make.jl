using Pkg
Pkg.activate(@__DIR__)

using Documenter, DimensionalData

CI = get(ENV, "CI", nothing) == "true" || get(ENV, "GITHUB_TOKEN", nothing) !== nothing

docsetup = quote 
    using DimensionalData, Random 
    Random.seed!(1234)
end
DocMeta.setdocmeta!(DimensionalData, :DocTestSetup, docsetup; recursive=true)

makedocs(
    modules = [DimensionalData],
    sitename = "DimensionalData.jl",
    format = Documenter.HTML(
        prettyurls = CI,
    ),
    pages = [
        "Introduction" => "index.md",
        "Crash course" => "course.md",
        "API" => "api.md",
        "For Developers" => "developer.md"
        ],
)

if CI
    deploydocs(
        repo = "github.com/rafaqz/DimensionalData.jl.git",
        target = "build",
        push_preview = true
    )
end
