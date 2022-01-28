# PlutoStaticHTML

Convert Pluto notebooks to pure HTML (without Javascript).
The benefit of this is that it can easily be styled via CSS.
Also, it is possible to zero or more code blocks making it easy to show Julia generated output without showing code.
Typically, converting Pluto notebooks to HTML is useful for things like

- tutorials (a ready-to-use template can be found at <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>)
- blogs
- documentation

, it is possible to show Julia generated output without 

This package is used for the tutorials at [TuringGLM.jl](https://turinglang.github.io/TuringGLM.jl/dev/tutorials/linear_regression/).
Also, I'm using this package for my own blog, for example: <https://huijzer.xyz/posts/frequentist-bayesian-coin-flipping/>.

## API overview

The most important methods are `notebook2html` or `parallel_build` ([API](@ref)).

!!! note
    `notebook2html` and `parallel_build` ensure that the original notebook will not be changed.
    The notebook will be copied and placed in the same folder so that `@__DIR__` can be used to locate files relative to the notebook path.
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
    It is typically not a good idea to call the conversion from inside a Documenter.jl code block.
    For some reason, that is likely to freeze or hang; probably due to `stdout` being flooded with information or something.
    To avoid this, generate documents via `docs/make.jl` and import those in Documenter.jl.

## Franklin.jl

See the template at <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>.

## Parallel build

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

Pluto uses MathJax by default, so make sure to setup MathJax in Franklin or Documenter.
For Franklin, see <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>.
For Documenter, see `docs/make.jl` in this repository.

## API

```@docs
HTMLOptions
BuildOptions
parallel_build
notebook2html
```
