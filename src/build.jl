function _is_cell_done(cell)
    if cell.running_disabled
        return true
    else
        return !cell.queued && !cell.running
    end
end

"""
    _is_notebook_done(notebook::Notebook)

Return whether all cells in the `notebook` have executed.
This method is more reliable than using `notebook.executetoken` because Pluto.jl drops that lock also after installing packages.
"""
function _notebook_done(notebook::Notebook)
    cells = [last(elem) for elem in notebook.cells_dict]
    return all(_is_cell_done, cells)
end

"""
    parallel_build!(
        dir,
        files;
        print_log=true,
        session=ServerSession()
    )

Build HTML files in parallel and write output to files with a ".html" extension.
This can be useful to speed up the build locally or in CI.
"""
function parallel_build!(
        dir,
        files;
        print_log=true,
        session=ServerSession()
    )

    # Start all the notebooks in parallel with async enabled.
    # This way, Pluto handles concurrency.
    notebooks = map(files) do in_file
        in_path = joinpath(dir, in_file)
        @assert isfile(in_path) "Expected .jl file at $in_path"

        @info "Starting evaluation of Pluto notebook at $in_file"
        notebook = SessionActions.open(session, in_path; run_async=true)
        return notebook
    end

    for (in_file, notebook) in zip(files, notebooks)
        while !_notebook_done(notebook)
            sleep(1)
        end

        without_extension, _ = splitext(in_file)
        out_file = "$(without_extension).html"
        out_path = joinpath(dir, out_file)

        html = notebook2html(notebook)
        SessionActions.shutdown(session, notebook)
        write(out_path, html)
    end

    return nothing
end

function parallel_build!(dir; print_log=true)
    files = filter(endswith(".jl"), readdir(dir))
    parallel_build!(dir, files; print_log)
    return nothing
end
