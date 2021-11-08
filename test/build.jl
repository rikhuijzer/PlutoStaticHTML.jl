@testset "build" begin
    mktempdir() do dir
        files = map(1:2) do i
            without_extension = "file$i"
            file = "$(without_extension).jl"
            content = pluto_notebook_content("x = 3000 + $i")
            path = joinpath(dir, file)
            write(path, content)
            return file
        end
        parallel_build!(dir, files)

        html_file = joinpath(dir, "file1.html")
        @test contains(read(html_file, String), "3001")
    end
end

@testset "invalid_notebook" begin
    try
        mktempdir() do dir
            content = pluto_notebook_content("x =")
            file = "file"
            path = joinpath(dir, file)
            write(path, content)
            parallel_build!(dir, [file])
        end
        error("Test should have failed")
    catch
        @test true # Success.
    end
end
