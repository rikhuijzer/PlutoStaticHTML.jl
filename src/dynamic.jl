
"Temporary function for development purposes"
function __build()
    dir = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
    file = "dynamic.jl"

    bopts = BuildOptions(dir; use_distributed=false)
    htmls = parallel_build(bopts, [file])
    html = only(htmls)
    return html
end

