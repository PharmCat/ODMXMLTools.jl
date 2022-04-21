

function oclformdetailslist(md)
    fl = findelements(md, :FormDef)
    df = DataFrame(OID = String[], Name = String[], Repeating = String[],
    ParentFormOID = String[], SectionLabel = String[], SectionTitle = String[], SectionSubtitle = String[], SectionInstructions = String[], SectionPageNumber = String[])
    for i in fl
        el = findelement(i, :FormDetails)
        if !(isnothing(el))
            pfoid  = attribute(el, "ParentFormOID")
            secdet = findelement(el, :SectionDetails)
            sec    = findelements(secdet, :Section)
            for s in sec
                seclab = attribute(s, "SectionLabel")
                sectit = attribute(s, "SectionTitle")
                secsubt = attribute(s, "SectionSubtitle")
                secinst = attribute(s, "SectionInstructions")
                secpn = attribute(s, "SectionPageNumber")
                push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating"), pfoid, seclab, sectit, secsubt, secinst, secpn))
            end
        else
            pfoid = ""
            seclab = ""
            sectit = ""
            secsubt = ""
            secinst = ""
            secpn = ""
            push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating"), pfoid, seclab, sectit, secsubt, secinst, secpn))
        end
    end
    df
end
