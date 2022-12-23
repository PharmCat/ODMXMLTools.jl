

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType)
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ODM})
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

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Study})
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

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:GlobalVariables})
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

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:StudyName})
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:StudyDescription})
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ProtocolName})
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:BasicDefinitions})
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
end
function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:MeasurementUnit})
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
function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Symbol})
    length(node.attr) == 0 || push!(log, "$(name(node)): Unknown attribute(s) - $(keys(node.attr))")
    ch = children(node)
    for i in ch
        if name(i) ∉ CHNS[name(node)] push!(log, "$(name(node)): Unexpected node ($(name(i))) in body") end
    end
    if countnodenames(node, :TranslatedText) < 1 push!(log, "$(name(node)): No TranslatedText node in body") end
end

#Human-readable text that is appropriate for a particular language. TranslatedText elements typically occur in a series, presenting a set of alternative textual renditions for different languages.
function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:TranslatedText})
    ks = Set([Symbol("xml:lang")])
    for k in keys(node.attr)
        k in ks || push!(log, "$(name(node)): Unknown attribute ($(k))")
    end
    if !existchildtextnode(node) push!(log, "$(name(node)): No text node in body") end
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
function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:MetaDataVersion})
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

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Include})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Protocol})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Description})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:StudyEventRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:StudyEventDef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FormRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FormDef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ItemGroupRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ItemGroupDef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ItemRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ItemDef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Question})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ExternalQuestion})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:MeasurementUnitRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:RangeCheck})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ErrorMessage})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:CodeListRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Alias})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:CodeList})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:CodeListItem})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Decode})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ExternalCodeList})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:EnumeratedItem})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ArchiveLayout})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:MethodDef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Presentation})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ConditionDef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FormalExpression})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:AdminData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:User})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:LoginName})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:DisplayName})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FullName})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FirstName})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:LastName})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Organization})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Address})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:StreetName})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:City})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:StateProv})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Country})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:PostalCode})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:OtherText})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Email})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Picture})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Pager})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Fax})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Phone})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:LocationRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Certificate})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Location})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:MetaDataVersionRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:SignatureDef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Meaning})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:LegalReason})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ReferenceData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ClinicalData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:SubjectData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:StudyEventData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FormData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ItemGroupData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ItemData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ItemData})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ArchiveLayoutRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:AuditRecord})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:UserRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:DateTimeStamp})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:ReasonForChange})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:SourceID})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Signature})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:SignatureRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Annotation})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Comment})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Flag})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FlagValue})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:FlagType})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:InvestigatorRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:SiteRef})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:AuditRecords})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Signatures})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Annotations})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:Association})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:KeySet})
end

function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{Symbol("ds:Signature")})
end

function countnodenames(node, nodename)
    cnt = 0
    ch = children(node)
    for i in ch
        if name(i) == nodename cnt += 1 end
    end
    cnt
end
function existchildtextnode(node)
    for i in children(node)
        if isa(i, ODMTextNode) return true end
    end
    false
end


function validateodm_(log::AbstractVector, node::AbstractODMNode)
    checknode!(log, node, ODMNodeType(name(node)))
    for i in node.el
        validateodm_(log, i)
    end
end
function validateodm_(log::AbstractVector, node::ODMTextNode)
end
function validateodm(odm::ODMRoot)
    log = String[]
    validateodm_(log, odm)
    log
end
