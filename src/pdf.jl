function tectonic_bin()
    return joinpath(artifact"tectonic", "bin", "tectonic")
end

function tectonic_version()
    bin = tectonic_bin()
    return read(`$bin --version`, String)
end
