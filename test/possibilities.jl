# This looks like a @bind b slider, but note that Pluto always start min at 1.
html = """<bond def="b"><input type='range' min='4' max='6' value='5'></bond>"""

input = PlutoStaticHTML.HTMLInput(html)
@test Set(keys(input.attributes)) == Set(["max", "min", "value"])
elem = PlutoStaticHTML.HTMLRange(input)
@test elem == PlutoStaticHTML.HTMLRange(4.0, 6.0, 1.0, 5.0)
@test PlutoStaticHTML._possibilities(html) == 1:3

html = """
    <bond def="b">
        <select>
            <option value="1">1</option>
            <option value="2">2</option>
        </select>
    </bond>
    """
@test PlutoStaticHTML._possibilities(html) == 1:2
