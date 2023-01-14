struct NodeInfo
    val
    parent
    attrs
    body
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
    else
        for i in ni.body
            print(io, "\n    $(i[1]): $(bodyps(i[2]))")
        end
    end
end

const NODEINFO = Dict{Symbol, NodeInfo}(
:Study => NodeInfo(:Study, 
    :ODM,
    [(:OID, :!, "OID")],
    [(:GlobalVariables, :!), (:BasicDefinitions, :?), (:MetaDataVersion, :*)]
    )

)