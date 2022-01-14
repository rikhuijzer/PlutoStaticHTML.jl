
"Temporary function for development purposes"
function __build()
    dir = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")

    bopts = BuildOptions(dir; use_distributed=false)
    htmls = parallel_build(bopts, ["dynamic.jl"])
    html = only(htmls)
    return html
end
