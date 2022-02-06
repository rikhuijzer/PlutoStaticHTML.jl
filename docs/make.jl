using Documenter:
    DocMeta,
    HTML,
    MathJax3,
    asset,
    deploydocs,
    makedocs
using PlutoStaticHTML

const NOTEBOOK_DIR = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")

"""
    build_notebooks()

Run all Pluto notebooks (".jl" files) in `NOTEBOOK_DIR`.
"""
function build_notebooks()
    println("Building notebooks")
    hopts = HTMLOptions(; append_build_context=true)
    output_format = documenter_output
    bopts = BuildOptions(NOTEBOOK_DIR; output_format)
    parallel_build(bopts, hopts)
    return nothing
end

if !("DISABLE_NOTEBOOK_BUILD" in keys(ENV))
    build_notebooks()
end

sitename = "PlutoStaticHTML.jl"
pages = [
    "PlutoStaticHTML" => "index.md",
    "Example notebook" => "notebook.md"
]

# Using MathJax3 since Pluto uses that engine too.
mathengine = MathJax3()
prettyurls = get(ENV, "CI", nothing) == "true"
format = HTML(; mathengine, prettyurls)
modules = [PlutoStaticHTML]
strict = true
checkdocs = :none
makedocs(; sitename, pages, format, modules, strict, checkdocs)

repo = "github.com/rikhuijzer/PlutoStaticHTML.jl.git"
push_preview = false
devbranch = "main"
deploydocs(; devbranch, repo, push_preview)

# For local development.
cd(pkgdir(PlutoStaticHTML))
