session = ServerSession()
options = Pluto.Configuration.from_flat_kwargs(; workspace_use_distributed=false)
session.options = options

nb = Notebook([
    Cell("""@bind a html"<input type=range min='1' max='2'>" """), # 1
    Cell("""@bind b html"<input type=range min='1' max='3'>" """), # 2
    Cell("c = 3"), # 3
    Cell("d = a + b"), # 4
    Cell("e = b + c"), # 5
    Cell("f = e") # 6
    ])

uuids(nb::Notebook, I::Vector{Int}) = cell2uuid.(getindex(nb.cells, I))

f = nb.cells[end]
run_notebook!(nb, session)
actual = PlutoStaticHTML._indirect_upstream_cells(nb, f)
expected = uuids(nb, [5, 2, 3])
@test actual == expected

a = nb.cells[1]
b = nb.cells[2]
actual = PlutoStaticHTML._indirect_downstream_cells(nb, b)
expected = uuids(nb, [4, 5, 6])
@test actual == expected

actual = PlutoStaticHTML._upstream_bind_cells(nb, f)
expected = uuids(nb, [2])
@test actual == expected

nbo = PlutoStaticHTML.NotebookBindOutputs(nb)
actual = PlutoStaticHTML._depend_binds(nbo)
expected = uuids(nb, [4, 5, 6])
@test Set(actual) == Set(expected)

upstream_binds = PlutoStaticHTML._upstream_binds(nbo, f.cell_id)
# output = Pluto.CellOutput(; body="3")
# PlutoStaticHTML._store_output!(nbo, f.cell_id, upstream_binds, output)
# upstream_outputs = PlutoStaticHTML._upstream_outputs(nbo, f.cell_id, upstream_binds)
# actual = PlutoStaticHTML._get_output(nbo, f.cell_id, upstream_outputs)
# @test actual == output

actual = PlutoStaticHTML._combined_possibilities([b])
expected = [(f,) for f in 1.0:3.0]
@test actual == expected
actual = PlutoStaticHTML._combined_possibilities([a, b])
@test last(actual) == (2.0, 3.0)
@test length(actual) == 2 * 3

@test PlutoStaticHTML._binds_group(nb, a) == [a, b]
@test PlutoStaticHTML._binds_group(nb, b) == [a, b]

nbo = PlutoStaticHTML._run_dynamic!(nb, session)
bo = nbo.bindoutputs[cell2uuid(f)]
bo.values

