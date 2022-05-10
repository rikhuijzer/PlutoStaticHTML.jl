module PlutoStaticHTML

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@max_methods"))
    @eval Base.Experimental.@max_methods 1
end

import Base:
    show,
    string
import Pluto:
    PlutoRunner,
    WorkspaceManager

using Base64: base64encode
using Dates
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
using PrecompileSignatures: @precompile_signatures
using SHA: sha256
using TOML: parse as parsetoml

include("module_doc.jl")
include("context.jl")
include("cache.jl")
include("mimeoverride.jl")
include("with_terminal.jl")
include("html.jl")
include("style.jl")
include("build.jl")
include("documenter.jl")

export HTMLOptions
export documenter_output, franklin_output, html_output
export BuildOptions, build_notebooks

@precompile_signatures(PlutoStaticHTML)

end # module
