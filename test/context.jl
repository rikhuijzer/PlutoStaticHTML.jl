@testset "context" begin
    hopts = HTMLOptions(; append_build_context=true)
    bopts = BuildOptions(dirname(NOTEBOOK_PATH))

    html = only(parallel_build(bopts, hopts))
    @test contains(html, r"Built with Julia 1.*")
    @test contains(html, "CairoMakie")
end
