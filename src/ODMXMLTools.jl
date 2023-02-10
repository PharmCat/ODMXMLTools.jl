module ODMXMLTools
    using  EzXML, DataFrames, AbstractTrees
    using CategoricalArrays
    #using Dates
	import AbstractTrees
    import AbstractTrees: children, isroot
    import Base: show, findfirst, findall

    export importxml,
    findclinicaldata,
    findstudy,
    findstudymetadata,
    findelement,
    findallelements,

    buildmetadata,

	metadatalist,
    eventlist,
    formlist,
    itemgrouplist,
    itemlist,
	clinicaldatalist,

	protocolcontent,
	eventcontent,
	formcontent,
    itemgroupcontent,

	itemformcontent,

	clinicaldatatable,
	codelisttable,
	itemcodelisttable,
	subjectdatatable,

	itemdescription,
	itemquestion,
	nodedesq,

    validateodm,
	checkdatavalues,
	children

    StrOrSym = Union{String, Symbol}

    const FILETYPE    = Set(["Snapshot", "Transactional"])
    const GRANULARITY = Set(["All", "Metadata", "AdminData", "ReferenceData", "AllClinicalData", "SingleSite", "SingleSubject"])
    const ARCHIVAL    = Set(["Yes", "No"])
    const ODMVERSION  = Set(["1.2", "1.2.1", "1.3", "1.3.1", "1.3.2"])


    const ODMNAMESPACE = Set([:Address
	:AdminData
	:Alias
	:Annotations
    :Annotation
	:ArchiveLayout
	:ArchiveLayoutRef
	:Association
	:AuditRecord
	:AuditRecords
	:BasicDefinitions
	:Certificate
	:CheckValue
	:City
	:ClinicalData
	:CodeList
	:CodeListItem
	:CodeListRef
	:Comment
	:ConditionDef
	:Country
	:CryptoBindingManifest
	:DateTimeStamp
	:Decode
	:Description
	:DisplayName
	:Email
	:EnumeratedItem
	:ErrorMessage
	:ExternalCodeList
	:ExternalQuestion
	:Fax
	:FirstName
	:Flag
	:FlagType
	:FlagValue
	:FormalExpression
	:FormData
	:FormDef
	:FormRef
	:FullName
	:GlobalVariables
	:ImputationMethod
	:Include
	:InvestigatorRef
	:ItemData
	:ItemDataAny
	:ItemDataBase64Binary
	:ItemDataBase64Float
	:ItemDataBoolean
	:ItemDataDate
	:ItemDataDatetime
	:ItemDataDouble
	:ItemDataDurationDatetime
	:ItemDataFloat
	:ItemDataHexBinary
	:ItemDataHexFloat
	:ItemDataIncompleteDate
	:ItemDataIncompleteDatetime
	:ItemDataIncompleteTime
	:ItemDataInteger
	:ItemDataIntervalDatetime
	:ItemDataPartialDate
	:ItemDataPartialDatetime
	:ItemDataPartialTime
	:ItemDataString
	:ItemDataTime
	:ItemDataURI
	:ItemDef
	:ItemGroupData
	:ItemGroupDef
	:ItemGroupRef
	:ItemRef
	:KeySet
	:LastName
	:LegalReason
	:Location
	:LocationRef
	:LoginName
	:Meaning
	:MeasurementUnit
	:MeasurementUnitRef
	:MetaDataVersion
	:MetaDataVersionRef
	:MethodDef
	:ODM
	:Organization
	:OtherText
	:Pager
	:Phone
	:Picture
	:PostalCode
	:Presentation
	:Protocol
	:ProtocolName
	:Question
	:RangeCheck
	:ReasonForChange
	:ReferenceData
	:Role
	:Signature
	:SignatureDef
	:SignatureRef
	:Signatures
	:SiteRef
	:SourceID
	:StateProv
	:StreetName
	:Study
	:StudyDescription
	:StudyEventData
	:StudyEventDef
	:StudyEventRef
	:StudyName
	:SubjectData
	:Symbol
	:TranslatedText
	:User
	:UserRef])


    const ODMATTRNAMESPACE = Set([:AddressAnnotationID
	:Archival
	:ArchiveLayoutOID
	:AsOfDateTime
	:AuditRecordID
	:Category
	:Code
	:CodedValue
	:CodeListOID
	:CollectionExceptionConditionOID
	:Comment
	:Comparator
	:Context
	:CreationDateTime
	:DataType
	:Description
	:Dictionary
	:Domain
	:EditPoint
	:EffectiveDate
	:FileOID
	:FileType
	:FormOID
	:FormRepeatKey
	:Granularity
	:ID
	:Id
	:ImageType
	:ImputationMethodOID
	:IsNull
	:IsReferenceData
	:ItemGroupOID
	:ItemGroupRepeatKey
	:ItemOID
	:KeySequence
	:Length
	:LocationOID
	:LocationType
	:Mandatory
	:MeasurementUnitOID
	:MetaDataVersionOID
	:MethodOID
	:Methodology
	:Name
	:ODMVersion
	:OID
	:OrderNumber
	:Origin
	:Originator
	:PdfFileName
	:PictureFileName
	:PresentationOID
	:PriorFileOID
	:Purpose
	:Rank
	:ref
	:Repeating
	:Role
	:RoleCodeListOID
	:SASDatasetName
	:SASFieldName
	:SASFormatName
	:SDSVarName
	:SeqNum
	:SignatureID
	:SignatureOID
	:SignificantDigits
	:SoftHard
	:SourceSystem
	:SourceSystemVersion
	:SponsorOrSite
	:StudyEventOID
	:StudyEventRepeatKey
	:StudyOID
	:SubjectKey
	:TransactionType
	:Type
	:UsedImputationMethod
	:UserOID
	:UserType
	:Value
	:Version
	:lang
	:xmlns])

    const ITEMDATATYPE = Set([:ItemDataAny
	:ItemDataBase64Binary
	:ItemDataBase64Float
	:ItemDataBoolean
	:ItemDataDate
	:ItemDataDatetime
	:ItemDataDouble
	:ItemDataDurationDatetime
	:ItemDataFloat
	:ItemDataHexBinary
	:ItemDataHexFloat
	:ItemDataIncompleteDate
	:ItemDataIncompleteDatetime
	:ItemDataIncompleteTime
	:ItemDataInteger
	:ItemDataIntervalDatetime
	:ItemDataPartialDate
	:ItemDataPartialDatetime
	:ItemDataPartialTime
	:ItemDataString
	:ItemDataTime
	:ItemDataURI])

	const DATATYPES = Set(["text"
	 "integer" 
	 "float"
	 "date"
	 "time"
	 "datetime" 
	 "string"
	 "boolean"
	 "double"
	 "hexBinary"
	 "base64Binary"
	 "hexFloat"
	 "base64Float"
	 "partialDate"
	 "partialTime"
	 "partialDatetime"
	 "durationDatetime"
	 "intervalDatetime"
	 "incompleteDatetime"
	 "incompleteDate"
	 "incompleteTime"
	 "URI"])

    const CHNS = Dict(
    :Symbol => [:TranslatedText],
    )

	const SPLSTRATTRS = Set([:Repeating
		:IsReferenceData
		:Mandatory
		:DataType
		:Type	
		:UserType
		:LocationType
		:Methodology
		:TransactionType
		:EditPoint
		:UsedImputationMethod
		:Comparator
		:SoftHard])

    include("odmxml.jl")
    include("checknode.jl")
    include("spss.jl")
	include("nodeinfo.jl")
    include("ocl.jl")

end # module
