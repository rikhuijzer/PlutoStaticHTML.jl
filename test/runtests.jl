include("preliminaries.jl")

const TIMEROUTPUT = TimerOutput()

@timed_testset "context" begin
    include("context.jl")
end

@timed_testset "cache" begin
    include("cache.jl")
end

@timed_testset "mimeoverride" begin
    include("mimeoverride.jl")
end

@timed_testset "html" begin
    include("html.jl")
end

@timed_testset "build" begin
    include("build.jl")
end

show(TIMEROUTPUT; compact=true, sortby=:firstexec)
