@testset "htmltypes" begin
    # This looks like a @bind b slider, but note that Pluto always start min at 1.
    html = """<bond def="b"><input type='range' min='4' max='5' value='6'></bond>"""

    input = PlutoStaticHTML.HTMLInput(html)
    @test Set(keys(input.attributes)) == Set(["max", "min", "value"])
    elem = PlutoStaticHTML.HTMLElement(input)
    @test elem == PlutoStaticHTML.HTMLElement(4.0, 5.0, 1.0, 6.0)
end
