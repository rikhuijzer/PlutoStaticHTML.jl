cell2uuid(cell::Pluto.Cell) = cell.cell_id
uuid2cell(nb::Notebook, id::Base.UUID) = nb.cells_dict[id]

function _inject_script(html, script)
    return html * script
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
    values::Dict{NTuple{N, Any}, CellOutput}
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
            values = Dict{NTuple{N, Any}, CellOutput}()
            uuid = cell2uuid(cell)
            return BindOutputs{N}(uuid, upstream_binds, values)
        end
        uuids = cell2uuid.(depend_on_binds)
        return new(nb, Dict(zip(uuids, bindoutputs)))
    end
end

function show(io::IO, nbo::NotebookBindOutputs)
    println(io, string(typeof(nbo), '(', typeof(nbo.bindoutputs), '('))
    for key in keys(nbo.bindoutputs)
        println(io, string("  ", key, " => ", nbo.bindoutputs[key]))
    end
    print(io, ')')
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

"Store output for `cell` based on current state of the notebook."
function _store_output!(nbo::NotebookBindOutputs, cell::Base.UUID, upstream_binds, output::CellOutput)
    upstream_outputs = _upstream_outputs(nbo, cell, upstream_binds)
    bo = nbo.bindoutputs[cell]
    bo.values[upstream_outputs] = output
    return nothing
end

"Store output for `cell` based on the current state of the notebook."
function _store_output!(nbo::NotebookBindOutputs, cell::Base.UUID, output::CellOutput)
    upstream_binds = _upstream_binds(nbo, cell)
    return _store_output!(nbo, cell, upstream_binds, output)
end

"Store output for `cell` based on the current state of the notebook."
function _store_output!(nbo::NotebookBindOutputs, cell_uuid::Base.UUID)
    cell = uuid2cell(nbo.nb, cell_uuid)
    return _store_output!(nbo, cell_uuid, cell.output)
end

"Useful for testing."
function _get_output(nbo::NotebookBindOutputs, cell::Base.UUID, upstream_outputs)::CellOutput
    bo::BindOutputs = nbo.bindoutputs[cell]
    return bo.values[upstream_outputs]
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


"The possible values can be any according to Pluto.BondValue."
function _possibilities(input::HTMLInput{:range})::Vector{Any}
    r = HTTPRange(input)
    real_values = collect(range(r.min, r.max; step=r.step))
    bond_values = collect(1:length(real_values))
    return bond_values
end

"Pluto.possible_bond_values didn't work, so here we are."
function _change_assignment!(cell::Cell, input)
    var = _var(cell)
    # For debugging purposes; to test whether Pluto evaluates the cells.
    input = "(@show $var; $input)"
    # @show string(var, " = ", input)
    cell.code = string(var, " = ", input)
end

function _read_assignment(cell::Cell)
    input_start_location = first(findfirst("=", cell.code)) + 2
    return string(cell.code[input_start_location:end])
end

"Return all binds and the input `cell` which affect some output together with this cell."
function _binds_group(nb, cell::Cell)::Vector{Cell}
    @assert _is_bind(cell)
    # These are non-bind because a bind cannot depend on a bind.
    downstream = _indirect_downstream_cells(nb, cell)
    related = Cell[]
    for cell_uuid::Base.UUID in downstream
        cell = uuid2cell(nb, cell_uuid)
        upstream = _indirect_upstream_cells(nb, cell)
        for upstream_cell_uuid in upstream
            upstream_cell = uuid2cell(nb, upstream_cell_uuid)
            if _is_bind(upstream_cell)
                push!(related, upstream_cell)
            end
        end
    end
    related = unique(related)
    return related
end

"Vector of all possible bind combinations."
function _combined_possibilities(cells::Vector{Cell})::Vector{Tuple}
    all_possibilities = _possibilities.(cells)
    prod = collect(Iterators.product(all_possibilities...))
    return vec(prod)
end

function _instantiate_bind_values!(nb::Notebook)
    binds = filter(_is_bind, nb.cells)
    for cell in binds
        v = _var(cell)
        nb.bonds[v] = BondValue(1)
    end
end

function _downstream_output_cells(nbo, binds_group::Vector{Cell})::Vector{Cell}
    out = Cell[]
    for bind::Cell in binds_group
        downstream = _indirect_downstream_cells(nbo.nb, bind)
        # Cannot be binds because they are downstream.
        downstream_cells = uuid2cell.(Ref(nbo.nb), downstream)
        foreach(c -> push!(out, c), downstream_cells)
    end
    return unique(out)
end

_val(cell::Cell) = cell.output.body

function _update_run_bind_values!(nbo, session, binds_group, values)
    binds_uuids = cell2uuid.(binds_group)
    bondvalues = Dict(zip(binds_uuids, values))
    cell_uuids = collect(keys(bondvalues))
    cells = uuid2cell.(Ref(nbo.nb), cell_uuids)
    bound_sym_names = [_var(cell) for cell in cells]
    for (cell, bound_sym_name) in zip(cells, bound_sym_names)
        # Note that the bondvalue is the slider number and not the real number.
        nbo.nb.bonds[bound_sym_name] = BondValue(bondvalues[cell2uuid(cell)])
    end
    Pluto.set_bond_values_reactive(; session, notebook=nbo.nb, bound_sym_names)

    # Update stored values.
    for downstream_cell::Cell in _downstream_output_cells(nbo, cells)
        bo = nbo.bindoutputs[cell2uuid(downstream_cell)]
        binds_order = bo.upstream_binds # NTuple{N, Base.UUID}
        # @show binds_order
        # @show _val.(uuid2cell.(Ref(nbo.nb), binds_order))
        # @show bondvalues
        key = Tuple(bondvalues[uuid] for uuid in binds_order)
        value = _val(downstream_cell)
        # @show key
        bo.values[key] = downstream_cell.output
    end
end

"""
Change all inputs for the binds in `nb` iteratively and store the outputs.
"""
function _run_dynamic!(nb::Notebook, session::ServerSession)
    @assert isready(nb)
    nbo = NotebookBindOutputs(nb)
    binds = filter(_is_bind, nb.cells)
    _instantiate_bind_values!(nb)
    for cell::Cell in binds
        binds_group = _binds_group(nb, cell)::Vector{Cell}
        combined_possibilities = _combined_possibilities(binds_group)
        for values in combined_possibilities
            _update_run_bind_values!(nbo, session, binds_group, values)
        end
    end
    return nbo
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

    bopts = BuildOptions(dir; store_binds=true, use_distributed=false)
    hopts = HTMLOptions(; output_class="documenter-example-output")
    htmls = parallel_build(bopts, [file], hopts)
    html = only(htmls)

    # Drop extension regex; thanks to https://stackoverflow.com/questions/25351184.
    rx = raw"""/\.[^/.]+$/"""
    script = """
        // this file should be fully stand-alone and parse the index.
        <script type='text/javascript'>
            async function getText(url) {
                let f = await fetch(url);
                let text = await f.text();
                return text
            }
            async function process() {
                output_dir = window.location.href.replace($rx, "")
                const url = output_dir + '/c/1/1.html';
                console.log('url: ' + url);
                var output = await getText(url);
                console.log('output: ' + output);
                const el = document.getElementById('d');
                console.log(el);
            }
            process()
        </script>
        """

    return _inject_script(html, script)
end

