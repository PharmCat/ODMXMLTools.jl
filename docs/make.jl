using ODMXMLTools
using Documenter


makedocs(
        modules = [ODMXMLTools],
        sitename = "ODMXMLTools.jl",
        authors = "Vladimir Arnautov",
        pages = [
            "Home" => "index.md",
            "Examples" => "examples.md",
            "ODM" => [
                "ODM" => ".//odm//odm.md",
                "Form" => ".//odm//form.md",
                "ItemGroup" => ".//odm//itemgroup.md",
                "Item" => ".//odm//item.md",
                "ClinicalData"=>".//odm//clinicaldata.md"],
            "API" => "api.md"
            ],
        )

deploydocs(repo = "github.com/PharmCat/ODMXMLTools.jl.git", devbranch = "main", forcepush = true
)
