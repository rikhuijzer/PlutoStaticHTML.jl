@testset "build" begin
    mktempdir() do dir
        files = map(1:2) do i
            without_extension = "file$i"
            file = "$(without_extension).jl"
            content = pluto_notebook_content("x = begin sleep(3); x = 3000 + $i; end")
            path = joinpath(dir, file)
            write(path, content)
            return file
        end
        parallel_build(dir)

        html_file = joinpath(dir, "file1.html")
        @test contains(read(html_file, String), "3001")

        html_file = joinpath(dir, "file2.html")
        @test contains(read(html_file, String), "3002")
    end
end

@testset "invalid_notebook" begin
    try
        mktempdir() do dir
            content = pluto_notebook_content("@assert false")
            file = "file.jl"
            path = joinpath(dir, file)
            write(path, content)
            parallel_build(dir, [file])
        end
        error("Test should have failed")
    catch AssertionError
        @test true # Success.
    end
end
