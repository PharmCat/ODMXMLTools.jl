

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ODM}; integrity = false)
    ks = Set([:Description, :FileType, :Granularity, :Archival, :FileOID, :CreationDateTime, :PriorFileOID, :AsOfDateTime, :ODMVersion, :Originator, :SourceSystem, :SourceSystemVersion, :ID])
    for k in keys(node.attr)
        k in ks || push!(log, "$(name(node)): Unknown attribute ($(k))")
    end
    if :FileType in keys(node.attr)
        attribute(node, :FileType) in FILETYPE || push!(log, "$(name(node)): Wrong FileType")
        #other check
    else
        push!(log, "$(name(node)): No FileType attribute")
    end
    if :Granularity in keys(node.attr)
        attribute(node, :Granularity) in GRANULARITY || push!(log, "$(name(node)): Wrong Granularity")
    end
    if :Archival in keys(node.attr)
        attribute(node, :Archival) in ARCHIVAL || push!(log, "$(name(node)): Wrong Archival")
        attribute(node, :FileType) == "Transactional" || push!(log, "$(name(node)): Archival is $(attribute(node, "Archival")), but FileType not Transactional")
    end
    if :ODMVersion in keys(node.attr)
        attribute(node, :ODMVersion) in ODMVERSION || push!(log, "$(name(node)): Wrong ODMVersion")
    end
    if :FileOID ∉ keys(node.attr)
        push!(log, "$(name(node)): No FileOID")
    end
    if :CreationDateTime ∉ keys(node.attr)
        push!(log, "$(name(node)): No CreationDateTime")
    else
        #datetime
    end
    if :AsOfDateTime in keys(node.attr)
        #datetime
    end
    for i in node.el
        if name(i) ∉ Set([:Study, :AdminData, :ReferenceData, :ClinicalData, :Association, Symbol("ds:Signature")])
            push!(log, "$(name(node)): Unexpected node ($(name(i))) in body")
        end
    end
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Study}; integrity = false)
    ks = Set([:OID])
    for k in keys(node.attr)
        k in ks || push!(log, "$(name(node)) ($(attribute(node, :OID))): Unknown attribute ($(k))")
    end
    if :OID ∉ keys(node.attr)
        push!(log, "$(name(node)): No OID")
    end
    gvn = 0
    bdn = 0
    for i in node.el
        if name(i) ∉ Set([:GlobalVariables, :BasicDefinitions, :MetaDataVersion])
            push!(log, "$(name(node)) ($(attribute(node, :OID))): Unexpected node ($(name(i))) in body")
        end
        name(i) == :GlobalVariables &&  (gvn += 1)
        name(i) == :BasicDefinitions &&  (bdn += 1)
    end
    gvn == 1 || push!(log, "$(name(node)) ($(attribute(node, :OID))): GlobalVariables not 1 ($gvn)")
    bdn <= 1 || push!(log, "$(name(node)) ($(attribute(node, :OID))): BasicDefinitions more than 1 ($bdn)")
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:GlobalVariables}; integrity = false)
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
    snn = 0
    sdn = 0
    pnn = 0
    for i in node.el
        if name(i) ∉ Set([:StudyName, :StudyDescription, :ProtocolName])
            push!(log, "$(name(node)): Unexpected node ($(name(i))) in body")
        end
        name(i) == :StudyName &&  (snn += 1)
        name(i) == :StudyDescription &&  (sdn += 1)
        name(i) == :ProtocolName &&  (pnn += 1)
    end
    snn == 1 || push!(log, "$(name(node)): StudyName not 1 ($snn)")
    sdn == 1 || push!(log, "$(name(node)): StudyDescription not 1 ($sdn)")
    pnn == 1 || push!(log, "$(name(node)): ProtocolName not 1 ($pnn)")
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyName}; integrity = false)
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyDescription}; integrity = false)
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ProtocolName}; integrity = false)
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:BasicDefinitions}; integrity = false)
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MeasurementUnit}; integrity = false)
    ks = Set([:OID, :Name])
    for k in keys(node.attr)
        k in ks || push!(log, "$(name(node)): Unknown attribute ($(k))")
    end
    if :OID in keys(node.attr)
        #other check
    else
        push!(log, "$(name(node)): No OID attribute")
    end
    if :Name in keys(node.attr)
        #other check
    else
        push!(log, "$(name(node)): No Name attribute")
    end
