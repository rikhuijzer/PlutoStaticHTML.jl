module PlutoStaticHTML

using Base64: base64encode
using Pluto:
    Cell,
    CellOutput,
    Notebook,
    ServerSession,
    generate_html,
    load_notebook_nobackup,
    update_run!,
    notebook_to_js
    SessionActions

include("html.jl")

export notebook2html, notebook2html2

end # module
