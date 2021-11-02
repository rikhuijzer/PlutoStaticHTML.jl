using Documenter:
    DocMeta,
    HTML,
    deploydocs,
    makedocs
using PlutoStaticHTML

"""
    write_homepage()

Write Pluto output to a HTML file.
This avoidings running via the Documenter.jl evaluation machine, which appears to just hang.
"""
function write_homepage()
    dir = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
    notebook_path = joinpath(dir, "notebook.jl")
    @info "Running notebook at $notebook_path"
    html = notebook2html(notebook_path)
    index_path = joinpath(dir, "index.md")
    md = """
        # PlutoStaticHTML

        ```@raw html
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/fonsp/Pluto.jl@0.16.4/frontend/treeview.css" type="text/css" />

        <style>
        div.markdown {
            padding-top: 1rem;
            padding-bottom: 2rem;
        }
        </style>

        $html
        ```
        """
    write(index_path, md)
    return nothing
end

write_homepage()

sitename = "PlutoStaticHTML.jl"
pages = [
    "PlutoStaticHTML" => "index.md"
]
format = HTML(; prettyurls = get(ENV, "CI", nothing) == "true")
modules = [PlutoStaticHTML]
strict = true
checkdocs = :none
makedocs(; sitename, pages, format, modules, strict, checkdocs)

repo = "github.com/rikhuijzer/PlutoStaticHTML.jl.git"
push_preview = false
devbranch = "main"
deploydocs(; devbranch, repo, push_preview)
