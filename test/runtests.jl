include("preliminaries.jl")

include("context.jl")
include("cache.jl")

@testset "mimeoverride" begin
    include("mimeoverride.jl")
end

@testset "html" begin
    include("html.jl")
end

include("build.jl")

