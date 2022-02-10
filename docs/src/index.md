# PlutoStaticHTML

Convert Pluto notebooks to pure HTML (without Javascript).
This allows Pluto notebooks to be embedded in Documenter, Franklin and (optionally) to be styled manually via CSS.
Also, it is possible to hide code blocks making it easy to show Julia generated output without showing code.
Typically, converting Pluto notebooks to HTML is useful for things like

- tutorials (a ready-to-use template can be found at <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>)
- blogs
- documentation

For a quick preview, this package is used for the tutorials at [TuringGLM.jl](https://turinglang.github.io/TuringGLM.jl/dev/tutorials/linear_regression/).
Also, I'm using this package for my own blog, for example: <https://huijzer.xyz/posts/frequentist-bayesian-coin-flipping/>.

## API overview

The most important method is `parallel_build` ([API](@ref)).

!!! note
    `parallel_build` ensures that the original notebook will not be changed.

In general, the idea is to

1. Create a bunch of Pluto notebooks.
1. Get the name of the directory `dir` which contains your Pluto notebooks.
1. Choose an appropriate `output_format` depending on how the output will be used.
    The output format can be `html_output`, `documenter_output` or `franklin_output`.
1. Pass the paths to [`parallel_build`](@ref) which, depending on `output_format`, writes HTML or Markdown outputs to files.
1. Read the output from the files and show them on a website via either your own logic or Documenter or Franklin.

Note that this is a very nice development workflow because developing in Pluto notebooks is easy and allows for quick debugging.
Also, Pluto has a lot of conversions built-in.
This package will take the converted outputs, such as plots or tables, from Pluto which ensures that what you see in Pluto is what you see in the HTML output.

As an extension of Pluto, this package provides `# hide` and `# hideall` comments like Franklin and Documenter.
A `# hideall` somewhere in a Pluto code block will hide the code (but not the output).
A `# hide` behind a line in a code block will hide the line.
Also, by default, this package hides all Markdown code blocks since readers are probably only interested in reading the output of the Markdown code block.
This and more options can be tuned via [`HTMLOptions`](@ref).

See below for more specific instructions on

- [Documenter.jl](@ref)
- [Franklin.jl](@ref)
- [Parallel build](@ref)

## Documenter.jl

The `output_format=documenter_output` is used at various places which can all serve as an example:

- "docs/make.jl" in this repository.
- [TuringGLM.jl](https://github.com/TuringLang/TuringGLM.jl); for example output see the [linear regression tutorial](https://turinglang.github.io/TuringGLM.jl/dev/tutorials/linear_regression/).
- [Resample.jl](https://github.com/rikhuijzer/Resample.jl); for example output see the [SMOTE tutorial](https://rikhuijzer.github.io/Resample.jl/dev/notebooks/smote/).

!!! warn
    Avoid calling the conversion from inside a Documenter.jl code block.
    For some reason, that is likely to freeze or hang; probably due to `stdout` being flooded with information.
    Instead generate Markdown files via `docs/make.jl` and point to these files in `pages`.

## Franklin.jl

For `output_format=franklin_output` examples, see

- The template at <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>.
- [My blog](https://gitlab.com/rikh/blog).
    For example, a post on [random forests](https://huijzer.xyz/posts/random-forest/).

## Parallel build

To speed up the build, this package defines [`parallel_build`](@ref).
This function evaluates the notebooks in parallel by default.
Also, it can use [Caching](@ref) to speed up the build even more.

To use it, pass a `dir` to write HTML files for all notebook files (the files are recognized by the ".jl" extension):

```julia
julia> using PlutoStaticHTML: parallel_build

julia> dir = joinpath("posts", "notebooks");

julia> parallel_build(BuildOptions(dir));
[...]
```

To run only specific notebooks, use:

```julia
julia> files = ["notebook1.jl", "notebook2.jl"];

julia> parallel_build(BuildOptions(dir), files)
[...]
```

In CI, be sure to call this before using Franklin `serve` or `optimize`.

For more options, such as `append_build_context` to add Julia and packages version information, you can pass [`HTMLOptions`](@ref):

```julia
julia> bopts = BuildOptions(dir);

julia> hopts = HTMLOptions(; append_build_context=true);

julia> parallel_build(bopts, files, hopts)
[...]
```

See [`parallel_build`](@ref) for more information.

### Caching

Using caching can greatly speed up running times by avoiding to re-evaluate notebooks.
Caching can be enabled by passing `previous_dir` via [`BuildOptions`](@ref).
This `previous_dir` should point to a location where HTML or Markdown files are from the previous build.
Then, `parallel_build` will, for each input file `file.jl`, check:

1. Whether `joinpath(previous_dir, "file.html")` exists
2. Whether the SHA checksum of the current `$file.jl` matches the checksum of the previous `$file.jl`.
    When assuming that Pluto's built-in package manager is used to manage packages, this check ensures that the packages of the previous run match the packages of the current run.
3. Whether the Julia version of the previous run matches the Julia version of the current run.

!!! note
    Caching assumes that notebooks are deterministic, that is, the notebook will produce the same output from the same input.

!!! note
    The `previous_dir` provides a lot of flexibility.
    For example, it is possible to point towards a Git directory with the HTML or Markdown output files from last time.
    Alternatively, for `output_format=html_output` it is possible to download the web pages where the notebooks are shown and put these web pages in a directory.
    This works by extracting the state from the previous run from the output.

## LaTeX equations

Pluto uses MathJax by default, so make sure to setup MathJax in Franklin or Documenter.
For Franklin, see <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>.
For Documenter, see `docs/make.jl` in this repository.

## API

```@docs
parallel_build
BuildOptions
HTMLOptions
```
