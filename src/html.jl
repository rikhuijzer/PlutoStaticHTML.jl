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

function output_block(s; output_pre_class="pre-class", var="")
    if s == ""
        return ""
    end
    id = var == "" ? "" : "id='var-$var'"
    return "<pre $id class='$output_pre_class'>$s</pre>"
end

function _code2html(cell::Cell, oopts::OutputOptions)
    if oopts.hide_code || cell.code_folded
        return ""
    end
    code = cell.code
    if oopts.hide_md_code && startswith(code, "md\"")
        return ""
    end
    if oopts.hide_md_def_code
        lstripped = lstrip(code, ['\"', ' ', '\n', '\r'])
        if startswith(lstripped, "+++")
            return ""
        end
    end
    if oopts.replace_code_tabs
        code = _replace_code_tabs(code)
    end
    if contains(code, "# hideall")
        return ""
    end
    sep = '\n'
    lines = split(code, sep)
    filter!(!endswith("# hide"), lines)
    code = join(lines, sep)
    return code_block(code; oopts.code_class)
end

function _output2html(cell::Cell, T::IMAGEMIME, oopts)
    encoded = base64encode(cell.output.body)
    uri = "data:$T;base64,$encoded"
    return """<img src="$uri">"""
end

function _tr_wrap(elements::Vector)
    joined = join(elements, '\n')
    return "<tr>\n$joined\n</tr>"
end
_tr_wrap(::Array{String, 0}) = "<tr>\n<td>...</td>\n</tr>"

function _output2html(cell::Cell, ::MIME"application/vnd.pluto.table+object", oopts)
    body = cell.output.body::Dict{Symbol,Any}
    rows = body[:rows]
    nms = body[:schema][:names]
    wide_truncated = false
    if rows[1][end][end] == "more"
        # Replace "more" by "..." in the last column of wide tables.
        nms[end] = "..."
        wide_truncated = true
    end
    headers = _tr_wrap(["<th>$colname</th>" for colname in [""; nms]])
    contents = map(rows) do row
        index = row[1]
        row = row[2:end]
        # Unpack the type and throw away mime info.
        elements = try
            first.(only(row))
        catch
            first.(first.(row))
        end
        if eltype(elements) != Char && wide_truncated
            elements[end] = ""
        end
        eltype(index) != Char ? pushfirst!(elements, string(index)::String) : ""
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

function _output2html(cell::Cell, ::MIME"text/plain", oopts)
    var = _var(cell)
    body = string(cell.output.body)::String
    # `+++` means that it is a cell with Franklin definitions.
    if oopts.hide_md_def_code && startswith(body, "+++")
        # Go back into Markdown mode instead of HTML
        return string("~~~\n", body, "\n~~~")
    end
    output_block(body; oopts.output_pre_class, var)
end

function _patch_dollar_symbols(body::String)::String
    lines = split(body, '\n')
    # Pluto wraps inline HTML in a tex class, so if we see a dollar symbol in a plain text output,
    # we should escape it since it is not a LaTeX expression.
    for i in 1:length(lines)
        line = lines[i]
        if !(contains(line, "<pre>") || contains(line, "<code>"))
            lines[i] = replace(line, "&#36;" => "\\\$")
        end
    end
    return join(lines, '\n')
end

function _output2html(cell::Cell, ::MIME"text/html", oopts)
    body = string(cell.output.body)::String
    body = _patch_dollar_symbols(body)::String

    if contains(body, """<script type="text/javascript" id="plutouiterminal">""")
        return _patch_with_terminal(body)
    end

    # The docstring is already visible in Markdown and shouldn't be shown below the code.
    if startswith(body, """<div class="pluto-docs-binding">""")
        return ""
    end

    return body
end

function _output2html(cell::Cell, ::MIME"application/vnd.pluto.stacktrace+object", oopts)
    return error(string(cell.output.body)::String)
end

_output2html(cell::Cell, T::MIME, oopts) = error("Unknown type: $T")

function _cell2html(cell::Cell, oopts::OutputOptions)
    if cell.metadata["disabled"]
        return ""
    end
    code = _code2html(cell, oopts)
    output = _output2html(cell, cell.output.mime, oopts)
    if oopts.convert_admonitions
        output = _convert_admonitions(output)
    end
    if oopts.show_output_above_code
        return """
            $output
            $code
            """
    else
        return """
            $code
            $output
            """
    end
end

"""
    notebook2html(nb::Notebook, path, opts::OutputOptions=OutputOptions())::String

Return the code and output as HTML for `nb`.
Assumes that the notebook has already been executed.
"""
function notebook2html(nb::Notebook, path, oopts::OutputOptions=OutputOptions())::String
    @assert isready(nb)
    order = nb.cell_order
    outputs = map(order) do cell_uuid
        cell = nb.cells_dict[cell_uuid]
        _cell2html(cell, oopts)
    end
    html = join(outputs, '\n')
    if oopts.add_state && !isnothing(path)
        html = string(path2state(path)) * html
    end
    if oopts.append_build_context
        html = html * _context(nb)
    end
    html = string(BEGIN_IDENTIFIER, '\n', html, '\n', END_IDENTIFIER)::String
    return html
end
