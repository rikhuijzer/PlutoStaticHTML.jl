# PlutoStaticHTML.jl

Convert Pluto notebooks to pure HTML (without Javascript).

The functionality provided by this package is quite simple.
It would probably be better to move this into Pluto.jl at some point if the maintainers agree.
For now, I'm just trying this out a bit to see how well it works.

An example output from a Pluto notebook is visible at <https://rikhuijzer.github.io/PlutoStaticHTML.jl/dev/>.

## Documenter.jl

To see how to embed output from a Pluto notebook in Documenter.jl, checkout "make.jl" in this repository.

## Franklin.jl

In `utils.jl` define:

    """
        lx_pluto(com, _)

    Embed a Pluto notebook via:
    https://github.com/rikhuijzer/PlutoStaticHTML.jl
    """
    function lx_pluto(com, _)
        file = string(Franklin.content(com.braces[1]))::String
        notebook_path = joinpath("posts", "notebooks", "$file.jl")
        log_path = joinpath("posts", "notebooks", "$file.log")

        return """
            ```julia:pluto
            # hideall

            using PlutoStaticHTML: notebook2html

            path = "$notebook_path"
            log_path = "$log_path"
            @assert isfile(path)
            @info "→ evaluating Pluto notebook at (\$path)"
            html = open(log_path, "w") do io
                redirect_stdout(io) do
                    html = notebook2html(path)
                    return html
                end
            end
            println("~~~\n\$html\n~~~\n")
            ```
            \\textoutput{pluto}
            """
    end

Next, the Pluto notebook at "/posts/notebooks/analysis.jl" can be included in a Franklin webpage.
For example:

```
+++
title = "My analysis"
showall = false
+++

\pluto{analysis}
```

> NOTE: NEW API Support with SessionActions Support

```julia
    input = "path/to/PlutoNotebook.jl"
    session = Pluto.ServerSession();
    notebook = Pluto.SessionActions.open(session, input; run_async=false)

    html_contents = notebook2html2(notebook)
    write("$(input)2.html", html_contents)
```
