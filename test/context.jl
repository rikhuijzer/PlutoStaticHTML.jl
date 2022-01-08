@testset "context" begin
    notebook = PlutoStaticHTML._load_notebook(NOTEBOOK_PATH)
    opts = HTMLOptions(; append_build_context=true)
    html = notebook2html_helper(notebook, opts)
    @test contains(html, r"Built with Julia 1.*")
    @test contains(html, "CairoMakie")
end
