using ClearMethods
using Documenter

makedocs(;
    modules=[ClearMethods],
    authors="Qi Zhang <singularitti@outlook.com>",
    repo="https://github.com/singularitti/ClearMethods.jl/blob/{commit}{path}#L{line}",
    sitename="ClearMethods.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://singularitti.github.io/ClearMethods.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/singularitti/ClearMethods.jl",
)
