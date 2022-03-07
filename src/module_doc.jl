let
    text = raw"""
        # PlutoStaticHTML.jl

        To quickly build two notebooks (evaluate all the code and convert the output to HTML), use:

        ```
        julia> dir = joinpath("posts", "notebooks");

        julia> files = ["notebook1.jl", "notebook2.jl"];

        julia> build_notebooks(BuildOptions(dir), files)
        ```

        and to build all notebooks, use:

        ```
        julia> build_notebooks(BuildOptions(dir))
        ```

        See https://rikhuijzer.github.io/PlutoStaticHTML.jl/dev/ for the full documentation.
        """
    @doc text PlutoStaticHTML
end
