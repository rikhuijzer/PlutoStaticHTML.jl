module PlutoStaticHTML

using Base64: base64encode
using Pluto:
    Cell,
    CellOutput,
    Notebook,
    PlutoRunner,
    ServerSession,
    SessionActions,
    WorkspaceManager,
    generate_html,
    load_notebook_nobackup,
    update_dependency_cache!,
    update_run!,
    update_save_run!

include("html.jl")
include("build.jl")

export notebook2html, run_notebook!
export parallel_build!

end # module
