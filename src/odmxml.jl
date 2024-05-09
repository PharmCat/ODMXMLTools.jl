abstract type AbstractODMNode end
abstract type AbstractODMNodeType end

struct ODMNodeType{Symbol} <: AbstractODMNodeType
    function ODMNodeType(s::Symbol)
        new{s}()
    end
end

struct ODMNode <: AbstractODMNode
    name::Symbol
    attr::Dict{Symbol, String}
    el::Vector{ODMNode}
    content::String
    namespace::Symbol

    function ODMNode(name, attr, content::String, namespace::Symbol) 
        new(name, attr, ODMNode[], content, namespace)
    end
    function ODMNode(name, attr, content, ::Nothing) 
        ODMNode(name, attr, content, Symbol(""))
    end
    function ODMNode(name, attr, ::Nothing, namespace) 
        ODMNode(name, attr, "", namespace)
    end
    function ODMNode(name, attr, content) 
        ODMNode(name, attr, content, Symbol(""))
    end
    function ODMNode(name, attr) 
        ODMNode(name, attr, "", Symbol(""))
    end
end

struct ODMRoot <: AbstractODMNode
    name::Symbol
    attr::Dict{Symbol, String}
    el::Vector{ODMNode}
    ns::Dict{String, Symbol}
    function ODMRoot(attr, ns)
        new(:ODM, attr, ODMNode[], ns)
    end
end

struct StudyMetaData <: AbstractODMNode
    metadata::ODMNode
    el::Vector{ODMNode}
end

struct NodeXOR
    val::Vector{Tuple{Symbol, Symbol}}
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

function Base.length(n::AbstractODMNode)
    length(n.el)
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
#=
function makenode(str, attr)
    #symb = Symbol(str)
    return ODMNode(Symbol(str), attr)
end
=#
function attributes_dict(n, ns)
    d = Dict{Symbol, String}()
    attributes_dict!(d, root, n)
    d
end
function attributes_dict!(d, ns, n)
    for i in EzXML.attributes(n)
            if EzXML.hasnamespace(i)
                pref = ns[EzXML.namespace(i)]
                k = Symbol(string(pref)*":"*i.name)
            else
                k = Symbol(i.name)
            end
            d[k] = i.content
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
    nsv = namespaces(xodm)
    if EzXML.hasnamespace(xodm)
        nsv = namespaces(xodm)
        push!(nsv, "xml" => "http://www.w3.org/XML/1998/namespace" )
    else
        nsv = ["xml" => "http://www.w3.org/XML/1998/namespace"]
    end
    ns    = Dict([p[2] => Symbol(p[1]) for p in nsv]...)
    odm   = ODMRoot(attributes_dict(xodm, ns), ns)
    importxml_(odm, xodm, ns)
    odm
end

function importxml_(parent, root, ns)
    if hasnode(root)
        chld = EzXML.eachelement(root)
        for c in chld
            content = nothing
            attr = Dict{Symbol, String}()
            #if iselement(c)
            attributes_dict!(attr, ns, c)
            if !haselement(c)
                tv = EzXML.eachnode(root)
                for t in tv
                    if istext(t)
                        content = nodecontent(c)
                        break
                    end
                end
            end
            if EzXML.hasnamespace(c)
                nns = ns[c.namespace]
            else
                nns = Symbol("")
            end
            odmn = ODMNode(Symbol(nodename(c)), attr, content, nns)
            push!(parent.el, odmn)
            if haselement(c) importxml_(odmn, c, ns) end
            #end
        end
    end
    parent
end

################################################################################
# BASE FUNCTIONS
################################################################################
function Base.deleteat!(node::AbstractODMNode, inds)
    deleteat!(node.el, inds)
end
################################################################################
# SUPPORT FUNCTIONS
################################################################################
"""
    hasattribute(n::AbstractODMNode, attr::Symbol)

Return `true` if node have attribute `attr`.
"""
function hasattribute(n::AbstractODMNode, attr::Symbol)
    haskey(getfield(n, :attr), attr)
end
"""
    attribute(n::AbstractODMNode, attr::Symbol, str::Bool = false)

Return attribute value. If `str` is `true` - always return `String`. 
"""
function attribute(n::AbstractODMNode, attr::Symbol, str::Bool = false)
    attrf = getfield(n, :attr)
    if haskey(attrf, attr) 
        return attrf[attr] 
    else 
        if str return "" else return missing end 
    end
