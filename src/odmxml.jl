abstract type AbstractODMNode end
abstract type AbstractODMNodeType end

struct ODMNodeType{Symbol} <: AbstractODMNodeType
    function ODMNodeType(s::Symbol)
        new{s}()
    end
    function ODMNodeType(::Nothing)
        new{:TextNode}()
    end
end

struct ODMNode <: AbstractODMNode
    name::Symbol
    attr::Dict{Symbol, String}
    el::Vector{ODMNode}
    content::String
    function ODMNode(name, attr, content) 
        new(name, attr, ODMNode[], content)
    end
    function ODMNode(name, attr)
        ODMNode(name, attr, ODMNode[], "")
    end
end

struct ODMRoot <: AbstractODMNode
    name::Symbol
    attr::Dict{Symbol, String}
    el::Vector{ODMNode}
    ns::Vector
    function ODMRoot(attr, ns)
        new(:ODM, attr, ODMNode[], ns)
    end
end

struct StudyMetaData <: AbstractODMNode
    metadata::ODMNode
    el::Vector{AbstractODMNode}
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

function AbstractTrees.children(x::T) where T <: AbstractODMNode
    x.el
end

function AbstractTrees.isroot(x::ODMRoot)
    true
end
function AbstractTrees.isroot(x::AbstractODMNode)
    false
end

#AbstractTrees.nodetype(::IntTree) = IntTree

function makenode(str, attr)
    #symb = Symbol(str)
    return ODMNode(Symbol(str), attr)
end

function attributes_dict(n)
    d = Dict{Symbol, String}()
    for i in eachattribute(n)
        d[Symbol(i.name)] = i.content
    end
    d
end
function attributes_dict!(d, n)
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
    ns    = namespaces(xodm)
    odm   = ODMRoot(attributes_dict(xodm), ns)
    importxml_(odm, xodm)
    odm
end
    function importxml_(parent, root)
        if hasnode(root)
            chld = EzXML.eachnode(root)
            for c in chld
                content = ""
                attr = Dict{Symbol, String}()
                if iselement(c)
                    attributes_dict!(attr, c)
                    if !haselement(c)
                        tv = EzXML.eachnode(root)
                        for t in tv
                            if istext(t)
                                content = nodecontent(c)
                                break
                            end
                        end
                    end
                    odmn = ODMNode(Symbol(nodename(c)), attr, content)
                    push!(parent.el, odmn)
                    if haselement(c) importxml_(odmn, c) end
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

isMetaDataVersion(node::AbstractODMNode) = name(node) == :MetaDataVersion
isStudy(node::AbstractODMNode) = name(node) == :Study

isClinicalData(node::AbstractODMNode) = name(node) == :ClinicalData
isSubjectData(node::AbstractODMNode) = name(node) == :SubjectData
isStudyEventData(node::AbstractODMNode) = name(node) == :StudyEventData
isFormData(node::AbstractODMNode) = name(node) == :FormData
isItemGroupData(node::AbstractODMNode) = name(node) == :ItemGroupData
isItemData(node::AbstractODMNode) = name(node) == :ItemData
isItemDataType(node::AbstractODMNode) = name(node) in ITEMDATATYPE

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

function appendelements!(inds::AbstractVector, n::AbstractODMNode, nname::Union{Set{Symbol}, AbstractVector{Symbol}})
    for i in n.el
        if name(i) in nname
            push!(inds, i)
        end
    end
    inds
end

function content(n::AbstractODMNode)
    n.content
end

function getitemdatavalue(n::AbstractODMNode, null)
    if attribute(n, :IsNull) == "Yes" return null end
    if isItemData(n)
        return attribute(n, :Value) 
    elseif isItemDataType(n) 
        val = content(n) 
        if isnothing(val)
            @warn "ItemData[TYPE] content is empty"
            return ""
        else
            return val
        end
    end
    nothing
end

