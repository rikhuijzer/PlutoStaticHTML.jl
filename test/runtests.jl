using PlutoStaticHTML
using Pluto:
    Cell,
    Notebook,
    ServerSession
using Test:
    @testset,
    @test

const PKGDIR = string(pkgdir(PlutoStaticHTML))::String

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

include("html.jl")
include("build.jl")
