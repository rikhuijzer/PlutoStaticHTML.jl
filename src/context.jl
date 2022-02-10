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
