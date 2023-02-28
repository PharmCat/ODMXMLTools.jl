struct NodeInfo
    val::Symbol
    parent::Union{Symbol, Vector{Symbol}}
    attrs::Vector
    body::Union{Vector, String}
end

struct NodeXOR
    val::Vector
end

function attps(s::Symbol)
    if s == :!
        return "mandatory"
    elseif s == :?
        return "optional"
    end
    ""
end
function bodyps(s::Symbol)
    if s == :!
        return "mandatory"
    elseif s == :?
        return "optional (zero or one)"
    elseif s == :*
        return "optional (zero or more)"
    elseif s == :+
        return "mandatory (one or more)"
    end
    ""
end

function Base.show(io::IO, ni::NodeInfo)
    println(io, "Node info:")
    println(io, "Parent: $(ni.parent)")
    println(io, "Attributes:")
    if length(ni.attrs) == 0
        println(io, "    NONE")
    else
        for i in ni.attrs
            println(io, "    $(i[1]): $(attps(i[2])) ($(i[3]))")
        end
    end
    print(io, "Body:")
    if length(ni.body) == 0
        print(io, "\n    NONE")
    elseif isa(ni.body, String)
        print(io, "\n    $(ni.body)")
    else
        for i in ni.body
            print(io, "\n    "*bcvecstr(i))
        end
    end
end

function bcvecstr(el::Tuple{Symbol, Symbol})
    "$(el[1]): $(bodyps(el[2]))"
end
function bcvecstr(el::NodeXOR)
    str = "$(el.val[1][1]): $(bodyps(el.val[1][2]))"
    for i = 2:length(el.val)
        str *= " | $(el.val[i][1]): $(bodyps(el.val[i][2]))"
    end
    str
end

const NODEINFO = Dict{Symbol, NodeInfo}(
:Study => NodeInfo(:Study, 
    :ODM,
    [(:OID, :!,  :oid)],
    [(:GlobalVariables, :!), (:BasicDefinitions, :?), (:MetaDataVersion, :*)]
    ),
:GlobalVariables => NodeInfo(:GlobalVariables, 
    :Study,
    [],
    [(:StudyName, :!), (:StudyDescription, :!), (:ProtocolName, :!)]
    ),
:StudyName => NodeInfo(:StudyName, 
    :GlobalVariables,
    [],
    "name"
    ),
:StudyDescription => NodeInfo(:StudyDescription, 
    :GlobalVariables,
    [],
    "text"
    ),
:ProtocolName => NodeInfo(:ProtocolName, 
    :GlobalVariables,
    [],
    "name"
    ),
:BasicDefinitions => NodeInfo(:BasicDefinitions, 
    :Study,
    [],
    [(:MeasurementUnit, :*)]
    ),
:MeasurementUnit => NodeInfo(:MeasurementUnit, 
    :BasicDefinitions,
    [(:OID, :!,  :oid), (:Name, :!,  :text)],
    [(:Symbol, :!), (:Alias, :*)]
    ),
:Symbol => NodeInfo(:Symbol, 
    :MeasurementUnit,
    [],
    [(:TranslatedText, :+)]
    ),
:TranslatedText => NodeInfo(:TranslatedText, 
    [:Decode, :ErrorMessage, :Question, :Symbol, :Description],
    [(:lang, :?,  :languageTag)],
    "text"
    ),
:MetaDataVersion => NodeInfo(:MetaDataVersion, 
    :Study,
    [(:OID, :!,  :oid), (:Name, :!,  :name), (:Description, :?,  :text)],
    [(:Include, :?), (:Protocol, :?), (:StudyEventDef, :*), (:FormDef, :*), (:ItemGroupDef, :*), (:ItemDef, :*), (:CodeList, :*), (:Presentation, :*), (:ConditionDef, :*), (:MethodDef, :*)]
    ),
:Include => NodeInfo(:Include, 
    :MetaDataVersion,
    [(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref)],
    []
    ),
:Protocol => NodeInfo(:Protocol, 
    :MetaDataVersion,
    [],
    [(:Description, :?), (:StudyEventRef, :*), (:Alias, :*)]
    ),
:Description => NodeInfo(:Description, 
    [:Protocol, :StudyEventDef, :FormDef, :ItemGroupDef, :ItemDef, :ConditionDef, :MethodDef],
    [],
    [(:TranslatedText, :+)]
    ),
:StudyEventRef => NodeInfo(:StudyEventRef, 
    :Protocol,
    [(:StudyEventOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, [:Yes, :No]), (:CollectionExceptionConditionOID, :?,  :oidref)],
    []
    ),
:StudyEventDef => NodeInfo(:StudyEventDef, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), (:Name, :!,  :name), (:Repeating, :!, [:Yes, :No]), (:Type, :!, [:Scheduled,:Unscheduled,:Common]), (:Category, :?,  :text)],
    [(:Description, :?), (:FormRef, :*), (:Alias, :*)]
    ),
