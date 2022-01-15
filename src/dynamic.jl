
function _inject_script(html, script)
    return script * html
end

_is_bond(body, ::MIME"text/html") = startswith(body, "<bond")
_is_bond(body, mime) = false
_is_bond(cell::Pluto.Cell) = _is_bond(cell.output.body, cell.output.mime)

"Return indirect upstream cells. Pluto never needs this it seems."
function indirect_upstream_cells(nb::Notebook, cell::Cell)
    map = Pluto.upstream_cells_map(cell, nb)
end

"""
Outputs for one cell which depends on one or more binds.

- `name`: Name of the cell.
- `upstream_binds`:
    Names of the upstream binds, that is, the binds on which the cell depends.
- `values`: A value for each combination of values for `upstream_binds`.
"""
struct BindOutputs
    name::Base.UUID
    upstream_binds::Tuple{Symbol}
    values::Dict{Tuple,Any}
end

"""
All the BindOutputs for the entire notebook.
Struct field contents are modified while changing binds and grabbing outputs.
The invariant of this struct is that each cell has an entry in it.
"""
struct NotebookBindOutputs
    bindoutputs::Dict{Base.UUID,BindOutputs}

    function NotebookBindOutputs(nb::Notebook)
        uuids = nb.cell_order
        bindoutputs = map(uuids) do uuid
            cell = nb.cells_dict[uuid]
            upstream_binds = (:foo, ) # _upstream_bind_cells(nb, cell)
            values = Dict{Tuple,Any}()
            return BindOutputs(uuid, upstream_binds, values)
        end
        return new(Dict(zip(uuids, bindoutputs)))
    end
end

"""
Return upstream bind cells for `cell`.
For these, we need to store all possible outputs.
"""
function _upstream_bind_cells(nb::Notebook, cell::Cell)
    top = nb.topology

end

function _run_dynamic!(nb::Notebook, session::ServerSession)
    cells = [nb.cells_dict[cell_uuid] for cell_uuid in nb.cell_order]
    for cell in reverse(cells)
        if _is_bond(cell)
            @show Pluto.downstream_cells_map(cell, nb)
        end
    end
end

"Based on test/Bonds.jl"
function _set_bond_value!(
        session::ServerSession,
        notebook::Notebook,
        name::Symbol,
        value;
        is_first_value=false
    )
    notebook.bonds[name] = Dict("value" => value)
    Pluto.set_bond_values_reactive(;
        session,
        notebook,
        bound_sym_names=[name],
        is_first_values=[is_first_value],
        run_async=false
    )
    return nothing
end

function _possibilities(input::HTMLInput{:range})::Vector
    return collect(range(input.min, input.max; step=input.step))
end

"""
    _possibilities(cell::Cell)::Union{Vector,Nothing}

Return possible values for `cell` or `Nothing` if this cell isn't a `Bond`.
This method works by reading the Pluto generated HTML input, such as `range`.
"""
function _possibilities(cell::Cell)::Union{Vector,Nothing}
    if _is_bond(cell)
        html = cell.output.body
        input = HTMLInput(html)
        return _possibilities(input)::Vector
    else
        return nothing
    end
end

function _cells_by_rootassignee(nb::Notebook)
    assignees = map(nb.cell_order) do cell_uuid
        cell = nb.cells_dict[cell_uuid]
        out = cell.output
        if hasfield(typeof(out), :rootassignee)
            assignee = out.rootassignee
            if isnothing(assignee)
                assignee = cell.cell_dependencies.downstream_cells_map |> keys |> only
            end
            return (; cell_uuid, assignee)
        else
            return missing
        end
    end
    tuples = collect(skipmissing(assignees))
    K = getproperty.(tuples, :assignee)
    V = getproperty.(tuples, :cell_uuid)
    return Dict(zip(K, V))
end

function _cell(nb::Notebook, assignee::Symbol)
    mapping = PlutoStaticHTML._cells_by_rootassignee(nb)
    cell_uuid = mapping[assignee]
    return nb.cells_dict[cell_uuid]
end

"Temporary function for development purposes."
function __notebook()
    nb = _load_notebook("/home/rik/git/PlutoStaticHTML.jl/docs/src/dynamic.jl")
    session = ServerSession()
    options = Pluto.Configuration.from_flat_kwargs(; workspace_use_distributed=false)
    session.options = options

    run_notebook!(nb, session)
    return (session, nb)
end

"Temporary function for development purposes"
function __build()
    dir = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
    file = "dynamic.jl"

    bopts = BuildOptions(dir; use_distributed=false)
    hopts = HTMLOptions(; output_class="documenter-example-output")
    htmls = parallel_build(bopts, [file], hopts)
    html = only(htmls)

    script = """
        <script>
        console.log("ba")
        </script>
        """

    return _inject_script(html, script)
end

