function _extract_txt(body)
    sep = '\n'
    lines = split(body, sep)
    index = findfirst(contains("let txt = "), lines)
    txt_line = strip(lines[index])
    txt = txt_line[12:end-1]
    with_newlines = replace(txt, "\\n" => '\n')
    without_extraneous_newlines = strip(with_newlines, '\n')
    return without_extraneous_newlines
end

function _patch_with_terminal(body::String)
    txt = _extract_txt(body)
    return """
        <pre id="plutouiterminal">
        $txt
        </pre>
        """
end
precompile(_patch_with_terminal, (String,))
