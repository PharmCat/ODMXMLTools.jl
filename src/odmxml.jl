
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
    attr::Dict{Symbol, String}
    el::Vector{AbstractODMNode}
    function ODMRoot(attr)
        new(:ODM, attr, AbstractODMNode[])
    end
end

struct ODMNode <: AbstractODMNode
    name::Symbol
    attr::Dict{Symbol, String}
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
    print(io, "$(n.name)  ($(:OID in keys(n.attr) ? "OID:$(attribute(n, :OID)))" : "")$(:StudyOID in keys(n.attr) ? " StudyOID:$(attribute(n, :StudyOID)))" : ""))")
end
function Base.show(io::IO, n::ODMRoot)
    print(io, "ODM root node")
end
function Base.show(io::IO, n::StudyMetaData)
    print(io, "Completed Study MetaData ($(length(n.el)) elements), OID: $(attribute(n.metadata, :OID)), Name: $(attribute(n.metadata, :Name))")
end
function Base.show(io::IO, n::ODMTextNode)
    print(io, "Text Node")
end


function AbstractTrees.children(x::T) where T <: AbstractODMNode
    x.el
end
function AbstractTrees.children(i::ODMTextNode)
    []
end
    #AbstractTrees.nodetype(::IntTree) = IntTree

function makenode(str, attr)
    #symb = Symbol(str)
    return ODMNode(Symbol(str), attr)
end
function makenode(content::String)
    return ODMTextNode(content)
end
function attributes_dict(n)
    d = Dict{Symbol, String}()
    for i in eachattribute(n)
        d[Symbol(i.name)] = i.content
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
function attribute(n::AbstractODMNode, attr::Symbol)
    attrf = getfield(n, :attr)
    if haskey(attrf, attr) return attrf[attr] else return "" end
end
function attribute(n::AbstractODMNode, attr::String)
    attribute(n, Symbol(attr))
end
function attributes(n::AbstractODMNode, attrs)
    broadcast(x-> attribute(n, x), attrs)
end

function name(n::ODMRoot)
    :ODM
end
function name(n::ODMNode)
    getfield(n, :name)
end

isStudyEventData(node::AbstractODMNode) = name(node) == :StudyEventData
isFormData(node::AbstractODMNode) = name(node) == :FormData
isItemGroupData(node::AbstractODMNode) = name(node) == :ItemGroupData
isItemData(node::AbstractODMNode) = name(node) == :ItemData
isSubjectData(node::AbstractODMNode) = name(node) == :SubjectData
isMetaDataVersion(node::AbstractODMNode) = name(node) == :MetaDataVersion
isStudy(node::AbstractODMNode) = name(node) == :Study
isClinicalData(node::AbstractODMNode) = name(node) == :ClinicalData


function name(n::ODMTextNode)
    nothing
end
function have_attr(n::AbstractODMNode, attr::Symbol)
    if  haskey(getfield(n, :attr), attr) return true else return false end
end
function have_oid(n::AbstractODMNode)
    have_attr(n, :OID)
end
function appendelements!(inds::AbstractVector, n::AbstractODMNode, nname::Symbol)
    for i in n.el
        if name(i) == nname
            push!(inds, i)
        end
    end
    inds
end
function content(n::ODMTextNode)
    getfield(n, :content)
end
function content(n::AbstractODMNode)
    for i in n.el
        if isa(i, ODMTextNode)
            return content(i)
        end
    end
    nothing
end

t_collect(a::Tuple) = [i for i in a];
t_collect(a::Vector) = a;
t_collect(a) = collect(a);
################################################################################
# BASIC FUNCTIONS
################################################################################
"""
    findelement(n::AbstractODMNode, name::Symbol, oid::AbstractString)

Find first element by name and oid.
"""
function findelement(n::AbstractODMNode, nname::Symbol, oid::AbstractString)
    for i in n.el
        if i.name == nname
            if have_oid(i)
                if attribute(i, :OID) == oid return i end
            end
        end
    end
