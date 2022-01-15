
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

