@testset "dynamic" begin
    session = ServerSession()
    options = Pluto.Configuration.from_flat_kwargs(; workspace_use_distributed=false)
    session.options = options

    nb = Notebook([
        Cell("""@bind x html"<input type=range min=1 max=2 value=1>" """),
        Cell("y = x + 1")
    ])
    run_notebook!(nb, session)
    # Apparently, the default value is set by Javascript?
    # The next test is the most important anyway.
    @test _cell(nb, :y).output.body == "missing"
    PlutoStaticHTML._set_bond_value!(session, nb, :x, 2)
    @test _cell(nb, :y).output.body == "3"
end