end
function attribute(n::AbstractODMNode, attr::String, str::Bool = false)
    attribute(n, Symbol(attr), str)
end
function attributes(n::AbstractODMNode, attrs)
    broadcast(x-> attribute(n, x), attrs)
end

function setattribute!(n::AbstractODMNode, attr::Symbol, val::String)
    n.attr[attr] = val
end

function addattributes!(a, n::AbstractODMNode, attrs)
    for i in attrs
        push!(a, attribute(n, i))
    end
    a
end


"""
    name(n::ODMNode)

Return name of ODM node.
"""
function name(n::ODMNode)
    getfield(n, :name)
end
function name(::ODMRoot)
    :ODM
end
function name(::StudyMetaData)
    :StudyMetaData
end


isMetaDataVersion(node::AbstractODMNode) = name(node) == :MetaDataVersion
isStudy(node::AbstractODMNode) = name(node) == :Study
isStudyEventDef(node::AbstractODMNode) = name(node) == :StudyEventDef
isStudyEventRef(node::AbstractODMNode) = name(node) == :StudyEventRef
isFormDef(node::AbstractODMNode) = name(node) == :FormDef
isFormRef(node::AbstractODMNode) = name(node) == :FormRef

isClinicalData(node::AbstractODMNode) = name(node) == :ClinicalData
isSubjectData(node::AbstractODMNode) = name(node) == :SubjectData
isStudyEventData(node::AbstractODMNode) = name(node) == :StudyEventData
isFormData(node::AbstractODMNode) = name(node) == :FormData
isItemGroupData(node::AbstractODMNode) = name(node) == :ItemGroupData
isItemData(node::AbstractODMNode) = name(node) == :ItemData
isItemDataType(node::AbstractODMNode) = name(node) in ITEMDATATYPE


function have_oid(n::AbstractODMNode)
    hasattribute(n, :OID)
end
function appendelements!(inds::AbstractVector, n::AbstractODMNode, nname::Symbol)
    for i in n.el
        if name(i) == nname
            push!(inds, i)
        end
    end
    inds
end
#=
function appendelements!(inds::AbstractVector, n::AbstractODMNode, nname::Union{Set{Symbol}, AbstractVector{Symbol}})
    for i in n.el
        if name(i) in nname
            push!(inds, i)
        end
    end
    inds
end
=#
"""
    content(n::AbstractODMNode)
    
Return node content.
"""
function content(n::AbstractODMNode)
    n.content
end
function content(n::ODMRoot)
    ""
end
function content(::StudyMetaData)
    ""
end

function getitemdatavalue(n::AbstractODMNode, null)
    ina = attribute(n, :IsNull)
    if !ismissing(ina) && ina == "Yes" return null end
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
# MAKE NODE
################################################################################
"""
    mekenode!(root::AbstractODMNode, nname::Symbol, attrs::Dict = Dict(); content = nothing, namespace = Symbol(""), checkname = false, checkni = false)

Make ODM node in root.
"""
function mekenode!(root::AbstractODMNode, nname::Symbol, attrs::Dict = Dict(); content = nothing, namespace = Symbol(""), checkname = false, checkni = false)
    if checkname
        if nname ∉ ODMNAMESPACE error("Name $nname not in ODMNAMESPACE!") end
    end
    if checkni
        ni = NODEINFO[name(root)]
        if isa(ni.body, AbstractString) || isnothing(ni.body) error("Node can not be added to $(name(root))!") end
        nifail = true
        for e in ni.body
            if isa(e, NodeXOR)
                for j in e.val
                    if j[1] == nname 
                        nifail = false
                        break
                    end
                end
            else
                if e[1] == nname nifail = false end
            end
            if !nifail break end
        end
        if nifail error("Node can not be added to $(name(root))! See `ODMXMLTools.NODEINFO[:$(name(root))]`")  end
    end
    newnode = ODMNode(nname, attrs, content, namespace)
    push!(root.el, newnode)
    newnode
end

################################################################################
# BASIC FUNCTIONS
################################################################################
"""
    findelementbyattr(el::AbstractVector{<:AbstractODMNode}, nname::Symbol, attr::Symbol, value::AbstractString)

Find first element by node name `nname` with attribute `attr` equal `value`.
"""
function findelementbyattr(el::AbstractVector{<:AbstractODMNode}, nname::Symbol, attr::Symbol, value::AbstractString)
    for i in el
        if i.name == nname
            if hasattribute(i, attr)
                if attribute(i, attr) == value return i end
            end
        end
    end
