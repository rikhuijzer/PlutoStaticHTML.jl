@testset "context" begin
    html = notebook2html!(NOTEBOOK_PATH; append_build_context=true)
    @test contains(html, r"Built with Julia 1.*")
    @test contains(html, "CairoMakie")
end
