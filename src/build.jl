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
        dir,
        files,
        opts::HTMLOptions=HTMLOptions();
        session=ServerSession()
    ) -> Vector{String}

Build all ".jl" files in `dir` in parallel.
"""
function parallel_build(
        dir,
        files,
        opts::HTMLOptions=HTMLOptions();
        session=ServerSession()
    )::Vector{String}

    htmls::Vector{String} = if !isnothing(opts.previous_html_function)
        previous_html_function(files)
    else
        repeat([""], length(files))
    end

    # Start all the notebooks in parallel with async enabled.
    # This way, Pluto handles concurrency.
    X = map(zip(files, htmls)) do (in_file, html)
        in_path = joinpath(dir, in_file)
        @assert isfile(in_path) "Expected .jl file at $in_path"

        previous = Previous(html)
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

            html = notebook2html(X, opts)
            SessionActions.shutdown(session, X)
            return string(html)::String
        end
    end

    return H
end

"""
    parallel_build(dir, opts::HTMLOptions=HTMLOptions()) -> Vector{String}

Build all ".jl" files in `dir` in parallel.
"""
function parallel_build(dir, opts::HTMLOptions=HTMLOptions())::Vector{String}
    files = filter(endswith(".jl"), readdir(dir))
    return parallel_build(dir, files, opts)
end

