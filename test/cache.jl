@testset "prefix" begin
    version = VERSION
    text = repeat("foobar\n", 100)
    html = string(PlutoStaticHTML.State(text)) * text
    state = PlutoStaticHTML.State(html)
    @test state.input_sha == PlutoStaticHTML.sha(html)
    @test state.julia_version == string(VERSION)
end

function try_read(file)::String
    for i in 1:100
        try
            return read(file, String)
        catch
            sleep(0.2)
        end
    end
    # Throw original error if still no success.
    read(file, String)
end

function try_rm(file)
    for i in 1:100
        try
            return rm(file)
        catch
            sleep(0.2)
        end
    end
    # Throw original error if still no success.
    rm(file)
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
        write("a.jl", code)

        code = pluto_notebook_content("""write("$(path('b'))", "b")""")
        write("b.jl", code)

        bo = BuildOptions(dir)
        parallel_build(bo)

        # Without try_read, Pluto in another process may still have a lock on a txt file.
        @test try_read("a.txt") == "a"
        try_read("a.html")
        @test try_read("b.txt") == "b"
        try_read("b.html")

        try_rm("a.html")
        try_rm("a.txt")
        try_rm("b.txt")

        previous_dir = dir
        dir = mktempdir()

        cd(dir) do
            cp(joinpath(previous_dir, "a.jl"), joinpath(dir, "a.jl"))
            cp(joinpath(previous_dir, "b.jl"), joinpath(dir, "b.jl"))

            bo = BuildOptions(dir; previous_dir)
            parallel_build(bo)

            # a was evaluated because "a.html" was removed.
            # note that pluto always writes txt files to the first dir.
            @test try_read(joinpath(previous_dir, "a.txt")) == "a"
            try_read("a.html")

            # b was not evaluated because "b.html" was used from the cache.
            @test !isfile(joinpath(previous_dir, "b.txt"))
            try_read("b.html")
        end
    end
end