t_collect(a::Tuple) = [i for i in a];
t_collect(a::Vector) = a;
t_collect(a) = collect(a);

# Make DataFrame from md node, by name, include attrs
function df_list(md::AbstractODMNode, nname::Symbol, attrs)
    df_list(md.el, nname, attrs)
end
function df_list(el::Vector{T}, nname::Symbol, attrs) where T <: AbstractODMNode
    df = DataFrame(Matrix{Union{Missing, String}}(undef, 0, length(attrs)), t_collect(attrs))
    for i in el
        if name(i) == nname
            push!(df, attributes(i, attrs))
        end
    end
    df
end

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

Base.findfirst(n::AbstractODMNode, args...) = findelement(n, args...)
#Base.findfirst(n::AbstractODMNode, nname::Symbol, oid::AbstractString) = findelement(n, nname, oid)

function findelements_(n, nname::Symbol)
    inds = ODMNode[]
    for i in n
        if name(i) == nname
            push!(inds, i)
        end
    end
    inds
end

function findelements_(n, nnames::Vector{Symbol})
    inds = ODMNode[]
    for i in n
        if name(i) in nnames
            push!(inds, i)
        end
    end
    inds
end
"""
    findelements(n::AbstractODMNode, nname::Symbol)

Find all elements by name.
"""
function findelements(n::AbstractODMNode, nname::Symbol)
    findelements_(n.el, nname)
end

"""
    findelements(n::AbstractODMNode, nnames::Vector{Symbol})

Find all elements by name in list.
"""
function findelements(n::AbstractODMNode, nnames::Vector{Symbol})
    findelements_(n.el, nname)
end

Base.findall(n::AbstractODMNode, args...) = findelements(n, args...)
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
    studylist(odm::ODMRoot; categ = false)

Returm table of Study elements.
"""
function studylist(odm::ODMRoot; categ = false)
    df = DataFrame(StudyOID = String[])
    for i in odm.el
        if isStudy(i)
            push!(df, (attribute(i, "OID"),))
        end
    end
    if categ
        transform!(df, :StudyOID => categorical, renamecols=false)
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
    findclinicaldata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Find ClinicalData by StudyOID and MetaDataVersionOID.

Returns single element or nothing.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    for i in odm.el
        if isClinicalData(i) && attribute(i, "StudyOID") == soid && attribute(i, "MetaDataVersionOID") == moid return i end
    end
    nothing
end

"""
    findclinicaldata(odm::ODMRoot, soid::AbstractString)

Find ClinicalData by StudyOID.

Returns vector.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString)
    inds = ODMNode[]
    for i in odm.el
        if isClinicalData(i) && attribute(i, "StudyOID") == soid 
            push!(inds, i)
        end
    end
    inds
end
"""
    findclinicaldata(odm::ODMRoot)

Find all ClinicalData.

Returns vector.
"""
function findclinicaldata(odm::ODMRoot)
    inds = ODMNode[]
    for i in odm.el
        if isClinicalData(i)
            push!(inds, i)
        end
    end
    inds
end
###########
#
###########
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
    eventlist(md::AbstractODMNode; optional = false, attrs = nothing, categ = false)

Return events (StudyEventDef).

Keywords:

* `optional` (true/false) - get optional attributes;
* `attrs` - get selected attributes;
* `categ` - return `OID` as categorical;
"""
function eventlist(md::AbstractODMNode; optional = false, attrs = nothing, categ = false)
    if isnothing(attrs)
        if optional
            attrs = (:OID, :Name, :Repeating, :Type, :Category)
        else
            attrs = (:OID, :Name, :Repeating, :Type)
        end
    end
    df = df_list(md, :StudyEventDef, attrs)

    if categ
        transform!(df, :OID => categorical, renamecols=false)
    end
    df
end
################################################################################
# Form
"""
    formlist(el::Vector{T}; attrs = nothing,  categ = false) where T <: AbstractODMNode