end
"""
    findelement(n::AbstractODMNode, nname)

Find first element by name.
"""
function findelement(n::AbstractODMNode, nname::Symbol)
    for i in n.el
        if name(i) == nname
            return i
        end
    end
end
"""
    findelements(n::AbstractODMNode, name::Symbol)

Find all elements by name.
"""
function findelements(n::AbstractODMNode, nname::Symbol)
    inds = AbstractODMNode[]
    for i in n.el
        if name(i) == nname
            push!(inds, i)
        end
    end
    inds
end
"""
    countelements(n::AbstractODMNode, name::Symbol)

Count elements by name.
"""
function countelements(n::AbstractODMNode, nname::Symbol)
    inds = 0
    for i in n.el
        if name(n) == nname
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
        if name(i) == :Study
            for j in i.el
                if isMetaDataVersion(j)
                    push!(df, (attribute(i, "OID"), attribute(j, "OID"), attribute(j, "Name")))
                end
            end
        end
    end
    df
end
"""
    studylist(odm::ODMRoot)

Returm table of Study elements.
"""
function studylist(odm::ODMRoot)
    df = DataFrame(StudyOID = String[])
    for i in odm.el
        if isStudy(i)
            push!(df, (attribute(i, "OID"),))
        end
    end
    df
end
"""
    clinicaldatalist(odm::ODMRoot)

Returm table of ClinicalData elements.
"""
function clinicaldatalist(odm::ODMRoot)
    df = DataFrame(StudyOID = String[], MetaDataVersionOID = String[])
    for i in odm.el
        if isClinicalData(i)
            push!(df, (attribute(i, "StudyOID"), attribute(i, "MetaDataVersionOID")))
        end
    end
    df
end
"""
    findclinicaldata(odm::ODMRoot, soid::AbstractString)

Return ClinicalData element by study OID (`soid`), nothing if not found.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString)
    for i in odm.el
        if isClinicalData(i) && attribute(i, "StudyOID") == soid return i end
    end
    nothing
end
"""
    findclinicaldata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Find ClinicalData by StudyOID and MetaDataVersionOID.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    for i in odm.el
        if isClinicalData(i) && attribute(i, "StudyOID") == soid && attribute(i, "MetaDataVersionOID") == moid return i end
    end
    nothing
end
"""
    findstudy(odm::ODMRoot, oid::AbstractString)

Find Study element by OID (`oid`), nothing if not found.
"""
function findstudy(odm::ODMRoot, oid::AbstractString)
    for i in odm.el
        if isStudy(i) && attribute(i, "OID") == oid return i end
    end
    nothing
end
"""
    findstudymetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Find metadata for study with study OID soid and metadata OID moid.
"""
function findstudymetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    study = findstudy(odm, soid)
    findelement(study, :MetaDataVersion, moid)
end
################################################################################
# List functions (return DataFrames)
################################################################################
"""
    eventlist(md::AbstractODMNode)

Return events (StudyEventDef).
"""
function eventlist(md::AbstractODMNode; categ = false)
    df = DataFrame(OID = String[], Name = String[], Repeating= String[], Type = String[])
    for i in md.el
        if name(i) == :StudyEventDef
            push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating"), attribute(i, "Type")))
        end
    end
    if categ
        transform!(df, :OID => categorical, renamecols=false)
    end
    df
end
"""
    formlist(md::AbstractODMNode)

Return forms (FormDef).
"""
function formlist(md::AbstractODMNode; categ = false)
    formlist(md.el, categ = categ)
