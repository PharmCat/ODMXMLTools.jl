
abstract type AbstractODMNode end

struct ODMNodeType{Symbol}
    function ODMNodeType(s::Symbol)
        new{s}()
    end
    function ODMNodeType(s::Nothing)
        new{:TextNode}()
    end
end

struct ODMRoot <: AbstractODMNode
    name::Symbol
    attr::Dict{String, String}
    el::Vector{AbstractODMNode}
    function ODMRoot(attr)
        new(:ODM, attr, AbstractODMNode[])
    end
end

struct ODMNode <: AbstractODMNode
    name::Symbol
    attr::Dict{String, String}
    el::Vector{AbstractODMNode}
    function ODMNode(name, attr, el)
        new(name, attr, el)
    end
    function ODMNode(name, attr)
        ODMNode(name, attr, AbstractODMNode[])
    end
end
struct ODMTextNode <: AbstractODMNode
    content::String
end
struct StudyMetaData <: AbstractODMNode
    metadata::ODMNode
    el::Vector
end

function Base.show(io::IO, n::T) where T <: AbstractODMNode
    print(io, "$(n.name)$("OID" in keys(n.attr) ? "(OID:$(attribute(n, "OID")))" : "")")
end
function Base.show(io::IO, n::ODMRoot)
    print(io, "ODM root node")
end
function Base.show(io::IO, n::StudyMetaData)
    print(io, "Completed Study MetaData ($(length(n.el)) elements), OID: $(attribute(n.metadata, "OID")), Name: $(attribute(n.metadata, "Name"))")
end
function Base.show(io::IO, n::ODMTextNode)
    print(io, "Text Node")
end


function AbstractTrees.children(x::T) where T <: AbstractODMNode
    x.el
end
function AbstractTrees.children(i::ODMTextNode)
    ()
end
    #AbstractTrees.nodetype(::IntTree) = IntTree

function makenode(str, attr)
    symb = Symbol(str)
    return ODMNode(symb, attr)
end
function makenode(content::String)
    return ODMTextNode(content)
end
function attributes_dict(n)
    d = Dict{String, String}()
    for i in eachattribute(n)
        d[i.name] = i.content
    end
    d
end
"""
    importxml(file::AbstractString)

Import odm.xml file.
"""
function importxml(file::AbstractString)
    isfile(file) || error("File not found!")
    xdoc  = readxml(file)
    xodm  = root(xdoc)
    odm   = ODMRoot(attributes_dict(xodm))
    importxml_(odm, xodm)
    odm
end
    function importxml_(parent, root)
        if haselement(root)
            chld = EzXML.eachelement(root)
            for c in chld
                if iselement(c)
                    attr = attributes_dict(c)
                    odmn = makenode(nodename(c), attr)
                    push!(parent.el, odmn)
                    if hasnode(c) importxml_(odmn, c) end
                end
            end
        else
            chld = EzXML.eachnode(root)
            for c in chld
                if istext(c)
                    odmn = makenode(nodecontent(c))
                    push!(parent.el, odmn)
                end
            end
        end
        parent
    end
################################################################################
# SUPPORT FUNCTIONS
################################################################################
function attribute(n::AbstractODMNode, attr)
    if ht_keyindex(n.attr, attr) > 0 return n.attr[attr] else return missing end
end
function name(n::ODMRoot)
    :ODM
end
function name(n::ODMNode)
    n.name
end
function name(n::ODMTextNode)
    nothing
end
function have_oid(n::AbstractODMNode)
    if ht_keyindex(n.attr, "OID") > 0 return true else return false end
end
function have_attr(n::AbstractODMNode, attr::AbstractString)
    if ht_keyindex(n.attr, attr) > 0 return true else return false end
end
function appendelements!(inds::AbstractVector, n::AbstractODMNode, name::Symbol)
    for i in n.el
        if i.name == name
            push!(inds, i)
        end
    end
    inds
end
################################################################################
# BASIC FUNCTIONS
################################################################################
"""
    findelement(n::AbstractODMNode, name::Symbol, oid::AbstractString)

Find first element by name and oid.
"""
function findelement(n::AbstractODMNode, name::Symbol, oid::AbstractString)
    for i in n.el
        if i.name == name
            if have_oid(i)
                if i.attr["OID"] == oid return i end
            end
        end
    end
end
"""
    findelement(n::AbstractODMNode, name)

Find first element by name.
"""
function findelement(n::AbstractODMNode, name::Symbol)
    for i in n.el
        if i.name == name
            return i
        end
    end
