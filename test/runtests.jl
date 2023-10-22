include("preliminaries.jl")

@testset "pdf" begin
    include("pdf.jl")
end

@testset "context" begin
    include("context.jl")
end

@testset "cache" begin
    include("cache.jl")
end

@testset "mimeoverride" begin
    include("mimeoverride.jl")
end

@testset "with_terminal" begin
    include("with_terminal.jl")
end

@testset "html" begin
    include("html.jl")
end

@testset "style" begin
    include("style.jl")
end

@testset "build" begin
    include("build.jl")
end

@testset "aqua" begin
    Aqua.test_all(PlutoStaticHTML; ambiguities=false)
end
