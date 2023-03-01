struct NodeInfo{A<:Union{Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}}, B<:Union{Vector{Tuple{Symbol, Symbol}}, Vector{Union{Tuple{Symbol, Symbol}, NodeXOR}}, String}}
    val::Symbol
    parent::Vector{Symbol}
    attrs::Vector{A}
    body::B
    function NodeInfo(val, parent, attrs, body)
        if isa(parent, Symbol) parent = [parent] end 
        new{eltype(attrs), typeof(body)}(val, parent, attrs, body)
    end
    function NodeInfo(val, parent, ::Nothing, body)
        NodeInfo(val, parent, Tuple{Symbol, Symbol, Symbol}[], body)
    end
    function NodeInfo(val, parent, attrs, ::Nothing)
        NodeInfo(val, parent, attrs, Tuple{Symbol, Symbol}[])
    end
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
:ODM => NodeInfo(:ODM, 
    :XML,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:Description, :?,  :text),
    (:FileType, :!,  ["Snapshot","Transactional"]),
    (:Granularity, :?,["All","Metadata","AdminData","ReferenceData","AllClinicalData","SingleSite", "SingleSubject"]),
    (:Archival, :?,  ["Yes", "No"]),
    (:FileOID, :?,  :oid),
    (:CreationDateTime, :?,  :datetime),
    (:PriorFileOID, :?,  :oidref),
    (:AsOfDateTime, :?,  :datetime),
    (:ODMVersion, :?,  ["1.2","1.2.1","1.3","1.3.1","1.3.2"]),
    (:Originator, :?,  :text),
    (:SourceSystem, :?,  :text),
    (:SourceSystemVersion, :?,  :text),
    (:ID, :?,  :ID)],
    [(:GlobalVariables, :!), (:BasicDefinitions, :?), (:MetaDataVersion, :*)]
    ),
:Study => NodeInfo(:Study, 
    :ODM,
    Tuple{Symbol, Symbol, Symbol}[(:OID, :!,  :oid)],
    [(:GlobalVariables, :!), (:BasicDefinitions, :?), (:MetaDataVersion, :*)]
    ),
:GlobalVariables => NodeInfo(:GlobalVariables, 
    :Study,
    nothing,
    Tuple{Symbol, Symbol}[(:StudyName, :!), (:StudyDescription, :!), (:ProtocolName, :!)]
    ),
:StudyName => NodeInfo(:StudyName, 
    :GlobalVariables,
    nothing,
    "name"
    ),
:StudyDescription => NodeInfo(:StudyDescription, 
    :GlobalVariables,
    nothing,
    "text"
    ),
:ProtocolName => NodeInfo(:ProtocolName, 
    :GlobalVariables,
    nothing,
    "name"
    ),
:BasicDefinitions => NodeInfo(:BasicDefinitions, 
    :Study,
    nothing,
    [(:MeasurementUnit, :*)]
    ),
:MeasurementUnit => NodeInfo(:MeasurementUnit, 
    :BasicDefinitions,
    Tuple{Symbol, Symbol, Symbol}[(:OID, :!,  :oid), (:Name, :!,  :text)],
    Tuple{Symbol, Symbol}[(:Symbol, :!), (:Alias, :*)]
    ),
:Symbol => NodeInfo(:Symbol, 
    :MeasurementUnit,
    nothing,
    Tuple{Symbol, Symbol}[(:TranslatedText, :+)]
    ),
:TranslatedText => NodeInfo(:TranslatedText, 
    [:Decode, :ErrorMessage, :Question, :Symbol, :Description],
    Tuple{Symbol, Symbol, Symbol}[(:lang, :?,  :languageTag)],
    "text"
    ),
:MetaDataVersion => NodeInfo(:MetaDataVersion, 
    :Study,
    Tuple{Symbol, Symbol, Symbol}[(:OID, :!,  :oid), (:Name, :!,  :name), (:Description, :?,  :text)],
    Tuple{Symbol, Symbol}[(:Include, :?), (:Protocol, :?), (:StudyEventDef, :*), (:FormDef, :*), (:ItemGroupDef, :*), (:ItemDef, :*), (:CodeList, :*), (:Presentation, :*), (:ConditionDef, :*), (:MethodDef, :*)]
    ),
