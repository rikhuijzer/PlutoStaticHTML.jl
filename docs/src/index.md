# PlutoStaticHTML

Convert Pluto notebooks to pure HTML (without Javascript).
Small discussion with Fons van der Plas at <https://github.com/fonsp/Pluto.jl/discussions/1607>.

I'm using this package for my own blog, for example: <https://huijzer.xyz/posts/frequentist-bayesian-coin-flipping/>.
A link to the notebook is at the bottom of the page.

See the [Example notebook](@ref) for how the output of PlutoStaticHTML looks.

### notebook2html

The most important methods are `notebook2html` or `parallel_build!` ([Docstrings](@ref)).
In general, what works best is to

1. Determine a list of paths to your notebooks.
1. Pass the paths to `notebook2html` or `parallel_build!` and write the HTML output to files.
1. Read the output from the HTML files and show it inside a static website.

!!! warn
    It is typically not a good idea to call the conversion from inside `Documenter.jl` or `Franklin.jl`.
    For some reason, that is likely to freeze or hang; probably due to stdout being flooded with information or something.

More specific instructions for

- [Documenter.jl](@ref)
- [Franklin.jl](@ref)
- [Parallel build](@ref)
- [Docstrings](@ref)

are listed below.

## Documenter.jl

To see how to embed output from a Pluto notebook in Documenter.jl, checkout "make.jl" in this repository.

## Franklin.jl

See the next section for a parallel version.
In `utils.jl` define:

    """
        lx_readhtml(com, _)

    Embed a Pluto notebook via:
    https://github.com/rikhuijzer/PlutoStaticHTML.jl
    """
    function lx_readhtml(com, _)
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

```markdown
+++
title = "My analysis"
+++

\readhtml{analysis}
```

## Parallel build

The approach above lets Franklin.jl handle the build.
This doesn't work in parallel.
To run the notebooks in parallel and speed up the build, this package defines `parallel_build!`.
To use it, pass a `dir` to write HTML files for all notebook files (recognized by ".jl" extension):

```julia
julia> dir = joinpath("posts", "notebooks");

julia> parallel_build!(dir);

```

Or, to run only specific notebooks, use:

```julia
julia> files = ["notebook1.jl", "notebook2.jl"];

julia> parallel_build!(dir, files)
```

In CI, be sure to call this before using Franklin `serve` or `optimize`.
Next, read the HTML back into Franklin by defining in `utils.jl`:

    """
        lx_readhtml(com, _)

    Embed a Pluto notebook via:
    https://github.com/rikhuijzer/PlutoStaticHTML.jl
    """
    function lx_readhtml(com, _)
        file = string(Franklin.content(com.braces[1]))::String
        dir = joinpath("posts", "notebooks")
        filename = "$(file).jl"

        return """
            ```julia:pluto
            # hideall

            filename = "$filename"
            html = read(filename, String)
            println("~~~\n\$html\n~~~\n")
            ```
            \\textoutput{pluto}
            """
    end

and calling this from Franklin.
For example:

```
+++
title = "My analysis"
reeval = true
+++

\readhtml{analysis}
```

## LaTeX equations

With Franklin.jl, I've just updated `foot_katex.html` to include:

```javascript
<script>
  const options = {
    delimiters: [
      {left: "$$", right: "$$", display: true},
      {left: "$", right: "$", display: false},
      {left: "\\begin{equation}", right: "\\end{equation}", display: true},
      {left: "\\begin{align}", right: "\\end{align}", display: true},
      {left: "\\begin{alignat}", right: "\\end{alignat}", display: true},
      {left: "\\begin{gather}", right: "\\end{gather}", display: true},
      {left: "\\(", right: "\\)", display: false},
      {left: "\\[", right: "\\]", display: true}
    ]
  };
  renderMathInElement(document.body, options);
</script>
```

which basically ensures that inline math surrounded by single dollar symbols is also rendered.
Note that Pluto.jl runs MathJax by default which might sometimes cause inconsistencies between the math in Pluto and inside your HTML.

## Docstrings

`kwargs` for `notebook2html(path; ...)` and `parallel_build!` are passed to `notebook2html`:

```@docs
parallel_build!
notebook2html
```
