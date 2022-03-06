tmpdir = mktempdir()
content = pluto_notebook_content("""
    # Very small package.
    using PrecompileMacro
    """)
write(joinpath(tmpdir, "notebook.jl"), content)

hopts = HTMLOptions(; append_build_context=true)
bopts = BuildOptions(tmpdir; use_distributed=true)

html = only(parallel_build(bopts, hopts))
@test contains(html, r"Built with Julia 1.*")
@test contains(html, "PrecompileMacro")
