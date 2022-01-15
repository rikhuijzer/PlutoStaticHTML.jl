using PlutoStaticHTML
using Pluto:
    Cell,
    Notebook,
    Pluto,
    ServerSession
using Test

const PKGDIR = string(pkgdir(PlutoStaticHTML))::String
const NOTEBOOK_DIR = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
const NOTEBOOK_PATH = joinpath(NOTEBOOK_DIR, "notebook.jl")

function pluto_notebook_content(code)
    return """
        ### A Pluto.jl notebook ###
        # v0.17.4

        using Markdown
        using InteractiveUtils

        # ╔═╡ a6dda572-3f2c-11ec-0eeb-69e2323a92de
        $(code)

        # ╔═╡ Cell order:
        # ╠═a6dda572-3f2c-11ec-0eeb-69e2323a92de
        """
end

function drop_cache_info(html::AbstractString)
    n = PlutoStaticHTML.n_cache_lines()
    sep = '\n'
    lines = split(html, sep)
    return join(lines[n:end], sep)
end

function drop_begin_end(html::AbstractString)
    sep = '\n'
    lines = split(html, sep)
    return join(lines[2:end-1], sep)
end

function notebook2html_helper(
        notebook::Notebook,
        opts=HTMLOptions();
        append_cells=Cell[]
    )
    session = ServerSession()
    PlutoStaticHTML._append_cell!(notebook, append_cells)
    run_notebook!(notebook, session)
    path = nothing
    html = notebook2html(notebook, path, opts)

    has_cache = contains(html, PlutoStaticHTML.STATE_IDENTIFIER)
    without_cache = has_cache ? drop_cache_info(html) : html

    has_begin_end = contains(html, PlutoStaticHTML.BEGIN_IDENTIFIER)
    without_begin_end = has_begin_end ? drop_begin_end(html) : html

    return without_begin_end
end