end
#parse(DateTime, "2022-01-21T13:23:36.45", dateformat"yyyy-mm-ddTHH:MM:SS.s")
#ZonedDateTime("2022-01-21T13:23:36+00:00", "yyyy-mm-ddTHH:MM:SSzzzz")
#ZonedDateTime("2022-01-21T13:23:36.664+00:00", "yyyy-mm-ddTHH:MM:SS.s+zzzz")

# A human-readable name for a measurement unit
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Symbol}; integrity = false)
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
    ch = children(node)
    for i in ch
        if name(i) ∉ CHNS[name(node)] push!(log, "$(name(node)): Unexpected node ($(name(i))) in body") end
    end
    if countnodenames(node, :TranslatedText) < 1 push!(log, "$(name(node)): No TranslatedText node in body") end
end

#Human-readable text that is appropriate for a particular language. TranslatedText elements typically occur in a series, presenting a set of alternative textual renditions for different languages.
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:TranslatedText}; integrity = false)
    ks = Set([:lang])
    for k in keys(node.attr)
        k in ks || push!(log, "$(name(node)): Unknown attribute ($(k))")
    end
    if node.content == "" push!(log, "$(name(node)): No content is empty.") end
    for i in children(node)
        if !isa(i, ODMTextNode) push!(log, "$(name(node)): Unexpected node ($(name(i))) in body") end
    end
end

#=
An element group consists of one or more element names (or element groups) enclosed in parentheses, 
and separated with commas or vertical bars. Commas indicate that the elements (or element groups)
 must occur in the XML sequentially in the order listed in the group. Vertical bars indicate that
  exactly one of the elements (or element groups) must occur. An element or element group can be 
  followed by a ? (meaning optional), a * (meaning zero or more occurrences), or a + (meaning one or more occurrences).
=#
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MetaDataVersion}; integrity = false)
    ks = Set([:OID, :Name, :Description])
    ns = Set([:Include, :Protocol, :StudyEventDef, :FormDef, :ItemGroupDef, :ItemDef, :CodeList, :ImputationMethod, :Presentation, :ConditionDef, :MethodDef])
    for k in keys(node.attr)
        k in ks || push!(log, "$(name(node)): Unknown attribute ($(k))")
    end
    for i in node.el
        name(i) in ns || push!(log, "$(name(node)): Unknown body node ($(name(i))")
        cnt = findelements(node, :Include)
        length(cnt) > 1 && push!(log, "$(name(node)): More than 1 Include elements")
        cnt = findelements(node, :Protocol)
        length(cnt) > 1 && push!(log, "$(name(node)): More than 1 Protocol elements")
    end
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Include}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Protocol}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Description}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyEventRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyEventDef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormDef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemGroupRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemGroupDef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDef}; integrity = false)
    ks = Set([:OID, :Name, :DataType, :Length, :SignificantDigits, :SASFieldName, :SDSVarName, :Origin, :Comment])
    for k in keys(node.attr)
        k in ks || push!(log, "$(name(node)): Unknown attribute ($(k))")
    end
    if :OID in keys(node.attr)
        #other check
    else
        push!(log, "$(name(node)): No OID attribute")
    end
    if :Name in keys(node.attr)
        #other check
    else
        push!(log, "$(name(node)): No Name attribute")
    end
    if :DataType in keys(node.attr)
        attribute(node, :DataType) in DATATYPES || push!(log, "$(name(node)): Wrong DataType")
    else
        push!(log, "$(name(node)): No DataType attribute")
    end
    # Check child nodes
    nnamelist = nodenameslist(node) 
    for i in nnamelist
        if i ∉ Set([:Description, :Question, :ExternalQuestion, :MeasurementUnitRef, :RangeCheck, :CodeListRef, :Alias]) 
            push!(log, "$(name(node)): Unknown child node ($(i))")
        end
    end

    fel = findelements(node, :Description)
    if !isnothing(fel)
        if length(fel) > 1 push!(log, "$(name(node)): More than one Description elements") end
        #other check
    end

    fel = findelements(node, :Question)
    if !isnothing(fel)
        if length(fel) > 1 push!(log, "$(name(node)): More than one Question elements") end
        #other check
    end

    fel = findelements(node, :ExternalQuestion)
    if !isnothing(fel)
        if length(fel) > 1 push!(log, "$(name(node)): More than one ExternalQuestion elements") end
        #other check
    end

    fel = findelements(node, :MeasurementUnitRef)
    if !isnothing(fel)
        #other check
    end

    fel = findelements(node, :RangeCheck)
    if !isnothing(fel)
        #other check
    end

    fel = findelements(node, :CodeListRef)
    if !isnothing(fel)
        if length(fel) > 1 push!(log, "$(name(node)): More than one ExternalQuestion elements") end
        #other check
    end

    fel = findelements(node, :Alias)
    if !isnothing(fel)
        #other check
    end
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Question}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ExternalQuestion}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MeasurementUnitRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:RangeCheck}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ErrorMessage}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:CodeListRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Alias}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:CodeList}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:CodeListItem}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Decode}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ExternalCodeList}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:EnumeratedItem}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ArchiveLayout}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MethodDef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Presentation}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ConditionDef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormalExpression}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:AdminData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:User}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LoginName}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:DisplayName}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FullName}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FirstName}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LastName}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Organization}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Address}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StreetName}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:City}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StateProv}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Country}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:PostalCode}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:OtherText}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Email}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Picture}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Pager}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Fax}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Phone}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LocationRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Certificate}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Location}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MetaDataVersionRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:SignatureDef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Meaning}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LegalReason}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ReferenceData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ClinicalData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:SubjectData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyEventData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemGroupData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemData}; integrity = false)
end

