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
        # Block until execution is done.
        take!(notebook.executetoken)

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
