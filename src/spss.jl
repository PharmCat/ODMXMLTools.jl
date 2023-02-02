abstract type  AbstractSPSSSyntax end

struct SPSSVariableLabels <: AbstractSPSSSyntax
    v::Vector
end

function Base.show(io::IO, spssc::SPSSVariableLabels)
    print(io, "VARIABLE LABELS")
    for i = 1:length(spssc.v)
        print(io, "\n$(spssc.v[i][1]) '$(spssc.v[i][2])'")
    end
    print(io, ".")
end

struct  SPSSValueLabels
    v::Vector{Pair{String, Vector{Pair}}}
end

function Base.show(io::IO, spssc::SPSSValueLabels)
    if length(spssc.v) == 0 
        print(io, "") 
        return 
    end
    print(io, "VALUE LABELS")
    print(io, "\n", spssc.v[1][1])
    v = spssc.v[1][2]
    for i = 1:length(v)
        if isa(v[i][1], String) val = "'$(v[i][1])'" else val = v[i][1] end
        print(io, "\n$(val) '$(v[i][2])'")
    end
    if length(spssc.v) > 1
        for i = 2:length(spssc.v)
            print(io, "/\n", spssc.v[i][1])
            v = spssc.v[i][2]
            for j = 1:length(v)
                if isa(v[j][1], String) val = "'$(v[j][1])'" else val = v[j][1] end
                print(io, "\n$(val) '$(v[j][2])'")
            end
        end
    end
    print(io, ".")
end


"""
    spss_form_variable_labels(mdb, form; variable = :OID, labels = :Name)

SPSS command to set variable labels.

`variable` - varable names attribute, `OID` by default.

`labels` - labels names attribute, `Name` by default.

"""
function spss_form_variable_labels(mdb, form; variable = :OID, labels = :Name)
    df = itemformdefcontent_(mdb, form; optional = true)
    v  = Vector{Pair}(undef, length(df))
    for i = 1:size(df, 1)
        v[i] = attribute(df[i], variable) => attribute(df[i], labels)
    end
    SPSSVariableLabels(v)
end
"""
    spss_form_variable_labels(mdb, form, `pairs`; kwargs...)

SPSS command to set variable labels.

Append pair vector `pairs` at the end. 
"""
function spss_form_variable_labels(mdb, form, pairs; kwargs...)
    lbls = spss_form_variable_labels(mdb, form; kwargs...)
    append!(lbls.v, pairs)
    lbls
end

"""
    spss_form_value_labels(mdb, form; variable = :OID)
    
SPSS command to set value labels.

`variable` - varable names attribute, `OID` by default.
"""
function spss_form_value_labels(mdb, form; variable = :OID)
    items = itemformdefcontent_(mdb, form)
    v  = Vector{Pair{String, Vector{Pair}}}(undef, 0)
    for i = 1:length(items)
        cid = findelement(items[i], :CodeListRef)
        if !isnothing(cid)
            p   = Vector{Pair}(undef, 0) 
            cl  = findelement(mdb, :CodeList, attribute(cid, :CodeListOID))
            cli = findelements(cl, :CodeListItem)
            
            for j = 1:length(cli)
                d  = findelement(cli[j], :Decode)
                tt = findelement(d, :TranslatedText)
                strcval = attribute(cli[j], :CodedValue)
                if attribute(cl, :DataType) == "integer"
                    try
                        cval = parse(Int, strcval)
                    catch
                        @warn "Can't parse integer value $strcval for item OID $(attribute(items[i], :OID)), string value used."
                        cval = strcval
                    end
                elseif attribute(cl, :DataType) == "float"
                    try
                        cval = parse(Float64, strcval)
                    catch
                        @warn "Can't parse float value $strcval for item OID $(attribute(items[i], :OID)), string value used."
                        cval = strcval
                    end
                else
                    cval = strcval
                end
                push!(p, cval => content(tt))
            end
            push!(v, attribute(items[i], variable) => p)
        end
    end
    SPSSValueLabels(v)
end

"""
    spss_events_value_labels(mdb; variable = "StudyEventOID", value::Symbol = :OID, label::Symbol = :Name)

Labels for event values.
"""
function spss_events_value_labels(mdb; variable = "StudyEventOID", value::Symbol = :OID, label::Symbol = :Name)
    events = findelements(mdb, :StudyEventDef)
    p   = Vector{Pair}(undef, 0) 
    for i in events
        push!(p, attribute(i, value) => attribute(i, label))
    end
    SPSSValueLabels([variable => p])
end

