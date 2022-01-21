using Documenter:
    DocMeta,
    HTML,
    MathJax3,
    asset,
    deploydocs,
    makedocs
using PlutoStaticHTML

const NOTEBOOK_DIR = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
const NOTEBOOK_PATH = joinpath(NOTEBOOK_DIR, "notebook.jl")

"""
    write_notebook()

Write Pluto output to a HTML file.
This avoidings running via the Documenter.jl evaluation, which appears to just hang.
Probably similar cause as https://github.com/JuliaDocs/Documenter.jl/issues/1514.
"""
function write_notebook()
    @info "Running notebook at $NOTEBOOK_PATH"
    opts = HTMLOptions(; append_build_context=true)
    html = notebook2html(NOTEBOOK_PATH, opts)
    md_path = joinpath(NOTEBOOK_DIR, "notebook.md")
    md = """
        ```@eval
        # Auto generated file. Do not modify.
        ```

        # Example notebook

        The Julia version and package information below is added after running the notebook by setting `append_build_context=true`.

        ```@raw html
        $html
        ```
        """
    write(md_path, md)
    return nothing
end

if !("DISABLE_NOTEBOOK_BUILD" in keys(ENV))
    write_notebook()
end

function write_dynamic_notebook()
    html = PlutoStaticHTML.__build()
    md = """
        # Dynamic

        ```@raw html
        $html
        ```
        """
    md_path = joinpath(NOTEBOOK_DIR, "dynamic.md")
    write(md_path, md)
    return nothing
end

write_dynamic_notebook()

sitename = "PlutoStaticHTML.jl"
pages = [
    "PlutoStaticHTML" => "index.md",
    "Example notebook" => "notebook.md",
    "Dynamic" => "dynamic.md"
]

# Using MathJax3 since Pluto uses that engine too.
mathengine = MathJax3()
prettyurls = get(ENV, "CI", nothing) == "true"
assets = [
    # asset("assets/dynamic.js", islocal=true)
]
format = HTML(; assets, mathengine, prettyurls)
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
