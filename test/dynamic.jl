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

    nb = Notebook([
        Cell("a = 1"), # 1
        Cell("b = 2"), # 2
        Cell("c = 3"), # 3
        Cell("d = a + b"), # 4
        Cell("e = b + c"), # 5
        Cell("f = e") # 6
        ])
    f = nb.cells[end]
    run_notebook!(nb, session)
    actual = PlutoStaticHTML._indirect_upstream_cells(nb, f)
    expected = [nb.cells[index].cell_id for index in [5, 2, 3]]
    @test Set(actual) == Set(expected)
end
