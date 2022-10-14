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
                padding: 0em 1.25em !important;
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
    start = first(findfirst("</header>", html)::UnitRange{Int}) + 10
    stop = try
        first(findlast("</div>", html)::UnitRange{Int}) - 2
    catch
        length(html)
    end
    body = html[start:stop]

    function wrap_body(body)
        return rstrip("""
              <div class="admonition-body">
                $body
              </div>
            """)
    end

    return replace(html, body => wrap_body)
end

"Convert a single admonition from Pluto to Documenter."
function _convert_admonition(html::AbstractString)
    return parsed

    html = replace(html, """<div class="admonition """ =>
        """<div class="admonition is-""")
    html = replace(html, r"""<p class="admonition-title">([^<]*)</p>""" =>
        s"""\n  <header class="admonition-header">\n    \1\n  </header>\n""")
    html = _wrap_admonition_body(html)
    return html
end

function _convert_admonition_class!(el::HTMLElement{:div})
    @assert el.children[1].attributes["class"] == "admonition-title"
    attributes = el.attributes
    class = attributes["class"]
    updated_class = replace(class, "admonition " => "admonition is-")
    attributes["class"] = updated_class
    return nothing
end

function _convert_p_to_header!(el::HTMLElement{:div})
    p = el.children[1]
    new = let
        children = p.children
        parent = el
        attributes = Dict("class" => "admonition-header")
        HTMLElement{:header}(children, parent, attributes)
    end
    el.children[1] = new
    return nothing
end

function _convert_siblings_to_admonition_body!(el)
    siblings = el.children[2:end]
    new = let
        children = siblings
        parent = el
        attributes = Dict("class" => "admonition-body")
        HTMLElement{:div}(children, parent, attributes)
    end
    el.children[2] = new
    return nothing
end

function _convert_admonition!(el::HTMLElement{:div})
    _convert_admonition_class!(el)
    _convert_p_to_header!(el)
    _convert_siblings_to_admonition_body!(el)
    return nothing
end

function _convert_admonitions!(el::HTMLElement{:div})
    if haskey(el.attributes, "class")
        if startswith(el.attributes["class"], "admonition")
            first_child = el.children[1]
            if first_child isa HTMLElement{:p}
                if haskey(first_child.attributes, "class")
                    if first_child.attributes["class"] == "admonition-title"
                        _convert_admonition!(el)
                    end
                end
            end
        end
    end
    return nothing
end

# HTMLText and such.
_convert_admonitions!(el) = nothing

function _convert_admonitions!(el::HTMLElement)
    for child in el.children
        _convert_admonitions!(child)
    end
    return nothing
end

"""
Convert Pluto's admonitions HTML to Documenter's admonitions HTML.
This ensures that admonitions are properly styled in `documenter_output`.
"""
function _convert_admonitions(html::AbstractString)
    parsed = parsehtml(html)
    body = parsed.root.children[2]
    _convert_admonitions!(body)
    return string(parsed)::String
end
