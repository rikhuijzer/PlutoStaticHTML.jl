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
        previous_dir::Union{Nothing,AbstractString}=nothing,
        use_distributed::Bool=true,
        store_binds::Bool=false
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
    Beware that `use_distributed=false` will not work with Pluto's built-in package manager.
- `store_binds::Bool=false`:
    Store outputs for all possible combinations of bind values.
    *Highly experimental feature which may be removed at any time.*
- `max_stored_binds::Int=1_000`:
    Maximum number of bind outputs to store.
    Most repositories and static site hosters should easily be able to handle 10k files or more, but a default of 1k seems reasonable.
"""
struct BuildOptions
    dir::String
    write_files::Bool
    previous_dir::Union{Nothing,String}
    use_distributed::Bool
    store_binds::Bool

    function BuildOptions(
        dir::AbstractString;
        write_files::Bool=true,
        previous_dir::Union{Nothing,AbstractString}=nothing,
        use_distributed::Bool=true,
        store_binds::Bool=false
    )
        return new(
            string(dir)::String,
            write_files,
            nothingstring(previous_dir),
            use_distributed,
            store_binds
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

"Write `html` to a file which is a sibling to `in_path`."
function _write_html(in_path, html, bopts::BuildOptions)
    if bopts.write_files
        dir = dirname(in_path)
        in_file = basename(in_path)
        without_extension, _ = splitext(in_file)
        out_file = "$(without_extension).html"
        out_path = joinpath(dir, out_file)
        write(out_path, html)
    end
    return nothing
end

function _outcome2html(session, prev::Previous, in_path, bopts, hopts)::String
    html = prev.html
    _write_html(in_path, html, bopts)
    return html
end

function _outcome2html(session, nb::Notebook, in_path, bopts, hopts)::String
    while !_notebook_done(nb)
        sleep(0.1)
    end

    if bopts.store_binds
        nbo = _run_dynamic!(nb, session)
        top_dir_name = first(splitext(basename(in_path)))
        output_dir = joinpath(dirname(in_path), top_dir_name)
        _storebinds(output_dir, nbo, hopts)
    end
    html = notebook2html(nb, in_path, hopts)
    SessionActions.shutdown(session, nb)

    _write_html(in_path, html, bopts)
    return string(html)::String
end

"""
    parallel_build(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession()
    ) -> Vector{String}

Build all `files` in `dir` in parallel.
"""
function parallel_build(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession()
    )::Vector{String}

    dir = bopts.dir


    # Start all the notebooks in parallel with async enabled if `use_distributed`.
    X = map(files) do in_file
        in_path = joinpath(dir, in_file)
        @assert isfile(in_path) "Expected .jl file at $in_path"

        previous = Previous(bopts, in_file)
        if reuse_previous_html(previous, bopts.dir, in_file)
            @info "Using cache for Pluto notebook at $in_file"
            return previous
        else
            @info "Starting evaluation of Pluto notebook $in_file"
            compiler_options = hopts.compiler_options
            if bopts.use_distributed
                tmp_path = _tmp_copy(in_path)
                nb = SessionActions.open(session, tmp_path; compiler_options, run_async=true)
                return nb
            else
                nb = _load_notebook(in_path; compiler_options)
                options = Pluto.Configuration.from_flat_kwargs(; workspace_use_distributed=false)
                session.options = options
                session.options.server.disable_writing_notebook_files = true
                run_notebook!(nb, session)
                return nb
            end
        end
    end

    H = map(zip(files, X)) do (in_file, x)
        in_path = joinpath(dir, in_file)
        html = _outcome2html(session, x, in_path, bopts, hopts)
        return html
    end

    return H
end

"""
    parallel_build(
        bopts::BuildOptions,
        hopts::HTMLOptions=HTMLOptions()
    ) -> Vector{String}

Build all ".jl" files in `dir` in parallel.
"""
function parallel_build(
        bopts::BuildOptions,
        hopts::HTMLOptions=HTMLOptions()
    )::Vector{String}
    files = filter(readdir(bopts.dir)) do file
        endswith(file, ".jl") && !startswith(file, TMP_COPY_PREFIX)
    end
    return parallel_build(bopts, files, hopts)
end

