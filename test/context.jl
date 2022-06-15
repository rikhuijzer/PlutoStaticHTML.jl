tmpdir = mktempdir()
in_file = "notebook.jl"
content = pluto_notebook_content("""
    # Very small package.
    using PrecompileMacro
    """)
write(joinpath(tmpdir, in_file), content)

hopts = OutputOptions(; append_build_context=true)
bopts = BuildOptions(tmpdir; use_distributed=true)

outputs = build_notebooks(bopts, hopts)
html = only(outputs[in_file])
@test contains(html, r"Built with Julia 1.*")
@test contains(html, "PrecompileMacro")
