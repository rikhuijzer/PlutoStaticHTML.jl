using Pkg;
Pkg.activate(; temp=true)
Pkg.add("LiveServer")

ENV["DISABLE_NOTEBOOK_BUILD"] = true

using LiveServer

PKGDIR = @__DIR__

Pkg.activate(joinpath(PKGDIR, "docs"))

dir = joinpath(PKGDIR, "docs", "src")

function build_docs()
    println("Running docs/make.jl")
    include(joinpath(PKGDIR, "docs", "make.jl"))
end

function custom_callback(file::AbstractString)
    if endswith(file, ".jl")
        build_docs()
    end
    LiveServer.file_changed_callback(file)
end

function custom_simplewatcher(dir)
    # The callback, defined by LiveServer.jl, receives a file.
    cb(file) = custom_callback(file)
    sw = LiveServer.SimpleWatcher(cb)

    src_dir = joinpath(PKGDIR, "src")
    for path in readdir(src_dir; join=true)
        println("Watching $path")
        LiveServer.watch_file!(sw, path)
    end
    return sw
end

fw = custom_simplewatcher(dir)

build_dir = joinpath(PKGDIR, "docs", "build")
serve(fw; dir=build_dir)
