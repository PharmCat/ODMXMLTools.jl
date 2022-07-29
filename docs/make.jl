using ODMXMLTools
using Documenter


makedocs(
        modules = [ODMXMLTools],
        sitename = "ODMXMLTools.jl",
        authors = "Vladimir Arnautov",
        pages = [
            "Home" => "index.md",
            "Examples" => "examples.md",
            "ODM" => ["Form" => "form.md",
                "ItemGroup" => "itemgroup.md",
                "Item" => "item.md"],
            "API" => "api.md"
            ],
        )

deploydocs(repo = "github.com/PharmCat/ODMXMLTools.jl.git", devbranch = "main", forcepush = true
)
