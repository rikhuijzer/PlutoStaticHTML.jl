using PackageCompiler: create_sysimage
using TestEnv: TestEnv
using Pkg: Pkg

const PKGDIR = string(dirname(@__DIR__))::String

Pkg.activate(PKGDIR)
TestEnv.activate()

pkgs = [pair.second for pair in Pkg.dependencies()]
filter!(p -> p.name != "PlutoStaticHTML", pkgs)
pkg_names = getproperty.(pkgs, :name)

function pkginfo2pkgspec(info)
    return Pkg.PackageSpec(; info.name, info.version)
end

pkg_specs = pkginfo2pkgspec.(pkgs)

# We need to explicitly install all packages to make them available to PackageCompiler.
Pkg.activate(; temp=true)
Pkg.add(pkg_specs)
Pkg.develop(; path=PKGDIR)

sysimage_path = joinpath(@__DIR__, "img.so")

precompile_execution_code = """
    using Pkg: Pkg
    Pkg.activate("$PKGDIR")
    try
        include(joinpath("$PKGDIR", "test", "runtests.jl"))
    catch e
        @warn "Failed to run all tests" exception=(e, catch_backtrace())
    end
    """

precompile_execution_file = let
    path, _ = mktemp()
    write(path, precompile_execution_code)
    path
end

create_sysimage(pkg_names; sysimage_path, precompile_execution_file)

println("Wrote sysimage to $sysimage_path")
