
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

function _cells_by_rootassignee(nb::Notebook)
    pairs = map(nb.cell_order) do cell_uuid
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
    mapping = collect(skipmissing(pairs))
    K = getproperty.(mapping, :assignee)
    V = getproperty.(mapping, :cell_uuid)
    return Dict(zip(K, V))
end

"Temporary function for development purposes."
function __asnotebook()
    nb = _load_notebook("/home/rik/git/PlutoStaticHTML.jl/docs/src/dynamic.jl")
    options = Pluto.Configuration.from_flat_kwargs(; workspace_use_distributed=false)
    session = ServerSession()
    session.options = options

    run_notebook!(nb, session)
    cells = _cells_by_rootassignee(nb)
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