end
"""
    formlist(el::Vector{T}) where T <: AbstractODMNode

Return forms (FormDef).
"""
function formlist(el::Vector{T}; categ = false) where T <: AbstractODMNode
    df = DataFrame(OID = String[], Name = String[], Repeating= String[])
    for i in el
        if name(i) == :FormDef
            push!(df, (attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating")))
        end
    end
    if categ
        transform!(df, :OID => categorical, renamecols=false)
    end
    df
end

"""
    itemgrouplist(md::AbstractODMNode; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)

Return item groups (ItemGroupDef).

If optional = true - return all optional attributes.
attrs - list of attributes.
"""
function itemgrouplist(md::AbstractODMNode; optional = false, attrs::Union{AbstractVector, Nothing} = nothing, categ = false)
    itemgrouplist(md.el; optional = optional, attrs = attrs, categ = categ)
end
"""
    itemgrouplist(el::Vector{T}; optional = false, attrs = nothing) where T <: AbstractODMNode

Return item groups (ItemGroupDef).

If optional = true - return all optional attributes.
attrs - list of attributes.
"""
function itemgrouplist(el::Vector{T}; optional = false, attrs = nothing, categ = false) where T <: AbstractODMNode
    if isnothing(attrs)
        if optional
            attrs = (:OID, :Name, :Repeating, :SASDatasetName, :Comment)
        else
            attrs = (:OID, :Name, :Repeating)
        end
    end
    df = DataFrame(Matrix{Union{Missing, String}}(undef, 0, length(attrs)), t_collect(attrs))
    for i in el
        if name(i) == :ItemGroupDef
            push!(df, attributes(i, attrs))
        end
    end
    if categ
        transform!(df, :OID => categorical, renamecols=false)
    end
    df
end

"""
    itemlist(md::AbstractODMNode; optional = false, attrs = nothing)

Return items (ItemDef).

If optional = true - return all optional attributes.
"""
function itemlist(md::AbstractODMNode; optional = false, attrs = nothing, categ = false)
    itemlist(md.el; optional = optional, attrs = attrs, categ = categ)
end
"""
    itemlist(el::Vector{T}; optional = false, attrs = nothing) where T <: AbstractODMNode
"""
function itemlist(el::Vector{T}; optional = false, attrs = nothing, categ = false) where T <: AbstractODMNode
    if isnothing(attrs)
        if optional
            attrs = (:OID, :Name, :DataType, :Length, :SignificantDigits, :SASFieldName, :SDSVarName, :Origin, :Comment)
        else
            attrs = (:OID, :Name, :DataType)
        end
    end
    df = DataFrame(Matrix{Union{Missing, String}}(undef, 0, length(attrs)), t_collect(attrs))
    for i in el
        if name(i) == :ItemDef
            push!(df, attributes(i, attrs))
        end
    end
    if categ
        transform!(df, :OID => categorical, renamecols=false)
    end
    df
end

################################################################################
# CONTENT
################################################################################
function formcontent_(md, oid)
    ig   = findelement(md, :FormDef, oid)
    inds = AbstractODMNode[]
    for i in ig.el
        if name(i) == :ItemGroupRef
            el = findelement(md, :ItemGroupDef, attribute(i, "ItemGroupOID"))
            if !(isnothing(el)) push!(inds, el) end
        end
    end
    inds
end

function itemgroupcontent_(md, oid)
    ig   = findelement(md, :ItemGroupDef, oid)
    inds = AbstractODMNode[]
    for i in ig.el
        if name(i) == :ItemRef
            el = findelement(md, :ItemDef, attribute(i, "ItemOID"))
            if !(isnothing(el)) push!(inds, el) end
        end
    end
    inds
end

"""
    formcontent(md, oid)

Return item groups (ItemGroupDef) for concrete form (FormDef) by OID.

"""
function formcontent(md, oid; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)
    inds = formcontent_(md, oid)
    itemgrouplist(inds; optional = optional, attrs = attrs)
end
"""
    itemgroupcontent(md, oid; optional = false)

Return items (ItemDef) for concrete item group (ItemGroupDef) by OID.

If optional = true - return all optional attributes.
"""
function itemgroupcontent(md, oid; optional = false)
    inds = itemgroupcontent_(md, oid)
    itemlist(inds; optional = optional)
end

"""
    itemsformcontent(md, oid; optional = false)


"""
function itemsformcontent(md, oid; optional = false)
    inds   = AbstractODMNode[]
    frm    = findelement(md, :FormDef, oid)
    iginds = findelements(frm, :ItemGroupRef)
    for i in iginds
        igoid = attribute(i, "ItemGroupOID")
        append!(inds, itemgroupcontent_(md, igoid))
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
    itemcodelisttable(cd::AbstractODMNode; lang = nothing) where T <: AbstractODMNode

List of coded values.
"""
function itemcodelisttable(cd::AbstractODMNode; lang = nothing)
    df = DataFrame(OID = String[], Name = String[], DataType = String[], CodedValue = String[], Rank = String[], OrderNumber = String[], Text = String[])

    cll  = findelements(cd, :CodeList)
    clil = AbstractODMNode[] # CodeListItem
    for cl in cll
        resize!(clil, 0)
        appendelements!(clil, cl, :CodeListItem)
        for cli in clil
            dec  = findelement(cli, :Decode)
            text = findelement(dec, :TranslatedText)
            push!(df, (attribute(cl, :OID),
            attribute(cl, :Name),
            attribute(cl, :DataType),
            attribute(cli, :CodedValue),
            attribute(cli, :Rank),
            attribute(cli, :OrderNumber),
            content(text)))
        end
    end
    df
end


"""
    clinicaldatatable(cd::AbstractODMNode; itemgroup = nothing)

Return clinical data table in long formal. `cd` should be ClinicalData.
"""
function clinicaldatatable(cd::AbstractODMNode; itemgroup = nothing, categ = false)
    if name(cd) != :ClinicalData error("This is not ClinicalData") end
    #df = DataFrame(SubjectKey = String[], StudyEventOID = CategoricalArray(String[]), FormOID = CategoricalArray(String[]), ItemGroupOID = CategoricalArray(String[]), ItemGroupRepeatKey = CategoricalArray(String[]), ItemOID = CategoricalArray(String[]), Value = String[])
    df = DataFrame(SubjectKey = String[], StudyEventOID = String[], FormOID = String[], ItemGroupOID = String[], ItemGroupRepeatKey = String[], ItemOID = String[], Value = String[])
    sdl = findelements(cd, :SubjectData)
    edl = AbstractODMNode[]
    fdl = AbstractODMNode[]
    gdl = AbstractODMNode[]
    idl = AbstractODMNode[]
    #sdl = Iterators.filter(isSubjectData, cd.el)
    for s in sdl
        resize!(edl, 0)
        appendelements!(edl, s, :StudyEventData)
        #edl = Iterators.filter(isStudyEventData, s.el)
        for e in edl
            resize!(fdl, 0)
            appendelements!(fdl, e, :FormData)
            #fdl = Iterators.filter(isFormData, e.el)
            for f in fdl
                resize!(gdl, 0)
                appendelements!(gdl, f, :ItemGroupData)
                #gdl = Iterators.filter(isItemGroupData, f.el)
                for g in gdl
                    if !isnothing(itemgroup)
                        if attribute(g, :ItemGroupOID) != itemgroup continue end
                    end
                    resize!(idl, 0)
                    appendelements!(idl, g, :ItemData)
                    #idl = Iterators.filter(isItemData, g.el)
                    for i in idl
                        push!(df, (attribute(s, :SubjectKey),
                        attribute(e, :StudyEventOID),
                        attribute(f, :FormOID),
                        attribute(g, :ItemGroupOID),
                        attribute(g, :ItemGroupRepeatKey),
                        attribute(i, :ItemOID),
                        attribute(i, :Value)))
                    end
                end
            end
        end
    end
    if categ
        transform!(df, :StudyEventOID => categorical, renamecols=false)
        transform!(df, :FormOID => categorical, renamecols=false)
        transform!(df, :ItemGroupOID => categorical, renamecols=false)
        transform!(df, :ItemGroupRepeatKey => categorical, renamecols=false)
        transform!(df, :ItemOID => categorical, renamecols=false)
    end
    df
end
"""
    clinicaldatatable(odm::ODMRoot, soid::AbstractString, moid::AbstractString; itemgroup = nothing)

Return clinical data table in long formal.
"""
function clinicaldatatable(odm::ODMRoot, soid::AbstractString, moid::AbstractString; itemgroup = nothing)
    cld  = findclinicaldata(odm, soid, moid)
    isnothing(cld) && error("ClinicalData not found")
    clinicaldatatable(cld; itemgroup = itemgroup)
end

"""
    subjectdatatable(cld::AbstractODMNode; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)

Subject information table
"""
function subjectdatatable(cld::AbstractODMNode; optional = false, attrs = nothing)
    if name(cld) != :ClinicalData error("This is not ClinicalData") end
    if isnothing(attrs)
        if optional
            attrs = (:SubjectKey, :TransactionType)
        else
            attrs = tuple(:SubjectKey)
        end
    end
    df = DataFrame(Matrix{Union{String, Missing}}(undef, 0, length(attrs)), t_collect(attrs))
    for s in cld.el
        if isSubjectData(s)
            push!(df, attributes(s, attrs))
        end
    end
    df
end
"""
    subjectdatatable(odm::ODMRoot; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)
"""
function subjectdatatable(odm::ODMRoot; optional = false, attrs = nothing)
    cld = findelements(odm, :ClinicalData)
    if length(cld) > 0
        df = subjectdatatable(cld[1]; optional = optional, attrs = attrs)
        if length(cld) > 1
            for i = 2:length(cld)
                append!(df, subjectdatatable(cld[i]; optional = optional, attrs = attrs))
            end
        end
        return df
    end
    nothing
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
                if n.attr[:OID] == i.attr[:OID] return true end
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
            fillstmd_(dest, findstudymetadata(odm, attribute(i, :StudyOID), attribute(i, :MetaDataVersionOID)), odm)
        end
    end
    dest
end
################################################################################
# Information
################################################################################
"""
    studyinfo(odm::ODMRoot, oid::AbstractString;  io = stdout)

Study information.
"""
function studyinfo(odm::ODMRoot, oid::AbstractString;  io = stdout)
    for i in odm.el
        if name(i) == :Study && attribute(i, :OID) == oid
            studyinfo(i; io = io)
        end
    end
    print(io, "")
end
"""
    studyinfo(odm::ODMRoot;  io = stdout)

Study information.
"""
function studyinfo(odm::ODMRoot;  io = stdout)
    str = ""
    for i in odm.el
        if name(i) == :Study
            str *= "--------------------------------------\n"
            str *= studyinfo_(i)
        end
    end
    str *= "--------------------------------------\n"
    print(io, str)
end
"""
    studyinfo(st::AbstractODMNode;  io = stdout)

Study information.
"""
function studyinfo(st::AbstractODMNode;  io = stdout)
    str = studyinfo_(st)
    print(io, str)
end
function studyinfo_(st::AbstractODMNode)
    if name(st) != :Study error("This is not Study") end
    str = "Study OID: $(attribute(st, "OID"))\n"
    gv  = findelement(st, :GlobalVariables)
    sn  = findelement(gv, :StudyName)
    str *= "StudyName: $(content(sn))\n"
    sd  = findelement(gv, :StudyDescription)
    str *= "StudyDescription: $(content(sd))\n"
    pn  = findelement(gv, :ProtocolName)
    str *= "ProtocolName: $(content(pn))\n"
    str *= "MetaDataVersion: \n"
    mdl = findelements(st, :MetaDataVersion)
    if length(mdl) > 0
        for i in mdl
            str *= "    OID: $(attribute(i, :OID)); Name: $(attribute(i, :Name))\n"
        end
    else
        str *= "    No\n"
    end
    str
end
