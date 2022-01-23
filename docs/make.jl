using ODMXMLTools
using Documenter


makedocs(
        modules = [ODMXMLTools],
        sitename = "ODMXMLTools.jl",
        authors = "Vladimir Arnautov",
        pages = [
            "Home" => "index.md",
            ],
        )

deploydocs(repo = "github.com/PharmCat/ODMXMLTools.jl.git", devbranch = "main", forcepush = true
)