#=
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataTyped}; integrity = false)
end
=#

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ArchiveLayoutRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:AuditRecord}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:UserRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:DateTimeStamp}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ReasonForChange}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:SourceID}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Signature}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:SignatureRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Annotation}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Comment}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Flag}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FlagValue}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FlagType}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:InvestigatorRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:SiteRef}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:AuditRecords}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Signatures}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Annotations}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Association}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:KeySet}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{Symbol("ds:Signature")}; integrity = false)
end

function countnodenames(node, nodename)
    cnt = 0
    ch = children(node)
    for i in ch
        if name(i) == nodename cnt += 1 end
    end
    cnt
end

function nodenameslist(node)
    set = Set{Symbol}()
    ch = children(node)
    for i in ch 
        push!(set, name(i))
    end
    set
end

function existchildtextnode(node)
    for i in children(node)
        if isa(i, ODMTextNode) return true end
    end
    false
end

function validateodm_!(log::AbstractVector, root::ODMRoot, node::AbstractODMNode)
    checknode!(log, root, node, ODMNodeType(name(node)))
    for i in node.el
        validateodm_!(log, root, i)
    end
end

"""
    validateodm(odm::ODMRoot)

Basic structure validation.

!!! warning
    Not full implemented.

"""
function validateodm(odm::ODMRoot)
    log = String[]
    validateodm_!(log, odm, odm)
    log
end


