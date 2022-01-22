include("preliminaries.jl")

include("context.jl")
include("cache.jl")
include("html.jl")
include("build.jl")

@testset "possibilities" begin
    include("possibilities.jl")
end

@testset "dynamic" begin
    include("dynamic.jl")
end
