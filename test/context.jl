@testset "context" begin
    notebook = PlutoStaticHTML._load_notebook(NOTEBOOK_PATH)
    html = notebook2html!(notebook; append_build_context=true)
    @test contains(html, r"Built with Julia 1.*")
    @test contains(html, "CairoMakie")
end
