@testset "htmltypes" begin
    # @bind b Slider([4, 5])
    html = """<bond def="b"><input type='range' min='1' max='2' value='1'></bond>"""
    input = PlutoStaticHTML.HTMLInput(html)
    @test Set(keys(input.attributes)) == Set(["max", "min", "value"])
end
