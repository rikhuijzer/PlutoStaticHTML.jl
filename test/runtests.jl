include("preliminaries.jl")

include("context.jl")
include("cache.jl")

@testset "html" begin
    include("html.jl")
end

include("build.jl")

@testset "possibilities" begin
    include("possibilities.jl")
end

@testset "dynamic" begin
    include("dynamic.jl")
end