:Include => NodeInfo(:Include, 
    :MetaDataVersion,
    Tuple{Symbol, Symbol, Symbol}[(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref)],
    nothing
    ),
:Protocol => NodeInfo(:Protocol, 
    :MetaDataVersion,
    nothing,
    [(:Description, :?), (:StudyEventRef, :*), (:Alias, :*)]
    ),
:Description => NodeInfo(:Description, 
    [:Protocol, :StudyEventDef, :FormDef, :ItemGroupDef, :ItemDef, :ConditionDef, :MethodDef],
    nothing,
    Tuple{Symbol, Symbol}[(:TranslatedText, :+)]
    ),
:StudyEventRef => NodeInfo(:StudyEventRef, 
    :Protocol,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:StudyEventOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, ["Yes", "No"]), (:CollectionExceptionConditionOID, :?,  :oidref)],
    nothing
    ),
:StudyEventDef => NodeInfo(:StudyEventDef, 
    :MetaDataVersion,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), (:Name, :!,  :name), (:Repeating, :!, ["Yes", "No"]), (:Type, :!, ["Scheduled","Unscheduled","Common"]), (:Category, :?,  :text)],
    Tuple{Symbol, Symbol}[(:Description, :?), (:FormRef, :*), (:Alias, :*)]
    ),
:FormRef => NodeInfo(:FormRef, 
    :StudyEventDef,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:FormOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, ["Yes", "No"]), (:CollectionExceptionConditionOID, :?,  :oidref)],
    nothing
    ),
:FormDef => NodeInfo(:FormDef, 
    :MetaDataVersion,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), (:Name, :!,  :name), (:Repeating, :!, ["Yes", "No"])],
    [(:Description, :?), (:ItemGroupRef, :*), (:ArchiveLayout, :*), (:Alias, :*)]
    ),
:ItemGroupRef => NodeInfo(:ItemGroupRef, 
    :FormDef,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemGroupOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, ["Yes", "No"]), (:CollectionExceptionConditionOID, :?,  :oidref)],
    nothing
    ),
:ItemGroupDef => NodeInfo(:ItemGroupDef, 
    :MetaDataVersion,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), (:Name, :!,  :name), (:Repeating, :!, ["Yes", "No"]), (:IsReferenceData, :?, ["Yes", "No"]), (:SASDatasetName, :?,  :sasName), (:Domain, :?,  :text), (:Origin, :?,  :text), (:Purpose, :?,  :text), (:Comment, :?,  :text)],
    [(:Description, :?), (:ItemRef, :*), (:Alias, :*)]
    ),
:ItemRef => NodeInfo(:ItemRef, 
    :ItemGroupDef,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:OrderNumber, :?,  :integer), (:Mandatory, :!, ["Yes", "No"]), (:KeySequence, :?,  :integer), (:MethodOID, :?,  :oidref), (:Role, :?,  :text), (:RoleCodeListOID, :?,  :oidref), (:CollectionExceptionConditionOID, :?,  :oidref)],
    nothing
    ),
:ItemDef => NodeInfo(:ItemDef, 
    :MetaDataVersion,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), 
    (:Name, :!,  :name), 
    (:DataType, :!, ["text","integer","float","date","time","datetime","string","boolean","double","hexBinary","base64Binary","hexFloat","base64Float","partialDate","partialTime", "partialDatetime","durationDatetime","intervalDatetime","incompleteDatetime","incompleteDate","incompleteTime","URI"]), 
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
    nothing,
    [(:TranslatedText, :+)]
    ),
:ExternalQuestion => NodeInfo(:ExternalQuestion, 
    :ItemDef,
    [(:Dictionary, :?,  :text),(:Version, :?,  :text),(:Code, :?,  :text)],
    nothing
    ),
:MeasurementUnitRef => NodeInfo(:MeasurementUnitRef, 
    [:ItemData, :ItemDef, :RangeCheck],
    [(:MeasurementUnitOID, :!,  :oidref)],
    nothing
    ),
