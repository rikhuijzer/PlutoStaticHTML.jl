include("preliminaries.jl")

const TIMEROUTPUT = TimerOutput()

@timed_testset "pdf" begin
    include("pdf.jl")
end

@timed_testset "context" begin
    include("context.jl")
end

@timed_testset "cache" begin
    include("cache.jl")
end

@timed_testset "mimeoverride" begin
    include("mimeoverride.jl")
end

@timed_testset "with_terminal" begin
    include("with_terminal.jl")
end

@timed_testset "html" begin
    include("html.jl")
end

@timed_testset "style" begin
    include("style.jl")
end

@timed_testset "build" begin
    include("build.jl")
end

@timed_testset "aqua" begin
    Aqua.test_all(PlutoStaticHTML; ambiguities=false)
end

show(TIMEROUTPUT; compact=true, sortby=:firstexec)
