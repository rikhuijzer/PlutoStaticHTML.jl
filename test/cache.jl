@testset "prefix" begin
    version = $VERSION
    text = repeat("foobar\n", 100)
    html = string(PlutoStaticHTML.State(html)) * text
    state = PlutoStaticHTML.State(html)
    @test state.input_sha == PlutoStaticHTML.sha(html)
    @test state.julia_version == string(VERSION)::String
end
