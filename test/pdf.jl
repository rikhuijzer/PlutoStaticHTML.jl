const PS = PlutoStaticHTML

@test contains(PS.tectonic_version(), "Tectonic")

nb = Notebook([
    Cell("x = 1 + 1"),
])

tex, nb = notebook2tex_helper(nb)

@test contains(tex, "x = 1 + 1")