:RangeCheck => NodeInfo(:RangeCheck, 
    :ItemDef,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:Comparator, :!, ["LT","LE","GT","GE","EQ","NE","IN","NOTIN"]), (:SoftHard, :!, ["Soft","Hard"])],
    Union{NodeXOR, Tuple{Symbol, Symbol}}[NodeXOR([(:CheckValue, :+), (:FormalExpression, :+)]), (:MeasurementUnitRef, :?), (:ErrorMessage, :?)]
    ),
:CheckValue => NodeInfo(:CheckValue, 
    :RangeCheck,
    nothing,
    "value"
    ),
:ErrorMessage => NodeInfo(:ErrorMessage, 
    :RangeCheck,
    nothing,
    [(:TranslatedText, :+)]
    ),
:CodeListRef => NodeInfo(:CodeListRef, 
    :ItemDef,
    [(:CodeListOID, :!,  :oidref)],
    nothing
    ),
:Alias => NodeInfo(:Alias, 
    [:Protocol, :StudyEventDef, :FormDef, :ItemGroupDef, :ItemDef, :CodeList, :CodeListItem, :EnumeratedItem, :MethodDef, :ConditionDef],
    [(:Context, :!,  :text), (:Name, :!,  :text)],
    nothing
    ),
:CodeList => NodeInfo(:CodeList, 
    :MetaDataVersion,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), (:Name, :!,  :name), (:DataType, :!, ["integer","float","text","string"]), (:SASFormatName, :?,  :sasFormat)],
    Union{NodeXOR, Tuple{Symbol, Symbol}}[(:Description, :?), NodeXOR([(:CodeListItem, :+), (:EnumeratedItem, :+), (:ExternalCodeList, :!)]), (:Alias, :*)]
    ),
:CodeListItem => NodeInfo(:CodeListItem, 
    :CodeList,
    [(:CodedValue, :!,  :text), (:Rank, :?,  :float), (:OrderNumber, :?,  :integer)],
    [(:Decode, :!), (:Alias, :*)]
    ),
:Decode => NodeInfo(:Decode, 
    :CodeListItem,
    nothing,
    [(:TranslatedText, :+)]
    ),
:ExternalCodeList => NodeInfo(:ExternalCodeList, 
    :CodeList,
    [(:Dictionary, :?,  :text), (:Version, :?,  :text), (:ref, :?,  :text), (:href, :?,  :text)],
    nothing
    ),
:EnumeratedItem => NodeInfo(:EnumeratedItem, 
    :CodeList,
    [(:CodedValue, :!,  :text), (:Rank, :?,  :float), (:OrderNumber, :?,  :integer)],
    [(:Alias, :*)]
    ),
:ArchiveLayout => NodeInfo(:ArchiveLayout, 
    :FormDef,
    [(:OID, :!,  :oid), (:PdfFileName, :!,  :fileName), (:PresentationOID, :?,  :oidref)],
    nothing
    ),
:MethodDef => NodeInfo(:MethodDef, 
    :MetaDataVersion,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), (:Name, :!,  :name), (:Type, :!, ["Computation","Imputation","Transpose","Other"])],
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
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), (:UserType, :?, ["Sponsor","Investigator","Lab","Other"])],
    [(:LoginName, :?),(:DisplayName, :?),(:FullName, :?),
    (:FirstName, :?),(:LastName, :?),(:Organization, :?),
    (:Address, :*),(:Email, :*),(:Picture, :?),(:Pager, :?),(:Fax, :*),(:Phone, :*),(:LocationRef, :*),(:Certificate, :*)]
    ),
:LoginName => NodeInfo(:LoginName, 
    :User,
    nothing,
    "text"
    ),
:DisplayName => NodeInfo(:DisplayName, 
    :User,
    nothing,
    "text"
    ),
:FullName => NodeInfo(:FullName, 
    :User,
    nothing,
    "text"
    ),
:FirstName => NodeInfo(:FirstName, 
    :User,
    nothing,
    "text"
),
:LastName => NodeInfo(:LastName, 
    :User,
    nothing,
    "text"
),
:Organization => NodeInfo(:Organization, 
    :User,
    nothing,
    "text"
    ),
:Address => NodeInfo(:Address, 
    :User,
    nothing,
    [(:StreetName, :*),(:City, :?),(:StateProv, :?),
    (:Country, :?),(:PostalCode, :?),(:OtherText, :?)]
    ),
:StreetName => NodeInfo(:StreetName, 
    :Address,
    nothing,
    "text"
    ),
