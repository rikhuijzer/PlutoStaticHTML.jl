"""
    parallel_build!(dir, files; print_log=true)

Build HTML files in parallel and write output to files with a ".html" extension.
This can be useful to speed up the build in CI.
"""
function parallel_build!(dir, files; print_log=true)
    session = ServerSession()
    H = Vector{String}(undef, length(files))

    # The static schedule creates one task per thread.
    Threads.@threads :static for i in 1:length(files)
        in_file = files[i]
        in_path = joinpath(dir, in_file)
        @assert isfile(in_path) "Expected file at $in_path"

        @info "→ evaluating Pluto notebook at ($in_file)"
        html = notebook2html(in_path; session)
        H[i] = html
    end

    for i in 1:length(files)
        in_file = files[i]
        without_extension, _ = splitext(in_file)
        out_file = "$(without_extension).html"
        out_path = joinpath(dir, out_file)

        html = H[i]
        write(out_path, html)
    end

    return nothing
end

function parallel_build!(dir; print_log=true)
    files = filter(endswith(".jl"), readdir(dir))
    parallel_build!(dir, files; print_log)
    return nothing
end
