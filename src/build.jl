function _is_cell_done(cell)
    if cell.running_disabled
        return true
    else
        return !cell.queued && !cell.running
    end
end

function nothingstring(x::Union{Nothing,AbstractString})::Union{Nothing,String}
    if x isa Nothing
        return x
    else
        return string(x)::String
    end
end

"""
    BuildOptions(
        dir::AbstractString;
        write_files::Bool=true,
        previous_dir::Union{Nothing,AbstractString}=nothing
    )

- `dir`:
    Directory in which the Pluto notebooks are stored.
- `write_files::Bool=true`:
    Write files to 
- `previous_dir::Union{Nothing,AbstractString}=Nothing`:
    Use the output from the previous run as a cache to speed up running time.
    To use the cache, specify a directory `previous_dir::AbstractString` which contains HTML files from a previous run.
    The output from the previous run may be embedded in a larger HTML web page.
    This package will extract the original output from the full HTML web page.
    By default, caching is disabled since `previous_dir=Nothing`.
"""
struct BuildOptions
    dir::String
    previous_dir::Union{Nothing,String}

    function BuildOptions(
        dir::AbstractString;
        write_files::Bool=true,
        previous_dir::Union{Nothing,AbstractString}=nothing
    )
        return new(
            string(dir)::String,
            write_files,
            nothingstring(previous_dir)
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
    start = last(start_range) + 1

    stop_range = findfirst(END_IDENTIFIER, html)
    @assert !isnothing(stop_range)
    stop = last(stop_range)

    return html[start, stop]
end

"""
    struct Previous

- `state::State`: Previous state.
- `html::String`: HTML starting with "$BEGIN_IDENTIFIER" and ending with "$END_IDENTIFIER".
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

function previous_html(btops::BuildOptions, in_file)
    
end

function reuse_previous_html(previous, dir, in_file)::Bool
    in_path = joinpath(dir, in_file)
    text = read(in_path, String)
    prev = previous.state
    curr = State(text)
    isnothing(prev) && return false
    sha_match = prev.input_sha == curr.input_sha
    julia_match = prev.julia_version == curr.julia_version
    return sha_match && julia_match
end

"""
    parallel_build(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession(),
        write_files=true
    ) -> Vector{String}

Build all ".jl" files in `dir` in parallel.
"""
function parallel_build(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession(),
        write_files=true
    )::Vector{String}

    htmls::Vector{String} = if !isnothing(hopts.previous_html_function)
        previous_html(bopts, files)
    else
        repeat([""], length(files))
    end

    # Start all the notebooks in parallel with async enabled.
    # This way, Pluto handles concurrency.
    X = map(files) do in_file
        in_path = joinpath(dir, in_file)
        @assert isfile(in_path) "Expected .jl file at $in_path"

        previous = Previous(previous_html(btops, in_file))
        if reuse_previous_html(previous, dir, in_file)
            @info "Using cache for Pluto notebook at $in_file"
            return previous
        else
            @info "Starting evaluation of Pluto notebook at $in_file"
            notebook = SessionActions.open(session, in_path; run_async=true)
            return notebook
        end
    end

    H = map(zip(files, X)) do (in_file, x)
        if x isa Previous
            return x.html
        else
            while !_notebook_done(x)
                sleep(0.1)
            end

            without_extension, _ = splitext(in_file)
            out_file = "$(without_extension).html"
            out_path = joinpath(dir, out_file)

            html = notebook2html(x, hopts)
            SessionActions.shutdown(session, x)

            if write_files
                write(out_path, html)
            end
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
    files = filter(endswith(".jl"), readdir(dir))
    return parallel_build(bopts, files, hopts)
end

