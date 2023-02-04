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
    [(:OID, :!, "oid")],
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
    [(:OID, :!, "oid"), (:Name, :!, "text")],
    [(:Symbol, :!), (:Alias, :*)]
    ),
:Symbol => NodeInfo(:Symbol, 
    :MeasurementUnit,
    [],
    [(:TranslatedText, :+)]
    ),
:TranslatedText => NodeInfo(:TranslatedText, 
    [:Decode, :ErrorMessage, :Question, :Symbol, :Description],
    [(:lang, :?, "languageTag")],
    "text"
    ),
:MetaDataVersion => NodeInfo(:MetaDataVersion, 
    :Study,
    [(:OID, :!, "oid"), (:Name, :!, "name"), (:Description, :?, "text")],
    [(:Include, :?), (:Protocol, :?), (:StudyEventDef, :*), (:FormDef, :*), (:ItemGroupDef, :*), (:ItemDef, :*), (:CodeList, :*), (:Presentation, :*), (:ConditionDef, :*), (:MethodDef, :*)]
    ),
:Include => NodeInfo(:Include, 
    :MetaDataVersion,
    [(:StudyOID, :!, "oidref"), (:MetaDataVersionOID, :!, "oidref")],
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
    [(:StudyEventOID, :!, "oidref"), (:OrderNumber, :?, "integer"), (:Mandatory, :!, "Yes|No"), (:CollectionExceptionConditionOID, :?, "oidref")],
    []
    ),
:StudyEventDef => NodeInfo(:StudyEventDef, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), (:Name, :!, "name"), (:Repeating, :!, "Yes|No"), (:Type, :!, "Scheduled|Unscheduled|Common"), (:Category, :?, "text")],
    [(:Description, :?), (:FormRef, :*), (:Alias, :*)]
    ),
:FormRef => NodeInfo(:FormRef, 
    :StudyEventDef,
    [(:FormOID, :!, "oidref"), (:OrderNumber, :?, "integer"), (:Mandatory, :!, "Yes|No"), (:CollectionExceptionConditionOID, :?, "oidref")],
    []
    ),
:FormDef => NodeInfo(:FormDef, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), (:Name, :!, "name"), (:Repeating, :!, "Yes|No")],
    [(:Description, :?), (:ItemGroupRef, :*), (:ArchiveLayout, :*), (:Alias, :*)]
    ),
:ItemGroupRef => NodeInfo(:ItemGroupRef, 
    :FormDef,
    [(:ItemGroupOID, :!, "oidref"), (:OrderNumber, :?, "integer"), (:Mandatory, :!, "Yes|No"), (:CollectionExceptionConditionOID, :?, "oidref")],
    []
    ),
:ItemGroupDef => NodeInfo(:ItemGroupDef, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), (:Name, :!, "name"), (:Repeating, :!, "Yes|No"), (:IsReferenceData, :?, "Yes|No"), (:SASDatasetName, :?, "sasName"), (:Domain, :?, "text"), (:Origin, :?, "text"), (:Purpose, :?, "text"), (:Comment, :?, "text")],
    [(:Description, :?), (:ItemRef, :*), (:Alias, :*)]
    ),
:ItemRef => NodeInfo(:ItemRef, 
    :ItemGroupDef,
    [(:ItemOID, :!, "oidref"), (:OrderNumber, :?, "integer"), (:Mandatory, :!, "Yes|No"), (:KeySequence, :?, "integer"), (:MethodOID, :?, "oidref"), (:Role, :?, "text"), (:RoleCodeListOID, :?, "oidref"), (:CollectionExceptionConditionOID, :?, "oidref")],
    []
    ),