Return forms (FormDef).

Keywords:

* `attrs` - get selected attributes;
* `categ` - return `OID` as categorical;
"""
function formlist(el::Vector{T}; attrs = nothing,  categ = false) where T <: AbstractODMNode
    if isnothing(attrs)
        attrs = (:OID, :Name, :Repeating)
    end
    df = df_list(el, :FormDef, attrs)

    if categ && :OID in attrs
        transform!(df, :OID => categorical, renamecols=false)
    end
    df
end
"""
    formlist(md::AbstractODMNode)

Return forms (FormDef).
"""
function formlist(md::AbstractODMNode; kwargs...)
    formlist(md.el; kwargs...)
end
################################################################################
# ItemGroup
"""
    itemgrouplist(el::Vector{T}; optional = false, attrs = nothing, categ = false) where T <: AbstractODMNode

Return item groups (ItemGroupDef).

Keywords:

* `optional` (true/false) - get optional attributes;
* `attrs` - get selected attributes;
* `categ` - return `OID` as categorical;
"""
function itemgrouplist(el::Vector{T}; optional = false, attrs = nothing, categ = false) where T <: AbstractODMNode
    if isnothing(attrs)
        if optional
            attrs = (:OID, :Name, :Repeating, :SASDatasetName, :Comment)
        else
            attrs = (:OID, :Name, :Repeating)
        end
    end
    df = df_list(el, :ItemGroupDef, attrs)
    if categ && :OID in attrs
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
function itemgrouplist(md::AbstractODMNode; kwargs...)
    itemgrouplist(md.el; kwargs...)
end
################################################################################
# Item
"""
    itemlist(el::Vector{T}; optional = false, attrs = nothing, categ = false, datatype = nothing) where T <: AbstractODMNode

Get list of items.

Keywords:

* `optional` (true/false) - get optional attributes;
* `attrs` - get selected attributes;
* `categ` - return `OID` as categorical;
* `datatype` - select only this type of items (See DataType);
"""
function itemlist(el::Vector{T}; optional = false, attrs = nothing, categ = false, datatype = nothing) where T <: AbstractODMNode
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
            if !isnothing(datatype)
                if attribute(i, :DataType) != datatype continue end
            end
            push!(df, attributes(i, attrs))
        end
    end
    if categ && :OID in attrs
        transform!(df, :OID => categorical, renamecols=false)
    end
    df
end
"""
    itemlist(md::AbstractODMNode; kwargs...)

Return items (ItemDef).
"""
function itemlist(md::AbstractODMNode; kwargs...)
    itemlist(md.el;  kwargs...)
end
################################################################################
# CONTENT
################################################################################
function formcontent_(md, oid)
    ig   = findelement(md, :FormDef, oid)
    inds = ODMNode[]
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
    inds = ODMNode[]
    for i in ig.el
        if name(i) == :ItemRef
            el = findelement(md, :ItemDef, attribute(i, "ItemOID"))
            if !(isnothing(el)) push!(inds, el) end
        end
    end
    inds
end

"""
    formcontent(md, oid; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)

Return item groups (ItemGroupDef) for concrete form (FormDef) by OID.

"""
function formcontent(md, oid; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)
    inds = formcontent_(md, oid)
    itemgrouplist(inds; optional = optional, attrs = attrs)
end
"""
    itemgroupcontent(md, oid; kwargs...)

Return items (ItemDef) for concrete item group (ItemGroupDef) by OID.

If optional = true - return all optional attributes.

keywords see (itemlist)[@ref].
"""
function itemgroupcontent(md, oid; kwargs...)
    inds = itemgroupcontent_(md, oid)
    itemlist(inds; kwargs...)
end
###############################################################################
# Item form content
###############################################################################
function itemformcontent_(md, oid; kwargs...)
    inds   = ODMNode[]
    frm    = findelement(md, :FormDef, oid)
    if isnothing(frm) return inds end
    iginds = findelements(frm, :ItemGroupRef)
    for i in iginds
        igoid = attribute(i, :ItemGroupOID)
        append!(inds, itemgroupcontent_(md, igoid))
    end
    inds
end
"""
    itemsformcontent(md, oid; optional = false)

