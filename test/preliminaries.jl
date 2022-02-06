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

function pluto_more_cell_content(code1, code2, code3)
    return """
        ### A Pluto.jl notebook ###
        # v0.17.4

        using Markdown
        using InteractiveUtils

        # ╔═╡ a6dda572-3f2c-11ec-0eeb-000000000001
        $(code1)

        # ╔═╡ a6dda572-3f2c-11ec-0eeb-000000000002
        $(code2)

        # ╔═╡ a6dda572-3f2c-11ec-0eeb-000000000003
        $(code3)

        # ╔═╡ Cell order:
        # ╠═a6dda572-3f2c-11ec-0eeb-000000000001
        # ╠═a6dda572-3f2c-11ec-0eeb-000000000002
        # ╠═a6dda572-3f2c-11ec-0eeb-000000000003
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

"Helper function to simply pass a `nb::Notebook` and run it."
function notebook2html_helper(
        nb::Notebook,
        opts=HTMLOptions();
        append_cells=Cell[]
    )
    PlutoStaticHTML._append_cell!(nb, append_cells)
    path = tempname()
    Pluto.save_notebook(nb, path)
    _run
    run_notebook!(
    html = notebook2html(nb, path, opts)

    # Remove the caching information because it's not important for most tests.
    has_cache = contains(html, PlutoStaticHTML.STATE_IDENTIFIER)
    without_cache = has_cache ? drop_cache_info(html) : html

    has_begin_end = contains(html, PlutoStaticHTML.BEGIN_IDENTIFIER)
    without_begin_end = has_begin_end ? drop_begin_end(html) : html

    return without_begin_end
end

