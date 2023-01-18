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
                "Study" => ".//odm//study.md",
                "MetaDataVersion" => ".//odm//metadata.md",
                "StudyEventDef" => ".//odm//event.md",
                "FormDef" => ".//odm//form.md",
                "ItemGroupDef" => ".//odm//itemgroup.md",
                "ItemDef" => ".//odm//item.md",
                "ClinicalData"=>".//odm//clinicaldata.md"],
            "API" => "api.md"
            ],
        )

deploydocs(repo = "github.com/PharmCat/ODMXMLTools.jl.git", devbranch = "main", forcepush = true
)
