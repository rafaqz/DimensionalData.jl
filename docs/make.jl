using DocumenterVitepress ## add https://github.com/LuxDL/DocumenterVitepress.jl.git
using Documenter
using DimensionalData

makedocs(; sitename="DimensionalData", authors="Rafael Schouten et al.",
    # modules=[DimensionalData],
    # checkdocs=:all,
    format=DocumenterVitepress.MarkdownVitepress(
        repo = "github.com/rafaqz/DimensionalData.jl",
        devbranch = "main", 
        devurl = "dev", 
    ),
    draft=false,
    source="src", 
    build=joinpath(@__DIR__, "build"), 
    warnonly = true,
)

deploydocs(; 
    repo="github.com/rafaqz/DimensionalData.jl",
    target="build", # this is where Vitepress stores its output
    branch = "gh-pages",
    devbranch = "main",
    push_preview = true
)
