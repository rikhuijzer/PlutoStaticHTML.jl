"""
    parallel_build!(dir, files; print_log=true)

Build HTML files in parallel and write output to files with a ".html" extension.
This can be useful to speed up the build in CI.
"""
function parallel_build!(dir, files; print_log=true)
    # The static schedule creates one task per thread.
    Threads.@threads :static for in_file in files
        without_extension, _ = splitext(in_file)
        in_path = joinpath(dir, in_file)
        @assert isfile(in_path) "Expected file at $in_path"
        out_file = "$(without_extension).html"
        out_path = joinpath(dir, out_file)
        log_file = "$(without_extension).log"
        log_path = joinpath(dir, log_file)

        @info "→ evaluating Pluto notebook at ($in_file)"
        open(log_path, "w") do io
            redirect_stdout(io) do
                # Can't run notebook2html in parallel without multithreading issues.
                # Need to improve the function, but for now this should work.
                # Also can't use IOCapture.jl because it hangs.
                ex = """
                    using PlutoStaticHTML;
                    notebook2html("$in_path", "$out_path")
                    """
                cmd = `$(Base.julia_cmd()) --project -e $ex`
                run(cmd)
            end
        end
        if print_log
            print(read(log_path, String))
        end
    end
end