"""
    checkdatavalues(odm::ODMRoot)

Check all data values in all ClinicalData sections.

!!! warning
    Not full implemented.
"""
function checkdatavalues(odm::ODMRoot)
    cld  = findclinicaldata(odm)
    log = []
    for cldv in cld
        mdv = buildmetadata(odm, attribute(cldv, :StudyOID), attribute(cldv, :MetaDataVersionOID))
        idd = defdict(mdv, :ItemDef)
        cldd = defdict(mdv, :CodeList)
        for s in cldv.el
            if isSubjectData(s)
                for e in s.el
                    if isStudyEventData(e) 
                        for f in e.el
                            if isFormData(f)
                                for g in f.el
                                    if isItemGroupData(g)
                                        for i in g.el
                                            if isItemData(i) || isItemDataType(i)
                                                if isItemData(i)
                                                    val = attribute(i, :Value)
                                                else
                                                    val = content(i)
                                                end
                                                ain = attribute(i, :IsNull)
                                                if !ismissing(ain) && ain == "Yes" && val != ""
                                                    pushlog!(log, :WARN, s, e, f, g, i, "Attribute `IsNull` set `Yes`, but value not empty")
                                                end
                                                if attribute(i, :ItemOID) ∉ keys(idd)
                                                    pushlog!(log, :ERROR, s, e, f, g, i, "ItemOID not found in ItemRef list.")
                                                    continue
                                                end
                                                idef = idd[attribute(i, :ItemOID)]
                                                itype = attribute(idef, :DataType)
                                                if isItemDataType(i)
                                                    msg = ""
                                                    if name(i) == :ItemDataAny
	                                                elseif name(i) == :ItemDataString
                                                        if itype != "string" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataInteger
                                                        if itype != "integer" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataFloat
                                                        if itype != "float" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataDate
                                                        if itype != "date" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataTime
                                                        if itype != "time" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataDatetime
                                                        if itype != "datetime" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataBoolean
                                                        if itype != "boolean" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataHexBinary
                                                        if itype != "hexBinary" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataBase64Binary
                                                        if itype != "base64Binary" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataHexFloat
                                                        if itype != "hexFloat" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataBase64Float
                                                        if itype != "base64Float" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataPartialDate
                                                        if itype != "partialDate" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataPartialTime
                                                        if itype != "partialTime" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataPartialDatetime
                                                        if itype != "partialDatetime" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataDurationDatetime
                                                        if itype != "durationDatetime" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataIntervalDatetime
                                                        if itype != "intervalDatetime" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataIncompleteDatetime
                                                        if itype != "incompleteDatetime" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataIncompleteDate
                                                        if itype != "incompleteDate" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataIncompleteTime
                                                        if itype != "incompleteTime" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    elseif name(i) == :ItemDataURI
                                                        if itype != "URI" msg = "DataType inconsistent: $(name(i)) != $itype" end
                                                    end
                                                    if msg != ""
                                                        pushlog!(log, :WARN, s, e, f, g, i, msg)
                                                    end
                                                end
                                                if itype == "integer"
                                                    pval = tryparse(Int, val)
                                                elseif itype == "float" || itype == "double" 
                                                    pval = tryparse(Float64, val)
                                                elseif itype == "boolean"
                                                    pval = tryparse(Bool, "false")
                                                else
                                                    pval = ""
                                                end
                                                if isnothing(pval)
                                                    pushlog!(log, :WARN, s, e, f, g, i, "DataType is $(itype), but value `$val` can't be parsed.")
                                                end
                                                clr = findelement(idef, :CodeListRef)
                                                if !isnothing(clr)
                                                    cld = cldd[attribute(clr, :CodeListOID)]
                                                    if attribute(cld, :DataType) != itype
                                                        pushlog!(log, :ERROR, s, e, f, g, i, "ItemDef DataType ($(itype)) not equal CodeList's DataType ($(attribute(cld, :DataType))).")
                                                    end
                                                    cvs = codedvalueset(cld)
                                                    if length(cvs) > 0
                                                        if val ∉ cvs
                                                            pushlog!(log, :WARN, s, e, f, g, i, "Value ($(val)) not in CodeListItem's CodedValue set.")
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    log
end


function defdict(mdv, nname)
    d = Dict{String, ODMNode}()
    for i in mdv.el
        if name(i) == nname
            d[attribute(i, :OID)] = i
        end
    end
    d
end

function codedvalueset(n)
    s = Set{String}()
    for i in n.el
        if name(n) == :CodeListItem
            push!(s, attribute(i, :CodedValue))
        end
    end
    s
end


function pushlog!(log, t, s, e, f, g, i, msg)
    push!(log, (t, 
    attribute(s, :SubjectKey),
    attribute(e, :StudyEventOID),
    attribute(e, :StudyEventRepeatKey),
    attribute(f, :FormOID),
    attribute(f, :FormRepeatKey),
    attribute(g, :ItemGroupOID),
    attribute(g, :ItemGroupRepeatKey),
    attribute(i, :ItemOID),
    msg))
end
