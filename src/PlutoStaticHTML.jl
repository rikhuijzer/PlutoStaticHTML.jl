module PlutoStaticHTML

import Base:
    show,
    string

using Base64: base64encode
using Pkg:
    Types.Context,
    Types.UUID,
    Operations
using Pluto:
    BondValue,
    Cell,
    CellOutput,
    Configuration.CompilerOptions,
    Notebook,
    PkgCompat.dependencies,
    Pluto,
    PlutoRunner,
    ServerSession,
    SessionActions,
    WorkspaceManager,
    generate_html,
    load_notebook_nobackup,
    update_dependency_cache!,
    update_run!,
    update_save_run!
using SHA: sha256
using TOML: parse as parsetoml

include("module_doc.jl")
include("context.jl")
include("cache.jl")
include("html.jl")
include("build.jl")
include("possibilities.jl")
include("dynamic.jl")
include("storebinds.jl")

export HTMLOptions, notebook2html, run_notebook!
export BuildOptions, parallel_build
export cell2uuid

# tmp
export __build
export _cell
export __notebook

end # module
