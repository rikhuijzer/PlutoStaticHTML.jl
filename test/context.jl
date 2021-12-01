@testset "context" begin
    notebook = Notebook([
        Cell("a = 600 + 1"),
    ])
    html = notebook2html!(notebook; append_build_context=true)
    @test contains(html, r"Built with Julia 1.*")
end
