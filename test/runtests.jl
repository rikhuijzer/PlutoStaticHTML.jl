using PlutoStaticHTML
using Pluto:
    Cell,
    Notebook,
    ServerSession
using Test:
    @testset,
    @test

const PKGDIR = string(pkgdir(PlutoStaticHTML))::String
const NOTEBOOK_DIR = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
const NOTEBOOK_PATH = joinpath(NOTEBOOK_DIR, "notebook.jl")

function pluto_notebook_content(code)
    return """
        ### A Pluto.jl notebook ###
        # v0.17.1

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

function notebook2html!(notebook::Notebook; append_cells=Cell[], kwargs...)
    session = ServerSession()
    PlutoStaticHTML._append_cell!(notebook, append_cells)
    run_notebook!(notebook, session)
    html = notebook2html(notebook; kwargs...)
    has_cache = contains(html, PlutoStaticHTML.CACHE_IDENTIFIER)
    return has_cache ? drop_cache_info(html) : html
end

include("context.jl")
include("cache.jl")
include("html.jl")
include("build.jl")
