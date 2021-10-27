using Documenter:
    DocMeta,
    HTML,
    deploydocs,
    makedocs
using PlutoHTML

DocMeta.setdocmeta!(
    PlutoHTML,
    :DocTestSetup,
    :(using PlutoHTML);
    recursive=true
)

sitename = "PlutoHTML.jl"
pages = [
    "PlutoHTML" => "index.md"
]
format = HTML(; prettyurls = get(ENV, "CI", nothing) == "true")
modules = [PlutoHTML]
strict = true
checkdocs = :none
makedocs(; sitename, pages, format, modules, strict, checkdocs)

repo = "github.com/rikhuijzer/PlutoHTML.jl.git"
push_preview = false
devbranch = "main"
deploydocs(; devbranch, repo, push_preview)
