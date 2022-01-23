
    abstract type AbstractODMNode end

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
        metadata
        el
    end

    #AbstractTrees.children(x::ODMNode) = x.el
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
    findclinicaldata(odm::ODMRoot, soid::AbstractString)

Returt ClinicalData element by study OID (`soid`), nothing if not found.
"""
function findclinicaldata(odm::ODMRoot, soid::AbstractString)
    for i in odm.el
        if i.name == :ClinicalData && attribute(i, "StudyOID") == soid return i end
    end
    nothing
end
"""
    findstudy(odm::ODMRoot, oid)

Find Study element by OID (`oid`), nothing if not found.
"""
function findstudy(odm::ODMRoot, oid)
    for i in odm.el
        if i.name == :Study && attribute(i, "OID") == oid return i end
    end
end

    function findstudymetadata(odm::ODMRoot, soid, moid)
        study = findstudy(odm, soid)
        findelement(study, :MetaDataVersion, moid)
    end
    function have_oid(n::AbstractODMNode)
        if ht_keyindex(n.attr, "OID") > 0 return true else return false end
    end
    function findelement(n::AbstractODMNode, name, oid)
        for i in n.el
            if i.name == name
                if have_oid(i)
                    if i.attr["OID"] == oid return i end
                end
            end
        end
    end
    function findelement(n::AbstractODMNode, name)
        for i in n.el
            if i.name == name
                return i
            end
        end
    end
    function findallelements(n::AbstractODMNode, name)
        inds = AbstractODMNode[]
        for i in n.el
            if i.name == name
                push!(inds, i)
            end
        end
        inds
    end
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
        incl = findallelements(source, :Include)
        if length(incl) > 0
            for i in incl
                fillstmd_(dest, findstudymetadata(odm, attribute(i, "StudyOID"), attribute(i, "MetaDataVersionOID")), odm)
            end
        end
        dest
    end
    function buildmetadata(odm::ODMRoot, soid, moid)
        mdat   = findstudymetadata(odm, soid, moid)
        stmd   = StudyMetaData(mdat, AbstractODMNode[])
        fillstmd_(stmd.el, stmd.metadata, odm)
        stmd
    end

    function eventlist(md::AbstractODMNode)
        df = DataFrame(OID = String[], Name = String[], Repeating= String[], Type = String[])
        for i in md.el
            if name(i) == :StudyEventDef
                push!(df, [attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating"), attribute(i, "Type")])
            end
        end
        df
    end
    function formlist(md::AbstractODMNode)
        df = DataFrame(OID = String[], Name = String[], Repeating= String[])
        for i in md.el
            if name(i) == :FormDef
                push!(df, [attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating")])
            end
        end
        df
    end
    function itemgrouplist(md::AbstractODMNode)
        df = DataFrame(OID = String[], Name = String[], Repeating= String[])
        for i in md.el
            if name(i) == :ItemGroupDef
                push!(df, [attribute(i, "OID"), attribute(i, "Name"), attribute(i, "Repeating")])
            end
        end
        df
    end
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
                    push!(df, [attribute(i, "OID"), attribute(i, "Name"), attribute(i, "DataType"),
                    attribute(i, "Length"), attribute(i, "SignificantDigits"),
                    attribute(i, "SASFieldName"), attribute(i, "SDSVarName"),
                    attribute(i, "Origin"), attribute(i, "Comment")])
                end
            end
        else
            df = DataFrame(OID = String[], Name = String[], DataType= String[])
            for i in el
                if name(i) == :ItemDef
                    push!(df, [attribute(i, "OID"), attribute(i, "Name"), attribute(i, "DataType")])
                end
            end
        end
        df
    end

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
