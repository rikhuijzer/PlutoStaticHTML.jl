@testset "prefix" begin
    version = VERSION
    text = repeat("foobar\n", 100)
    html = string(PlutoStaticHTML.State(text)) * text
    state = PlutoStaticHTML.State(html)
    @test state.input_sha == PlutoStaticHTML.sha(html)
    @test state.julia_version == string(VERSION)
end

@testset "caching" begin
    dir = mktempdir()

    cd(dir) do
        code = pluto_notebook_content("""write("a.txt", "a")""")
        write("a.jl", code)

        code = pluto_notebook_content("""write("b.txt", "b")""")
        write("b.jl", code)

        bo = BuildOptions(dir)
        parallel_build(bo)

        @test read("a.txt", String) == "a"
        @test isfile("a.html")
        @test read("b.txt", String) == "b"
        @test isfile("b.html")

        rm("a.html")

        previous_dir = dir
        dir = mktempdir()

        cd(dir) do
            bo = BuildOptions(dir; previous_dir)
            parallel_build(bo)

            # a was evaluated because "a.html" was removed.
            @test read("a.txt", String) == "a"
            @test isfile("a.html")

            # b was not evaluated because "b.html" was used from the cache.
            @test !isfile("b.txt")
            @test isfile("b.html")
        end
    end
end
