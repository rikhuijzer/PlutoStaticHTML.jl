@testset "context" begin
    hopts = HTMLOptions(; append_build_context=true)
    files = ["notebook.jl"]
    bopts = BuildOptions(dirname(NOTEBOOK_PATH))

    html = only(parallel_build(bopts, files, hopts))
    @test contains(html, r"Built with Julia 1.*")
    @test contains(html, "CairoMakie")
end
