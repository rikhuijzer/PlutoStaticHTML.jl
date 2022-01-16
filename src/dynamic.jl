cell2uuid(cell::Pluto.Cell) = cell.cell_id
uuid2cell(nb::Notebook, id::Base.UUID) = nb.cells_dict[id]

function _inject_script(html, script)
    return script * html
end

"Return indirect dependency cells. Pluto never needs this it seems."
function _indirect_dependency_cells(nb, cell::Cell, map_fn; out=Base.UUID[])
    @assert isready(nb)
    direct = map_fn(cell, nb)::Dict{Symbol, Vector{Cell}}
    for name::Symbol in collect(keys(direct))
        cells = direct[name]
        if !isempty(cells)
            for cell in cells
                push!(out, cell2uuid(cell))
                _indirect_dependency_cells(nb, cell, map_fn; out)
            end
        end
    end
    return out
end

function _indirect_upstream_cells(nb::Notebook, cell::Cell)::Vector{Base.UUID}
    map_fn = Pluto.upstream_cells_map
    return _indirect_dependency_cells(nb, cell, map_fn)
end

function _indirect_downstream_cells(nb::Notebook, cell::Cell)::Vector{Base.UUID}
    map_fn = Pluto.downstream_cells_map
    return _indirect_dependency_cells(nb, cell, map_fn)
end

_is_bind(body, ::MIME"text/html") = startswith(body, "<bond")
_is_bind(body, ::Any) = false
_is_bind(cell::Pluto.Cell) = _is_bind(cell.output.body, cell.output.mime)

"""
Return upstream bind cells for `cell`.
For these, we need to store all possible outputs.
"""
function _upstream_bind_cells(nb::Notebook, cell::Cell)::Vector{Base.UUID}
    upstream = uuid2cell.(Ref(nb), _indirect_upstream_cells(nb, cell))
    filtered = filter(_is_bind, upstream)
    return cell2uuid.(filtered)
end

"""
Outputs for one cell which depends on one or more binds.

- `name`: Name of the cell.
- `upstream_binds`:
    Names of the upstream binds, that is, the binds on which the cell depends.
- `values`:
    A value for each combination of values for `upstream_binds`.
    For example, an entry could be `[2, 4] => 6` if `name` depends on two bind cells which give 6 as output when the bind cells are set to 2 and 4.
"""
struct BindOutputs{N}
    name::Base.UUID
    upstream_binds::NTuple{N, Base.UUID}
    values::Dict{NTuple{N, CellOutput}, CellOutput}
end

function show(io::IO, bo::BindOutputs)
    println(io, string(typeof(bo), '('))
    println(io, string("    name = ", bo.name))
    println(io, string("    upstream_binds = ", bo.upstream_binds))
    println(io, string("    values = ", bo.values))
    print(io, "  )")
end

"""
All the BindOutputs for the entire notebook.
Struct field contents are modified while changing binds and grabbing outputs.
One invariant of this struct is that each cell which depends on an upstream bind has an entry in it.
"""
struct NotebookBindOutputs
    nb::Notebook
    bindoutputs::Dict{Base.UUID, BindOutputs}

    function NotebookBindOutputs(nb::Notebook)
        @assert isready(nb)
        output_cells = filter(!_is_bind, nb.cells)
        depend_on_binds = filter(output_cells) do cell
            !isempty(_upstream_bind_cells(nb, cell))
        end

        bindoutputs = map(depend_on_binds) do cell
            upstream_uuids = _upstream_bind_cells(nb, cell)
            N = length(upstream_uuids)
            upstream_binds = NTuple{N, Base.UUID}(upstream_uuids)
            values = Dict{NTuple{N, CellOutput}, CellOutput}()
            uuid = cell2uuid(cell)
            return BindOutputs{N}(uuid, upstream_binds, values)
        end
        uuids = cell2uuid.(depend_on_binds)
        return new(nb, Dict(zip(uuids, bindoutputs)))
    end
