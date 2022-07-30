const PS = PlutoStaticHTML

@test contains(PS.tectonic_version(), "Tectonic")

nb = Notebook([
    Cell("x = 1 + 1"),
])

tex, nb = notebook2tex_helper(nb; use_distributed=false)

@test contains(tex, "x = 1 + 1")

tmpdir = joinpath(PS.PKGDIR, "test", "tmp")
mkpath(tmpdir)
in_path = joinpath(tmpdir, "test.jl")
pdf_path = PS.notebook2pdf(nb, in_path, OutputOptions())
@test isfile(joinpath(tmpdir, "test.pdf"))

# pdf_path, nb = notebook2pdf_helper(nb; use_distributed=false)
