# PlutoStaticHTML

Convert Pluto notebooks to pure HTML (without Javascript).
This allows Pluto notebooks to be embedded in Documenter, Franklin and (optionally) to be styled manually via CSS.
Also, it is possible to hide code blocks making it easy to show Julia generated output without showing code.
Typically, converting Pluto notebooks to HTML is useful for things like

- tutorials (a ready-to-use template can be found at <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>)
- blogs
- documentation

For a quick preview, this package is used for the tutorials at [TuringGLM.jl](https://turinglang.github.io/TuringGLM.jl/dev/tutorials/linear_regression/).

Also, I have used this package for my own blog, for example: <https://huijzer.xyz/posts/frequentist-bayesian-coin-flipping/>.
Currently, I would advise against using PlutoStaticHTML.jl for blogs though as I wrote [in a blog post](https://huijzer.xyz/posts/blogs-with-code/).
Internal dashboards could still work.

## API overview

The most important method is `build_notebooks` ([API](@ref)).

!!! note
    `build_notebooks` ensures that the original notebook will not be changed.

In general, the idea is to

1. Create a bunch of Pluto notebooks.
1. Get the name of the directory `dir` which contains your Pluto notebooks.
1. Choose one or more appropriate `output_format`s depending on how the output will be used.
    The output format can be `html_output`, `documenter_output`, `franklin_output` or `pdf_output`.
1. Pass the paths to [`build_notebooks`](@ref) which, depending on `output_format`, writes HTML or Markdown outputs to files.
1. Read the output from the files and show them on a website via either your own logic or Documenter or Franklin.

Note that this is a very nice development workflow because developing in Pluto notebooks is easy and allows for quick debugging.
Also, Pluto has a lot of conversions built-in.
This package will take the converted outputs, such as plots or tables, from Pluto which ensures that what you see in Pluto is what you see in the HTML output.

As an extension of Pluto, this package provides `# hide` and `# hideall` comments like Franklin and Documenter.
A `# hideall` somewhere in a Pluto code block will hide the code (but not the output).
A `# hide` behind a line in a code block will hide the line.
Also, by default, this package hides all Markdown code blocks since readers are probably only interested in reading the output of the Markdown code block.
This and more options can be tuned via [`OutputOptions`](@ref).

See below for more specific instructions on

- [Documenter.jl](@ref)
- [Franklin.jl](@ref)
- [Parallel build](@ref)

## Documenter.jl

The `output_format=documenter_output` is used at various places which can all serve as an example:

- "docs/make.jl" in this repository.
- [TuringGLM.jl](https://github.com/TuringLang/TuringGLM.jl); for example output see the [linear regression tutorial](https://turinglang.github.io/TuringGLM.jl/dev/tutorials/linear_regression/).
- [Resample.jl](https://github.com/rikhuijzer/Resample.jl); for example output see the [SMOTE tutorial](https://rikhuijzer.github.io/Resample.jl/dev/notebooks/smote/).
- [GraphNeuralNetworks.jl](https://github.com/CarloLucibello/GraphNeuralNetworks.jl) tutorials, see for example [Hand-On Graph Neural Networks](https://carlolucibello.github.io/GraphNeuralNetworks.jl/dev/tutorials/gnn_intro_pluto/).

!!! warn
    Avoid calling the conversion from inside a Documenter.jl code block.
    For some reason, that is likely to freeze or hang; probably due to `stdout` being flooded with information.
    Instead generate Markdown files via `docs/make.jl` and point to these files in `pages`.

## Franklin.jl

For `output_format=franklin_output` examples, see

- The template at <https://rikhuijzer.github.io/JuliaTutorialsTemplate/>.
- [My blog](https://gitlab.com/rikh/blog).
    For example, a post on [random forests](https://huijzer.xyz/posts/random-forest/).

Specifically, use the following KaTeX options:

```javascript
const options = {
  delimiters: [
    {left: "$$", right: "$$", display: true},
    {left: "\\begin{equation}", right: "\\end{equation}", display: true},
    {left: "\\begin{align}", right: "\\end{align}", display: true},
    {left: "\\begin{alignat}", right: "\\end{alignat}", display: true},
    {left: "\\begin{gather}", right: "\\end{gather}", display: true},
    {left: "\\(", right: "\\)", display: false},
    {left: "\\[", right: "\\]", display: true}
  ]
};

document.addEventListener('DOMContentLoaded', function() {
  renderMathInElement(document.body, options);
});
```

Note that `$x$` will not be interpreted as inline math by this KaTeX configuration.
This is to avoid conflicts with using the dollar symbol to represent the dollar (currency).
Instead, `PlutoStaticHTML.jl` automatically converts inline math from `$x$` to `\($x\)`.
With above KaTeX settings, `Franklin.jl` will interpret this as inline math.
By default, `Documenter.jl` will also automatically interpret this as inline math.

## Parallel build

To speed up the build, this package defines [`build_notebooks`](@ref).
This function evaluates the notebooks in parallel by default.
Also, it can use [Caching](@ref) to speed up the build even more.

To use it, pass a `dir` to write HTML files for all notebook files (the files are recognized by the ".jl" extension and that the file starts with `### A Pluto.jl notebook ###`):

```julia
julia> using PlutoStaticHTML: build_notebooks

julia> dir = joinpath("posts", "notebooks");

julia> bopts = BuildOptions(dir);

julia> build_notebooks(bopts);
[...]
```

To run only specific notebooks, specify the `files`:

```julia
julia> files = ["notebook1.jl", "notebook2.jl"];

julia> build_notebooks(bopts, files)
[...]
```

In CI, be sure to call this before using Franklin `serve` or `optimize`.

For more options, such as `append_build_context` to add Julia and packages version information, you can pass [`OutputOptions`](@ref):

```julia
julia> oopts = OutputOptions(; append_build_context=true);

julia> build_notebooks(bopts, files, oopts)
[...]
```

See [`build_notebooks`](@ref) for more information.

### Caching

Using caching can greatly speed up running times by avoiding to re-evaluate notebooks.
Caching can be enabled by passing `previous_dir` via [`BuildOptions`](@ref).
This `previous_dir` should point to a location where HTML or Markdown files are from the previous build.
Then, `build_notebooks` will, for each input file `file.jl`, check:

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
build_notebooks
BuildOptions
OutputOptions
```
