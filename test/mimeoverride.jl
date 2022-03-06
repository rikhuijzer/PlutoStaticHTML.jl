notebook = Notebook([
    Cell("md\"This is **markdown**\"")
])
html, nb = notebook2html_helper(notebook; use_distributed=false)
lines = split(html, '\n')
@test contains(lines[2], "<strong>")

notebook = Notebook([
    Cell("""("pluto", "tree", "object")"""),
    Cell("""["pluto", "tree", "object"]"""),
    Cell("""[1, (2, (3, 4))]"""),
    Cell("(; a=(1, 2), b=(3, 4))")
])
html, nb = notebook2html_helper(notebook; use_distributed=false);
lines = split(html, '\n')
@test contains(lines[2], "(\"pluto\", \"tree\", \"object\")")
@test contains(lines[2], "<pre")
@test contains(lines[6], "pluto")
@test contains(lines[7], "tree")
@test contains(lines[8], "object")
@test contains(lines[11], "2-element Vector")
@test contains(lines[16], "(a = (1, 2), b = (3, 4))")