Return items (ItemDef) for concrete item form (FormDef) by OID.

keywords see (itemlist)[@ref].
"""
function itemformcontent(md, oid; kwargs...)
    inds = itemformcontent_(md, oid; kwargs...)
    itemlist(inds; kwargs...)
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
    if isnothing(mdat) error("MetaDataVersion not found (StudyOID: $(soid), MetaDataVersionOID: $(moid))") end
    stmd   = StudyMetaData(mdat, AbstractODMNode[])
    fillstmd_(stmd.el, stmd.metadata, odm)
    stmd
end


"""
    buildmetadata(odm::ODMRoot, moid::AbstractString)

Build MetaData from MetaDataVersion.
"""
function buildmetadata(odm::ODMRoot, moid::AbstractString)
    mdv = nothing
    for i in odm.el
        if name(i) == :Study
            mdv = findelement(i, :MetaDataVersion, moid)
            isnothing(mdv) || break
        end
    end
    if isnothing(mdv) return nothing end 
    stmd   = StudyMetaData(mdv, AbstractODMNode[])
    fillstmd_(stmd.el, stmd.metadata, odm)
    stmd
end

"""
    codelisttable(cd::AbstractODMNode; lang = nothing) where T <: AbstractODMNode

List of coded values.
"""
function codelisttable(cd::AbstractODMNode; lang = nothing)
    df = DataFrame(OID = String[], Name = String[], DataType = String[], CodedValue = String[], Rank = String[], OrderNumber = String[], Text = String[])

    cll  = findelements(cd, :CodeList)
    clil = ODMNode[] # CodeListItem
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
    itemcodelisttable(cd::AbstractODMNode; lang = nothing) where T <: AbstractODMNode

List of coded values.
"""
function itemcodelisttable(cd::AbstractODMNode; lang = nothing)
    df    = DataFrame(OID = String[], CodeListOID = String[], Name = String[], DataType = String[], Type = String[], CodedValue = String[], Rank = String[], OrderNumber = String[], Text = String[])
    idef  = findelements(cd, :ItemDef)
    for id in idef
        clr = findfirst(id, :CodeListRef)
        if !isnothing(clr)
            cla   = attribute(clr, :CodeListOID)
            cl    = findfirst(cd, :CodeList, cla)
            clil  = findelements(cl, [:CodeListItem, :EnumeratedItem])
            for cli in clil
                    dec  = findelement(cli, :Decode)
                        text = findelement(dec, :TranslatedText)
                        push!(df, (attribute(id, :OID),
                        cla,
                        attribute(cl, :Name),
                        attribute(cl, :DataType),
                        name(cli) == :CodeListItem ? "CodeListItem" : "EnumeratedItem",
                        attribute(cli, :CodedValue),
                        attribute(cli, :Rank),
                        attribute(cli, :OrderNumber),
                        content(text)))
            end
        end
    end
    df
end

function dfpush!(df, s, e, f, g, i, null)
    push!(df, (s,
    attribute(e, :StudyEventOID),
    attribute(e, :StudyEventRepeatKey),
    attribute(f, :FormOID),
    attribute(f, :FormRepeatKey),
    attribute(g, :ItemGroupOID),
    attribute(g, :ItemGroupRepeatKey),
    attribute(i, :ItemOID),
    getitemdatavalue(i, null)))
