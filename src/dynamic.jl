
function _inject_script(html, script)
    return script * html
end

_is_bond(body, ::MIME"text/html") = startswith(body, "<bond")
_is_bond(body, mime) = false
_is_bond(cell::Pluto.Cell) = _is_bond(cell.output.body, cell.output.mime)

function _run_dynamic!(nb::Notebook, session::ServerSession)
    cells = [nb.cells_dict[cell_uuid] for cell_uuid in nb.cell_order]
    for cell in cells
        if _is_bond(cell)
            @show Pluto.downstream_cells_map(cell, nb)
        end
    end
end

function _possibilities(input::HTMLInput{:range})::Vector
    
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
    options = Pluto.Configuration.from_flat_kwargs(; workspace_use_distributed=false)
    session = ServerSession()
    session.options = options

    run_notebook!(nb, session)
    return nb
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