:ItemDef => NodeInfo(:ItemDef, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), 
    (:Name, :!, "name"), 
    (:DataType, :!, "text|integer|float|date|time|datetime|string|boolean|double|hexBinary|base64Binary|hexFloat|base64Float|partialDate|partialTime|partialDatetime|durationDatetime|intervalDatetime|incompleteDatetime|incompleteDate|incompleteTime|URI"), 
    (:Length, :?, "positiveInteger"), 
    (:SignificantDigits, :?, "nonNegativeInteger"), 
    (:SASFieldName, :?, "sasName"), 
    (:SDSVarName, :?, "sasName"), 
    (:Origin, :?, "text"), 
    (:Comment, :?, "text")],
    [(:Description, :?), (:Question, :?), (:ExternalQuestion, :?), (:MeasurementUnitRef, :*), (:RangeCheck, :*), (:CodeListRef, :?), (:Alias, :*)]
    ),
:Question => NodeInfo(:Question, 
    :ItemDef,
    [],
    [(:TranslatedText, :+)]
    ),
:ExternalQuestion => NodeInfo(:ExternalQuestion, 
    :ItemDef,
    [(:Dictionary, :?, "text"),(:Version, :?, "text"),(:Code, :?, "text")],
    []
    ),
:MeasurementUnitRef => NodeInfo(:MeasurementUnitRef, 
    [:ItemData, :ItemDef, :RangeCheck],
    [(:MeasurementUnitOID, :!, "oidref")],
    []
    ),
:RangeCheck => NodeInfo(:RangeCheck, 
    :ItemDef,
    [(:Comparator, :!, "LT|LE|GT|GE|EQ|NE|IN|NOTIN"), (:SoftHard, :!, "Soft|Hard")],
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
    [(:CodeListOID, :!, "oidref")],
    []
    ),
:Alias => NodeInfo(:Alias, 
    [:Protocol, :StudyEventDef, :FormDef, :ItemGroupDef, :ItemDef, :CodeList, :CodeListItem, :EnumeratedItem, :MethodDef, :ConditionDef],
    [(:Context, :!, "text"), (:Name, :!, "text")],
    []
    ),
:CodeList => NodeInfo(:CodeList, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), (:Name, :!, "name"), (:DataType, :!, "integer|float|text|string"), (:SASFormatName, :?, "sasFormat")],
    [(:Description, :?), NodeXOR([(:CodeListItem, :+), (:EnumeratedItem, :+), (:ExternalCodeList, :!)]), (:Alias, :*)]
    ),
:CodeListItem => NodeInfo(:CodeListItem, 
    :CodeList,
    [(:CodedValue, :!, "text"), (:Rank, :?, "float"), (:OrderNumber, :?, "integer")],
    [(:Decode, :!), (:Alias, :*)]
    ),
:Decode => NodeInfo(:Decode, 
    :CodeListItem,
    [],
    [(:TranslatedText, :+)]
    ),
:ExternalCodeList => NodeInfo(:ExternalCodeList, 
    :CodeList,
    [(:Dictionary, :?, "text"), (:Version, :?, "text"), (:ref, :?, "text"), (:href, :?, "text")],
    []
    ),
:EnumeratedItem => NodeInfo(:EnumeratedItem, 
    :CodeList,
    [(:CodedValue, :!, "text"), (:Rank, :?, "float"), (:OrderNumber, :?, "integer")],
    [(:Alias, :*)]
    ),
:ArchiveLayout => NodeInfo(:ArchiveLayout, 
    :FormDef,
    [(:OID, :!, "oid"), (:PdfFileName, :!, "fileName"), (:PresentationOID, :?, "oidref")],
    []
    ),
:MethodDef => NodeInfo(:MethodDef, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), (:Name, :!, "name"), (:Type, :!, "Computation|Imputation|Transpose|Other")],
    [(:Description, :!),(:FormalExpression, :*),(:Alias, :*)]
    ),
:Presentation => NodeInfo(:Presentation, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), (:lang, :?, "languageTag")],
    "text"
    ),
:ConditionDef => NodeInfo(:ConditionDef, 
    :MetaDataVersion,
    [(:OID, :!, "oid"), (:Name, :!, "name")],
    [(:Description, :!),(:FormalExpression, :*),(:Alias, :*)]
    ),
:FormalExpression => NodeInfo(:FormalExpression, 
    [:ConditionDef, :MethodDef, :RangeCheck],
    [(:Context, :!, "text")],
    "PCDATA"
    ),
)