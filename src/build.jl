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
end

"""
    BuildOptions(
        dir::AbstractString;
        write_files::Bool=true,
        previous_dir::Union{Nothing,AbstractString}=nothing,
        output_format::OutputFormat=html_output,
        add_documenter_css::Bool=true,
        use_distributed::Bool=true
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
    To generate Franklin or Documenter files, use respectively `franklin_output` or `documenter_output`.
    When `BuildOptions.write_files == true` and `output_format != html_output`, the output file has a ".md" extension instead of ".html".
- `add_documenter_css` whether to add a CSS style to the HTML when `documenter_output=true`.
- `use_distributed`:
    Whether to build the notebooks in different processes.
    By default, this is enabled just like in Pluto and the notebooks are build in parallel.
    The benefit of different processes is that things are more independent of each other.
    Unfortunately, the drawback is that compilation has to happen for each process.
    By setting this option to `false`, all notebooks are built sequentially in the same process which avoids recompilation.
    This is likely quicker in situations where there are few threads available such as GitHub Runners depending on the notebook contents.
    Beware that `use_distributed=false` will not work with Pluto's built-in package manager.
"""
struct BuildOptions
    dir::String
    write_files::Bool
    previous_dir::Union{Nothing,String}
    output_format::OutputFormat
    add_documenter_css::Bool
    use_distributed::Bool

    function BuildOptions(
        dir::AbstractString;
        write_files::Bool=true,
        previous_dir::Union{Nothing,AbstractString}=nothing,
        output_format::OutputFormat=html_output,
        add_documenter_css::Bool=true,
        use_distributed::Bool=true
    )
        return new(
            string(dir)::String,
            write_files,
            nothingstring(previous_dir),
            output_format,
            add_documenter_css,
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

function Previous(bopts::BuildOptions, in_file)
    prev_dir = bopts.previous_dir
    if isnothing(prev_dir)
        return Previous(nothing, "")
    end
    name, _ = splitext(in_file)
    ext = bopts.output_format == html_output ? ".html" : ".md"
    prev_path = joinpath(prev_dir, "$name$ext")
    if !isfile(prev_path)
        return Previous(nothing, "")
    end
    text = read(prev_path, String)
    return Previous(text)
end

function reuse_previous(previous::Previous, dir, in_file)::Bool
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
Write to a ".html" or ".md" file depending on `HTMLOptions.output_format`.
The output file is always a sibling to the file at `in_path`.
"""
function _write_main_output(in_path, text, bopts::BuildOptions, hopts::HTMLOptions)
    ext = bopts.output_format == html_output ? ".html" : ".md"
    if bopts.write_files
        dir = dirname(in_path)
        in_file = basename(in_path)
        without_extension, _ = splitext(in_file)
        out_file = "$(without_extension)$(ext)"
        out_path = joinpath(dir, out_file)
        write(out_path, text)
    end
    return nothing
end

"Used when creating the page for the first time and to restore the cache."
function _wrap_franklin_output(html)
    return "~~~\n$(html)\n~~~"
end

"Add some style overrides to make things a bit prettier and more consistent with Pluto."
function _add_documenter_css(html)
    style = """
        <style>
            table {
                display: table !important;
                margin: 2rem auto !important;
                border-top: 2pt solid rgba(0,0,0,0.2);
                border-bottom: 2pt solid rgba(0,0,0,0.2);
            }

            pre, div {
                margin-top: 1.4rem !important;
                margin-bottom: 1.4rem !important;
            }
        </style>
        """
    return string(style, '\n', html)
end

"Used when creating the page for the first time and to restore the cache."
function _wrap_documenter_output(html, add_documenter_css::Bool)
    if add_documenter_css
        html = _add_documenter_css(html)
    end
    return "```@raw html\n$(html)\n```"
end

function _outcome2text(session, prev::Previous, in_path::String, bopts, hopts)::String
    text = prev.text
    if bopts.output_format == franklin_output
        text = _wrap_franklin_output(text)
    end
    if bopts.output_format == documenter_output
        text = _wrap_documenter_output(text, bopts.add_documenter_css)
    end
    _write_main_output(in_path, text, bopts, hopts)
    return text
end

function _inject_script(html, script)
    l = length(END_IDENTIFIER)
    without_end = html[1:end-l]
    return string(without_end, '\n', script, '\n', END_IDENTIFIER)
end

function _outcome2text(session, nb::Notebook, in_path::String, bopts, hopts)::String
    while !_notebook_done(nb)
        sleep(0.1)
    end

    _throw_if_error(session, nb)

    # Grab output before changing binds via `_run_dynamic!`.
    # Otherwise, the outputs look wrong when opening a page for the first time.
    html = notebook2html(nb, in_path, hopts)

    if bopts.output_format == franklin_output
        html = _wrap_franklin_output(html)
    end
    if bopts.output_format == documenter_output
        html = _wrap_documenter_output(html, bopts.add_documenter_css)
    end

    _write_main_output(in_path, html, bopts, hopts)

    # The sleep avoids `AssertionError: will_run_code(notebook)`
    @async begin
        sleep(5)
        SessionActions.shutdown(session, nb; verbose=false)
    end

    return string(html)::String
end

"""
    build_notebooks(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession()
    ) -> Vector{String}

Build all `files` in `dir` in parallel.
"""
function build_notebooks(
        bopts::BuildOptions,
        files,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession()
    )::Vector{String}

    dir = bopts.dir

    # Start all the notebooks in parallel with async enabled if `use_distributed`.
    X = map(files) do in_file
        in_path = joinpath(dir, in_file)::String
        @assert isfile(in_path) "Expected .jl file at $in_path"

        previous = Previous(bopts, in_file)
        if reuse_previous(previous, dir, in_file)
            @info "Using cache for Pluto notebook at $in_file"
            return previous
        else
            @info "Starting evaluation of Pluto notebook $in_file"
            if bopts.use_distributed
                run_async = true
            else
                run_async = false
                # `use_distributed` means mostly "whether to run in a new process".
                session.options.evaluation.workspace_use_distributed = false
            end
            nb = run_notebook!(in_path, session; hopts, run_async)
            return nb
        end
    end

    H = map(zip(files, X)) do (in_file, x)
        in_path = joinpath(dir, in_file)
        html = _outcome2text(session, x, in_path, bopts, hopts)
        return html
    end

    return H
end
precompile(build_notebooks, (BuildOptions, Vector{Any}, HTMLOptions))

function _is_pluto_file(path::AbstractString)::Bool
    first(eachline(string(path))) == "### A Pluto.jl notebook ###"
end

"""
    build_notebooks(
        bopts::BuildOptions,
        hopts::HTMLOptions=HTMLOptions()
    ) -> Vector{String}

Build all ".jl" files in `dir` in parallel.
"""
function build_notebooks(
        bopts::BuildOptions,
        hopts::HTMLOptions=HTMLOptions()
    )::Vector{String}
    dir = bopts.dir
    files = filter(readdir(dir)) do file
        path = joinpath(dir, file)
        endswith(file, ".jl") && _is_pluto_file(path) && !startswith(file, TMP_COPY_PREFIX)
    end
    return build_notebooks(bopts, files, hopts)
end
precompile(build_notebooks, (BuildOptions, HTMLOptions))

