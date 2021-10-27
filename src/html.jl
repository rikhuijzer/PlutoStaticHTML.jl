function code_block(code)
    if code == ""
        return ""
    end
    return """<pre><code class="language-julia">$code</code></pre>"""
end

function output_block(code)
    return """<pre><code class="code-output">$code</code></pre>"""
end


function _output2html(body, ::MIME"text/plain")
    return output_block(body)
end

function _output2html(body, ::MIME"text/html")
    return body
end

function data_uri(imtype::AbstractString, body)
    encoded = base64encode(body)
    return "data:$imtype;base64,$encoded"
end

# Fallback.
function _output2html(body, T::MIME)
    T_str = string(T)::String
    if contains(T_str, "image/")
        uri = data_uri(T_str, body)
        return """<img src="$uri">"""
    else
        error("Unknown type: $T")
    end
end

function _code2html(code::AbstractString)
    if contains(code, "# hideall")
        return ""
    end
    return code_block(code)
end

function _cell2html(cell::Cell)
    code = _code2html(cell.code)
    output = _output2html(cell.output.body, cell.output.mime)
    return """
        $code
        $output
        """
end

function notebook2html(
        notebook::Notebook;
        session=ServerSession()
    )
    cells = [last(e) for e in notebook.cells_dict]
    update_run!(session, notebook, cells)
    order = notebook.cell_order
    outputs = [_cell2html(notebook.cells_dict[cell_uuid]) for cell_uuid in order]
    return join(outputs, '\n')
end

function notebook2html(path::AbstractString)
    notebook_file = "/home/rik/Downloads/tmp.jl"
    notebook = load_notebook_nobackup(notebook_file)
    return notebook2html(notebook)
end
