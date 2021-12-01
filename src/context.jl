"""
    _dependencies(ctx::Context)

`dependencies` method for a `Context` based on the implementation in Pkg.jl at Julia 1.6.
This method has been removed in Julia 1.7.
"""
function _dependencies(ctx::Context)
    pkgs = Operations.load_all_deps(ctx)
    return Dict(pkg.uuid::UUID => Operations.package_info(ctx, pkg) for pkg in pkgs)
end

"""
    _direct_dependencies(notebook::Notebook) -> String

Return the direct dependencies for a `notebook`.
"""
function _direct_dependencies(notebook::Notebook)::String
    deps = [last(pair) for pair in _dependencies(notebook.nbpkg_ctx)]
    filter!(p -> p.is_direct_dep, deps)
    # Ignore stdlib modules.
    filter!(p -> !isnothing(p.version), deps)
    list = ["$(p.name) $(p.version)" for p in deps]
    sort!(list)
    return join(list, '\n')
end

function _direct_dependencies(notebook::AbstractString)
    return _direct_dependencies(_load_notebook(notebook))
end

"""
    _context(notebook::Notebook) -> String

Return build context, such as the Julia version and package versions, for `notebook`.
"""
function _context(notebook::Notebook)::String
    deps = _direct_dependencies(notebook)
    return """
        <h2>Version</h2>

        Built with Julia $VERSION and<br>
        <br>
        <pre>
        $deps
        </pre>
        """
end