:FormRef => NodeInfo(:FormRef, 
    :StudyEventDef,
    [(:FormOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, [:Yes, :No]), (:CollectionExceptionConditionOID, :?,  :oidref)],
    []
    ),
:FormDef => NodeInfo(:FormDef, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), (:Name, :!,  :name), (:Repeating, :!, [:Yes, :No])],
    [(:Description, :?), (:ItemGroupRef, :*), (:ArchiveLayout, :*), (:Alias, :*)]
    ),
:ItemGroupRef => NodeInfo(:ItemGroupRef, 
    :FormDef,
    [(:ItemGroupOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, [:Yes, :No]), (:CollectionExceptionConditionOID, :?,  :oidref)],
    []
    ),
:ItemGroupDef => NodeInfo(:ItemGroupDef, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), (:Name, :!,  :name), (:Repeating, :!, [:Yes, :No]), (:IsReferenceData, :?, [:Yes, :No]), (:SASDatasetName, :?,  :sasName), (:Domain, :?,  :text), (:Origin, :?,  :text), (:Purpose, :?,  :text), (:Comment, :?,  :text)],
    [(:Description, :?), (:ItemRef, :*), (:Alias, :*)]
    ),
:ItemRef => NodeInfo(:ItemRef, 
    :ItemGroupDef,
    [(:ItemOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, [:Yes, :No]), (:KeySequence, :?,  :integer), (:MethodOID, :?,  :oidref), (:Role, :?,  :text), (:RoleCodeListOID, :?,  :oidref), (:CollectionExceptionConditionOID, :?,  :oidref)],
    []
    ),
:ItemDef => NodeInfo(:ItemDef, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), 
    (:Name, :!,  :name), 
    (:DataType, :!, [:text,:integer,:float,:date,:time,:datetime,:string,:boolean,:double,:hexBinary,:base64Binary,:hexFloat,:base64Float,:partialDate,:partialTime,:partialDatetime,:durationDatetime,:intervalDatetime,:incompleteDatetime,:incompleteDate,:incompleteTime,:URI]), 
    (:Length, :?,  :positiveInteger), 
    (:SignificantDigits, :?,  :nonNegativeInteger), 
    (:SASFieldName, :?,  :sasName), 
    (:SDSVarName, :?,  :sasName), 
    (:Origin, :?,  :text), 
    (:Comment, :?,  :text)],
    [(:Description, :?), (:Question, :?), (:ExternalQuestion, :?), (:MeasurementUnitRef, :*), (:RangeCheck, :*), (:CodeListRef, :?), (:Alias, :*)]
    ),
:Question => NodeInfo(:Question, 
    :ItemDef,
    [],
    [(:TranslatedText, :+)]
    ),
:ExternalQuestion => NodeInfo(:ExternalQuestion, 
    :ItemDef,
    [(:Dictionary, :?,  :text),(:Version, :?,  :text),(:Code, :?,  :text)],
    []
    ),
:MeasurementUnitRef => NodeInfo(:MeasurementUnitRef, 
    [:ItemData, :ItemDef, :RangeCheck],
    [(:MeasurementUnitOID, :!,  :oidref)],
    []
    ),