end
"""
    findelements(n::AbstractODMNode, name::Symbol)

Find all elements by name.
"""
function findelements(n::AbstractODMNode, name::Symbol)
    inds = AbstractODMNode[]
    for i in n.el
        if i.name == name
            push!(inds, i)
        end
    end
    inds
end
"""
    countelements(n::AbstractODMNode, name::Symbol)

Count elements by name.
"""
function countelements(n::AbstractODMNode, name::Symbol)
    inds = 0
    for i in n.el
        if i.name == name
            inds += 1
        end
    end
    inds
end
################################################################################
# SEARCH FUNCTIONS (find*)
################################################################################
"""
    metadatalist(odm::ODMRoot)

Returm table of MetaDataVersion elements.
"""
function metadatalist(odm::ODMRoot)
    df = DataFrame(StudyOID = String[], OID = String[], Name = String[])
    for i in odm.el
        if i.name == :Study
            for j in i.el
                if j.name == :MetaDataVersion
                    push!(df, [attribute(i, "OID"), attribute(j, "OID"), attribute(j, "Name")])
                end
            end
        end
    end
    df
end
"""
    findstudymetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Find metadata for study with study OID soid and metadata OID moid.
"""
function findstudymetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    study = findstudy(odm, soid)
    findelement(study, :MetaDataVersion, moid)
end
"""
    findclinicaldata(odm::ODMRoot, soid::AbstractString)

Return ClinicalData element by study OID (`soid`), nothing if not found.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString)
    for i in odm.el
        if i.name == :ClinicalData && attribute(i, "StudyOID") == soid return i end
    end
    nothing
end
"""
    findclinicaldata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Find ClinicalData by StudyOID and MetaDataVersionOID.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    for i in odm.el
        if i.name == :ClinicalData && attribute(i, "StudyOID") == soid && attribute(i, "MetaDataVersionOID") == moid return i end
    end
    nothing
end
"""
    findstudy(odm::ODMRoot, oid::AbstractString)

Find Study element by OID (`oid`), nothing if not found.
"""
function findstudy(odm::ODMRoot, oid::AbstractString)
    for i in odm.el
        if i.name == :Study && attribute(i, "OID") == oid return i end
    end
    nothing
end
################################################################################
# List functions (return DataFrames)
################################################################################
"""
    eventlist(md::AbstractODMNode)

Return events (StudyEventDef).
"""
function eventlist(md::AbstractODMNode)
    df = DataFrame(OID = String[], Name = String[], Repeating= String[], Type = String[])
    for i in md.el
        if name(i) == :StudyEventDef
            push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating"), attribute(i, "Type")))
        end
    end
    df
end
"""
    formlist(md::AbstractODMNode)

Return forms (FormDef).
"""
function formlist(md::AbstractODMNode)
    df = DataFrame(OID = String[], Name = String[], Repeating= String[])
    for i in md.el
        if name(i) == :FormDef
            push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating")))
        end
    end
    df
end

"""
    itemgrouplist(md::AbstractODMNode; optional = false)

Return item groups (ItemGroupDef).

If optional = true - return all optional attributes.
"""
function itemgrouplist(md::AbstractODMNode; optional = false)
    if optional
        df = DataFrame(OID = String[], Name = String[], Repeating= String[], SASDatasetName = Union{Missing, String}[], Comment = Union{Missing, String}[])
        for i in md.el
            if name(i) == :ItemGroupDef
                push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating"), attribute(i, "SASDatasetName"), attribute(i, "Comment")))
            end
        end
    else
        df = DataFrame(OID = String[], Name = String[], Repeating= String[])
        for i in md.el
            if name(i) == :ItemGroupDef
                push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating")))
            end
        end
    end
    df
end
"""
    itemlist(md::AbstractODMNode; optional = false)

Return items (ItemDef).

If optional = true - return all optional attributes.
"""
function itemlist(md::AbstractODMNode; optional = false)
    itemlist(md.el; optional = optional)
end
function itemlist(el::Vector{T}; optional = false) where T <: AbstractODMNode
    if optional
        df = DataFrame(OID = String[], Name = String[], DataType= String[],
        Length = Union{Missing, String}[], SignificantDigits = Union{Missing, String}[],
        SASFieldName = Union{Missing, String}[], SDSVarName = Union{Missing, String}[],
        Origin = Union{Missing, String}[], Comment = Union{Missing, String}[])
        for i in el
            if name(i) == :ItemDef
                push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "DataType"),
                attribute(i, "Length"), attribute(i, "SignificantDigits"),
                attribute(i, "SASFieldName"), attribute(i, "SDSVarName"),
                attribute(i, "Origin"), attribute(i, "Comment")))
            end
        end
    else
        df = DataFrame(OID = String[], Name = String[], DataType= String[])
        for i in el
            if name(i) == :ItemDef
                push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "DataType")))
            end
        end
    end
    df
