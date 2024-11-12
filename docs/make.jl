using DocumenterVitepress
using Documenter
using DimensionalData
using Dates
using DimensionalData.Dimensions
using DimensionalData.Lookups

# Names are available everywhere so that [`function`](@ref) works.
# ====================

doctest_setup = quote
    using DimensionalData
    using DimensionalData.Dimensions
    using DimensionalData.Dimensions.Lookups
end
DocMeta.setdocmeta!(DimensionalData, :DocTestSetup, doctest_setup; recursive=true)

# Build documentation.
# ====================

makedocs(; sitename="DimensionalData", authors="Rafael Schouten et al.",
    modules=[DimensionalData],
    checkdocs=:all,
    format=DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/rafaqz/DimensionalData.jl",
        devbranch = "main", 
        devurl = "dev", 
    ),
    draft=false,
    source="src", 
    build="build",
)

# Deploy built documentation.
# ===========================
deploydocs(; 
    repo="github.com/rafaqz/DimensionalData.jl",
    target="build", # this is where Vitepress stores its output
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true
)
