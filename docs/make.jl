using Documenter:
    DocMeta,
    HTML,
    deploydocs,
    makedocs
using PlutoStaticHTML

"""
    write_notebook()

Write Pluto output to a HTML file.
This avoidings running via the Documenter.jl evaluation, which appears to just hang.
Probably similar cause as https://github.com/JuliaDocs/Documenter.jl/issues/1514.
"""
function write_notebook()
    dir = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
    notebook_path = joinpath(dir, "notebook.jl")
    @info "Running notebook at $notebook_path"
    append_cells = PACKAGE_VERSIONS
    html = notebook2html(notebook_path; append_cells)
    md_path = joinpath(dir, "notebook.md")
    md = """
        ```@eval
        # Auto generated file. Do not modify.
        ```

        # Example notebook

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
    write(md_path, md)
    return nothing
end

write_notebook()

sitename = "PlutoStaticHTML.jl"
pages = [
    "PlutoStaticHTML" => "index.md",
    "Example notebook" => "notebook.md"
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