end
"""
    itemlist(md::AbstractODMNode; optional = false)

Return items (ItemDef) for concrete item group (ItemGroupDef) by OID.

If optional = true - return all optional attributes.
"""
function itemgroupcontent(md, oid; optional = false)
    ig   = findelement(md, :ItemGroupDef, oid)
    inds = AbstractODMNode[]
    for i in ig.el
        if name(i) == :ItemRef
            el = findelement(md, :ItemDef, attribute(i, "ItemOID"))
            if !(isnothing(el)) push!(inds, el) end
        end
    end
    itemlist(inds; optional = optional)
end
################################################################################
# TOP LEVEL FUNCTIONS
# clinicaldatatable
# buildmetadata
# buildelementsdata
################################################################################
"""
    buildmetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Build MetaData from MetaDataVersion.
"""
function buildmetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    mdat   = findstudymetadata(odm, soid, moid)
    stmd   = StudyMetaData(mdat, AbstractODMNode[])
    fillstmd_(stmd.el, stmd.metadata, odm)
    stmd
end
"""
    buildmetadata(mdat::AbstractODMNode)

Build MetaData from MetaDataVersion mdat.
"""
function buildmetadata(mdat::AbstractODMNode)
    if name(cd) != :MetaDataVersion error("This is not MetaDataVersion") end
    stmd   = StudyMetaData(mdat, AbstractODMNode[])
    fillstmd_(stmd.el, stmd.metadata, odm)
    stmd
end
"""
    clinicaldatatable(cd::AbstractODMNode)

Return clinical data table in long formal. `cd` should be ClinicalData.
"""
function clinicaldatatable(cd::AbstractODMNode)
    if name(cd) != :ClinicalData error("This is not ClinicalData") end
    df = DataFrame(SubjectKey = String[], StudyEventOID = String[], FormOID = String[], ItemGroupOID = String[], ItemOID = String[], Value = String[])
    sdl = findelements(cd, :SubjectData)
    edl = AbstractODMNode[]
    fdl = AbstractODMNode[]
    gdl = AbstractODMNode[]
    idl = AbstractODMNode[]
    for s in sdl
        resize!(edl, 0)
        appendelements!(edl, s, :StudyEventData)
        for e in edl
            resize!(fdl, 0)
            appendelements!(fdl, e, :FormData)
            for f in fdl
                resize!(gdl, 0)
                appendelements!(gdl, f, :ItemGroupData)
                for g in gdl
                    resize!(idl, 0)
                    appendelements!(idl, g, :ItemData)
                    for i in idl
                        push!(df, (attribute(s, "SubjectKey"),
                        attribute(e, "StudyEventOID"),
                        attribute(f, "FormOID"),
                        attribute(g, "ItemGroupOID"),
                        attribute(i, "ItemOID"),
                        attribute(i, "Value")))
                    end
                end
            end
        end
    end
    df
end
"""
    clinicaldatatable(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Return clinical data table in long formal.
"""
function clinicaldatatable(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    cld  = findclinicaldata(odm, soid, moi)
    isnothing(cld) && error("ClinicalData not found")
    clinicaldatatable(cld)
end
"""
    buildelementsdata(stmd::AbstractODMNode)

Build elements data.
"""
function buildelementsdata(stmd::AbstractODMNode)
    error("not implemented")
end

################################################################################
# BUILD MetaData functions
################################################################################
function inlist(n, dest)
    for i in dest
        if n.name == i.name
            if have_oid(n)
                if n.attr["OID"] == i.attr["OID"] return true end
            else
                return true
            end
        end
    end
    false
end
function fillstmd_(dest, source, odm)
    inds = AbstractODMNode[]
    for i in source.el
        if !inlist(i, dest)
            push!(inds, i)
        end
    end
    if length(inds) > 0
        append!(dest, inds)
    end
    incl = findelements(source, :Include)
    if length(incl) > 0
        for i in incl
            fillstmd_(dest, findstudymetadata(odm, attribute(i, "StudyOID"), attribute(i, "MetaDataVersionOID")), odm)
        end
    end
    dest
end
################################################################################
