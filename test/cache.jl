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
        path(name) = joinpath(dir, "$name.txt")
        code = pluto_notebook_content("""
            begin
                path = "$(path('a'))"
                println("Writing to \$path")
                write(path, "a")
            end
            """)
        print(code)
        write("a.jl", code)

        code = pluto_notebook_content("""write("$(path('b'))", "b")""")
        write("b.jl", code)

        bo = BuildOptions(dir)
        parallel_build(bo)

        @test read("a.txt", String) == "a"
        @test isfile("a.html")
        @test read("b.txt", String) == "b"
        @test isfile("b.html")

        rm("a.html")
        rm("a.txt")
        rm("b.txt")

        previous_dir = dir
        dir = mktempdir()

        cd(dir) do
            cp(joinpath(previous_dir, "a.jl"), joinpath(dir, "a.jl"))
            cp(joinpath(previous_dir, "b.jl"), joinpath(dir, "b.jl"))

            @show readdir(previous_dir)
            @show readdir(dir)

            bo = BuildOptions(dir; previous_dir)
            parallel_build(bo)

            # a was evaluated because "a.html" was removed.
            # note that pluto always writes txt files to the first dir.
            @test read(joinpath(previous_dir, "a.txt"), String) == "a"
            @test isfile("a.html")

            # b was not evaluated because "b.html" was used from the cache.
            @test !isfile(joinpath(previous_dir, "b.txt"))
            @test isfile("b.html")
        end
    end
end
