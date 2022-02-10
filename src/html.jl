"""
    IMAGEMIME

Union of MIME image types.
Based on Pluto.PlutoRunner.imagemimes.
"""
const IMAGEMIME = Union{
    MIME"image/svg+xml",
    MIME"image/png",
    MIME"image/jpg",
    MIME"image/jpeg",
    MIME"image/bmp",
    MIME"image/gif"
}

"""
    HTMLOptions(;
        code_class::AbstractString="language-julia",
        output_class::AbstractString="code-output",
        output_pre_class::AbstractString="documenter-example-output",
        hide_code::Bool=false,
        hide_md_code::Bool=true,
        hide_md_def_code::Bool=true,
        add_state::Bool=true,
        append_build_context::Bool=false,
        compiler_options::Union{Nothing,CompilerOptions}=nothing
    )

Options for `notebook2html`:

- `code_class`:
    HTML class for code.
    This is used by CSS and/or the syntax highlighter.
` `output_pre_class`:
    HTML class for `<pre>`.
- `output_class`:
    HTML class for output.
    This is used by CSS and/or the syntax highlighter.
- `hide_code`:
    Whether to omit all code blocks.
    Can be useful when readers are not interested in code at all.
- `hide_md_code`:
    Whether to omit all Markdown code blocks.
- `hide_md_def_code`:
    Whether to omit Franklin Markdown definition code blocks (blocks surrounded by +++).
- `add_state`:
    Whether to add a comment in HTML with the state of the input notebook.
    This state can be used for caching.
    Specifically, this state stores a checksum of the input notebook and the Julia version.
- `append_build_context`:
    Whether to append build context.
    When set to `true`, this adds information about the dependencies and Julia version.
    This is not executed via Pluto.jl's evaluation to avoid having to add extra dependencies to existing notebooks.
    Instead, this reads the manifest from the notebook file.
- `compiler_options`:
    `Pluto.Configuration.CompilerOptions` to be passed to Pluto.
    This can, for example, be useful to pass custom system images from `PackageCompiler.jl`.
"""
struct HTMLOptions
    code_class::String
    output_pre_class::String
    output_class::String
    hide_code::Bool
    hide_md_code::Bool
    hide_md_def_code::Bool
    add_state::Bool
    append_build_context::Bool
    compiler_options::Union{Nothing,CompilerOptions}

    function HTMLOptions(;
        code_class::AbstractString="language-julia",
        output_pre_class::AbstractString="documenter-example-output",
        output_class::AbstractString="code-output",
        hide_code::Bool=false,
        hide_md_code::Bool=true,
        hide_md_def_code::Bool=true,
        add_state::Bool=true,
        append_build_context::Bool=false,
        compiler_options::Union{Nothing,CompilerOptions}=nothing
    )
        return new(
            string(code_class)::String,
            string(output_pre_class)::String,
            string(output_class)::String,
            hide_code,
            hide_md_code,
            hide_md_def_code,
            add_state,
            append_build_context,
            compiler_options
        )
    end
end

"""
    _escape_html(s::AbstractString)

Escape HTML.
Useful for showing HTML inside code blocks, see
https://github.com/rikhuijzer/PlutoStaticHTML.jl/issues/9.
"""
function _escape_html(s::AbstractString)
    s = replace(s, '<' => "&lt;")
    s = replace(s, '>' => "&gt;")
    return s
end

function code_block(code; pre_class="language-julia", code_class="")
    if code == ""
        return ""
    end
    code = _escape_html(code)
    return "<pre class='$pre_class'><code class='$code_class'>$code</code></pre>"
end

function output_block(s; class="code-output", pre_class="pre-class", var="")
    if s == ""
        return ""
    end
    id = var == "" ? "" : "id='var-$var'"
    return "<pre $id class='$pre_class'><code class='$class'>$s</code></pre>"
end

function _code2html(code::AbstractString, hopts::HTMLOptions)
    if hopts.hide_code
        return ""
    end
    if hopts.hide_md_code && startswith(code, "md\"")
        return ""
    end
    if hopts.hide_md_def_code
        lstripped = lstrip(code, ['\"', ' ', '\n', '\r'])
        if startswith(lstripped, "+++")
            return ""
        end
    end
    if contains(code, "# hideall")
        return ""
    end
    sep = '\n'
    lines = split(code, sep)
    filter!(!endswith("# hide"), lines)
    code = join(lines, sep)
    return code_block(code; hopts.code_class)
end

function _output2html(cell::Cell, T::IMAGEMIME, hopts)
    encoded = base64encode(cell.output.body)
    uri = "data:$T;base64,$encoded"
    return """<img src="$uri">"""
end

function _tr_wrap(elements::Vector)
    joined = join(elements, '\n')
    return "<tr>\n$joined\n</tr>"
end
_tr_wrap(::Array{String, 0}) = "<tr>\n<td>...</td>\n</tr>"

function _output2html(cell::Cell, ::MIME"application/vnd.pluto.table+object", hopts)
    body = cell.output.body::Dict{Symbol,Any}
    rows = body[:rows]
    nms = body[:schema][:names]
    headers = _tr_wrap(["<th>$colname</th>" for colname in nms])
    contents = map(rows) do row
        # Drop index.
        row = row[2:end]
        # Unpack the type and throw away mime info.
        elements = try
            first.(only(row))
        catch
            first.(first.(row))
        end
        elements = ["<td>$e</td>" for e in elements]
        return _tr_wrap(elements)
    end
    content = join(contents, '\n')
    return """
        <table>
        $headers
        $content
        </table>
        """
end

abstract type Struct end