:City => NodeInfo(:City, 
    :Address,
    nothing,
    "text"
    ),
:StateProv => NodeInfo(:StateProv, 
    :Address,
    nothing,
    "text"
    ),
:Country => NodeInfo(:Country, 
    :Address,
    nothing,
    "text"
),
:PostalCode => NodeInfo(:PostalCode, 
    :Address,
    nothing,
    "text"
),
:OtherText => NodeInfo(:OtherText, 
    :Address,
    nothing,
    "text"
),
:Email => NodeInfo(:Email, 
    :User,
    nothing,
    "text"
),
:Picture => NodeInfo(:Picture, 
    :User,
    [(:PictureFileName, :!,  :fileName), (:ImageType, :?,  :name)],
    nothing
),
:Pager => NodeInfo(:Pager, 
    :User,
    nothing,
    "text"
),
:Fax => NodeInfo(:Fax, 
    :User,
    nothing,
    "text"
),
:Phone => NodeInfo(:Phone, 
    :User,
    nothing,
    "text"
),
:LocationRef => NodeInfo(:LocationRef, 
    [:AuditRecord, :Signature, :User],
    [(:LocationOID, :!,  :oidref)],
    "text"
),
:Certificate => NodeInfo(:Certificate, 
    :User,
    nothing,
    "text"
),
:Location => NodeInfo(:Location, 
    :AdminData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:OID, :!,  :oid), (:Name, :!,  :name), (:LocationType, :?, ["Sponsor","Site","CRO","Lab","Other"])],
    [(:MetaDataVersionRef, :+)]
),
:MetaDataVersionRef => NodeInfo(:MetaDataVersionRef, 
    :Location,
    [(:StudyOID, :!,  :oidref), (:MetaDataVersionOID, :!,  :oidref), (:EffectiveDate, :!,  :date)],
    nothing
),
:SignatureDef => NodeInfo(:SignatureDef, 
    :AdminData,
    [(:OID, :!,  :oid), (:Methodology, :?,  :oidref)],
    [(:Meaning, :!), (:LegalReason, :!)]
),
:Meaning => NodeInfo(:Meaning, 
    :SignatureDef,
    nothing,
    "text"
),
:LegalReason => NodeInfo(:LegalReason, 
    :SignatureDef,
    nothing,
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
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:SubjectKey, :!,  :subjectKey), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"])],
    [(:AuditRecord, :?), (:Signature, :?), (:InvestigatorRef, :?), (:SiteRef, :?), (:Annotation, :*), (:StudyEventData, :*)]
),
:StudyEventData => NodeInfo(:StudyEventData, 
    :SubjectData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:StudyEventOID, :!,  :oidref), (:StudyEventRepeatKey, :?,  :repeatKey), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"])],
    [(:AuditRecord, :?), (:Signature, :?),  (:Annotation, :*), (:FormData, :*)]
),
:FormData => NodeInfo(:FormData, 
    :StudyEventData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:FormOID, :!,  :oidref), (:FormRepeatKey, :?,  :repeatKey), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"])],
    [(:AuditRecord, :?), (:Signature, :?), (:ArchiveLayoutRef, :?), (:Annotation, :*), (:ItemGroupData, :*)]
),
:ItemGroupData => NodeInfo(:ItemGroupData, 
    [:FormData, :ReferenceData],
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemGroupOID, :!,  :oidref), (:ItemGroupRepeatKey, :?,  :repeatKey), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"])],
    Union{NodeXOR, Tuple{Symbol, Symbol}}[(:AuditRecord, :?), (:Signature, :?),  (:Annotation, :*), NodeXOR([(:ItemData, :*), (:ItemDataTYPE, :*)])]
),
:ItemData => NodeInfo(:ItemData, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]), (:Value, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    [(:AuditRecord, :?), (:Signature, :?),  (:MeasurementUnitRef, :?), (:Annotation, :*)]
),
:ItemDataAny => NodeInfo(:ItemDataAny, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataString => NodeInfo(:ItemDataString, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataInteger => NodeInfo(:ItemDataInteger, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataFloat => NodeInfo(:ItemDataFloat, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataDate => NodeInfo(:ItemDataDate, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataTime => NodeInfo(:ItemDataTime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataDatetime => NodeInfo(:ItemDataDatetime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataBoolean => NodeInfo(:ItemDataBoolean, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataHexBinary => NodeInfo(:ItemDataHexBinary, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataBase64Binary => NodeInfo(:ItemDataBase64Binary, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataHexFloat => NodeInfo(:ItemDataHexFloat, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataBase64Float => NodeInfo(:ItemDataBase64Float, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataPartialDate => NodeInfo(:ItemDataPartialDate, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataPartialTime => NodeInfo(:ItemDataPartialTime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataPartialDatetime => NodeInfo(:ItemDataPartialDatetime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataDurationDatetime => NodeInfo(:ItemDataDurationDatetime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataIntervalDatetime => NodeInfo(:ItemDataIntervalDatetime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataIncompleteDatetime => NodeInfo(:ItemDataIncompleteDatetime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataIncompleteDate => NodeInfo(:ItemDataIncompleteDate, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataIncompleteTime => NodeInfo(:ItemDataIncompleteTime, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ItemDataURI => NodeInfo(:ItemDataURI, 
    :ItemGroupData,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:ItemOID, :!,  :oidref), (:TransactionType, :?, ["Insert","Update","Remove","Upsert","Context"]),  
    (:AuditRecordID, :?,  :IDREF), (:SignatureID, :?,  :IDREF), (:AnnotationID, :?,  :IDREF), (:MeasurementUnitOID, :?,  :oidref), (:IsNull, :?, ["Yes"])],
    "PCDATA"
),
:ArchiveLayoutRef => NodeInfo(:ArchiveLayoutRef, 
    :FormData,
    [(:ArchiveLayoutOID, :!,  :oidref)],
    nothing
),
:AuditRecord => NodeInfo(:AuditRecord, 
    [:FormData, :ItemData, :ItemGroupData, :StudyEventData, :SubjectData, :AuditRecords],
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:EditPoint, :?, ["Monitoring", "DataManagement", "DBAudit"]), (:UsedImputationMethod, :?, ["Yes", "No"]), (:ID, :?,  :ID)],
    [(:UserRef, :!), (:LocationRef, :!), (:DateTimeStamp, :!), (:ReasonForChange, :?), (:SourceID, :?)]
),
:UserRef => NodeInfo(:UserRef, 
    [:AuditRecord, :Signature],
    [(:UserOID, :!,  :oidref)],
    nothing
),
:DateTimeStamp => NodeInfo(:DateTimeStamp, 
    [:AuditRecord, :Signature],
    nothing,
    "datetime"
),
:ReasonForChange => NodeInfo(:ReasonForChange, 
    :AuditRecord,
    nothing,
    "text"
),
:SourceID => NodeInfo(:SourceID, 
    :AuditRecord,
    nothing,
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
    nothing
),
:Annotation => NodeInfo(:Annotation, 
    [:Association, :FormData, :ItemData, :ItemGroupData, :StudyEventData, :SubjectData, :Annotations],
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:SeqNum, :!,  :integer),(:TransactionType, :?, ["Insert" , "Update" , "Remove ", "Upsert" , "Context"]),(:ID, :?,  :ID)],
    [(:Comment, :?), (:Flag, :*)]
),
:Comment => NodeInfo(:Comment, 
    :Annotation,
    Tuple{Symbol, Symbol, Union{Symbol, Vector{String}}}[(:SponsorOrSite, :!, ["Sponsor", "Site"])],
    "text"
),
:Flag => NodeInfo(:Flag, 
    :Annotation,
    nothing,
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
    nothing
),
:SiteRef => NodeInfo(:SiteRef, 
    :SubjectData,
    [(:LocationOID, :!,  :oidref)],
    nothing
),
:AuditRecords => NodeInfo(:AuditRecords, 
    [:ReferenceData, :ClinicalData],
    nothing,
    [(:AuditRecord, :*)]
),
:Signatures => NodeInfo(:Signatures, 
    [:ReferenceData, :ClinicalData],
    nothing,
    [(:Signature, :*)]
),
:Annotations => NodeInfo(:Annotations, 
    [:ReferenceData, :ClinicalData],
    nothing,
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
    nothing
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