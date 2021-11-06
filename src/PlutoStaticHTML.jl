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

include("html.jl")

export evaluate_notebook!, notebook2html

end # module
