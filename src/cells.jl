const PACKAGE_VERSIONS_HEADER = let
    code = "md\"## Version\n\nBuilt with Julia \$VERSION and\""
    Cell(code)
end

const PACKAGE_VERSIONS_LOAD = let
    code = """
        # hideall
        using Pkg: dependencies
        """
    Cell(code)
end

const PACKAGE_VERSIONS_TEXT = let
    code = """
        # hideall
        let
            deps = [pair.second for pair in dependencies()]
            filter!(p -> p.is_direct_dep, deps)
            filter!(p -> !isnothing(p.version), deps)
            list = ["\$(p.name) \$(p.version)" for p in deps]
            sort!(list)
            joined = join(list, '\n')
            Base.Text(joined)
        end
        """
    Cell(code)
end

const PACKAGE_VERSIONS = Cell[
        PACKAGE_VERSIONS_HEADER,
        PACKAGE_VERSIONS_LOAD,
        PACKAGE_VERSIONS_TEXT
    ]

