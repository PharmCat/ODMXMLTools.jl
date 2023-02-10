
function checkattrs!(log, node, attrs, attrsref)
    for r in attrsref
        if !(r[1] in attrs) && r[2] == :! push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Attribute $(r[1]) not found.") end
    end
    for a in attrs
        found = false
        for r in attrsref
            if a == r[1] found = true end
        end
        if !found push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Unexpected attribute: $(a)") end
    end
end

function checkelements!(log, node, r)
    cnt = countelements(node, r[1])
    if r[2] == :! && cnt != 1 
        push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child ($(r[1])) elements count: $cnt != 1.") 
        return false
    elseif r[2] == :? && cnt > 1  
        push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child ($(r[1])) elements count: $cnt > 1.") 
        return false
    elseif r[2] == :+ && cnt == 0
        push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child ($(r[1])) elements count: $cnt < 1.") 
        return false 
    end
    true
end

function checkchlds!(log, node, chlds, chldsref::AbstractVector)
    for r in chldsref
        if isa(r, NodeXOR)
            nxor = falses(length(r.val))
            for xr = 1:length(r.val)
                nxor[xr] = checkelements!([], node, r.val[xr])
            end
            if !xor(nxor...)
                str = ""
                for nx = 1:length(nxor) 
                    if nxor[nx] 
                        str *= bcvecstr(r.val[nx])*": met. "
                    end
                end
                push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child elements. More than one condition met from XOR list - "*str)
            else
                if !any(nxor)
                    push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child elements. No elements found.")
                end
            end

        else
            checkelements!(log, node, r)
        end 
    end
    for c in chlds
        found = false
        for r in chldsref
            if isa(r, NodeXOR)
                for xr in r.val
                    if name(c) == xr[1] found = true 
                        break
                    end
                end
            else
                if name(c) == r[1] found = true 
                    break
                end
            end
        end
        if !found push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Unexpected child node: $(name(c))") end
    end
end
function checkchlds!(log, node, chlds, chldsref::String)
    if length(chlds) > 0
        push!(log, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Unexpected child node, $chldsref expected.") 
    end
end



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
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:GlobalVariables}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyDescription}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ProtocolName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:BasicDefinitions}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MeasurementUnit}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
#parse(DateTime, "2022-01-21T13:23:36.45", dateformat"yyyy-mm-ddTHH:MM:SS.s")
#ZonedDateTime("2022-01-21T13:23:36+00:00", "yyyy-mm-ddTHH:MM:SSzzzz")
#ZonedDateTime("2022-01-21T13:23:36.664+00:00", "yyyy-mm-ddTHH:MM:SS.s+zzzz")

# A human-readable name for a measurement unit
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Symbol}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

#Human-readable text that is appropriate for a particular language. TranslatedText elements typically occur in a series, presenting a set of alternative textual renditions for different languages.
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:TranslatedText}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

#=
An element group consists of one or more element names (or element groups) enclosed in parentheses, 
and separated with commas or vertical bars. Commas indicate that the elements (or element groups)
 must occur in the XML sequentially in the order listed in the group. Vertical bars indicate that
  exactly one of the elements (or element groups) must occur. An element or element group can be 
  followed by a ? (meaning optional), a * (meaning zero or more occurrences), or a + (meaning one or more occurrences).
=#
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MetaDataVersion}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Include}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Protocol}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Description}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyEventRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyEventDef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormDef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemGroupRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemGroupDef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDef}; integrity = false)   
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)

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
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ExternalQuestion}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MeasurementUnitRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:RangeCheck}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ErrorMessage}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:CodeListRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Alias}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:CodeList}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:CodeListItem}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Decode}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ExternalCodeList}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:EnumeratedItem}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ArchiveLayout}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MethodDef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Presentation}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ConditionDef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormalExpression}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:AdminData}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:User}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LoginName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:DisplayName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FullName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FirstName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LastName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Organization}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Address}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StreetName}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:City}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StateProv}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Country}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:PostalCode}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:OtherText}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Email}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Picture}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Pager}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Fax}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Phone}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LocationRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Certificate}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Location}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:MetaDataVersionRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:SignatureDef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:Meaning}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:LegalReason}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ReferenceData}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ClinicalData}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:SubjectData}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:StudyEventData}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:FormData}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemGroupData}; integrity = false)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemData}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataAny}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataString}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataInteger}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataFloat}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataDate}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataTime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataDatetime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataBoolean}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataHexBinary}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataBase64Binary}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataHexFloat}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataBase64Float}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataPartialDate}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataPartialTime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataPartialDatetime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataDurationDatetime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataIntervalDatetime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataIncompleteDatetime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataIncompleteDate}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataIncompleteTime}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ItemDataURI}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end
function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:ArchiveLayoutRef}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
end

function checknode!(log::AbstractVector, root::AbstractODMNode, node::AbstractODMNode, type::ODMNodeType{:AuditRecord}; integrity = false)
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
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
                                                    pval = val
                                                end
                                                if isnothing(pval)
                                                    pushlog!(log, :WARN, s, e, f, g, i, "DataType is $(itype), but value `$val` can't be parsed.")
                                                end
                                                # CODE LIST CHECK
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
                                                rcl = findelements(idef, :RangeCheck)
                                                if length(rcl) > 0
                                                    for rc in rcl
                                                        comp = attribute(rc, :Comparator)
                                                        if !ismissing(comp)
                                                            errnode = findelement(rc, :ErrorMessage)
                                                    
                                                            if comp == "LT"
                                                                cval = parse(Float64,content(findelement(rc, :CheckValue)))
                                                                if !(pval < cval)  
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) not less than ($(cval): "*errmsg)
                                                                end
                                                            elseif comp == "LE"
                                                                cval = parse(Float64,content(findelement(rc, :CheckValue)))
                                                                if !(pval <= cval)
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end 
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) not less than or equal to ($(cval):"*errmsg)
                                                                end
                                                            elseif comp == "GT"
                                                                cval = parse(Float64,content(findelement(rc, :CheckValue)))
                                                                if !(pval > cval)
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) not greater  than ($(cval):"*errmsg)
                                                                end
                                                            elseif comp == "GT"
                                                                cval = parse(Float64,content(findelement(rc, :CheckValue)))
                                                                if !(pval >= cval)
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) not greater than or equal to ($(cval):"*errmsg)
                                                                end
                                                            elseif comp == "EQ"
                                                                cval = content(findelement(rc, :CheckValue))
                                                                if !(val == cval)
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) not equal to ($(cval):"*errmsg)
                                                                end
                                                            elseif comp == "NE"
                                                                cval = content(findelement(rc, :CheckValue))
                                                                if val == cval
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end  
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) equal to ($(cval):"*errmsg)
                                                                end
                                                            elseif comp == "IN"
                                                                cval = content.(findelements(rc, :CheckValue))
                                                                if val in cval 
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) not one of listed values: ($(cval):"*errmsg)
                                                                end
                                                            elseif comp == "NOIN"
                                                                cval = content.(findelements(rc, :CheckValue))
                                                                if !(val in cval) 
                                                                    if !isnothing(errnode)
                                                                        errmsg = content(findelement(errnode, :TranslatedText))
                                                                    else
                                                                        errmsg = "No msg."
                                                                    end
                                                                    pushlog!(log, :WARN, s, e, f, g, i, "Value ($(pval)) in listed values: ($(cval):"*errmsg)
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
