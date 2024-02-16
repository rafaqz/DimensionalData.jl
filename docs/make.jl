using DocumenterVitepress ## add https://github.com/LuxDL/DocumenterVitepress.jl.git
using Documenter
using DimensionalData

makedocs(; sitename="DimensionalData", authors="Rafael Schouten et al.",
    # modules=[DimensionalData],
    # checkdocs=:all,
    format=DocumenterVitepress.MarkdownVitepress(),
    draft=false,
    source="src", 
    build=joinpath(@__DIR__, "docs_site"), 
    warnonly = true,
)