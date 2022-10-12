using Documenter:
    DocMeta,
    HTML,
    MathJax3,
    asset,
    deploydocs,
    makedocs
using PlutoStaticHTML

const NOTEBOOK_DIR = joinpath(@__DIR__, "src", "notebooks")

"""
    build()

Run all Pluto notebooks (".jl" files) in `NOTEBOOK_DIR`.
"""
function build()
    println("Building notebooks in $NOTEBOOK_DIR")
    oopts = OutputOptions(; append_build_context=true)
    output_format = documenter_output
    bopts = BuildOptions(NOTEBOOK_DIR; output_format)
    build_notebooks(bopts, oopts)
    return nothing
end

# Build the notebooks; defaults to true.
if get(ENV, "BUILD_DOCS_NOTEBOOKS", "true") == "true"
    build()
end

sitename = "PlutoStaticHTML.jl"
pages = [
    "PlutoStaticHTML" => "index.md",
    "Example notebook" => "notebooks/example.md",
    "Test notebook" => "notebooks/test.md",
    "`with_terminal`" => "with_terminal.md"
]

# Using MathJax3 since Pluto uses that engine too.
mathengine = MathJax3()
prettyurls = get(ENV, "CI", nothing) == "true"
format = HTML(; mathengine, prettyurls)
modules = [PlutoStaticHTML]
strict = true
checkdocs = :none
makedocs(; sitename, pages, format, modules, strict, checkdocs)

deploydocs(;
    branch="docs-output",
    devbranch="main",
    repo="github.com/rikhuijzer/PlutoStaticHTML.jl.git",
    push_preview=false
)
