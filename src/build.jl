function _is_cell_done(cell)
    if cell.running_disabled
        return true
    else
        return !cell.queued && !cell.running
    end
end

function nothingstring(x::Union{Nothing,AbstractString})::Union{Nothing,String}
    return x isa Nothing ? x : string(x)::String
end

"""
    BuildOptions(
        dir::AbstractString;
        write_files::Bool=true,
        previous_dir::Union{Nothing,AbstractString}=nothing
    )

Options for `parallel_build`:

- `dir`:
    Directory in which the Pluto notebooks are stored.
- `write_files::Bool=true`:
    Write files to `joinpath(dir, "\$file.html")`.
- `previous_dir::Union{Nothing,AbstractString}=Nothing`:
    Use the output from the previous run as a cache to speed up running time.
    To use the cache, specify a directory `previous_dir::AbstractString` which contains HTML files from a previous run.
    Specifically, files are expected to be at `joinpath(previous_dir, "\$file.html")`.
    The output from the previous run may be embedded in a larger HTML web page.
    This package will extract the original output from the full HTML web page.
    By default, caching is disabled.
- `use_distributed::Bool=true`:
    Whether to build the notebooks in different processes.
    By default, this is enabled just like in Pluto and the notebooks are build in parallel.
    The benefit of different processes is that things are more independent of each other.
    Unfortunately, the drawback is that compilation has to happen for each process.
    By setting this option to `false`, all notebooks are built sequentially in the same process which avoids recompilation.
    This is likely quicker in situations where there are few threads available such as GitHub Runners depending on the notebook contents.
"""
struct BuildOptions
    dir::String
    write_files::Bool
    previous_dir::Union{Nothing,String}
    use_distributed::Bool

    function BuildOptions(
        dir::AbstractString;
        write_files::Bool=true,
        previous_dir::Union{Nothing,AbstractString}=nothing,
        use_distributed::Bool=false
    )
        return new(
            string(dir)::String,
            write_files,
            nothingstring(previous_dir),
            use_distributed
        )
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

function extract_previous_output(html::AbstractString)::String
    start_range = findfirst(BEGIN_IDENTIFIER, html)
    @assert !isnothing(start_range)
    start = first(start_range)

    stop_range = findfirst(END_IDENTIFIER, html)
    @assert !isnothing(stop_range)
    stop = last(stop_range)

    return html[start:stop]
end

"""
    Previous(state::State, html::String)

- `state`: Previous state.
- `html`: HTML starting with "$BEGIN_IDENTIFIER" and ending with "$END_IDENTIFIER".
"""
struct Previous
    state::Union{State,Nothing}
    html::String
end

function Previous(html::String)
    state = contains(html, STATE_IDENTIFIER) ?
        extract_state(html) :
        nothing
    html = contains(html, BEGIN_IDENTIFIER) ?
        extract_previous_output(html) :
        ""
    return Previous(state, html)
end

function Previous(bopts::BuildOptions, in_file)
    prev_dir = bopts.previous_dir
    if isnothing(prev_dir)
        return Previous(nothing, "")
    end
    name, _ = splitext(in_file)
    prev_path = joinpath(prev_dir, "$name.html")
    if !isfile(prev_path)
        return Previous(nothing, "")
    end
    html = read(prev_path, String)
    return Previous(html)
end

function reuse_previous_html(previous::Previous, dir, in_file)::Bool
    in_path = joinpath(dir, in_file)
    curr = path2state(in_path)

    prev = previous.state
    isnothing(prev) && return false

    sha_match = prev.input_sha == curr.input_sha
    julia_match = prev.julia_version == curr.julia_version
    reuse = sha_match && julia_match
    return reuse
end

"""
    parallel_build(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession(),
        write_files=true
    ) -> Vector{String}

Build all `files` in `dir` in parallel.
"""
function parallel_build(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession(),
        write_files=true
    )::Vector{String}

    dir = bopts.dir

    # Start all the notebooks in parallel with async enabled.
    # This way, Pluto handles concurrency.
    X = map(files) do in_file
        in_path = joinpath(dir, in_file)
        @assert isfile(in_path) "Expected .jl file at $in_path"

        previous = Previous(bopts, in_file)
        if reuse_previous_html(previous, bopts.dir, in_file)
            @info "Using cache for Pluto notebook at $in_file"
            return previous
        else
            @info "Starting evaluation of Pluto notebook $in_file"
            tmp_path = _tmp_copy(in_path)
            compiler_options = hopts.compiler_options
            if bopts.use_distributed
                run_async = true
                notebook = SessionActions.open(session, tmp_path; compiler_options, run_async)
                return notebook
            else
                notebook = _load_notebook(tmp_path; compiler_options)
                options = Pluto.Configuration.from_flat_kwargs(; workspace_use_distributed=false)
                session.options = options
                run_notebook!(notebook, session; run_async=false)
                return notebook
            end
        end
    end

    function write_html(in_file, html)
        if bopts.write_files
            without_extension, _ = splitext(in_file)
            out_file = "$(without_extension).html"
            out_path = joinpath(dir, out_file)
            write(out_path, html)
        end
        return nothing
    end

    H = map(zip(files, X)) do (in_file, x)
        if x isa Previous
            html = x.html
            write_html(in_file, html)
            return html
        else
            while !_notebook_done(x)
                sleep(0.1)
            end

            path = joinpath(dir, in_file)
            html = notebook2html(x, path, hopts)
            SessionActions.shutdown(session, x)

            write_html(in_file, html)
            return string(html)::String
        end
    end

    return H
end

"""
    parallel_build(
        bopts::BuildOptions,
        hopts::HTMLOptions=HTMLOptions();
        write_files=true
    ) -> Vector{String}

Build all ".jl" files in `dir` in parallel.
"""
function parallel_build(
        bopts::BuildOptions,
        hopts::HTMLOptions=HTMLOptions();
        write_files=true
    )::Vector{String}
    files = filter(readdir(bopts.dir)) do file
        endswith(file, ".jl") && !startswith(file, TMP_COPY_PREFIX)
    end
    return parallel_build(bopts, files, hopts)
end

