"""
    _direct_dependencies(notebook::Notebook) -> String

Return the direct dependencies for a `notebook`.
"""
function _direct_dependencies(notebook::Notebook)::String
    deps = [last(pair) for pair in dependencies(notebook.nbpkg_ctx)]
    filter!(p -> p.is_direct_dep, deps)
    # Ignore stdlib modules.
    filter!(p -> !isnothing(p.version), deps)
    list = ["$(p.name) $(p.version)" for p in deps]
    sort!(list)
    return join(list, "<br>\n")
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

        <p>Built with Julia $VERSION and</p>
        <p>$deps</p>
        """
end
