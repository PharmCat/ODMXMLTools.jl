

struct ODMXMLlog
    log::Vector{Tuple{Symbol, String}}
end

function Base.push!(log::ODMXMLlog, msg::String)
    push!(log.log, (:STR, msg))
end
function Base.push!(log::ODMXMLlog, msg)
    push!(log.log, msg)
end
function Base.show(io::IO, log::ODMXMLlog)
    w = 0
    e = 0
    i = 0
    s = 0
    for m in log.log
        if m[1] == :WARN
            w += 1
        elseif m[1] == :ERROR
            e += 1
        elseif m[1] == :INFO
            i += 1
        elseif m[1] == :SKIP
            s += 1
        end
    end
    println(io, "ODMXML log: $(length(log.log)) item(s). Info = $i, Warnings = $w, Errors = $e, skipped $s node(s).")
end

function Base.show(io::IO, log::ODMXMLlog, type::Symbol)
    for i in 1:length(log.log)
        if type == log.log[i][1]
            println(io, log.log[i][1], " - ", log.log[i][2])
        end
    end
end
Base.show(log::ODMXMLlog, type::Symbol) = show(stdout, log, type)

function checkattrs!(log, node, attrs, attrsref)
    for r in attrsref
        if !(r[1] in attrs) 
            if r[2] == :! push!(log, (:ERROR, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Attribute $(r[1]) not found.")) end
        elseif isa(r[3], Vector{Symbol})
            if !(Symbol(attribute(node, r[1])) in r[3])
                push!(log, (:ERROR, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Attribute $(r[1]) value ($(attribute(node, r[1]))) not in list $(r[3]).")) 
            end
        end
    end
    for a in attrs
        found = false
        for r in attrsref
            if a == r[1] found = true end
        end
        if !found push!(log, (:WARN, "$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Unexpected attribute: $(a)")) end
    end
end

function checkelements!(log, node, r)
    cnt = countelements(node, r[1])
    if r[2] == :! && cnt != 1 
        push!(log, (:ERROR,"$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child ($(r[1])) elements count: $cnt != 1."))
        return false
    elseif r[2] == :? && cnt > 1  
        push!(log, (:ERROR,"$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child ($(r[1])) elements count: $cnt > 1."))
        return false
    elseif r[2] == :+ && cnt == 0
        push!(log, (:ERROR,"$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child ($(r[1])) elements count: $cnt < 1."))
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
                push!(log, (:ERROR,"$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child elements. More than one condition met from XOR list - "*str))
            else
                if !any(nxor)
                    push!(log, (:ERROR,"$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Wrong child elements. No elements found."))
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
        if !found push!(log, (:INFO,"$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Unexpected child node: $(name(c))")) end
    end
end
function checkchlds!(log, node, chlds, chldsref::String)
    if length(chlds) > 0
        push!(log, (:INFO,"$(name(node))$(hasattribute(node, :OID) ? "(OID: $(attribute(node, :OID, true)))" : ""): Unexpected child node, $chldsref expected."))
    end
end



function checknode!(log::ODMXMLlog, node::AbstractODMNode, ::ODMNodeType)
    if haskey(NODEINFO, name(node))
        checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
        checkchlds!(log, node, node.el, NODEINFO[name(node)].body)
    else
        push!(log, (:SKIP, "$(name(node)): Skipped unknown node."))
    end
end

function checknode!(log::ODMXMLlog, node::AbstractODMNode, ::ODMNodeType{:ODM})
    ks = Set([:Description, :FileType, :Granularity, :Archival, :FileOID, :CreationDateTime, :PriorFileOID, :AsOfDateTime, :ODMVersion, :Originator, :SourceSystem, :SourceSystemVersion, :ID])
    for k in keys(node.attr)
        k in ks || push!(log, (:WARN, "$(name(node)): Unknown attribute ($(k)) in ODM (root) node."))
    end
    if :FileType in keys(node.attr)
        attribute(node, :FileType) in FILETYPE || push!(log, (:ERROR, "$(name(node)): Wrong FileType attribute in ODM (root) node."))
        #other check
    else
        push!(log, (:WARN, "$(name(node)): No FileType attribute in ODM (root) node."))
    end
    if :Granularity in keys(node.attr)
        attribute(node, :Granularity) in GRANULARITY || push!(log, (:ERROR, "$(name(node)): Wrong Granularity in ODM (root) node."))
    end
    if :Archival in keys(node.attr)
        attribute(node, :Archival) in ARCHIVAL || push!(log, (:ERROR, "$(name(node)): Wrong Archival in ODM (root) node."))
        attribute(node, :FileType) == "Transactional" || push!(log, (:ERROR,"$(name(node)): Archival is $(attribute(node, "Archival")), but FileType not Transactional in ODM (root) node."))
    end
    if :ODMVersion in keys(node.attr)
        attribute(node, :ODMVersion) in ODMVERSION || push!(log, (:WARN,"$(name(node)): Wrong ODMVersion in ODM (root) node."))
    end
    if :FileOID ∉ keys(node.attr)
        push!(log, (:WARN, "$(name(node)): No FileOID in ODM (root) node."))
    end
    if :CreationDateTime ∉ keys(node.attr)
        push!(log, (:WARN, "$(name(node)): No CreationDateTime in ODM (root) node."))
    else
        #datetime
    end
    if :AsOfDateTime in keys(node.attr)
        #datetime
    end
    for i in node.el
        if name(i) ∉ Set([:Study, :AdminData, :ReferenceData, :ClinicalData, :Association, Symbol("Signature")])
            push!(log, (:WARN, "$(name(node)): Unexpected node ($(name(i))) in body of ODM (root) node."))
        end
    end
end

function checknode!(log::ODMXMLlog, node::AbstractODMNode, ::ODMNodeType{:ItemGroupData})
    checkattrs!(log, node, keys(node.attr), NODEINFO[name(node)].attrs)
    dn = countnodenames(node, :ItemData)
    if dn > 0
        if countnodenames(node, ITEMDATATYPE) > 0 push!(log, (:WARN, "$(name(node)) (ItemGroupOID = $(attribute(node, :ItemGroupOID))): contains ItemData and ItemData[TYPE].")) end
    end
    dn = countnodenames(node, :AuditRecord)
    if dn > 1 
        push!(log, (:ERROR,"$(name(node)) (ItemGroupOID = $(attribute(node, :ItemGroupOID))): Wrong child (AuditRecord) elements count: $dn > 1."))
    end
    dn = countnodenames(node, :Signature)
    if dn > 1 
        push!(log, (:ERROR,"$(name(node)) (ItemGroupOID = $(attribute(node, :ItemGroupOID))): Wrong child (Signature) elements count: $dn > 1."))
    end
end

function countnodenames(node, nodename::Symbol)
    cnt = 0
    ch = children(node)
    for i in ch
        if name(i) == nodename cnt += 1 end
    end
    cnt
end
function countnodenames(node, nodenames)
    cnt = 0
    ch = children(node)
    for i in ch
        if name(i) in nodenames cnt += 1 end
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


function validateodm_!(log::ODMXMLlog, node::AbstractODMNode; odmnamespace::Symbol)
    checknode!(log, node, ODMNodeType(name(node)))
    for i in node.el
        if i.namespace == odmnamespace
            validateodm_!(log, i; odmnamespace = odmnamespace)
        else
            push!(log, (:SKIP, "Node ($(name(i))) from namespace \"$(i.namespace)\" skipped from check."))
        end
    end
end
function validateodm_!(log::ODMXMLlog, node::StudyMetaData; odmnamespace::Symbol)
    for i in node.el
        if i.namespace == odmnamespace
            validateodm_!(log, i; odmnamespace = odmnamespace)
        else
            push!(log, (:SKIP, "Node ($(name(i))) from namespace \"$(i.namespace)\" skipped from check."))
        end
    end
end

"""
    validateodm(odm::AbstractODMNode)

Basic structure validation.

!!! warning
    Not full implemented.

"""
function validateodm(odm::AbstractODMNode; odmnamespace::Symbol = Symbol(""))
    log = ODMXMLlog(Tuple{Symbol, String}[])
    validateodm_!(log, odm; odmnamespace = odmnamespace)
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