end

function findelementbyattr(n::AbstractODMNode, nname::Symbol, attr::Symbol, value::AbstractString)
    findelementbyattr(n.el, nname, attr, value)
end
# First element
"""
    findelement(el::AbstractVector{AbstractODMNode}, nname::Symbol, oid::AbstractString)

Find first element by node name `nname` and `oid`.
"""
function findelement(el::AbstractVector{<:AbstractODMNode}, nname::Symbol, oid::AbstractString)
    for i in el
        if i.name == nname
            if have_oid(i)
                if attribute(i, :OID) == oid return i end
            end
        end
    end
end
"""
    findelement(n::AbstractODMNode, nname::Symbol, oid::AbstractString)

Find first element by node name `nname` and `oid`.
"""
function findelement(n::AbstractODMNode, nname::Symbol, oid::AbstractString)
    findelement(n.el, nname, oid)
end

"""
    findelement(n::AbstractODMNode, nname::Symbol)

Find first element by node name `nname`.
"""
function findelement(n::AbstractODMNode, nname::Symbol)
    for i in n.el
        if name(i) == nname
            return i
        end
    end
end
# All element
"""
    findelements(n::AbstractODMNode, nname::Symbol)

Find all elements by node name `nname`.
"""
function findelements(n::AbstractODMNode, nname::Symbol)
    findelements(n.el, nname)
end

"""
    findelements(n::AbstractODMNode, nnames::Vector{Symbol})

Find all elements by node name `nnames` (list).
"""
function findelements(n::AbstractODMNode, nnames::Vector{Symbol})
    findelements(n.el, nnames)
end
function findelements(el::AbstractVector{<:AbstractODMNode}, nname::Symbol)
    inds = ODMNode[]
    for i in el
        if name(i) == nname
            push!(inds, i)
        end
    end
    inds
end

function findelements(el::AbstractVector{<:AbstractODMNode}, nnames::Vector{Symbol})
    inds = ODMNode[]
    for i in el
        if name(i) in nnames
            push!(inds, i)
        end
    end
    inds
end

# Count
"""
    countelements(n::AbstractODMNode, nname::Symbol)

Count elements by node name `nname`.
"""
function countelements(n::AbstractODMNode, nname::Symbol)
    count(x-> nname == name(x), n.el)
end

##############
# Base find*
##############
"""
    findfirst(n::AbstractODMNode, nname::Symbol, oid::AbstractString)

Find first index of element.
"""
function Base.findfirst(n::AbstractODMNode, nname::Symbol, oid::AbstractString)
    for i in 1:length(n.el)
        el = n.el[i]
        if name(el) == nname
            if have_oid(el)
                if attribute(el, :OID) == oid return i end
            end
        end
    end
end
"""
    Base.findall(n::AbstractODMNode, nname::Symbol)

Find all elements indexes by node name `nname`.
"""
function Base.findall(n::AbstractODMNode, nname::Symbol)
    findall(n.el, nname)
end
function Base.findall(el::AbstractVector{<:AbstractODMNode}, nname::Symbol)
    inds = Int[]
    for i in 1:length(el)
        if name(el[i]) == nname
            push!(inds, i)
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

Find ClinicalData by StudyOID (`soid`) and MetaDataVersionOID (`moid`).

Returns single element or `nothing`.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    for i in odm.el
        if isClinicalData(i) && attribute(i, "StudyOID") == soid && attribute(i, "MetaDataVersionOID") == moid return i end
    end
    nothing
end

"""
    findclinicaldata(odm::ODMRoot, soid::AbstractString)

Find ClinicalData by StudyOID (`soid`).

Returns vector or empty vetctor if no elements found.
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

Returns vector or empty vetctor if no elements found.
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

Find Study element by OID (`oid`), `nothing`` if not found.
"""
function findstudy(odm::ODMRoot, oid::AbstractString)
    for i in odm.el
        if isStudy(i) && attribute(i, "OID") == oid return i end
    end
    nothing
end
"""
    findstudymetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)

Find MeteDataVersion by StudyOID (`soid`) and MetaDataVersionOID (`moid`).
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

Return StudyEventDef table (DataFrame).

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

Return FormDef table (DataFrame).

Keywords:

* `attrs` - get selected attributes;
* `categ` - return `OID` as categorical;
"""
function formlist(el::Vector{T}; optional = true, attrs = nothing,  categ = false) where T <: AbstractODMNode
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