function symbol2type(s::Symbol)
    if s == :Tuple
        return Tuple
    elseif s == :Array
        return Array
    elseif s == :struct
        return Struct
    else
        @warn "Missing type: $s"
        return Missing
    end
end

"""
    _var(cell::Cell)::Symbol

Return the variable which is set by `cell`.
This method requires that the notebook to be executed be able to give the right results.
"""
function _var(cell::Cell)::Symbol
    ra = cell.output.rootassignee
    if isnothing(ra)
        mapping = cell.cell_dependencies.downstream_cells_map
        K = keys(mapping)
        if isempty(K)
            h = hash(cell.code)
            # This is used when storing binds to give it reproducible name.
            return Symbol(first(string("hash", h), 10))
        end
        # `only` cannot be used because loading packages can give multiple keys.
        return first(K)
    else
        return ra
    end
end

function _output2html(cell::Cell, ::MIME"text/plain", hopts)
    var = _var(cell)
    body = cell.output.body
    # `+++` means that it is a cell with Franklin definitions.
    if hopts.hide_md_def_code && startswith(body, "+++")
        # Go back into Markdown mode instead of HTML
        return string("~~~\n", body, "\n~~~")
    end
    output_block(body; var)
end

function _output2html(cell::Cell, ::MIME"text/html", hopts)
    body = cell.output.body
    # The docstring is already visible in Markdown and shouldn't be shown below the code.
    if startswith(body, """<div class="pluto-docs-binding">""")
        return ""
    else
        return body
    end
end

function _output2html(cell::Cell, ::MIME"application/vnd.pluto.stacktrace+object", hopts)
    return error(string(cell.output.body)::String)
end

_output2html(cell::Cell, T::MIME, hopts) = error("Unknown type: $T")

function _cell2html(cell::Cell, hopts::HTMLOptions)
    code = _code2html(cell.code, hopts)
    output = _output2html(cell, cell.output.mime, hopts)
    return """
        $code
        $output
        """
end

"""
    _append_cell!(notebook::Notebook, cell::Cell)

Add one `cell` to the end of the `notebook`.
This is based on `add_remote_cell` in Pluto's `Editor.js`.
"""
function _append_cell!(notebook::Notebook, cell::Cell)
    push!(notebook.cell_order, cell.cell_id)
    notebook.cells_dict[cell.cell_id] = cell
    return notebook
end

function _append_cell!(notebook::Notebook, cells::AbstractVector{Cell})
    foreach(c -> _append_cell!(notebook, c), cells)
    return notebook
end

const BEGIN_IDENTIFIER = "<!-- PlutoStaticHTML.Begin -->"
const END_IDENTIFIER = "<!-- PlutoStaticHTML.End -->"

isready(nb::Notebook) = nb.process_status == "ready"

"""
    notebook2html(nb::Notebook, path, opts::HTMLOptions=HTMLOptions()) -> String

Return the code and output as HTML for `nb`.
Assumes that the notebook has already been executed.
"""
function notebook2html(nb::Notebook, path, hopts::HTMLOptions=HTMLOptions())::String
    @assert isready(nb)
    order = nb.cell_order
    outputs = map(order) do cell_uuid
        cell = nb.cells_dict[cell_uuid]
        _cell2html(cell, hopts)
    end
    html = join(outputs, '\n')
    if hopts.add_state && !isnothing(path)
        html = string(path2state(path)) * html
    end
    if hopts.append_build_context
        html = html * _context(nb)
    end
    html = string(BEGIN_IDENTIFIER, '\n', html, '\n', END_IDENTIFIER)::String
    return html
end

const TMP_COPY_PREFIX = "_tmp_"

function _retry_run(session, nb, cell::Cell)
    Pluto.update_save_run!(session, nb, [cell])
end

function _throw_if_error(session::ServerSession, nb::Notebook)
    cells = [nb.cells_dict[cell_uuid] for cell_uuid in nb.cell_order]
    for cell in cells
        if cell.errored
            # Re-try running macro cells.
            # Hack for Pluto.jl/issues/1664.
            if startswith(cell.code, '@')
                _retry_run(session, nb, cell)
                if !cell.errored
                    continue
                end
            end
            body = cell.output.body::Dict{Symbol,Any}
            msg = body[:msg]::String
            val = body[:stacktrace]::CapturedException
            io = IOBuffer()
            ioc = IOContext(io, :color => Base.get_have_color())
            showerror(ioc, val)
            error_text = String(take!(io))
            msg = """
                Execution of the notebook failed.
                Does the notebook show any errors when opening it in Pluto?

                Details:
                $error_text
                """
            error(msg)
        end
    end
    return nothing
end

function run_notebook!(
        path::AbstractString,
        session;
        hopts::HTMLOptions=HTMLOptions(),
        run_async=false
    )
    session.options.server.disable_writing_notebook_files = true
    compiler_options = hopts.compiler_options
    nb = SessionActions.open(session, path; compiler_options, run_async)
    if !run_async
        _throw_if_error(session, nb)
    end
    return nb
end

"""
    notebook2html(
        path::AbstractString,
        opts::HTMLOptions=HTMLOptions();
        session=ServerSession(),
        append_cells=Cell[],
    ) -> String

Run the Pluto notebook at `path` and return the code and output as HTML.
This makes a copy of the notebook at `path` and runs it.

Keyword arguments:

- `append_cells`: Specify one or more `Pluto.Cell`s to be appended at the end of the notebook.
"""
function notebook2html(
        path::AbstractString,
        hopts::HTMLOptions=HTMLOptions();
        session=ServerSession(),
        append_cells=Cell[],
    )::String
    nb = run_notebook!(path, session; run_async=false, hopts)
    html = notebook2html(nb, path, hopts)
    return html
end
