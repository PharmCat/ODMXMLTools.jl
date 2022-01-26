

struct SPSSExport
    df::DataFrame
    code::String
end
#=
function spssexportbyitemgroup(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

    cld    = findclinicaldata(odm, soid, moid)
    bmd    = buildmetadata(odm, soid, moid)
    cldtab = clinicaldatatable(cld)
    evlist = eventlist(bmd)
    iglist = itemgrouplist(bmd; optional = true)
    items  = itemlist(bmd; optional = true)
    ############################################################################
code   = """GET
FILE='filename.sav'.
DATASET NAME main WINDOW=FRONT.
"""
    uiglist = unique(cldtab[!, :ItemGroupOID])

    leftjoin!(cldtab, items[!, ["OID", "SASFieldName"]]; on = "ItemOID" => "OID")

    for ig in eachrow(iglist)
        if ig[:OID] in uiglist
            igc = itemgroupcontent(bmd, ig.OID; optional = true)
            code *= """
DATASET ACTIVATE main.
DATASET COPY sample WINDOW=HIDDEN.
DATASET ACTIVATE sample.
SELECT IF (ItemGroupOID = '$(ig[:OID])').
EXECUTE.
RENAME VARIABLE (ItemOID = IOID).

SORT CASES BY SubjectKey StudyEventOID IOID.
CASESTOVARS
  /ID=SubjectKey StudyEventOID
  /INDEX=IOID
  /GROUPBY=VARIABLE.

"""
            for i in eachrow(igc)
                code *= """RENAME VARIABLE (Value.$(i.OID) = $(i.SASFieldName)).\n"""
            end
            code *= """VARIABLE LABELS"""
            for i in eachrow(igc)
                code *= """\n $(i.SASFieldName) '$(i.Comment)'"""
            end
            code *= """.\n"""
            for i in eachrow(igc)
                itemdef = findelement(bmd, :ItemDef, i.OID)
                if countelements(itemdef, :CodeListRef) > 0
                    codelist = findelements(itemdef, :CodeListRef)
                    code *= """VALUE LABELS $(i.SASFieldName)"""
                    for cl in codelist
                        cldef = findelement(bmd, :CodeList, attribute(cl, "CodeListOID"))
                        for clel in cldef.el
                            if name(clel) == :CodeListItem
                                code *= """\n '$(attribute(clel, "CodedValue"))' '$(findelement(findelement(clel, :Decode), :TranslatedText).el[1].content)'"""
                            end
                        end
                    end
                    code *= """.\n"""
                end
            end
            code *= """SAVE OUTFILE=
    '$(ig[:OID]).sav'
  /COMPRESSED.
DATASET CLOSE sample. \n"""
        end
    end

    SPSSExport(cldtab, code)
end
=#