Return FormDef table (DataFrame).
"""
function formlist(md::AbstractODMNode; kwargs...)
    formlist(md.el; kwargs...)
end
################################################################################
# ItemGroup
"""
    itemgrouplist(el::Vector{T}; optional = false, attrs = nothing, categ = false) where T <: AbstractODMNode

Return ItemGroupDef table (DataFrame).

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

Return ItemGroupDef table (DataFrame).

If `optional` == `true` - return all optional attributes.

`attrs` - get selected attributes.
"""
function itemgrouplist(md::AbstractODMNode; kwargs...)
    itemgrouplist(md.el; kwargs...)
end
################################################################################
# Item
"""
    itemlist(el::Vector{T}; optional = false, attrs = nothing, categ = false, datatype = nothing) where T <: AbstractODMNode

Return ItemDef table (DataFrame).

Keywords:

* if `optional` == `true` - return all optional attributes;
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
    df = DataFrame((a => Union{Missing, String}[] for a in attrs)...)
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

Return ItemDef table (DataFrame).
"""
function itemlist(md::AbstractODMNode; kwargs...)
    itemlist(md.el;  kwargs...)
end
################################################################################
# CONTENT
################################################################################
function eventcontent_(sed; optional = false, attrs = nothing, categ = false)
    if isnothing(attrs)
        if optional
            attrs = (:FormOID, :OrderNumber, :Mandatory, :CollectionExceptionConditionOID)
        else
            attrs = (:FormOID, :Mandatory)
        end
    end
    df = DataFrame((a => Union{Missing, String}[] for a in attrs)...)
    insertcols!(df, 1, :StudyEventOID => String[]) 
    for s in sed
        fr  = findelements(s, :FormRef)
        for f in fr
            push!(df, addattributes!(Union{Missing, String}[attribute(s, :OID)], f, attrs))
        end
    end
    if categ && :FormOID in attrs
        transform!(df, :FormOID => categorical, renamecols=false)
    end
    df
end

function formcontent_(sed; optional = false, attrs = nothing, categ = false)
    if isnothing(attrs)
        if optional
            attrs = (:ItemGroupOID, :OrderNumber, :Mandatory, :CollectionExceptionConditionOID)
        else
            attrs = (:ItemGroupOID, :Mandatory)
        end
    end
    df = DataFrame((a => Union{Missing, String}[] for a in attrs)...)
    insertcols!(df, 1, :FormOID => String[]) 
    for s in sed
        fr  = findelements(s, :ItemGroupRef)
        for f in fr
            push!(df, addattributes!(Union{Missing, String}[attribute(s, :OID)], f, attrs))
        end
    end
    if categ && :ItemGroupOID in attrs
        transform!(df, :ItemGroupOID => categorical, renamecols=false)
    end
    df
end

#=
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
=#
function itemgroupcontent_(sed; optional = false, attrs = nothing, categ = false)
    if isnothing(attrs)
        if optional
            attrs = (:ItemOID, :OrderNumber, :Mandatory, :KeySequence, :MethodOID, :Role, :RoleCodeListOID, :CollectionExceptionConditionOID)
        else
            attrs = (:ItemOID, :Mandatory)
        end
    end
    df = DataFrame((a => Union{Missing, String}[] for a in attrs)...)
    insertcols!(df, 1, :ItemGroupOID => String[]) 
    for s in sed
        fr  = findelements(s, :ItemRef)
        for f in fr
            push!(df, addattributes!(Union{Missing, String}[attribute(s, :OID)], f, attrs))
        end
    end
    if categ && :ItemOID in attrs
        transform!(df, :ItemOID => categorical, renamecols=false)
    end
    df
end

"""
    function protocolcontent(md; optional = false, attrs = nothing, categ = false)

"""
function protocolcontent(md; optional = false, attrs = nothing, categ = false)
    pr   = findelement(md, :Protocol)
    ser  = findelements(pr, :StudyEventRef)
    if isnothing(attrs)
        if optional
            attrs = (:StudyEventOID, :OrderNumber, :Mandatory, :CollectionExceptionConditionOID)
        else
            attrs = (:StudyEventOID, :Mandatory)
        end
    end
    df = DataFrame((a => Union{Missing, String}[] for a in attrs)...)
    for i in ser
        push!(df, attributes(i, attrs))
    end
    if categ && :StudyEventOID in attrs
        transform!(df, :StudyEventOID => categorical, renamecols=false)
    end
    df
end

"""
    eventcontent(md; kwargs...)

