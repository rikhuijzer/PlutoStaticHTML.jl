# Changelog

All notable changes to this project will be documented in this file.

## [8.2.0] - 2026-09-09

### Features

- Make documenter output compatible to DocumenterCodeBlocks via the
  `documenter_code_blocks` option
  - Make the identification of literal string cells configurable

## [8.1.0] - 2026-08-31

### Features
- Moved package to JuliaPluto
- Update docs deployment. (#225)
* Update deployment  URLs to JuliaPluto
* update dependencies in example notebook
* switch cairomakie output to svg due to some errors

- Update Pluto compat to "~1.0" (#227)
* Add ExplicitImports + undocumented-names checks to the test suite
* Refine imports/precompile calls and add docstrings for OutputFormat
* Add 'pre' to CI test matrix

## [8.0.0] - 2026-05-29

### Features

- Update Pluto to 1.0.1 (#221)

## [7.0.11] - 2026-05-20

### Features

- Fix admonition header block in index.md (#216)

`!!! warn` not  recognized by Documenter, switch to `!!! warning`
- Add/update syntax highlight tags to fenced code blocks (#217)
- Try `ubuntu-24.04-arm` for `Docs.yml`
- Update Pluto to 0.20.27 (#220)

## [7.0.10] - 2026-02-24

### Features
- Update Pluto to 0.20.23 (#215)

## [7.0.9] - 2025-11-12

### Features

- Switch to Pluto 0.20.21 (#213)

At once, update notebooks

## [7.0.8] - 2025-09-13

### Features

- Update Pluto to 0.20.18 (#212)

## [7.0.7] - 2025-08-12

### Features

- Update Pluto to 0.20.14 (#210)

## [7.0.6] - 2025-07-08

### Features

- Update to Pluto 0.20.13 (#209)
- Set version to 7.0.6

## [7.0.5] - 2025-06-20

### Features

- Pluto 0.20.11 (#208)

## [7.0.4] - 2025-04-16

### Features

- Update Pluto to 0.20.6 (#205)

## [7.0.3] - 2024-12-21

### Features

- Update Pluto to 0.20.4 (#204)

## [7.0.2] - 2024-10-29

### Features

- Update Pluto to 0.20.3 (#203)

## [7.0.1] - 2024-10-14

### Features

- Update Pluto to 0.20.0 (#202)

## [7.0.0] - 2024-10-10

### Features

- Update Pluto to 0.19.47 (#201)

## [6.0.28] - 2024-08-17

### Features

- Fix doc links in README.md (fixes #198)
- Update Pluto to 0.19.46 (#199)

## [6.0.27] - 2024-07-16

### Features

- Update Pluto to 0.19.44 (#196)
- Update Pluto to 0.19.45 (#197)

## [6.0.26] - 2024-06-26

### Features

- Update Pluto to 0.19.43 (#195)

## [6.0.25] - 2024-06-12

### Features

- Revert escaping dollar symbol (#193)

## [6.0.24] - 2024-06-04

### Features

- Escape dollar (#192)


## [6.0.23] - 2024-05-08

### Features
- Update Pluto to 0.19.42 (#191)

## [6.0.22] - 2024-04-15

### Features

- Add github-actions dependabot
- Bump actions/checkout from 2 to 4 (#187)
- Bump julia-actions/setup-julia from 1 to 2 (#188)
- Update Pluto to 0.19.41 (#189)

## [6.0.21] - 2024-04-02

### Features

- Update Pluto to 0.19.40 (#181)

## [6.0.20] - 2024-02-21

### Features

- Remove mono deploy for docs
- Use permissions
- Update README.md
- More robust error throw & update Pluto (#179)
- Also updates Pluto to 0.19.39.

## [6.0.19] - 2024-01-24

### Features

- Update Pluto to 0.19.37 (#178)

## [6.0.18] - 2023-12-14

### Features

- Update Pluto to 0.19.36 (#177)

## [6.0.17] - 2023-12-07

### Features

- Update to Pluto 0.19.35 (#176)

## [6.0.16] - 2023-10-22

### Features

- Update example notebook in docs
- Bugfix for workspace_custom_startup_expr check & updated compat (#172)
- Update to Pluto 0.19.30 (#174)

## [6.0.15] - 2023-09-26

### Features

- Update to Pluto 0.19.28 (#171)

Contains fix for https://github.com/fonsp/Pluto.jl/pull/2654.

## [6.0.14] - 2023-05-20

### Features

- Set buildpkg v1
- Update to Pluto 0.19.26 (#168)

## [6.0.13] - 2023-02-24

### Features

- Avoid `startswith(Nothing, ...)` (#166)

## [6.0.12] - 2023-02-07

### Features

- Improve logging for cache (#165)

## [6.0.11] - 2023-01-27

### Features

- Update Docs.yml
- Update Pluto to `0.19.21` (#163)

## [6.0.10] - 2023-01-23

### Features

- Remove `Manopt.jl` ref
- Update Pluto to 0.19.20 (#162)

## [6.0.9] - 2023-01-07

### Features

- Update Pluto to 0.19.19 (#160)

## [6.0.8] - 2022-12-04

### Features

- Avoid benign warning (#157)

## [6.0.7] - 2022-12-04

### Features

- Update Pluto to 0.19.16 (#156)

## [6.0.6] - 2022-10-19

### Features

- Fix Gumbo outputting full HTML page (#153)

## [6.0.5] - 2022-10-16

### Features

- Create .gitattributes
- Handle cell metadata (#152)

## [6.0.4] - 2022-10-14

### Features

- Use Gumbo for modifying the HTML (#151)

## [6.0.3] - 2022-10-12

### Features

- Fix a bug in `_wrap_admonition_body` (#150)

## [6.0.2] - 2022-10-09

### Features

- Allow rich MIME override (#145)

## [6.0.1] - 2022-10-06

### Features

- Add example to `build_notebooks` docstring
- Fix typo
- Fix bug introduced by GitHub's web editor
- Bump Pluto compat (#146)

## [6.0.0] - 2022-08-10

### Features

- Fix link to manopt tutorial
- Add option for PDF output (#124)

## [5.0.13] - 2022-07-23

### Features

- Fix Markdown headers not being shown in Documenter (#129)

## [5.0.12] - 2022-06-25

### Features

- Fix Markdown code loading again (#126)

## [5.0.11] - 2022-06-23

### Features

- Simplify docs
- Fix Markdown not found in override (#125)

## [5.0.10] - 2022-06-10

### Features

- Add GraphNeuralNetworks.jl Documenter example (#120)
- Test via Aqua (#121)
- Improve error message if file is not found (#123)

## [5.0.9] - 2022-05-21

### Features

- Handle truncated tables better (#115)

## [5.0.8] - 2022-05-10

### Features

- Update make.jl
- Fix tests
- Avoid using Pkg again in tests
- Fix link to documentation in the README (#109)
- Fix docstring saying parallel
- Move to Pluto.jl 0.19.4 (#111)

## [5.0.7] - 2022-04-28

### Features

- Report how long it took to evaluate a notebook (#108)

## [5.0.6] - 2022-04-26

### Features

- Update index.md and add one further example (#105)
- Use PrecompileSignatures.jl (#106)

## [5.0.5] - 2022-04-24

### Features

- Set EditURL by making a best guess
- Bump Pluto to 0.19.2 and PlutoStaticHTML to 5.0.5


## [5.0.4] - 2022-04-21

### Features

- Revert incremental compilation fix (#102)

## [5.0.3] - 2022-04-20

### Features

- Fix incremental compilation warning (#100)
- Improve styling for admonitions in `documenter_output` (#101)

## [5.0.2] - 2022-04-11

### Features

- Add `max_concurrent_runs` setting (#99)

## [5.0.1] - 2022-04-11

### Features

- Limit concurrency (#98)

## [5.0.0] - 2022-04-10

### Features

- Disable syntax highlight for output blocks (#97)

## [4.2.0] - 2022-04-06

### Features

- Bump Pluto to 0.19
- Set version to 4.2.0

## [4.1.0] - 2022-03-28

### Features

- Disable coverage for runtest
- Fix documentation badges
- Add `replace_code_tabs` (#95)

## [4.0.5] - 2022-03-27

### Features

- Update terminal line-height
- Add ability to opt out of added documenter CSS (#96)

## [4.0.4] - 2022-03-20

### Features

- Remove a `@show`
- Fix `documenter_output` cache (#91)

## [4.0.3] - 2022-03-19

### Features

- Support `with_terminal` and update Pluto to 0.18.4 (#88)

## [4.0.2] - 2022-03-13

### Features

- Setup monodeploy (#86)
- Default to dev
- Force set dev to default
- Change docs branch name to docs-output
- Also deploy to docs-output
- Generate redirects for docs
- Generate redirects for all symlinks in monorepo
- Set default to dev again
- Update Pluto to 0.18.2 (#87)

## [4.0.1] - 2022-03-10

### Features

- Update index.md
- Allow showing output above code (#84)

## [4.0.0] - 2022-03-07

### Features

- Change the method name to `build_notebooks` (#83)

## [3.5.1] - 2022-03-06

### Features

- Reduce running time of tests (#80)
- Fix changing pwd (#81)
- Add some precompile statements (#82)
- Set version to 3.5.1

## [3.5.0] - 2022-02-28

### Features

- Bump Pluto compat entry to 0.18.1 (#77)
- Fix code output block appearance
- Set version to 3.5.0

## [3.4.2] - 2022-02-17

### Features

- Add Downloads badge to README (#72)
- Add error when context is missing (#75)
- Set version to 3.4.2

## [3.4.1] - 2022-02-13

### Features

- Test for the right thing
- Remove CI badge
- Fix caching for `franklin_output` (#71)
- Set version to 3.4.1

## [3.4.0] - 2022-02-10

### Features

- Deduplicate code in override (#63)
- Move tests
- Fix unclear error (#64)
- Fix 13 possible problems (JET)
- Update docs (#65)
- Improve error futher (#66)
- Set version to 3.4.0

## [3.3.1] - 2022-02-09

### Features

- Fix duplication happening when caching HTML files (#62)
- Set version to 3.3.1

## [3.3.0] - 2022-02-07

### Features

- Simplify tests and docs (#59)
- Disable Pluto's tree printing (#60)
- Set version to 3.3.0

## [3.2.2] - 2022-02-04

### Features

- Fix `@benchmark` failure (#58)
- Set version to 3.2.2

## [3.2.1] - 2022-02-03

### Features

- Add `documenter_output` (#56)
- Fix styling of h2 headings
- Set version to 3.2.1

## [3.2.0] - 2022-02-02

### Features

- Pin Pluto version
- Fix `run_notebook!` (#55)
- Set version to 3.2.0

## [3.1.4] - 2022-01-30

### Features

- Avoid showing docstrings (#52)
- Set version to 3.1.4

## [3.1.3] - 2022-01-28

### Features

- Fix writing Franklin output
- Improve styling of build context
- Manage cache for franklin_output
- Update documentation
- Fix typo
- Set version to 3.1.3

## [3.1.2] - 2022-01-26

### Features

- Insert `dynamic.js` correctly into HTML (#48)
- Remove dynamic (#51)
- Set version to 3.1.2

## [3.1.1] - 2022-01-22

### Features

- Proof of concept implementation for evaluation of `@bind`s (#39)
- Fix `_run_dynamic!` not executed (#44)
- Allow `PlutoUI.Select` (#46)


## [3.1.0] - 2022-01-13

### Features

- Allow passing of `Pluto.CompilerOptions` (#32)
- Avoid double tmp_path
- Throw error ASAP when `use_distributed == false` (#38)

## [3.0.0] - 2022-01-10

### Features

- Remove one <br>
- Update README with some minimal info and links (#24)
- Switch to julia-actions/cache
- Update README.md
- Update README.md
- Document that original notebooks are not changed
- Document that notebook2html returns a String
- Add state to each output and add `HTMLOptions` (#27)
- Implement caching (#28)

## [2.1.1] - 2021-12-01

### Features

- Switch to Pluto.PkgCompat (#21)
- Set version to 2.1.1

## [2.1.0] - 2021-12-01

### Features

- Update docs
- Add badges
- Add module doc
- Add append_build_context (#20)

## [2.0.2] - 2021-11-29

### Features

- Add `append_cells` keyword argument (#18)

## [2.0.1] - 2021-11-24

### Features

- Add hide_code keyword argument (#17)

## [2.0.0] - 2021-11-10

### Features

- Add `parallel_build!` (#13)
- Avoid spawning separate processes (#14)
- Let Pluto handle the multithreading (#15)

## [1.0.0] - 2021-11-08

### Features

- Use SessionActions.open (#10)
- Update README.md
- Escape HTML in code blocks (#11)
- Add note on LaTeX equations
- Set version to 1.0.0

## [0.1.0] - 2021-11-05

### Features
- Initial commit
