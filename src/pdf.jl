function run_tectonic(args::Vector)
    return read(`$(tectonic()) $args`, String)
end

tectonic_version() = strip(run_tectonic(["--version"]))

function _code2tex(code::String, oopts::OutputOptions)
    if oopts.hide_code
        return ""
    end
    if oopts.hide_md_code && startswith(code, "md\"")
        return ""
    end
    return """
        \\begin{lstlisting}[language=Julia]
        $code
        \\end{lstlisting}
        """
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
    body = string(cell.output.body)::String
    # `+++` means that it is a cell with Franklin definitions.
    if oopts.hide_md_def_code && startswith(body, "+++")
        return ""
    end
    return tex_output_block(body)
end

function _output2tex(cell::Cell, ::MIME"text/html", oopts::OutputOptions)
    body = cell.output.body
    return _html2tex(body)
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

"Return the directory of JuliaMono with a trailing slash to please fontspec."
function _juliamono_dir()
    artifact = LazyArtifacts.artifact"JuliaMono"
    dir = joinpath(artifact, string("juliamono-", JULIAMONO_VERSION))
    return string(dir, '/')
end

function _tex_header()
    juliamono_dir = _juliamono_dir()
    listings = joinpath(PKGDIR, "src", "listings", "julia_listings.tex")
    unicode = joinpath(PKGDIR, "src", "listings", "julia_listings_unicode.tex")
    return """
        \\documentclass{article}
        \\usepackage[left=3cm,top=1.5cm,right=3cm,bottom=2cm]{geometry}

        \\usepackage{fontspec}
        \\setmonofont{JuliaMono-Regular.ttf}[
            Path = $(juliamono_dir)/,
            Contextuals = Alternate,
            Ligatures = NoCommon
        ]

        \\newfontfamily{\\juliabold}{JuliaMono-Bold.ttf}[
            Path = $(juliamono_dir)/,
            Contextuals = Alternate,
            Ligatures = NoCommon
        ]

        \\input{$listings}
        \\input{$unicode}

        \\usepackage{lastpage}
        \\usepackage{fancyhdr}
        \\pagestyle{fancy}
        \\cfoot{Page \\thepage\\ of \\pageref{LastPage}}

        \\begin{document}
        """
end

function notebook2tex(nb::Notebook, in_path::String, oopts::OutputOptions)
    @assert isready(nb)
    order = nb.cell_order
    outputs = map(order) do cell_uuid
        cell = nb.cells_dict[cell_uuid]
        _cell2tex(cell, oopts)
    end
    header = _tex_header()
    body = join(outputs, '\n')
    tex = """
        $header
        $body
        \\end{document}
        """
    return tex
end

function _tectonic(args::Vector{String})
    tectonic() do bin
        run(`$bin $args`)
    end
end

function _tex2pdf(tex_path::String)
    dir = dirname(tex_path)
    args = [
        tex_path,
        "--outdir=$dir",
        "--print"
    ]
    _tectonic(args)
    return nothing
end

function notebook2pdf(nb::Notebook, in_path::String, oopts::OutputOptions)
    tex = notebook2tex(nb, in_path, oopts)
    dir = dirname(in_path)
    filename, _ = splitext(basename(in_path))
    tex_path = joinpath(dir, string(filename, ".tex"))
    @debug "Writing tex file for debugging purposes to $tex_path"
    write(tex_path, tex)

    pdf_path = joinpath(dir, string(filename, ".pdf"))
    @debug "Writing pdf file to $pdf_path"
    _tex2pdf(tex_path)
    return pdf_path
end

