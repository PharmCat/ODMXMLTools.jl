module ODMXMLTools
    using  EzXML, DataFrames, Dates, AbstractTrees
    import AbstractTrees: children
    import Base: show, ht_keyindex

    export importxml,
    metadatalist,
    findclinicaldata,
    findstudy,
    findstudymetadata,
    findelement,
    findallelements,
    buildmetadata,
    eventlist,
    formlist,
    itemgrouplist,
    itemlist,
    itemgroupcontent,
    validateodm,
    clinicaldatatable

    const FILETYPE    = Set(["Snapshot", "Transactional"])
    const GRANULARITY = Set(["All", "Metadata", "AdminData", "ReferenceData", "AllClinicalData", "SingleSite", "SingleSubject"])
    const ARCHIVAL    = Set(["Yes", "No"])
    const ODMVERSION  = Set(["1.2", "1.2.1", "1.3", "1.3.1", "1.3.2"])

    include("odmxml.jl")
    include("checknode.jl")
    include("spss.jl")

end # module