Return FormRef table (DataFrame) for concrete form (StudyEventDef).

if `optional` == `true` - return all optional attributes.
"""
function eventcontent(md; kwargs...)
    sed   = findelements(md, :StudyEventDef)
    eventcontent_(sed; kwargs...)
end
"""
    eventcontent(md, oid; kwargs...)    

Return FormRef table (DataFrame) for concrete form (StudyEventDef) by `oid`.

if `optional` == `true` - return all optional attributes.
"""
function eventcontent(md, oid; kwargs...)
    sed   = [findelement(md, :StudyEventDef, oid)]
    eventcontent_(sed; kwargs...)
end

"""
    formcontent(md; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)

Return ItemGroupRef table (DataFrame) for concrete form (FormDef).

if `optional` == `true` - return all optional attributes.
"""
function formcontent(md; kwargs...)
    sed   = findelements(md, :FormDef)
    formcontent_(sed; kwargs...)
end
"""
    formcontent(md, oid; optional = false, attrs::Union{AbstractVector, Nothing} = nothing)

Return ItemGroupRef table (DataFrame) for concrete form (FormDef) by `oid`.

if `optional` == `true` - return all optional attributes.
"""
function formcontent(md, oid; kwargs...)
    sed   = [findelement(md, :FormDef, oid)]
    formcontent_(sed; kwargs...)
end

"""
    itemgroupcontent(md; kwargs...)

Return ItemRef table (DataFrame) for concrete group (ItemGroupDef).

"""
function itemgroupcontent(md; kwargs...)
    sed   = findelements(md, :ItemGroupDef)
    itemgroupcontent_(sed; kwargs...)
end
"""
    itemgroupcontent(md, oid; kwargs...)

Return ItemRef table (DataFrame) for concrete group (ItemGroupDef) by `oid`.

"""
function itemgroupcontent(md, oid; kwargs...)
    sed   = [findelement(md, :ItemGroupDef, oid)]
    itemgroupcontent_(sed; kwargs...)
end
###############################################################################
# Item form content
###############################################################################
function itemgroupdefcontent_(md, oid)
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
# using by spss spss_form_variable_labels
function itemformdefcontent_(md, oid; kwargs...)
    inds   = ODMNode[]
    frm    = findelement(md, :FormDef, oid)
    if isnothing(frm) return inds end
    iginds = findelements(frm, :ItemGroupRef)
    for i in iginds
        igoid = attribute(i, :ItemGroupOID)
        append!(inds, itemgroupdefcontent_(md, igoid))
    end
    inds
end

"""
    itemsformlist(md, oid; optional = false)

Return ItemDef table (DataFrame) for concrete form (FormDef) by `oid`.

keywords see (itemlist)[@ref].
"""
function itemformlist(md, oid; kwargs...)
    inds = itemformdefcontent_(md, oid; kwargs...)
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

Build MetaData from MetaDataVersion by StudyOID (`soid`) and MetaDataVersionOID (`moid`).
"""
function buildmetadata(odm::ODMRoot, soid::AbstractString, moid::AbstractString)
    mdat   = findstudymetadata(odm, soid, moid)
    if isnothing(mdat) error("MetaDataVersion not found (StudyOID: $(soid), MetaDataVersionOID: $(moid))") end
    stmd   = StudyMetaData(mdat, ODMNode[])
    fillstmd_(stmd.el, stmd.metadata, odm)
    inds = findall(stmd, :Include)
    if length(inds) > 0 deleteat!(stmd, inds) end
    stmd
end

function buildmetadata(odm::ODMRoot, mdat::AbstractODMNode)
    if name(mdat) != :MetaDataVersion error("This is not a MetaDataVersion (nod name - $(name(mdat)))") end
    stmd   = StudyMetaData(mdat, ODMNode[])
    fillstmd_(stmd.el, stmd.metadata, odm)
    stmd
