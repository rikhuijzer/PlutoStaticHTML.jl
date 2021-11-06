module PlutoStaticHTML

using Base64: base64encode
using Pluto:
    Cell,
    CellOutput,
    Notebook,
    ServerSession,
    SessionActions,
    generate_html,
    load_notebook_nobackup,
    update_run!,
    notebook_to_js

include("html.jl")

export notebook2html, run_notebook!

end # module
