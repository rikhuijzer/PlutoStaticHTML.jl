
function _inject_into_head(html, script)
    h = firstindex("</head>")
    isnothing(h) && error("Couldn't find </head>")
    start = first(h)
    before = html[1:start]
    after = html[start+1:end]
end

"Temporary function for development purposes"
function __build()
    dir = joinpath(pkgdir(PlutoStaticHTML), "docs", "src")
    file = "dynamic.jl"

    bopts = BuildOptions(dir; use_distributed=false)
    htmls = parallel_build(bopts, [file])
    html = only(htmls)

    html = html * """\n
        <script>
        console.log("bar")
        </script>
        """
    return html
end

