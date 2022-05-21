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
    @test contains(lines[2], "class='$(PlutoStaticHTML.OUTPUT_PRE_CLASS_DEFAULT)'")

    @test contains(lines[end-1], """src=\"data:image/png;base64,""")
    @test contains(lines[end-1], "<img")

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
    use_distributed = false
    html, nb = notebook2html_helper(notebook; use_distributed)
    lines = split(html, '\n')
    @test contains(lines[end-1], "B(1, A())")

    notebook = Notebook([
        Cell("md\"my text\"")
    ])
    html, nb = notebook2html_helper(notebook, HTMLOptions(; hide_md_code=true); use_distributed)
    lines = split(html, '\n')
    @test lines[1] == ""

    html, nb = notebook2html_helper(notebook, HTMLOptions(; hide_md_code=false); use_distributed)
    lines = split(html, '\n')
    @test lines[1] != ""

    opts = HTMLOptions(; hide_md_code=false, hide_code=true)
    html, nb = notebook2html_helper(notebook, opts; use_distributed)
    lines = split(html, '\n')
    @test lines[1] == ""
end

@testset "use_distributed=false and pwd" begin
    dir = pwd()
    nb = Notebook([Cell("1 + 1")])
    _, _ = notebook2html_helper(nb, HTMLOptions(; hide_md_code=true); use_distributed=false)
    @test pwd() == dir
end

@testset "hide" begin
    nb = Notebook([
        Cell("x = 1 + 1 # hide"),
        Cell("""
            # hideall
            y = 3 + 3
            """)
        ])
    html, nb = notebook2html_helper(nb; use_distributed=false)
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
    # To avoid changing the current working directory; I don't know what causes it to change
    # exactly.
    cd(pwd()) do
        mktempdir() do dir
            text = pluto_notebook_content("sum(1, :b)")
            path = joinpath(dir, "notebook.jl")
            write(path, text)
            session = ServerSession()
            session.options.evaluation.workspace_use_distributed = false
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
end

@testset "pluto-docs-binding" begin
    text = """
        "This is a docstring"
        foo(x) = x
        """
    nb = Notebook([
        Cell(text),
    ])
    html, nb = notebook2html_helper(nb; use_distributed=false)

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

@testset "show_output_above_code" begin
    nb = Notebook([
        Cell("x = 1 + 1020"),
    ])
    hopts = HTMLOptions(; show_output_above_code=true)
    html, _ = notebook2html_helper(nb, hopts; use_distributed=false)
    lines = split(html, '\n')

    @test contains(lines[1], "1021")
    @test contains(lines[2], "1 + 1020")
end

@testset "with_terminal" begin
    nb = Notebook([
        Cell("using PlutoUI"),
        Cell("f(x) = Base.inferencebarrier(x);"),
        Cell("""
            with_terminal() do
                @code_warntype f(1)
            end
            """)
    ])
    html, _ = notebook2html_helper(nb)
    # Basically, this only tests whether `_patch_with_terminal` is applied.
    @test contains(html, """<pre id="plutouiterminal">""")
end

@testset "replace_code_tabs" begin
    code = """
        		1	
        	2
        """
    @test PlutoStaticHTML._replace_code_tabs(code) == """
                1	
            2
        """

    nb = Notebook([
        Cell("	a = 1 + 1021;"),
        Cell("		b = 1 + 1021;"),
    ])
    hopts = HTMLOptions()
    html, _ = notebook2html_helper(nb, hopts; use_distributed=false)
    lines = split(html, '\n')

    filter!(!isempty, lines)
    @test contains(lines[1], "    a = 1 + 1021")
    @test contains(lines[2], "        b = 1 + 1021")
end

@testset "big table" begin
    # Using DataFrames here instead of Tables to get the number of rows for long tables.
    nb = Notebook([
        Cell("using DataFrames: DataFrame"),
        Cell("DataFrame(rand(120, 20), :auto)")
    ])
    hopts = HTMLOptions()
    html, _ = notebook2html_helper(nb, hopts; use_distributed=false)
    # Use write(tmp.html, html) to test this.
    
end
