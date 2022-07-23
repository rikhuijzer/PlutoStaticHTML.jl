@testset "build" begin
    mktempdir() do dir
        files = map(1:2) do i
            without_extension = "file$i"
            file = "$(without_extension).jl"
            content = pluto_notebook_content("""
                x = begin
                    sleep(3)
                    x = 3000 + $i
                end
                """)
            path = joinpath(dir, file)
            write(path, content)
            return file
        end
        build_notebooks(BuildOptions(dir, use_distributed=false))

        html_file = joinpath(dir, "file1.html")
        @test contains(read(html_file, String), "3001")

        html_file = joinpath(dir, "file2.html")
        @test contains(read(html_file, String), "3002")
    end
end

@testset "is_pluto_file" begin
    cd(mktempdir()) do
        nb_text = """
            ### A Pluto.jl notebook ###
            # v0.14.0
            """
        write("true.jl", nb_text)
        @test PlutoStaticHTML._is_pluto_file("true.jl")

        jl_text = """
            module Foo
            end # module
            """
        write("false.jl", jl_text)
        @test !PlutoStaticHTML._is_pluto_file("false.jl")
    end
end

@testset "invalid_notebook" begin
    try
        mktempdir() do dir
            content = pluto_notebook_content("@assert false")
            file = "file.jl"
            path = joinpath(dir, file)
            write(path, content)
            build_notebooks(BuildOptions(dir), [file], use_distributed=false)
        end
        error("Test should have failed")
    catch AssertionError
        @test true # Success.
    end
end

@testset "extract_previous_output" begin
    # function extract_previous_output(html::AbstractString)::String
    html = """
        lorem
        $(PlutoStaticHTML.BEGIN_IDENTIFIER)
        ipsum
        $(PlutoStaticHTML.END_IDENTIFIER)
        dolar
        """
    actual = PlutoStaticHTML.extract_previous_output(html)
    expected = """
        $(PlutoStaticHTML.BEGIN_IDENTIFIER)
        ipsum
        $(PlutoStaticHTML.END_IDENTIFIER)
        """
    @test strip(actual) == strip(expected)
end

@testset "add_documenter_css" begin
    for add_documenter_css in (true, false)
        dir = mktempdir()
        cd(dir) do
            path = joinpath(dir, "notebook.jl")
            code = pluto_notebook_content("""
                x = 1
                """)
            write(path, code)

            use_distributed = false
            output_format = documenter_output
            bo = BuildOptions(dir; use_distributed, output_format, add_documenter_css)
            build_notebooks(bo)

            output_path = joinpath(dir, "notebook.md")
            lines = readlines(output_path)
            if add_documenter_css
                @test lines[2] == "<style>"
            else
                @test lines[2] != "<style>"
            end
        end
    end
end

@testset "EditURL" begin
    dir = joinpath(pkgdir(PlutoStaticHTML), "docs", "src", "notebooks")
    bopts = BuildOptions(dir)
    in_path = "example.jl"
    kv = [
        "GITHUB_REPOSITORY" => "",
        "GITHUB_REF" => ""
    ]
    withenv(kv...) do
        @test PlutoStaticHTML._editurl_text(bopts, in_path) == ""
    end

    kv = [
        "GITHUB_REPOSITORY" => "rikhuijzer/PlutoStaticHTML.jl",
        "GITHUB_REF" => "refs/heads/main"
    ]
    withenv(kv...) do
        url = "https://github.com/rikhuijzer/PlutoStaticHTML.jl/blob/main/docs/src/notebooks/example.jl"
        @test strip(PlutoStaticHTML._editurl_text(bopts, in_path)) == strip("""
            ```@meta
            EditURL = "$url"
            ```
            """)
    end
end

@testset "Fix header links" begin
    expected = """
        ```
        ## Admonitons
        ```@raw html
        <div class="markdown">
        """
    @test PlutoStaticHTML._fix_header_links("""<div class="markdown"><h2>Admonitons</h2>""") == expected
    @test PlutoStaticHTML._fix_header_links("") == ""

    mktempdir() do dir
        cd(dir) do
            path = joinpath(dir, "notebook.jl")
            code = pluto_notebook_content("""
                md"## Some header"
                """)
            write(path, code)
            use_distributed = false
            output_format = documenter_output
            bo = BuildOptions(dir; use_distributed, output_format)
            build_notebooks(bo)

            output_path = joinpath(dir, "notebook.md")
            output = read(output_path, String)
            @test contains(output, "## Some header")
        end
    end
end

@testset "Elapsed time" begin
    n = now()
    sleep(1)
    n2 = now()
    @test PlutoStaticHTML._pretty_elapsed(n2 - n) == "1 second"
    sleep(1)
    n2 = now()
    @test PlutoStaticHTML._pretty_elapsed(n2 - n) == "2 seconds"
end

nothing