:RangeCheck => NodeInfo(:RangeCheck, 
    :ItemDef,
    [(:Comparator, :!, [:LT,:LE,:GT,:GE,:EQ,:NE,:IN,:NOTIN]), (:SoftHard, :!, [:Soft,:Hard])],
    [NodeXOR([(:CheckValue, :+), (:FormalExpression, :+)]), (:MeasurementUnitRef, :?), (:ErrorMessage, :?)]
    ),
:CheckValue => NodeInfo(:CheckValue, 
    :RangeCheck,
    [],
    "value"
    ),
:ErrorMessage => NodeInfo(:ErrorMessage, 
    :RangeCheck,
    [],
    [(:TranslatedText, :+)]
    ),
:CodeListRef => NodeInfo(:CodeListRef, 
    :ItemDef,
    [(:CodeListOID, :!,  :oidref)],
    []
    ),
:Alias => NodeInfo(:Alias, 
    [:Protocol, :StudyEventDef, :FormDef, :ItemGroupDef, :ItemDef, :CodeList, :CodeListItem, :EnumeratedItem, :MethodDef, :ConditionDef],
    [(:Context, :!,  :text), (:Name, :!,  :text)],
    []
    ),
:CodeList => NodeInfo(:CodeList, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), (:Name, :!,  :name), (:DataType, :!, [:integer,:float,:text,:string]), (:SASFormatName, :?,  :sasFormat)],
    [(:Description, :?), NodeXOR([(:CodeListItem, :+), (:EnumeratedItem, :+), (:ExternalCodeList, :!)]), (:Alias, :*)]
    ),
:CodeListItem => NodeInfo(:CodeListItem, 
    :CodeList,
    [(:CodedValue, :!,  :text), (:Rank, :?,  :float), (:OrderNumber, :?,  :integer)],
    [(:Decode, :!), (:Alias, :*)]
    ),
:Decode => NodeInfo(:Decode, 
    :CodeListItem,
    [],
    [(:TranslatedText, :+)]
    ),
:ExternalCodeList => NodeInfo(:ExternalCodeList, 
    :CodeList,
    [(:Dictionary, :?,  :text), (:Version, :?,  :text), (:ref, :?,  :text), (:href, :?,  :text)],
    []
    ),
:EnumeratedItem => NodeInfo(:EnumeratedItem, 
    :CodeList,
    [(:CodedValue, :!,  :text), (:Rank, :?,  :float), (:OrderNumber, :?,  :integer)],
    [(:Alias, :*)]
    ),
:ArchiveLayout => NodeInfo(:ArchiveLayout, 
    :FormDef,
    [(:OID, :!,  :oid), (:PdfFileName, :!,  :fileName), (:PresentationOID, :?,  :oidref)],
    []
    ),
:MethodDef => NodeInfo(:MethodDef, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), (:Name, :!,  :name), (:Type, :!, [:Computation,:Imputation,:Transpose,:Other])],
    [(:Description, :!),(:FormalExpression, :*),(:Alias, :*)]
    ),
:Presentation => NodeInfo(:Presentation, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), (:lang, :?,  :languageTag)],
    "text"
    ),
:ConditionDef => NodeInfo(:ConditionDef, 
    :MetaDataVersion,
    [(:OID, :!,  :oid), (:Name, :!,  :name)],
    [(:Description, :!),(:FormalExpression, :*),(:Alias, :*)]
    ),
:FormalExpression => NodeInfo(:FormalExpression, 
    [:ConditionDef, :MethodDef, :RangeCheck],
    [(:Context, :!,  :text)],
    "PCDATA"
    ),
:AdminData => NodeInfo(:AdminData, 
    :ODM,
    [(:StudyOID, :?,  :oidref)],
    [(:User, :*),(:Location, :*),(:SignatureDef, :*)]
    ),
