### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 93635e2a-755e-11ec-3dae-c77f892d6c22
begin
    # Examples at https://juliapluto.github.io/sample-notebook-previews/PlutoUI.jl.html.
    using Pkg
    Pkg.activate(; temp=true)
    Pkg.add("PlutoUI")
    using PlutoUI
end

# ╔═╡ 52ce8ede-93d4-4724-ae7f-7d4cb0d2370a
md"""
The functionality shown at this page is highly experimental and may be dropped from this package at any point in time.
"""

# ╔═╡ 0000000a-7036-4bc5-b7b4-4e701eb653f7
@bind a Slider(1.0:0.1:1.3)

# ╔═╡ 0000000b-1321-4ba0-9642-ce0fd362c618
@bind b Select([1, 2])

# ╔═╡ 0000000c-8ead-4ea2-a301-2da990b9c516
c = a + b

# ╔═╡ 0000000d-7dd7-4ad6-858a-8eae9f1c36f3
d = c + 1

# ╔═╡ 207af9a9-5410-474f-bd5b-19ee0d692df5
@bind response Select(["👍" => "yes", "👎" => "no"])

# ╔═╡ 9c173019-5596-48d5-a636-3db61cc2bd78
response

# ╔═╡ Cell order:
# ╠═52ce8ede-93d4-4724-ae7f-7d4cb0d2370a
# ╠═93635e2a-755e-11ec-3dae-c77f892d6c22
# ╠═0000000a-7036-4bc5-b7b4-4e701eb653f7
# ╠═0000000b-1321-4ba0-9642-ce0fd362c618
# ╠═0000000c-8ead-4ea2-a301-2da990b9c516
# ╠═0000000d-7dd7-4ad6-858a-8eae9f1c36f3
# ╠═207af9a9-5410-474f-bd5b-19ee0d692df5
# ╠═9c173019-5596-48d5-a636-3db61cc2bd78
