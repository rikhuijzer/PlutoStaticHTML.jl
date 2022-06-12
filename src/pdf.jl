function run_tectonic(args::Vector)
    out = IOBuffer()
    err = IOBuffer()
    tectonic() do bin
        process = run(pipeline(`$bin $args`; stdout=out, stderr=err))
        stdout = read(out, String)
        stderr = read(err, String)
        exitcode = process.exitcode
        return (; exitcode, stdout, stderr)
    end
end

function tectonic_version()
end
