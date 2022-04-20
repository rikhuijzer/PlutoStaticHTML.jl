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

            .code-output {
                padding: 0.7rem 0.5rem !important;
            }

            .admonition-body {
                padding: 0em 1.25em;
            }
        </style>
        """
    return string(style, '\n', html)
end

"""
Wrap the body text in the proper styling.
Regex matching won't work here because the body can contain arbitrary HTML.

This function is applied after the other conversions, so we know that the first and last `p` tags must denote the start and end point of the body.
"""
function _wrap_admonition_body(html::AbstractString)
    start_p = first(findfirst("<p>", html)::UnitRange{Int})::Int
    end_p = last(findlast("</p>", html)::UnitRange{Int})::Int
    body_with_p = html[start_p:end_p]

    function wrap_body(body_with_p)
        return rstrip("""
              <div class="admonition-body">
                $body_with_p
              </div>
            """)
    end

    replace(html, body_with_p => wrap_body)
end

"Convert a single admonition from Pluto to Documenter."
function _convert_admonition(html::AbstractString)
    html = replace(html, """<div class="admonition """ =>
        """<div class="admonition is-""")
    html = replace(html, r"""<p class="admonition-title">([^<]*)</p>""" =>
        s"""\n  <header class="admonition-header">\n    \1\n  </header>\n""")
    html = _wrap_admonition_body(html)
    return html
end

"""
Convert Pluto's admonitions HTML to Documenter's admonitions HTML.
This ensures that admonitions are properly styled in `documenter_output`.
"""
function _convert_admonitions(html::AbstractString)
    rx = r"""<div class="admonition[^"]*">[^\n]*\n[^\n]*"""
    return replace(html, rx => _convert_admonition)
end
