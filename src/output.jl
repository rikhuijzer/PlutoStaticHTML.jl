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

const CODE_CLASS_DEFAULT = "language-julia"
const OUTPUT_PRE_CLASS_DEFAULT = "code-output documenter-example-output"
const HIDE_CODE_DEFAULT = false
const HIDE_MD_CODE_DEFAULT = true
const HIDE_MD_DEF_CODE_DEFAULT = true
const ADD_STATE_DEFAULT = true
const APPEND_BUILD_CONTEXT_DEFAULT = false
const COMPILER_OPTIONS_DEFAULT = nothing
const SHOW_OUTPUT_ABOVE_CODE_DEFAULT = false
const REPLACE_CODE_TABS_DEFAULT = true
const CONVERT_ADMONITIONS_DEFAULT = true

"""
    OutputOptions(;
        code_class::AbstractString="$CODE_CLASS_DEFAULT",
        output_pre_class::AbstractString="$OUTPUT_PRE_CLASS_DEFAULT",
        hide_code::Bool=$HIDE_CODE_DEFAULT,
        hide_md_code::Bool=$HIDE_MD_CODE_DEFAULT,
        hide_md_def_code::Bool=$HIDE_MD_DEF_CODE_DEFAULT,
        add_state::Bool=$ADD_STATE_DEFAULT,
        append_build_context::Bool=$APPEND_BUILD_CONTEXT_DEFAULT,
        show_output_above_code::Bool=$SHOW_OUTPUT_ABOVE_CODE_DEFAULT,
        replace_code_tabs::Bool=$REPLACE_CODE_TABS_DEFAULT,
        convert_admonitions::Bool=$CONVERT_ADMONITIONS_DEFAULT
    )

Arguments:

- `code_class`:
    HTML class for code.
    This is used by CSS and/or the syntax highlighter.
- `output_pre_class`:
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
- `show_output_above_code`:
    Whether to show the output from the code above the code.
    Pluto.jl shows the output above the code by default; this package shows the output below the code by default.
    To show the output above the code, set `show_output_above_code=true`.
- `replace_code_tabs`:
    Replace tabs at the start of lines inside code blocks with spaces.
    This avoids inconsistent appearance of code blocks on web pages.
- `convert_admonitions`:
    Convert admonitions such as
    ```
    !!! note
        This is a note.
    ```
    from Pluto's HTML to Documenter's HTML.
    When this is enabled, the `documenter_output` has proper styling by default.
"""
struct OutputOptions
    code_class::String
    output_pre_class::String
    hide_code::Bool
    hide_md_code::Bool
    hide_md_def_code::Bool
    add_state::Bool
    append_build_context::Bool
    show_output_above_code::Bool
    replace_code_tabs::Bool
    convert_admonitions::Bool

    function OutputOptions(;
            code_class::AbstractString=CODE_CLASS_DEFAULT,
            output_pre_class::AbstractString=OUTPUT_PRE_CLASS_DEFAULT,
            hide_code::Bool=HIDE_CODE_DEFAULT,
            hide_md_code::Bool=HIDE_MD_CODE_DEFAULT,
            hide_md_def_code::Bool=HIDE_MD_DEF_CODE_DEFAULT,
            add_state::Bool=ADD_STATE_DEFAULT,
            append_build_context::Bool=APPEND_BUILD_CONTEXT_DEFAULT,
            show_output_above_code::Bool=SHOW_OUTPUT_ABOVE_CODE_DEFAULT,
            replace_code_tabs::Bool=REPLACE_CODE_TABS_DEFAULT,
            convert_admonitions::Bool=CONVERT_ADMONITIONS_DEFAULT
        )
        return new(
            string(code_class)::String,
            string(output_pre_class)::String,
            hide_code,
            hide_md_code,
            hide_md_def_code,
            add_state,
            append_build_context,
            show_output_above_code,
            replace_code_tabs,
            convert_admonitions
        )
    end
end

"Replace tabs by spaces in code blocks."
function _replace_code_tabs(code)
    # Match all tabs at start of line or start of newline.
    rx = r"(^|\r|\n)([\t]*)"
    replacer(x::SubString{String}) = replace(x, '\t' => "    ")
    replace(code, rx => replacer)
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

const BEGIN_IDENTIFIER = "<!-- PlutoStaticHTML.Begin -->"
const END_IDENTIFIER = "<!-- PlutoStaticHTML.End -->"

isready(nb::Notebook) = nb.process_status == "ready"

const TMP_COPY_PREFIX = "_tmp_"

function _retry_run(session, nb, cell::Cell)
    Pluto.update_save_run!(session, nb, [cell])
end

"Indent each line by two spaces."
function _indent(s::AbstractString)::String
    return replace(s, '\n' => "\n  ")::String
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
            error_text = _indent(String(take!(io)))
            code = _indent(cell.code)
            filename = _indent(nb.path)
            msg = """
                Execution of notebook failed.
                Does the notebook show any errors when opening it in Pluto?

                Notebook:
                  $filename

                Code:
                  $code

                Error:
                  $error_text
                """
            error(msg)
        end
    end
    return nothing
end