end
"""
    clinicaldatatable(cd::AbstractODMNode;
        itemgroup = nothing,
        form = nothing,
        item::Union{Nothing, AbstractString, <: AbstractVector{<:AbstractString}} = nothing,
        categ = false, 
        addstudyid = false,
        addstudyidcol = false,
        idlnames = nothing)

Return clinical data table in long formal. `cd` should be ClinicalData.

* `itemgroup` - only this ItemGroupOID;
* `form` - only this FormOID;
* `item` - only this ItemOID;
* `categ` - make collumns categorical;
* `addstudyid` - add StudyOID as prefix to SubjectKey: "StudyOID_SubjectKey";
* `addstudyidcol` - add StudyOID as collumn to dataframe;
* `idlnames` - only this types of data will be collected, for example: ItemData, ItemDataInteger, ets (if `nothing`` - all will be collected). 
"""
function clinicaldatatable(cd::AbstractODMNode;
        itemgroup = nothing,
        form = nothing,
        event = nothing,
        item::Union{Nothing, AbstractString, <: AbstractVector{<:AbstractString}} = nothing,
        categ = false, 
        addstudyid = false,
        addstudyidcol = false,
        idlnames = nothing,
        null = "NULL",
        drop = [:StudyEventRepeatKey, :FormRepeatKey])
    
        
    if name(cd) != :ClinicalData error("This is not ClinicalData") end
    # For TypedData
    datatype = String
    #df = DataFrame(SubjectKey = String[], StudyEventOID = CategoricalArray(String[]), FormOID = CategoricalArray(String[]), ItemGroupOID = CategoricalArray(String[]), ItemGroupRepeatKey = CategoricalArray(String[]), ItemOID = CategoricalArray(String[]), Value = String[])
    df = DataFrame(SubjectKey = String[], StudyEventOID = String[], StudyEventRepeatKey = String[], FormOID = String[], FormRepeatKey = String[], ItemGroupOID = String[], ItemGroupRepeatKey = String[], ItemOID = String[], Value = datatype[])
    if isnothing(idlnames)
        idlnames = pushfirst!(collect(ITEMDATATYPE), :ItemData)
    end
    if isa(item, AbstractString) item = [item] end
    
    for s in cd.el
        if isSubjectData(s)
            if addstudyid
                subjid = attribute(cd, :StudyOID)*"_"*attribute(s, :SubjectKey)
            else
                subjid = attribute(s, :SubjectKey)
            end
            for e in s.el
                if isStudyEventData(e)
                    if !isnothing(event)
                        if attribute(e, :StudyEventOID) != event continue end
                    end 
                    for f in e.el
                        if isFormData(f)
                            if !isnothing(form)
                                if attribute(f, :FormOID) != form continue end
                            end
                            for g in f.el
                                if isItemGroupData(g)
                                    if !isnothing(itemgroup)
                                        if attribute(g, :ItemGroupOID) != itemgroup continue end
                                    end
                                    for i in g.el
                                        if isItemData(i) || isItemDataType(i)
                                            if !isnothing(item)
                                                if !(attribute(i, :ItemOID) in item) continue end
                                            end
                                            dfpush!(df, subjid, e, f, g, i, null)
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
    if categ
        transform!(df, :StudyEventOID => categorical, renamecols=false)
        transform!(df, :FormOID => categorical, renamecols=false)
        transform!(df, :ItemGroupOID => categorical, renamecols=false)
        transform!(df, :ItemGroupRepeatKey => categorical, renamecols=false)
        transform!(df, :ItemOID => categorical, renamecols=false)
    end
    if addstudyidcol
        insertcols!(df, 1, :StudyOID=>fill(attribute(cd, :StudyOID), size(df, 1)); copycols=false)
    end
    if length(drop) > 0
        select!(df, Not(drop))
    end
    df
end
"""
    clinicaldatatable(odm::ODMRoot, soid::AbstractString, moid::AbstractString; itemgroup = nothing)

Return clinical data table in long formal.

* soid - StudyOID
* moid - MetaDataVersionOID
"""
function clinicaldatatable(odm::ODMRoot, soid::AbstractString, moid::AbstractString; kwargs...)
    cld  = findclinicaldata(odm, soid, moid)
    isnothing(cld) && error("ClinicalData not found")
    clinicaldatatable(cld; kwargs...)
