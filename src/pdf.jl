function run_tectonic(args::Vector)
    return read(`$(tectonic()) $args`, String)
end

tectonic_version() = strip(run_tectonic(["--version"]))

function _code2tex(code::String, oopts::OutputOptions)
    return code
end

function _verbatim(text::String, language::String)
    return """
        \\begin{lstlisting}[language=$language]
        $text
        \\end{lstlisting}
        """
end

function tex_code_block(code)
    if code == ""
        return ""
    end
    return _verbatim(code, "Julia")
end

function tex_output_block(text::String)
    text == "" && return ""
    return _verbatim(text, "Output")
end

function _output2tex(cell::Cell, ::MIME"text/plain", oopts::OutputOptions)
    body = cell.output.body
    # `+++` means that it is a cell with Franklin definitions.
    if oopts.hide_md_def_code && startswith(body, "+++")
        return ""
    end
    return tex_output_block(body)
end

function _output2tex(cell::Cell, T, oopts::OutputOptions)
    return "<output>"
end

function _cell2tex(cell::Cell, oopts::OutputOptions)
    code = _code2tex(cell.code, oopts)
    output = _output2tex(cell, cell.output.mime, oopts)
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

function notebook2tex(nb::Notebook, in_path::String, oopts::OutputOptions)
    @assert isready(nb)
    order = nb.cell_order
    outputs = map(order) do cell_uuid
        cell = nb.cells_dict[cell_uuid]
        _cell2tex(cell, oopts)
    end
    body = join(outputs, '\n')
    tex = """
        <header>
        $body
        <footer>
        """
    return tex
end
