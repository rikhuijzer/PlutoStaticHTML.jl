# PlutoStaticHTML

Convert Pluto notebooks to pure HTML (without Javascript).
Small discussion with Fons van der Plas at <https://github.com/fonsp/Pluto.jl/discussions/1607>.

I'm using this package for my own blog, for example: <https://huijzer.xyz/posts/frequentist-bayesian-coin-flipping/>.
A link to the notebook is at the bottom of the page.

The most important methods are `notebook2html` or `parallel_build` ([API](@ref)).

!!! note
    `notebook2html` and `parallel_build` evaluate notebooks **after** copying your notebooks.
    This ensures that the original notebook will not be changed.
    The copied notebook will be placed in the same folder so that `@__DIR__` can be used to locate files relative to the notebook path.
    Add `**/_tmp_*` to your `.gitignore` to ignore the temporary copies.

### notebook2html

To process one notebook.
To make use of caching or parallel building, use [`parallel_build`](@ref).

Example usage for `notebook2html`:

```julia
julia> using PlutoStaticHTML

julia> notebook2html("Exciting analysis.jl") |> print
<div class="markdown"><p>This is an example notebook.</p>
[...]
```

Note that, in general, what works best is to

1. Determine a list of paths to your notebooks.
1. Pass the paths to  [`parallel_build`](@ref) which writes the HTML outputs to files by default.
1. Read the output from the HTML files and show it inside a static website.

More specific instructions for

- [Documenter.jl](@ref)
- [Franklin.jl](@ref)
- [Parallel build](@ref)

are listed below.

## Documenter.jl

To see how to embed output from a Pluto notebook in Documenter.jl, checkout "make.jl" in this repository.

!!! warn
    It is typically not a good idea to call the conversion from inside `Documenter.jl`.
    For some reason, that is likely to freeze or hang; probably due to `stdout` being flooded with information or something.

## Franklin.jl

See the next section for a parallel version.
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

```markdown
+++
title = "My analysis"
+++

\pluto{analysis}
```

## Parallel build

The approach above lets Franklin.jl handle the build.
This doesn't work in parallel.
To speed up the build, this package defines `parallel_build`.
`parallel_build` evaluates the notebooks in parallel by default.
Also, it can use [Caching](@ref) to speed up the build even more.

To use [`parallel_build`](@ref), pass a `dir` to write HTML files for all notebook files (recognized by ".jl" extension):

```julia
julia> using PlutoStaticHTML: parallel_build

julia> dir = joinpath("posts", "notebooks");

julia> parallel_build(BuildOptions(dir));

```

To run only specific notebooks, use:

```julia
julia> files = ["notebook1.jl", "notebook2.jl"];

julia> parallel_build(BuildOptions(dir), files)
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

### Caching

Using caching can greatly speed up running times by avoiding to re-evaluate notebooks.
Caching can be enabled by passing `previous_dir` via [`BuildOptions`](@ref).
This `previous_dir` should point to a location where HTML files are from the previous build.
Then, `parallel_build` will, for each input file `file.jl`, check:

1. Whether `joinpath(previous_dir, "file.html")` exists
2. Whether the SHA checksum of the current `$file.jl` matches the checksum of the previous `$file.jl`.
    When assuming that Pluto's built-in package manager is used to manage packages, this check ensures that the packages of the previous run match the packages of the current run.
3. Whether the Julia version of the previous run matches the Julia version of the current run.

!!! note
    Caching can only be used if the notebooks are deterministic, that is, the notebook will always produce the same output from the same input.

!!! note
    The `previous_dir` provides a lot of flexibility.
    For example, it is possible to point towards a Git directory with the HTML output files from last time.
    Alternatively, it is possible to download the web pages where the notebooks are shown and put these web pages in a directory.
    This works because this package extracts the state from the previous run automatically.

## LaTeX equations

With Franklin.jl, update `foot_katex.html` to include:

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

## API

```@docs
HTMLOptions
BuildOptions
parallel_build
notebook2html
```