end
#########################################################################
#########################################################################
function nodedesqu_(md::AbstractODMNode, tnode::Symbol, nname::Symbol; lang)
    tnode in [:Protocol, :StudyEventDef, :FormDef, :ItemGroupDef, :ItemDef, :ConditionDef, :MethodDef] || error("Wrong node name")
    nname in [:Description, :Question] || error("nname can be only :Description or :Question")
    if nname == :Question && tnode != :ItemDef error(":Question can be applied only to :ItemDef") end

    it = findelements(md, tnode)
    df = DataFrame(("lang_"*a => Union{Missing, String}[] for a in lang)...)
    insertcols!(df, 1, :OID => String[]) 
    for i in it
        row = [attribute(i, :OID)]
        d = findelement(i, nname)
        if !isnothing(d)
            tn = findelements(d, :TranslatedText)
            for l in lang
                destext = ""
                for t in tn
                    tattr = attribute(t, :lang) 
                    tattr = ismissing(tattr) ? "" : tattr
                    if tattr == l destext = content(t) end
                end
                push!(row, destext)
            end
            push!(df, row)
        end
    end
    df
end

"""
    nodedesq(md::AbstractODMNode, tnode::Symbol, nname::Symbol; lang = ["en"])

Get desctriptions or questions for node `tnode`.
    
`nname` can be only `:Description` or `:Question`.
"""
function nodedesq(md::AbstractODMNode, tnode::Symbol, nname::Symbol; lang = ["en"])
    nodedesqu_(md, tnode, nname; lang = lang)
end

"""
    itemdescription(md::AbstractODMNode; lang = ["en"])

ItemDef descriptions.
"""
function itemdescription(md::AbstractODMNode; lang = ["en"])
    nodedesqu_(md::AbstractODMNode, :ItemDef, :Description; lang = lang)
end

"""
    itemquestion(md::AbstractODMNode; lang = ["en"])

ItemDef questions.
"""
function itemquestion(md::AbstractODMNode; lang = ["en"])
    nodedesqu_(md::AbstractODMNode, :ItemDef, :Question; lang = lang)
end

"""
    codelisttable(cd::AbstractODMNode; lang = nothing)

Return CodeList table (DataFrame).
"""
function codelisttable(cd::AbstractODMNode; lang = "en")
    df = DataFrame(OID = String[], Name = String[], DataType = String[], CodedValue = String[], Rank = Union{Missing, String}[], OrderNumber = Union{Missing, String}[], Text = String[])

    cll  = findelements(cd, :CodeList)
    clil = ODMNode[] # CodeListItem
    for cl in cll
        resize!(clil, 0)
        appendelements!(clil, cl, :CodeListItem)
        for cli in clil
            dec  = findelement(cli, :Decode)
            tn = findelements(dec, :TranslatedText)
            text = content(first(tn))
            if length(tn) > 1
                for i = 2:length(tn)
                    if attribute(tn[i], Symbol("xml:lang")) == lang 
                        text = content(tn[i])
                        break
                    end
                end
            end
            push!(df, (attribute(cl, :OID),
            attribute(cl, :Name),
            attribute(cl, :DataType),
            attribute(cli, :CodedValue),
            attribute(cli, :Rank),
            attribute(cli, :OrderNumber),
            text))
        end
    end
    df
end

"""
    codelistitemdecode(cli; lang = nothing, nolangerr = true, nolangval = "")

Return TranslatedText content for Decode node.
"""
function codelistitemdecode(cli; lang = nothing, nolangerr = true, nolangval = "")
    if name(cli) != :CodeListItem  error("Wrong node name ($(name(cli)), not CodeListItem)") end
    decodenode = findelement(cli, :Decode)
    if isnothing(decodenode) error("No Decode node in CodeListItem") end
    t = findelements(decodenode, :TranslatedText)
    if length(t) == 0 error("No TranslatedText node in Decode") end
    if isnothing(lang)
        return content(first(t))
    else
        for tv in t 
            if attribute(tv, :lang)  == lang return content(first(tv)) end
        end
    end
    if nolangerr error("No TranslatedText for lang $lang found") end
    return nolangval
