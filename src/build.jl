function _default_n_threads()
    if "JULIA_NUM_THREADS" in keys(ENV)
        return parse(Int, ENV["JULIA_NUM_THREADS"])
    else
        return nothing
    end
end

"""
    parallel_build!(dir, files; n_threads=_default_n_threads())

Build HTML files in parallel and write output to files with a ".html" extension.
This can be useful to speed up the build in CI.
"""
function parallel_build!(dir, files; n_threads=_default_n_threads())
    if isnothing(n_threads)
        error("Specify number of threads via JULIA_NUM_THREADS or `n_threads`")
    end
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
    end
end
