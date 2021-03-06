

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


function checknode!(log::AbstractVector, node::AbstractODMNode, type::ODMNodeType{:MetaDataVersion})

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
