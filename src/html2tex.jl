using AbstractTrees: AbstractTrees
using Gumbo: Gumbo, parsehtml

_strip_div(s::String) = replace(s, r"<\/?div[^>]*>" => "")

function _handle_p(s::String)
    s = replace(s, "<p>" => "\\par{")
    s = replace(s, "</p>" => "}")
    return s
end

function map!(f::Function, doc::Gumbo.HTMLDocument)
    for elem in AbstractTrees.PreOrderDFS(doc.root)
        if elem isa Gumbo.HTMLElement
            # Changing elem directly doesn't work, so we loop direct children.
            children = elem.children
            for i in 1:length(children)
                elem.children[i] = f(elem.children[i])
            end
        end
        # else (isa Gumbo.HTMLText) is handled by the fact that we loop direct children.
    end
    return doc
end

function _html2tex(s::String)
    doc = parsehtml(s)
    # map!(println, doc)
    return string(doc)::String
end
