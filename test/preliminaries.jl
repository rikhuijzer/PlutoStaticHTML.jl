using PlutoStaticHTML
using Pluto:
    Cell,
    Notebook,
    Pluto,
    ServerSession,
    SessionActions
using Test

const PKGDIR = string(pkgdir(PlutoStaticHTML))::String
const NOTEBOOK_DIR = joinpath(PKGDIR, "docs", "src", "notebooks")

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

"Helper function to simply pass a `nb::Notebook` and run it."
function notebook2html_helper(
        nb::Notebook,
        opts=HTMLOptions()
    )
    tmpdir = mktempdir()
    tmppath = joinpath(tmpdir, "notebook.jl")
    Pluto.save_notebook(nb, tmppath)
    session = ServerSession()
    nb = PlutoStaticHTML.run_notebook!(tmppath, session)
    html = PlutoStaticHTML.notebook2html(nb, tmppath, opts)

    has_begin_end = contains(html, PlutoStaticHTML.BEGIN_IDENTIFIER)
    without_begin_end = has_begin_end ? drop_begin_end(html) : html

    # Remove the caching information because it's not important for most tests.
    has_cache = contains(html, PlutoStaticHTML.STATE_IDENTIFIER)
    without_cache = has_cache ? drop_cache_info(without_begin_end) : html

    return (without_cache, nb)
end