:User => NodeInfo(:User, 
    :AdminData,
    [(:OID, :!,  :oid), (:UserType, :?, [:Sponsor,:Investigator,:Lab,:Other])],
    [(:LoginName, :?),(:DisplayName, :?),(:FullName, :?),
    (:FirstName, :?),(:LastName, :?),(:Organization, :?),
    (:Address, :*),(:Email, :*),(:Picture, :?),(:Pager, :?),(:Fax, :*),(:Phone, :*),(:LocationRef, :*),(:Certificate, :*)]
    ),
:LoginName => NodeInfo(:LoginName, 
    :User,
    [],
    "text"
    ),
:DisplayName => NodeInfo(:DisplayName, 
    :User,
    [],
    "text"
    ),
:FullName => NodeInfo(:FullName, 
    :User,
    [],
    "text"
    ),
:FirstName => NodeInfo(:FirstName, 
    :User,
    [],
    "text"
),
:LastName => NodeInfo(:LastName, 
    :User,
    [],
    "text"
),
:Organization => NodeInfo(:Organization, 
    :User,
    [],
    "text"
    ),
:Address => NodeInfo(:Address, 
    :User,
    [],
    [(:StreetName, :*),(:City, :?),(:StateProv, :?),
    (:Country, :?),(:PostalCode, :?),(:OtherText, :?)]
    ),
:StreetName => NodeInfo(:StreetName, 
    :Address,
    [],
    "text"
    ),
:City => NodeInfo(:City, 
    :Address,
    [],
    "text"
    ),
:StateProv => NodeInfo(:StateProv, 
    :Address,
    [],
    "text"
    ),