end

"Return cells which depend on upstream bind cells."
_depend_binds(nbo::NotebookBindOutputs)::Vector{Base.UUID} = collect(keys(nbo.bindoutputs))

function _upstream_binds(nbo::NotebookBindOutputs, cell::Base.UUID)::NTuple
    return nbo.bindoutputs[cell].upstream_binds
end

function _upstream_outputs(nbo::NotebookBindOutputs, cell::Base.UUID, upstream_binds)
    upstream_outputs = map(upstream_binds) do uuid
        cell = uuid2cell(nbo.nb, uuid)
        cell.output
    end
    return upstream_outputs
end

function _set_output!(nbo::NotebookBindOutputs, cell::Base.UUID, upstream_binds, output::CellOutput)
    upstream_outputs = _upstream_outputs(nbo, cell, upstream_binds)
    bo = nbo.bindoutputs[cell]
    bo.values[upstream_outputs] = output
    return nothing
end

function _get_output(nbo::NotebookBindOutputs, cell::Base.UUID, upstream_outputs)::CellOutput
    bo::BindOutputs = nbo.bindoutputs[cell]
    return bo.values[upstream_outputs]
end

function show(io::IO, nbo::NotebookBindOutputs)
    println(io, string(typeof(nbo), '(', typeof(nbo.bindoutputs), '('))
    for key in keys(nbo.bindoutputs)
        println(io, string("  ", key, " => ", nbo.bindoutputs[key]))
    end
    print(io, ')')
end

"""
    _possibilities(cell::Cell)::Union{Vector,Nothing}

Return possible values for `cell` or `Nothing` if this cell isn't a `Bond`.
This method works by reading the Pluto generated HTML input, such as `range`.
"""
function _possibilities(cell::Cell)::Union{Vector,Nothing}
    if _is_bind(cell)
        html = cell.output.body
        input = HTMLInput(html)
        return _possibilities(input)::Vector
    else
        return nothing
    end
end

function _binds(nb::Notebook)::Vector{Base.UUID}
    @assert isready(nb)
    return cell2uuid.(filter(_is_bind, nb.cells))
end

function _change_assignment!(cell::Cell, value::String)
    var::Symbol = cell.output.rootassignee
    cell.code = string(var, " = ", value)
end

_strvalue(cell::Cell) = string(cell.output.body)::String

"""
Store output for `cell` after things have been updated.
"""
function _store_output!(nbo::NotebookBindOutputs, cell::Base.UUID)
    upstream_binds = _upstream_binds(nbo, cell)
    N = length(upstream_binds)
    upstream_values = map(upstream_binds) do uuid::Base.UUID
        cell = uuid2cell(nb, uuid)
        value = cell.output.body
    end
    
end

"""
Initiate value for `cell` and stores the outputs for all cells that depend on `cell`.
"""
function _run_initiate!(nbo, nb::Notebook, session, possibilities::Vector, cell::Base.UUID)
    value = first(possibilities)
    _change_assignment!(cell, value)
    run_notebook!(nb, session)
    downstream_output_cells = _indirect_downstream_cells(nb, cell)
    for cell in downstream_output_cells

    end
    return nothing
end

"""
Increase value for `cell` and capture the outputs for all cells that depend on `cell`.
Note that this also stores the value of other bind cells at the time of running.
"""
function _run_increase!(nbo, nb::Notebook, session, possibilities::Vector, cell::Base.UUID)
    current = cell.output.body

end

"""
Gather the dynamic (@bind) outputs.

"""
function _run_dynamic!(nb::Notebook, session::ServerSession)
    @assert isready(nb)
    nbo = NotebookBindOutputs(nb)
    cells = uuid2cell.(Ref(nb), nb.cell_order)

    output_cells = filter(!_is_bind, nb.cells)
    depend_on_binds = filter(output_cells) do cell
        !isempty(_upstream_bind_cells(nb, cell))
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

