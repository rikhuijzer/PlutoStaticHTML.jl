using Aqua: Aqua
using DataFrames: DataFrame
using Dates
using PlutoStaticHTML
using Pluto:
    Cell,
    Markdown,
    Notebook,
    Pluto,
    ServerSession,
    SessionActions
using Test

const PS = PlutoStaticHTML
const PKGDIR = string(pkgdir(PlutoStaticHTML))::String
const NOTEBOOK_DIR = joinpath(PKGDIR, "docs", "src", "notebooks")

function pluto_notebook_content(code)
    return """
        ### A Pluto.jl notebook ###
        # v0.18.1

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

function nb_tmppath(
        nb::Notebook,
        use_distributed::Bool;
        in_path::String=joinpath(mktempdir(), "notebook.jl")
        )
    Pluto.save_notebook(nb, in_path)
    session = ServerSession()
    session.options.evaluation.workspace_use_distributed = use_distributed
    PlutoStaticHTML._add_extra_preamble!(session)

    nb = PlutoStaticHTML.run_notebook!(in_path, session)
    if use_distributed
        @async begin
            sleep(5)
            Pluto.SessionActions.shutdown(session, nb)
        end
    end
    return (nb, in_path)
end

function notebook2html_helper(
        nb::Notebook,
        oopts=OutputOptions();
        use_distributed::Bool=true
    )

    nb, tmppath = nb_tmppath(nb, use_distributed)
    html = PlutoStaticHTML.notebook2html(nb, tmppath, oopts)

    has_begin_end = contains(html, PlutoStaticHTML.BEGIN_IDENTIFIER)
    without_begin_end = has_begin_end ? drop_begin_end(html) : html

    # Remove the caching information because it's not important for most tests.
    has_cache = contains(html, PlutoStaticHTML.STATE_IDENTIFIER)
    without_cache = has_cache ? drop_cache_info(without_begin_end) : html

    return (without_cache, nb)
end

function notebook2tex_helper(
        nb::Notebook,
        oopts=OutputOptions();
        use_distributed::Bool=true
    )
    nb, tmppath = nb_tmppath(nb, use_distributed)
    tex = PlutoStaticHTML.notebook2tex(nb, tmppath, oopts)
    return (tex, nb)
end

function notebook2pdf_helper(
        nb::Notebook,
        in_path::String,
        oopts=OutputOptions();
        use_distributed::Bool=true
    )
    nb, tmppath = nb_tmppath(nb, use_distributed; in_path)
    pdf_path = PlutoStaticHTML.notebook2pdf(nb, tmppath, oopts)
    return (pdf_path, nb)
end

function notebook2html(
        path::AbstractString;
        oopts::OutputOptions=OutputOptions(),
        session=ServerSession()
    )
    nb = PlutoStaticHTML.run_notebook!(path, session; run_async=false)
    html = PlutoStaticHTML.notebook2html(nb, path, oopts)
    return html
end

# Hide output when using `TestEnv.activate(); include("test/preliminaries.jl")`.
nothing