:Country => NodeInfo(:Country, 
    :Address,
    [],
    "text"
),
:PostalCode => NodeInfo(:PostalCode, 
    :Address,
    [],
    "text"
),
:OtherText => NodeInfo(:OtherText, 
    :Address,
    [],
    "text"
),
:Email => NodeInfo(:Email, 
    :User,
    [],
    "text"
),
:Picture => NodeInfo(:Picture, 
    :User,
    [(:PictureFileName, :!,  :fileName), (:ImageType, :?,  :name)],
    []
),
:Pager => NodeInfo(:Pager, 
    :User,
    [],
    "text"
),
:Fax => NodeInfo(:Fax, 
    :User,
    [],
    "text"
),
:Phone => NodeInfo(:Phone, 
    :User,
    [],
    "text"
),
:LocationRef => NodeInfo(:LocationRef, 
    [:AuditRecord, :Signature, :User],
    [(:LocationOID, :!,  :oidref)],
    "text"
),
:Certificate => NodeInfo(:Certificate, 
    :User,
    [],
    "text"
),
:Location => NodeInfo(:Location, 
    :AdminData,
    [(:OID, :!,  :oid), (:Name, :!,  :name), (:LocationType, :?, [:Sponsor,:Site,:CRO,:Lab,:Other])],
    [(:MetaDataVersionRef, :+)]
),
:MetaDataVersionRef => NodeInfo(:MetaDataVersionRef, 
    :Location,
    [(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref), (:EffectiveDate, :!,  :date)],
    []
),
:SignatureDef => NodeInfo(:SignatureDef, 
    :AdminData,
    [(:OID, :!,  :oid), (:Methodology, :?,  :oidref)],
    [(:Meaning, :!), (:LegalReason, :!)]
),
:Meaning => NodeInfo(:Meaning, 
    :SignatureDef,
    [],
    "text"
),
:LegalReason => NodeInfo(:LegalReason, 
    :SignatureDef,
    [],
    "text"
),
:ReferenceData => NodeInfo(:ReferenceData, 
    :ODM,
    [(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref)],
    [(:ItemGroupData, :*), (:AuditRecords, :*), (:Signatures, :*), (:Annotations, :*)]
),
:ClinicalData => NodeInfo(:ClinicalData, 
    :ODM,
    [(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref)],
    [(:SubjectData, :*), (:AuditRecords, :*), (:Signatures, :*), (:Annotations, :*)]
),
:SubjectData => NodeInfo(:SubjectData, 
    :ClinicalData,
    [(:SubjectKey, :!,  :subjectKey), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context])],
    [(:AuditRecord, :?), (:Signature, :?), (:InvestigatorRef, :?), (:SiteRef, :?), (:Annotation, :*), (:StudyEventData, :*)]
),
:StudyEventData => NodeInfo(:StudyEventData, 
    :SubjectData,
    [(:StudyEventOID, :!,  :oidref), (:StudyEventRepeatKey, :?,  :repeatKey), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context])],
    [(:AuditRecord, :?), (:Signature, :?),  (:Annotation, :*), (:FormData, :*)]
),
:FormData => NodeInfo(:FormData, 
    :StudyEventData,
    [(:FormOID, :!,  :oidref), (:FormRepeatKey, :?,  :repeatKey), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context])],
    [(:AuditRecord, :?), (:Signature, :?), (:ArchiveLayoutRef, :?), (:Annotation, :*), (:ItemGroupData, :*)]
),
:ItemGroupData => NodeInfo(:ItemGroupData, 
    [:FormData, :ReferenceData],
    [(:ItemGroupOID, :!,  :oidref), (:ItemGroupRepeatKey, :?,  :repeatKey), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context])],
    [(:AuditRecord, :?), (:Signature, :?),  (:Annotation, :*), NodeXOR([(:ItemData, :*), (:ItemDataTYPE, :*)])]
),
:ItemData => NodeInfo(:ItemData, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]), (:Value, :?,  :oidref), (:IsNull, :?, [:Yes])],
    [(:AuditRecord, :?), (:Signature, :?),  (:MeasurementUnitRef, :?), (:Annotation, :*)]
),
:ItemDataAny => NodeInfo(:ItemDataAny, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataString => NodeInfo(:ItemDataString, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataInteger => NodeInfo(:ItemDataInteger, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataFloat => NodeInfo(:ItemDataFloat, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataDate => NodeInfo(:ItemDataDate, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataTime => NodeInfo(:ItemDataTime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataDatetime => NodeInfo(:ItemDataDatetime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataBoolean => NodeInfo(:ItemDataBoolean, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataHexBinary => NodeInfo(:ItemDataHexBinary, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataBase64Binary => NodeInfo(:ItemDataBase64Binary, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataHexFloat => NodeInfo(:ItemDataHexFloat, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataBase64Float => NodeInfo(:ItemDataBase64Float, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataPartialDate => NodeInfo(:ItemDataPartialDate, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataPartialTime => NodeInfo(:ItemDataPartialTime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataPartialDatetime => NodeInfo(:ItemDataPartialDatetime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataDurationDatetime => NodeInfo(:ItemDataDurationDatetime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataIntervalDatetime => NodeInfo(:ItemDataIntervalDatetime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataIncompleteDatetime => NodeInfo(:ItemDataIncompleteDatetime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataIncompleteDate => NodeInfo(:ItemDataIncompleteDate, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataIncompleteTime => NodeInfo(:ItemDataIncompleteTime, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ItemDataURI => NodeInfo(:ItemDataURI, 
    :ItemGroupData,
    [(:ItemOID, :!,  :oidref), (:TransactionType, :?, [:Insert,:Update,:Remove,:Upsert,:Context]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, [:Yes])],
    "PCDATA"
),
:ArchiveLayoutRef => NodeInfo(:ArchiveLayoutRef, 
    :FormData,
    [(:ArchiveLayoutOID, :!,  :oidref)],
    []
),
:AuditRecord => NodeInfo(:AuditRecord, 
    [:FormData, :ItemData, :ItemGroupData, :StudyEventData, :SubjectData, :AuditRecords],
    [(:EditPoint, :?, [:Monitoring, :DataManagement, :DBAudit]), (:UsedImputationMethod, :?, [:Yes, :No]), (:ID, :?,  :ID)],
    [(:UserRef, :!), (:LocationRef, :!), (:DateTimeStamp, :!), (:ReasonForChange, :?), (:SourceID, :?)]
),
:UserRef => NodeInfo(:UserRef, 
    [:AuditRecord, :Signature],
    [(:UserOID, :!,  :oidref)],
    []
),
:DateTimeStamp => NodeInfo(:DateTimeStamp, 
    [:AuditRecord, :Signature],
    [],
    "datetime"
),
:ReasonForChange => NodeInfo(:ReasonForChange, 
    :AuditRecord,
    [],
    "text"
),
:SourceID => NodeInfo(:SourceID, 
    :AuditRecord,
    [],
    "text"
),
:Signature => NodeInfo(:Signature, 
    [:FormData, :ItemData, :ItemGroupData, :StudyEventData, :SubjectData, :Signatures],
    [(:ID, :?,  :ID)],
    [(:UserRef, :!), (:LocationRef, :!), (:SignatureRef, :!), (:DateTimeStamp, :?)]
),
:SignatureRef => NodeInfo(:SignatureRef, 
    :Signature,
    [(:SignatureOID, :!,  :oidref)],
    []
),
:Annotation => NodeInfo(:Annotation, 
    [:Association, :FormData, :ItemData, :ItemGroupData, :StudyEventData, :SubjectData, :Annotations],
    [(:SeqNum, :!,  :integer),(:TransactionType, :?, [:Insert , :Update , :Remove , :Upsert , :Context]),(:ID, :?,  :ID)],
    [(:Comment, :?), (:Flag, :*)]
),
:Comment => NodeInfo(:Comment, 
    :Annotation,
    [(:SponsorOrSite, :!, [:Sponsor, :Site ])],
    "text"
),
:Flag => NodeInfo(:Flag, 
    :Annotation,
    [],
    [(:FlagValue, :!), (:FlagType, :?)]
),
:FlagValue => NodeInfo(:FlagValue, 
    :Flag,
    [(:CodeListOID, :!,  :oidref)],
    "text"
),
:FlagType => NodeInfo(:FlagType, 
    :Flag,
    [(:CodeListOID, :!,  :oidref)],
    "name"
),
:InvestigatorRef => NodeInfo(:InvestigatorRef, 
    :SubjectData,
    [(:UserOID, :!,  :oidref)],
    []
),
:SiteRef => NodeInfo(:SiteRef, 
    :SubjectData,
    [(:LocationOID, :!,  :oidref)],
    []
),
:AuditRecords => NodeInfo(:AuditRecords, 
    [:ReferenceData, :ClinicalData],
    [],
    [(:AuditRecord, :*)]
),
:Signatures => NodeInfo(:Signatures, 
    [:ReferenceData, :ClinicalData],
    [],
    [(:Signature, :*)]
),
:Annotations => NodeInfo(:Annotations, 
    [:ReferenceData, :ClinicalData],
    [],
    [(:Annotation, :*)]
),
:Association => NodeInfo(:Association, 
    :ODM,
    [(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref)],
    [(:KeySet, :!),(:KeySet, :!),(:Annotation, :!)]
),
:KeySet => NodeInfo(:KeySet, 
    :Association,
    [(:StudyOID, :!,  :oidref), (:SubjectKey, :?,  :subjectKey), (:StudyEventOID, :?,  :oidref),
    (:StudyEventRepeatKey, :?,  :repeatKey), (:FormOID, :?,  :oidref), (:FormRepeatKey, :?,  :repeatKey), 
    (:ItemGroupOID, :?,  :oidref), (:ItemGroupRepeatKey, :?,  :repeatKey), (:ItemOID, :?,  :oidref)],
    []
),
:Association => NodeInfo(:Association, 
    :ODM,
    [(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref)],
    [(:KeySet, :!),(:KeySet, :!),(:Annotation, :!)]
),
)


const NODEINFO_DS = Dict{Symbol, NodeInfo}(
:Study => NodeInfo(:Study, 
    :ODM,
    [(:xmlns, :!, :CDATA), (:Id, :?, :ID)],
    [(:SignedInfo, :!), (:SignatureValue, :!), (:KeyInfo, :?), (:Object, :*)]
    )
)