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
- `values`: A value for each combination of values for `upstream_binds`.
"""
struct BindOutputs{N}
    name::Base.UUID
    upstream_binds::NTuple{N, Base.UUID}
    values::Dict{NTuple{N, Base.UUID}, Any}
end

"""
All the BindOutputs for the entire notebook.
Struct field contents are modified while changing binds and grabbing outputs.
One invariant of this struct is that each cell which depends on an upstream bind has an entry in it.
"""
struct NotebookBindOutputs
    bindoutputs::Dict{Base.UUID,BindOutputs}

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
            values = Dict{NTuple{N, Base.UUID}, Any}()
            uuid = cell2uuid(cell)
            return BindOutputs{N}(uuid, upstream_binds, values)
        end
        uuids = cell2uuid.(depend_on_binds)
        return new(Dict(zip(uuids, bindoutputs)))
    end
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

"""
Gather the dynamic (@bind) outputs.

"""
function _run_dynamic!(nb::Notebook, session::ServerSession)
    @assert isready(nb)
    return NotebookBindOutputs(nb)
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

