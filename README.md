# PlutoStaticHTML.jl

[![Docs dev][docs-dev-img]][docs-dev-url]
[![Code Style Blue][blue-img]][blue-url]
[![Contributor's Guide on Collaborative Practices][colprac-img]][colprac-url]
[![PlutoStaticHTML Downloads](https://shields.io/endpoint?url=https://pkgs.genieframework.com/api/v1/badge/PlutoStaticHTML)](https://pkgs.genieframework.com?packages=PlutoStaticHTML)

A [Julia package](https://julialang.org/) to convert [Pluto notebooks](https://github.com/fonsp/Pluto.jl) to static HTML.
Unlike [PlutoSliderServer](https://github.com/JuliaPluto/PlutoSliderServer.jl), the HTML files generated using PlutoStaticHTML are very minimal, and do not require JavaScript on the user side to render.
This makes it easier to style the output using CSS.
For example, with this package it is possible to create a website full with plots generated in Julia and all code hidden.
In effect, no one would be able to tell that the website was built with Julia.

## Automated builds

Next to outputting static HTML, this package is also aimed at building multiple Pluto.jl notebooks as reliably and quickly as possible in unsupervised settings such as CI.
Therefore, this package implements:

1. Parallel evaluation of notebooks 🚀.
1. Caching of notebooks to avoid re-running code if nothing changed 🚀.
1. Throwing an error if something goes wrong.
    This avoids publishing broken notebooks 🎯.

See the [documentation](https://huijzer.xyz/PlutoStaticHTML.jl/dev/) for more information.

[ci-url]: https://github.com/JuliaData/DataFrames.jl/actions?query=workflow%3ACI+branch%3Amain
[ci-img]: https://github.com/rikhuijzer/PlutoStaticHTML.jl/workflows/CI/badge.svg

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://huijzer.xyz/PlutoStaticHTML.jl/dev/

[blue-img]: https://img.shields.io/badge/code%20style-blue-4495d1.svg
[blue-url]: https://github.com/invenia/BlueStyle

[colprac-img]: https://img.shields.io/badge/ColPrac-contributor's%20guide-blueviolet
[colprac-url]: https://github.com/SciML/ColPrac
