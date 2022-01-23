module ODMXMLTools
    using  EzXML, DataFrames
    import Base: show, ht_keyindex

    export importxml,
    metadatalist,
    findclinicaldata,
    findstudy,
    findstudymetadata,
    findelement,
    findelement,
    findallelements,
    buildmetadata,
    eventlist,
    formlist,
    itemgrouplist,
    itemlist,
    itemgroupcontent
    
    include("odmxml.jl")

end # module
