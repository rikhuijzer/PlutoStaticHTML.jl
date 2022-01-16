include("preliminaries.jl")

include("context.jl")
include("cache.jl")
include("html.jl")
include("build.jl")
include("htmltypes.jl")

@testset "dynamic" begin
    include("dynamic.jl")
end