end
"""
    itemcodelisttable(cd::AbstractODMNode; lang = nothing) where T <: AbstractODMNode

Same as `codelisttable`, but return ItemDef (DataFrame).
"""
function itemcodelisttable(cd::AbstractODMNode; lang = nothing)
    df    = DataFrame(OID = String[], CodeListOID = String[], Name = String[], DataType = String[], Type = String[], CodedValue = String[], Rank = Union{Missing, String}[], OrderNumber = Union{Missing, String}[], Text = String[])
    idef  = findelements(cd, :ItemDef)
    for id in idef
        clr = findelement(id, :CodeListRef)
        if !isnothing(clr)
            cla   = attribute(clr, :CodeListOID)
            cl    = findelement(cd, :CodeList, cla)
            clil  = findelements(cl, [:CodeListItem, :EnumeratedItem])
            for cli in clil
                    dec  = findelement(cli, :Decode)
                        tn = findelements(dec, :TranslatedText)
                        text = content(first(tn))
                        if length(tn) > 1
                            for i = 2:length(tn)
                                if attribute(tn[i], Symbol("xml:lang")) == lang 
                                    text = content(tn[i])
                                    break
                                end
                            end
                        end
                        push!(df, (attribute(id, :OID),
                        cla,
                        attribute(cl, :Name),
                        attribute(cl, :DataType),
                        name(cli) == :CodeListItem ? "CodeListItem" : "EnumeratedItem",
                        attribute(cli, :CodedValue),
                        attribute(cli, :Rank),
                        attribute(cli, :OrderNumber),
                        text))
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
        event = nothing,
        item::Union{Nothing, AbstractString, <: AbstractVector{<:AbstractString}} = nothing,
        categ = false, 
        addstudyid = false,
        addstudyidcol = false,
        idlnames = nothing,
        null = "NULL",
        drop = [:StudyEventRepeatKey, :FormRepeatKey])

Return clinical data table in long formal. `cd` should be ClinicalData.