end

"""
    clinicaldatatable(odm::ODMRoot, inds::AbstractVector{Int}; kwargs...)

Return clinical data table in long formal.

* inds -  indexes of clinicaldatalist table.
"""
function clinicaldatatable(odm::ODMRoot, inds::AbstractVector{Int}; kwargs...)
    cld  = findclinicaldata(odm)
    (length(cld) == 0) && error("ClinicalData not found")
    (length(inds) != length(unique(inds)))  && error("Inds not qnique")
    all(x -> x in 1:length(cld), inds) || error("Inds not in range 1:$(length(cld))")

    df = clinicaldatatable(cld[first(inds)]; kwargs...)
    if length(inds) > 1
        for i = 2:length(inds)
            append!(df, clinicaldatatable(cld[inds[i]]; kwargs...))
        end
    end
    df
end

"""
    clinicaldatatable(odm::ODMRoot, range::UnitRange{Int64}; kwargs...)

Return clinical data table in long formal.

* inds -  indexes of clinicaldatalist table.
"""
function clinicaldatatable(odm::ODMRoot, range::UnitRange{Int64}; kwargs...)
    cld  = findclinicaldata(odm)
    s = length(cld)
    s == 0 && error("ClinicalData not found")
    if !(range ⊆ 1:s)
        error("Range $range not ⊆ 1:$(length(cld))")
    end

    df = clinicaldatatable(cld[first(range)]; kwargs...)
    if length(range) > 1
        for i = 2:length(range)
            append!(df, clinicaldatatable(cld[range[i]]; kwargs...))
        end
    end
    df
end

"""
    clinicaldatatable(odm::ODMRoot; kwargs...)

Return clinical data table in long formal.

"""
function clinicaldatatable(odm::ODMRoot; kwargs...)
    cld  = findclinicaldata(odm)
    if length(cld) == 0 
        error("ClinicalData not found") 
    end
    df = clinicaldatatable(first(cld); kwargs...)
    if length(cld) > 1
        for i = 2:length(cld)
            append!(df, clinicaldatatable(cld[i]; kwargs...))
        end
    end
    df
end

"""
    clinicaldatatable(odm::ODMRoot, soid::AbstractString; kwargs...)

Return clinical data table in long formal.
"""
function clinicaldatatable(odm::ODMRoot, soid::AbstractString; kwargs...)
    cld  = findclinicaldata(odm, soid)
    if length(cld) == 0 
        error("ClinicalData not found") 
    end
    df = clinicaldatatable(first(cld); kwargs...)
    if length(cld) > 1
        for i = 2:length(cld)
            append!(df, clinicaldatatable(cld[i]; kwargs...))
        end
    end
    df
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
    inds = ODMNode[]
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

################################################################################
# Modification
################################################################################
"""
    deletestudy!(odm::ODMRoot, oid::AbstractString)

Delete study by OID.
"""
function deletestudy!(odm::ODMRoot, oid::AbstractString)
    inds = Int[]
    for i in 1:length(odm.el)
        if name(odm.el[i]) == :Study && attribute(odm.el[i], :OID) == oid
            push!(inds, i)
        end
    end
    if length(inds) > 0
        deleteat!(odm.el, inds)
    end
    odm
end

"""
    deletestudy!(odm::ODMRoot, soid::AbstractString)

Delete clinical data  by StudyOID (`soid`).
"""
function deleteclinicaldata!(odm::ODMRoot, soid::AbstractString)
    inds = Int[]
    for i in 1:length(odm.el)
        if name(odm.el[i]) == :ClinicalData && attribute(odm.el[i], :StudyOID) == soid
            push!(inds, i)
        end
    end
    if length(inds) > 0
        deleteat!(odm.el, inds)
    end
    odm
end