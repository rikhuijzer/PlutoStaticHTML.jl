# PlutoStaticHTML.jl

Convert Pluto notebooks to pure HTML (without Javascript).
Small discussion with Fons van der Plas at <https://github.com/fonsp/Pluto.jl/discussions/1607>.

I'm using this package for my own blog, for example: <https://huijzer.xyz/posts/frequentist-bayesian-coin-flipping/>
A link to the notebook is at the bottom of the page.

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

