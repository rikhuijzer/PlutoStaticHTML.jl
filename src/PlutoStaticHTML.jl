module PlutoStaticHTML

import Base:
    show,
    string
import Pluto:
    PlutoRunner,
    WorkspaceManager

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
include("with_terminal.jl")
include("html.jl")
include("style.jl")
include("build.jl")

export HTMLOptions
export documenter_output, franklin_output, html_output
export BuildOptions, build_notebooks
export cell2uuid

# tmp
export __build
export _cell
export __notebook

function __init__()
    # Loading the mimeoverrides in `__init__` to avoid "incremental compilation may be
    # fatally broken for this module" errors.
    path = joinpath(pkgdir(PlutoStaticHTML), "src", "mimeoverride.jl")
    include(path)
end

end # module
