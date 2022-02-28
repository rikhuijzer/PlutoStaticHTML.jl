@testset "contains" begin
    html = "<b>foo</b>"
    block = PlutoStaticHTML.code_block(html)
    @test contains(block, "&lt;b&gt;foo&lt;/b&gt;")

    notebook = Notebook([
        Cell("x = 1 + 1"),
        Cell("using Images: load"),
        Cell("PKGDIR = \"$PKGDIR\""),
        Cell("""im_file(ext) = joinpath(PKGDIR, "test", "im", "im.\$ext")"""),
        Cell("""load(im_file("png"))""")
    ])
    html, nb = notebook2html_helper(notebook)
    lines = split(html, '\n')

    @test contains(lines[1], "1 + 1")
    @test contains(lines[2], "2")

    @test contains(lines[end-1], """<img src=\"data:image/png;base64,""")

    notebook = Notebook([
        Cell("struct A end"),
        Cell("""
            struct B
                x::Int
                a::A
            end
            """
            ),
        Cell("B(1, A())")
    ])
    html, nb = notebook2html_helper(notebook)
    lines = split(html, '\n')
    @test contains(lines[end-1], "B(1, A())")

    notebook = Notebook([
        Cell("md\"my text\"")
    ])
    html, nb = notebook2html_helper(notebook, HTMLOptions(; hide_md_code=true))
    lines = split(html, '\n')
    @test lines[1] == ""

    html, nb = notebook2html_helper(notebook, HTMLOptions(; hide_md_code=false))
    lines = split(html, '\n')
    @test lines[1] != ""

    opts = HTMLOptions(; hide_md_code=false, hide_code=true)
    html, nb = notebook2html_helper(notebook, opts);
    lines = split(html, '\n')
    @test lines[1] == ""
end

@testset "hide" begin
    nb = Notebook([
        Cell("x = 1 + 1 # hide"),
        Cell("""
            # hideall
            y = 3 + 3
            """)
        ])
    html, nb = notebook2html_helper(nb)
    @test contains(html, ">2<")
    @test !contains(html, "1 + 1")
    @test contains(html, ">6<")
    @test !contains(html, "3 + 3")
end

@testset "from_file" begin
    mktempdir() do dir
        file = joinpath(dir, "tmp.jl")
        content = pluto_notebook_content("x = 1 + 2")
        write(file, content)
        html = PlutoStaticHTML.notebook2html(file)
        @test contains(html, "3")
    end
end

@testset "run_notebook!_errors" begin
    mktempdir() do dir
        text = pluto_notebook_content("sum(1, :b)")
        path = joinpath(dir, "notebook.jl")
        write(path, text)
        session = ServerSession()
        err = nothing
        try
            nb = PlutoStaticHTML.run_notebook!(path, session)
        catch err
        end

        @test err isa Exception
        msg = sprint(showerror, err)
        @test contains(msg, "notebook failed")
        @test contains(msg, "notebook.jl")
        @test contains(msg, "sum(1, :b)")
        @test contains(msg, "Closest candidates are")
        @test contains(msg, "_foldl_impl")
    end
end

@testset "pluto-docs-binding" begin
    text = """
        "This is a docstring"
        foo(x) = x
        """
    nb = Notebook([
        Cell(text),
    ])
    html, nb = notebook2html_helper(nb)

    @test !contains(html, "pluto-docs-binding")
end

@testset "benchmark-hack" begin
    # Related to https://github.com/fonsp/Pluto.jl/issues/1664
    nb = Notebook([
        Cell("using BenchmarkTools"),
        Cell("@benchmark sum(x)"),
        Cell("x = [1, 2]")
    ])
    html, nb = notebook2html_helper(nb)
    @test contains(html, "BenchmarkTools.Trial")
end
