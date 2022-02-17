"""
    _direct_dependencies(notebook::Notebook) -> String

Return the direct dependencies for a `notebook`.
"""
function _direct_dependencies(notebook::Notebook)::String
    ctx = notebook.nbpkg_ctx
    if isnothing(ctx)
        error("""
            Failed to determine the notebook dependencies from the state of Pluto's built-in package manager
            This can be fixed by setting `append_build_context=false`.
            See https://github.com/rikhuijzer/PlutoStaticHTML.jl/issues/74 for more information and open an issue if the problem persists.
            """)
    end
    deps = [last(pair) for pair in dependencies(ctx)]
    filter!(p -> p.is_direct_dep, deps)
    # Ignore stdlib modules.
    filter!(p -> !isnothing(p.version), deps)
    list = ["$(p.name) $(p.version)" for p in deps]
    sort!(list)
    return join(list, "<br>\n")::String
end

"""
    _context(notebook::Notebook) -> String

Return build context, such as the Julia version and package versions, for `notebook`.
"""
function _context(notebook::Notebook)::String
    deps = _direct_dependencies(notebook)
    return """
        <div class='manifest-versions'>
        <p>Built with Julia $VERSION and</p>
        $deps
        </div>
        """
end
