function _is_cell_done(cell)
    if cell.metadata["disabled"]
        return true
    else
        return !cell.queued && !cell.running
    end
end

function nothingstring(x::Union{Nothing,AbstractString})::Union{Nothing,String}
    return x isa Nothing ? x : string(x)::String
end

@enum OutputFormat begin
    documenter_output
    franklin_output
    html_output
    pdf_output
end

const WRITE_FILES_DEFAULT = true
const PREVIOUS_DIR_DEFAULT = nothing
const OUTPUT_FORMAT_DEFAULT = html_output
const ADD_DOCUMENTER_CSS_DEFAULT = true
const USE_DISTRIBUTED_DEFAULT = true
const MAX_CONCURRENT_RUNS_DEFAULT = 4

"""
    BuildOptions(
        dir::AbstractString;
        write_files::Bool=$WRITE_FILES_DEFAULT,
        previous_dir::Union{Nothing,AbstractString}=$PREVIOUS_DIR_DEFAULT,
        output_format::Union{OutputFormat,Vector{OutputFormat}}=$OUTPUT_FORMAT_DEFAULT,
        add_documenter_css::Bool=$ADD_DOCUMENTER_CSS_DEFAULT,
        use_distributed::Bool=$USE_DISTRIBUTED_DEFAULT,
        compiler_options::Union{Nothing,CompilerOptions}=$COMPILER_OPTIONS_DEFAULT,
        max_concurrent_runs::Int=$MAX_CONCURRENT_RUNS_DEFAULT
    )

Arguments:

- `dir`:
    Directory in which the Pluto notebooks are stored.
- `write_files`:
    Write files to `joinpath(dir, "\$file.html")`.
- `previous_dir::Union{Nothing,AbstractString}=Nothing`:
    Use the output from the previous run as a cache to speed up running time.
    To use the cache, specify a directory `previous_dir::AbstractString` which contains HTML or Markdown files from a previous run.
    Specifically, files are expected to be at `joinpath(previous_dir, "\$file.html")`.
    The output from the previous run may be embedded in a larger HTML or Markdown file.
    This package will extract the original output from the full file contents.
    By default, caching is disabled.
-  `output_format`:
    What file to write the output to.
    By default this is `html_output::OutputFormat` meaning that the output of the HTML method is pure HTML.
    To generate Franklin, Documenter or PDF files, use respectively `franklin_output`, `documenter_output` or `pdf_output`.
    When `BuildOptions.write_files == true` and `output_format == franklin_output` or `output_format == documenter_output`, the output file has a ".md" extension instead of ".html".
    When `BuildOptions.write_files == true` and `output_format == pdf_output`, two output files are created with ".tex" and ".pdf" extensions.
- `add_documenter_css` whether to add a CSS style to the HTML when `documenter_output=true`.
- `use_distributed`:
    Whether to build the notebooks in different processes.
    By default, this is enabled just like in Pluto and the notebooks are build in parallel.
    The benefit of different processes is that things are more independent of each other.
    Unfortunately, the drawback is that compilation has to happen for each process.
    By setting this option to `false`, all notebooks are built sequentially in the same process which avoids recompilation.
    This is likely quicker in situations where there are few threads available such as GitHub Runners depending on the notebook contents.
    Beware that `use_distributed=false` will **not** work with Pluto's built-in package manager.
- `compiler_options`:
    `Pluto.Configuration.CompilerOptions` to be passed to Pluto.
    This can, for example, be useful to pass custom system images from `PackageCompiler.jl`.
- `max_concurrent_runs`:
    Maximum number of notebooks to evaluate concurrently when `use_distributed=true`.
    Note that each notebook starts in a different process and can start multiple threads, so don't set this number too high or the CPU might be busy switching tasks and not do any productive work.
"""
struct BuildOptions
    dir::String
    write_files::Bool
    previous_dir::Union{Nothing,String}
    output_format::Vector{OutputFormat}
    add_documenter_css::Bool
    use_distributed::Bool
    compiler_options::Union{Nothing,CompilerOptions}
    max_concurrent_runs::Int

    function BuildOptions(
            dir::AbstractString;
            write_files::Bool=WRITE_FILES_DEFAULT,
            previous_dir::Union{Nothing,AbstractString}=PREVIOUS_DIR_DEFAULT,
            output_format::Union{OutputFormat,Vector{OutputFormat}}=OUTPUT_FORMAT_DEFAULT,
            add_documenter_css::Bool=ADD_DOCUMENTER_CSS_DEFAULT,
            use_distributed::Bool=USE_DISTRIBUTED_DEFAULT,
            compiler_options::Union{Nothing,CompilerOptions}=COMPILER_OPTIONS_DEFAULT,
            max_concurrent_runs::Int=MAX_CONCURRENT_RUNS_DEFAULT
        )
        if !(output_format isa Vector)
            output_format = OutputFormat[output_format]
        end
        return new(
            string(dir)::String,
            write_files,
            nothingstring(previous_dir),
            output_format,
            add_documenter_css,
            use_distributed,
            compiler_options,
            max_concurrent_runs
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

function _wait_for_notebook_done(nb::Notebook)
    while !_notebook_done(nb)
        sleep(1)
    end
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
- `text`: Either
    - HTML starting with "$BEGIN_IDENTIFIER" and ending with "$END_IDENTIFIER" or
    - Contents of a Franklin/Documenter Markdown file.
"""
struct Previous
    state::Union{State,Nothing}
    text::String
end

function Previous(text::String)
    state = contains(text, STATE_IDENTIFIER) ?
        extract_state(text) :
        nothing
    text = contains(text, BEGIN_IDENTIFIER) ?
        extract_previous_output(text) :
        ""
    return Previous(state, text)
end

function Previous(previous_dir, output_format::OutputFormat, in_file)
    prev_dir = previous_dir
    if isnothing(prev_dir)
        return Previous(nothing, "")
    end
    name, _ = splitext(in_file)
    ext = output_format == html_output ? ".html" : ".md"
    prev_path = joinpath(prev_dir, "$name$ext")
    if !isfile(prev_path)
        @info "Could not find cache for \"$in_file\" at \"$prev_path\""
        return Previous(nothing, "")
    end
    text = read(prev_path, String)
    return Previous(text)
end

function reuse_previous(previous::Previous, dir, in_file)::Bool
    in_path = joinpath(dir, in_file)
    curr = path2state(in_path)

    prev = previous.state
    if isnothing(prev)
        return false
    end

    sha_match = prev.input_sha == curr.input_sha
    if !sha_match
        @info "SHA of previous file did not match the SHA of the current file. Ignoring cache for \"$in_file\""
    end
    julia_match = prev.julia_version == curr.julia_version
    if !julia_match
        @info "Julia version of previous file did not match the current version. Ignoring cache for \"$in_file\""
    end
    reuse = sha_match && julia_match
    return reuse
end

"""
Write to a ".html" or ".md" file depending on `OutputOptions.output_format`.
The output file is always a sibling to the file at `in_path`.
"""
function _write_main_output(
        in_path::String,
        text::String,
        bopts::BuildOptions,
        output_format::OutputFormat,
        oopts::OutputOptions
    )
    ext = output_format == html_output ? ".html" :
        output_format == pdf_output ? ".pdf" : ".md"
    if bopts.write_files
        dir = dirname(in_path)
        in_file = basename(in_path)
        without_extension, _ = splitext(in_file)
        out_file = "$(without_extension)$(ext)"
        out_path = joinpath(dir, out_file)
        @info "Writing output to \"$out_path\""
        write(out_path, text)
    end
    return nothing
end

"Used when creating the page for the first time and to restore the cache."
function _wrap_franklin_output(html)
    return "~~~\n$(html)\n~~~"
end

"Used when creating the page for the first time and when restoring the cache."
function _wrap_documenter_output(html::String, bopts::BuildOptions, in_path::String)
    if bopts.add_documenter_css
        html = _add_documenter_css(html)
    end
    editurl = _editurl_text(bopts, in_path)
    return """
        ```@raw html
        $(_fix_header_links(html))
        ```
        $editurl
        """
end

function _outcome2text(session, prevs::Vector{Previous}, in_path::String, bopts, oopts)::Vector{String}
    texts = map(zip(prevs, bopts.output_format)) do (prev, output_format)
        text = prev.text
        if output_format == franklin_output
            text = _wrap_franklin_output(text)
        end
        if output_format == documenter_output
            text = _wrap_documenter_output(text, bopts, in_path)
        end
        _write_main_output(in_path, text, bopts, output_format, oopts)
        return text
    end
    return texts
end

function _inject_script(html, script)
    l = length(END_IDENTIFIER)
    without_end = html[1:end-l]
    return string(without_end, '\n', script, '\n', END_IDENTIFIER)
end

function _outcome2pdf(
        nb::Notebook,
        in_path::String,
        bopts::BuildOptions,
        output_format::OutputFormat,
        oopts::OutputOptions
    )
    @assert output_format == pdf_output
    tex = notebook2tex(nb, in_path, oopts)

    # _write_main_output(...)

    return tex
end

function _outcome2html(
        nb::Notebook,
        in_path::String,
        bopts::BuildOptions,
        output_format::OutputFormat,
        oopts::OutputOptions
    )
    html = notebook2html(nb, in_path, oopts)

    if output_format == franklin_output
        html = _wrap_franklin_output(html)
    end
    if output_format == documenter_output
        html = _wrap_documenter_output(html, bopts, in_path)
    end

    _write_main_output(in_path, html, bopts, output_format, oopts)
    return string(html)::String
end

function _outcome2text(session, nb::Notebook, in_path::String, bopts, oopts)::Vector{String}
    _throw_if_error(session, nb)

    texts = map(bopts.output_format) do output_format
        if output_format == pdf_output
            return _outcome2pdf(nb, in_path, bopts, output_format, oopts)
        else
            return _outcome2html(nb, in_path, bopts, output_format, oopts)
        end
    end

    # The sleep avoids `AssertionError: will_run_code(notebook)`
    @async begin
        sleep(5)
        SessionActions.shutdown(session, nb; verbose=false)
    end

    return texts
end

const TimeState = Dict{String,DateTime}

_time_init!(time_state::TimeState, in_file::String) = setindex!(time_state, now(), in_file)
_time_elapsed(time_state::TimeState, in_file::String) = now() - time_state[in_file]

"Return `... minutes and ... seconds`."
function _pretty_elapsed(t::Millisecond)
    value = t.value
    seconds = Float64(value) / 1000
    min, sec = divrem(seconds, 60)
    rmin = round(Int, min)
    min_text = rmin == 0 ? "" :
        rmin == 1 ? "$rmin minute and " :
        "$rmin minutes and "
    rsec = round(Int, sec)
    sec_text = rsec == 1 ? "$rsec second" : "$rsec seconds"
    return string(min_text, sec_text)
end

"Return multiple previous files (caches) or nothing when a new evaluation is needed."
function _prevs(bopts::BuildOptions, dir, in_file)::Union{Vector{Previous},Nothing}
    prevs = Previous[]
    for output_format in bopts.output_format
        prev = Previous(bopts.previous_dir, output_format, in_file)
        if !reuse_previous(prev, dir, in_file)
            return nothing
        end
        push!(prevs, prev)
    end
    return prevs
end

function run_notebook!(
        path::AbstractString,
        session::ServerSession;
        compiler_options::Union{Nothing,CompilerOptions}=nothing,
        run_async::Bool=false
    )
    # Avoid changing pwd.
    previous_dir = pwd()
    session.options.server.disable_writing_notebook_files = true
    nb = SessionActions.open(session, path; compiler_options, run_async)
    if !run_async
        _throw_if_error(session, nb)
    end
    cd(previous_dir)
    return nb
end

function _add_extra_preamble!(session::ServerSession)
    current = session.options.evaluation.workspace_custom_startup_expr
    config = CONFIG_PLUTORUNNER
    if current !== nothing && current != config
        @warn "Expected the `workspace_custom_startup_expr` setting to not be set by someone else; overriding it."
    end
    session.options.evaluation.workspace_custom_startup_expr = config
    return session
end

"""
    _evaluate_file(bopts, oopts, session, in_file, time_state)

Return either
- `Vector{Previous}` if the cache was a hit for all `output_format`s, or
- `Notebook` if there was a cache miss for one or more `output_format`s.
"""
function _evaluate_file(bopts::BuildOptions, oopts::OutputOptions, session, in_file, time_state)
    dir = bopts.dir
    in_path = joinpath(dir, in_file)::String

    @assert isfile(in_path) "File not found at \"$in_path\""
    @assert (string(splitext(in_file)[2]) == ".jl") "File doesn't have a `.jl` extension at \"$in_path\""

    _add_extra_preamble!(session)

    prevs = _prevs(bopts, dir, in_file)
    if !isnothing(prevs)
        @info "Using cache for Pluto notebook at \"$in_file\""
        return prevs
    else
        @info "Starting evaluation of Pluto notebook \"$in_file\""
        if bopts.use_distributed
            run_async = true
        else
            run_async = false
            # `use_distributed` means mostly "whether to run in a new process".
            session.options.evaluation.workspace_use_distributed = false
        end
        nb = run_notebook!(in_path, session; bopts.compiler_options, run_async)

        if bopts.use_distributed
            # The notebook is running in a distributed process, but we still need to wait to
            # avoid spawning too many processes in `_evaluate_parallel`.
            _wait_for_notebook_done(nb)
        end
        elapsed = _time_elapsed(time_state, in_file)
        pretty_elapsed = _pretty_elapsed(elapsed)
        @info "Finished evaluation of Pluto notebook \"$in_file\" in $pretty_elapsed"
        return nb
    end
end

"""
Evaluate `files` in parallel.

Using asynchronous tasks instead of multi-threading since Downloads is not thread-safe on Julia 1.6/1.7.
https://github.com/JuliaLang/Downloads.jl/issues/110.
"""
function _evaluate_parallel(bopts, oopts, session, files, time_state)
    ntasks = bopts.max_concurrent_runs
    X = asyncmap(files; ntasks) do in_file
        _time_init!(time_state, in_file)
        _evaluate_file(bopts, oopts, session, in_file, time_state)
    end
    return X
end

function _evaluate_sequential(bopts, oopts, session, files, time_state)
    X = map(files) do in_file
        _time_init!(time_state, in_file)
        _evaluate_file(bopts, oopts, session, in_file, time_state)
    end
    return X
end

"""
    build_notebooks(
        bopts::BuildOptions,
        [files,]
        oopts::OutputOptions=OutputOptions();
        session=ServerSession()
    )

Build Pluto notebook `files` in `dir`.
Here, `files` is optional.
When not passing `files`, then all Pluto notebooks in `dir` will be built.

# Example
```
julia> dir = joinpath(homedir(), "my_project", "notebooks");

julia> bopts = BuildOptions(dir);

julia> oopts = OutputOptions(; append_build_context=true);

julia> files = ["pi.jl", "math.jl"];

julia> build_notebooks(bopts, files, oopts);
```
"""
function build_notebooks(
        bopts::BuildOptions,
        files,
        oopts::OutputOptions=OutputOptions();
        session=ServerSession()
    )::Dict{String,Vector{String}}

    time_state = TimeState()
    func = bopts.use_distributed ? _evaluate_parallel : _evaluate_sequential
    # Vector containing Notebooks and or Previous.
    X = func(bopts, oopts, session, files, time_state)::Vector

    # One `String` for every build_output.
    outputs = Dict{String,Vector{String}}()
    for (in_file, x::Union{Vector{Previous},Notebook}) in zip(files, X)
        in_path = joinpath(bopts.dir, in_file)
        text = _outcome2text(session, x, in_path, bopts, oopts)
        outputs[in_file] = text
    end

    return outputs
end

function _is_pluto_file(path::AbstractString)::Bool
    first(eachline(string(path))) == "### A Pluto.jl notebook ###"
end

function build_notebooks(
        bopts::BuildOptions,
        oopts::OutputOptions=OutputOptions()
    )::Dict{String,Vector{String}}
    dir = bopts.dir
    files = filter(readdir(dir)) do file
        path = joinpath(dir, file)
        endswith(file, ".jl") && _is_pluto_file(path) && !startswith(file, TMP_COPY_PREFIX)
    end
    return build_notebooks(bopts, files, oopts)
end