* `itemgroup` - only this ItemGroupOID;
* `form` - only this FormOID;
* `item` - only this ItemOID;
* `categ` - make collumns categorical;
* `addstudyid` - add StudyOID as prefix to SubjectKey: "StudyOID_SubjectKey";
* `addstudyidcol` - add StudyOID as collumn to dataframe;
* `null` = "NULL" - default `NULL` values; 
* `idlnames` - only this types of data will be collected, for example: ItemData, ItemDataInteger, ets (if `nothing`` - all will be collected). 
* `drop` - drop columns.
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
    df = DataFrame(SubjectKey = String[], 
    StudyEventOID = String[], 
    StudyEventRepeatKey = Union{Missing, String}[], 
    FormOID = String[], 
    FormRepeatKey = Union{Missing, String}[], 
    ItemGroupOID = String[], 
    ItemGroupRepeatKey = Union{Missing, String}[], 
    ItemOID = String[], 
    Value = datatype[])

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

Return ClinicalData table in long formal.

* `soid` - StudyOID;
* `moid` - MetaDataVersionOID.
"""
function clinicaldatatable(odm::ODMRoot, soid::AbstractString, moid::AbstractString; kwargs...)
    cld  = findclinicaldata(odm, soid, moid)
    isnothing(cld) && error("ClinicalData not found")
    clinicaldatatable(cld; kwargs...)
end

"""
    clinicaldatatable(odm::ODMRoot, inds::AbstractVector{Int}; kwargs...)

Return ClinicalData table in long formal.

* `inds` -  indexes of clinicaldatalist table.
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

Return ClinicalData table in long formal.

* `inds` -  indexes of clinicaldatalist table.
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

Return ClinicalData table in long formal.

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

Return ClinicalData table in long formal.
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

Subject information table.
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
            inmd = findstudymetadata(odm, attribute(i, :StudyOID), attribute(i, :MetaDataVersionOID))
            if isnothing(inmd) error("MetaDataVersion for inclusion (StudyOID: $(attribute(i, :StudyOID)), MetaDataVersionOID: $(attribute(i, :MetaDataVersionOID))) not found!") end
            fillstmd_(dest, inmd, odm)
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
    deletestudy!(odm::ODMRoot, soid::AbstractString)

Delete Study by StudyOID (`soid`).
"""
function deletestudy!(odm::ODMRoot, soid::AbstractString)
    inds = Int[]
    for i in 1:length(odm.el)
        if name(odm.el[i]) == :Study && attribute(odm.el[i], :OID) == soid
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

Delete ClinicalData by StudyOID (`soid`).
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


#
#
#

function writenode(node::AbstractODMNode)
    writenode(stdout, node::AbstractODMNode)
end
"""
    writenode(io::IO, node::AbstractODMNode)

Write XML node into IO.
"""
function writenode(io::IO, node::AbstractODMNode)
    println(io, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    writenode(io::IO, node::AbstractODMNode, 0)
end
function writenode(io::IO, node::AbstractODMNode, sp::Int)
    if sp > 0
        for n in 1:sp print(io, "    ") end
    end
    print(io, "<$(name(node))")
    attrs = NODEINFO[name(node)].attrs
    for a in attrs
        if hasattribute(node, a[1])
            print(io, " $(a[1])=\"$(Markdown.htmlesc(attribute(node, a[1])))\"")
        end
    end
    if length(content(node)) > 0 || length(node) > 0
        print(io, ">", Markdown.htmlesc(content(node)))
        if length(node.el) > 0
            println(io, "")
            for n in node.el
                writenode(io, n, sp + 1)
            end
            if sp > 0
                for n in 1:sp print(io, "    ") end
            end
        end
        println(io, "</$(name(node))>")
    else
        println(io, "/>")
    end
end
function writenode(file::String, node::AbstractODMNode; sp = 1)
    f = open(file, "w")
    try
        writenode(f, node, sp)
    finally
        close(f)
    end
    nothing
end

##########################################################################
##
##########################################################################

function compare(x::Symbol, v::Tuple{Symbol, Symbol})
    x == v[1]
end
function compare(x::Symbol, v::NodeXOR)
    for i in v.val
        if compare(x, i) return true end
    end
    false
end

function findnum(x, v)
    for i = 1:length(v)
        if compare(x, v[i]) return i end 
    end
    return length(v)+1
end

function nodeisless(x::AbstractODMNode, y::AbstractODMNode, root::Symbol)
    ni = NODEINFO[root]
    if name(x) == name(y)
        if hasattribute(x, :OrderNumber) && hasattribute(y, :OrderNumber) 
            xv = tryparse(Int, attribute(x, :OrderNumber))
            yv = tryparse(Int, attribute(y, :OrderNumber))
            if !isnothing(xv) && !isnothing(yv)
                return isless(xv, yv)
            end
        end
        if hasattribute(x, :OID)
            return isless(attribute(x, :OID), attribute(y, :OID))
        elseif hasattribute(x, :FormOID)
            return isless(attribute(x, :FormOID), attribute(y, :FormOID))
        elseif hasattribute(x, :ItemGroupOID)
            return isless(attribute(x, :ItemGroupOID), attribute(y, :ItemGroupOID))
        elseif hasattribute(x, :ItemOID)
            return isless(attribute(x, :ItemOID), attribute(y, :ItemOID))
        elseif hasattribute(x, :StudyOID)
            return isless(attribute(x, :StudyOID), attribute(y, :StudyOID))
        elseif hasattribute(x, :StudyOID)
            return isless(attribute(x, :StudyOID), attribute(y, :StudyOID))
        elseif hasattribute(x, :MeasurementUnitRef)
            return isless(attribute(x, :MeasurementUnitRef), attribute(y, :MeasurementUnitRef))
        elseif hasattribute(x, :MeasurementUnitOID)
            return isless(attribute(x, :MeasurementUnitOID), attribute(y, :MeasurementUnitOID))
        elseif hasattribute(x, :CodeListOID)
            return isless(attribute(x, :CodeListOID), attribute(y, :CodeListOID))
        else
            return false
        end
    else
        return isless(findnum(name(x), ni.body), findnum(name(y), ni.body))
    end
end

"""
    sortelements!(node::AbstractODMNode, rec::Bool = true)

Try to sort node elements as in Specification for the Operational Data Model (ODM).


`rec` - recursive.
"""
function sortelements!(node::AbstractODMNode, rec::Bool = true)
    if length(node.el) > 0
        sort!(node.el; lt = (x,y) -> nodeisless(x, y, name(node)))
        if rec
            for e in node.el
                sortelements!(e, rec)
            end
        end
    end
end


#####################################################################
## MAKE NODES
#####################################################################
"""
    makeclinicaldata!(odm::ODMRoot, soid::String, moid::String)

Make ClinicalData in ODM.
"""
function makeclinicaldata!(odm::ODMRoot, soid::String, moid::String)
    for i in odm.el
        if isClinicalData(i)
            if attribute(i, "StudyOID") == soid && attribute(i, "MetaDataVersionOID") == moid
                error("ODM has ClinicalData with same StudyOID and MetaDataVersionOID")
            end
        end
    end
    mekenode!(odm, :ClinicalData, Dict(:StudyOID => soid, :MetaDataVersionOID => moid))
end