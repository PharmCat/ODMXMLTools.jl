using ODMXMLTools

using Test

#path = dirname(@__FILE__)
#cd(path)

@testset "ODMXMLTools.jl" begin
    
    io = IOBuffer();

    # Make node
    name = :NodeName
    attr = Dict(:attr => "value")
    content = "content"
    namespace = :NameSpace
    @test_nowarn show(io, ODMXMLTools.ODMNode(name, attr, content, namespace))
    @test_nowarn  ODMXMLTools.ODMNode(name, attr, content, nothing) 
    @test_nowarn  ODMXMLTools.ODMNode(name, attr, nothing, namespace) 
    @test_nowarn  ODMXMLTools.ODMNode(name, attr, content) 
    @test_nowarn  ODMXMLTools.ODMNode(name, attr) 
  
    # Import

    odm = ODMXMLTools.importxml(joinpath(dirname(@__FILE__), "test.xml"))
    @test_nowarn show(io, odm)

    # List
    mdl = ODMXMLTools.metadatalist(odm)
    @test mdl[:, 1] == [ "TEMPLATE_ST_01"
    "ST_1_1"
    "ST_2_1"
    "ST_2_1"]
    @test mdl[:, 2] == [ "mvd_tpl_1"
    "mdv_1"
    "mdv_1"
    "mdv_2"] 

    stl = ODMXMLTools.studylist(odm; categ = true)
    @test stl[:, 1] == ["TEMPLATE_ST_01"
    "ST_1_1"
    "ST_2_1"]

    cdl = ODMXMLTools.clinicaldatalist(odm)
    @test cdl[:, 1] == ["ST_1_1"
    "ST_2_1"
    "ST_2_1"]

    # Build metadata for template
    mdb = ODMXMLTools.buildmetadata(odm, "TEMPLATE_ST_01", "mvd_tpl_1")
    @test_nowarn show(io, mdb)

    # no event list
    evl = ODMXMLTools.eventlist(mdb; categ = true)
    @test size(evl) == (0, 4)

    # Test wrong metadata ID
    @test_throws ErrorException("MetaDataVersion not found (StudyOID: ST_1_1, MetaDataVersionOID: mdv_23)") ODMXMLTools.buildmetadata(odm, "ST_1_1", "mdv_23")

    # Build metadata for study ST_1_1 (only one metadata available)
    mdb = ODMXMLTools.buildmetadata(odm, "ST_1_1", "mdv_1")
    # content 
    @test ODMXMLTools.content(mdb) == ""
    # name
    @test ODMXMLTools.name(mdb) == :StudyMetaData
    # No optional
    evl = ODMXMLTools.eventlist(mdb; categ = true)
    @test collect(evl[1, :]) == ["SE_VIZIT1"
    "Vizit 1"
    "No"
    "Scheduled"]
    # Optional
    evl = ODMXMLTools.eventlist(mdb; optional = true, categ = true)
    @test collect(evl[1, 1:4]) == ["SE_VIZIT1"
    "Vizit 1"
    "No"
    "Scheduled"]
    @test ismissing(evl[1, 5])

    mdb = ODMXMLTools.buildmetadata(odm, "ST_2_1", "mdv_2")

    fol =  ODMXMLTools.formlist(mdb; categ = true)
    @test fol[:, 1]== ["FORM_DEAN_1"
    "FORM_VD_1"]

    fol = ODMXMLTools.formlist(mdb, attrs =  (:Name,), categ = true)
    @test fol[:, 1] == ["Demographic and antropometric"
    "Vital data"]

    igl =  ODMXMLTools.itemgrouplist(mdb; categ = true)
    igl =  ODMXMLTools.itemgrouplist(mdb; optional = true)
    itl =  ODMXMLTools.itemlist(mdb; categ = true)
    itl =  ODMXMLTools.itemlist(mdb; optional = true)
    itl =  ODMXMLTools.itemlist(mdb.el)

    ifc =  ODMXMLTools.itemformlist(mdb, "FORM_VD_1"; optional = true)
    @test ifc[:, 1] == ["I_1"
    "I_2"
    "I_3"]
    @test ifc[:, 2] == ["SAD"
    "DAD"
    "HR"]

    # CONTENT
    @test_nowarn ODMXMLTools.protocolcontent(mdb; optional = false, categ = false)
    prc = ODMXMLTools.protocolcontent(mdb; optional = true, categ = true)

    @test_nowarn ODMXMLTools.eventcontent(mdb; optional = false, categ = false)
    ec = ODMXMLTools.eventcontent(mdb; optional = true, categ = true)
    @test ec[!, 2] ==  ODMXMLTools.eventcontent(mdb, "SE_VIZIT1"; optional = true, categ = true)[!, 2]

    fc = ODMXMLTools.formcontent(mdb; optional = true, categ = true)
    @test fc[!, 2] == ["DE_IG_1"
    "AN_IG_2"
    "VIT_IG_1"]
    fc = ODMXMLTools.formcontent(mdb, "FORM_VD_1")
    @test fc[1, :ItemGroupOID] == "VIT_IG_1"

    ODMXMLTools.itemgroupcontent(mdb, "VIT_IG_1"; optional = true, categ = true)
    igc = ODMXMLTools.itemgroupcontent(mdb, "VIT_IG_1")
    @test igc[:, 2] == ["I_1"
    "I_2"
    "I_3"]

    igca = ODMXMLTools.itemgroupcontent(mdb)
    @test size(igca) == (7, 3)
    
    # Find
    
    st1 =  ODMXMLTools.findstudy(odm, "ST_1_1")
    @test_nowarn show(io, st1)

    el = ODMXMLTools.findelement(st1, :GlobalVariables)
    @test_nowarn show(io, el)
    el = ODMXMLTools.findelement(el, :StudyName)
    @test_nowarn show(io, el)
    @test ODMXMLTools.content(el) == "Study 1"

    mdvind = ODMXMLTools.findfirst(st1, :MetaDataVersion, "mdv_1")
    @test mdvind == 2
    mdv = ODMXMLTools.findelement(st1, :MetaDataVersion, "mdv_1")
    @test mdv == ODMXMLTools.findstudymetadata(odm, "ST_1_1", "mdv_1")

    idfe = ODMXMLTools.findelements(mdv, :ItemDef)
    @test all(ODMXMLTools.name.(idfe) .== :ItemDef)

    idfei = ODMXMLTools.findall(mdv, :ItemDef)
    @test idfei == [7, 8]

    @test_nowarn ODMXMLTools.buildmetadata(odm, mdv)

    mdb = ODMXMLTools.buildmetadata(odm, "ST_2_1", "mdv_2")
    @test_nowarn show(io, mdb)

    igd =  ODMXMLTools.findelement(mdb, :ItemGroupDef, "AN_IG_2")
    @test ODMXMLTools.name(igd) == :ItemGroupDef

    @test_nowarn ODMXMLTools.clinicaldatatable(odm, addstudyid= true, addstudyidcol = true, categ = true)

    cdat = ODMXMLTools.findclinicaldata(odm, "ST_1_1", "mdv_1")
    @test cdat == ODMXMLTools.findclinicaldata(odm, "ST_1_1")[1]
  
    cdt = ODMXMLTools.clinicaldatatable(cdat, addstudyidcol = true)
    @test cdt[:, :Value] == ["F"
    "174"
    "120"
    "80"
    "63"
    "M"
    "181"
    "121"
    "79"
    "62"]
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, "ST_1_1")
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, [1])
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, 2:3)
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, "ST_1_1", "mdv_1")

    @test_nowarn ODMXMLTools.subjectdatatable(odm; attrs = [:SubjectKey, :StudySubjectID])
    @test_nowarn ODMXMLTools.subjectdatatable(odm; optional = true )
    @test_nowarn ODMXMLTools.subjectdatatable(odm; optional = false )


    ############

    clt = ODMXMLTools.codelisttable(mdb; lang = "en")
    @test clt[!, 7] == ["Male"
    "Female"
    "Asian"
    "Caucasian"]

    iclt = ODMXMLTools.itemcodelisttable(mdb; lang = "en")
    @test iclt[!, 9] == ["Male"
    "Female"
    "Asian"
    "Caucasian"]
    ############

    @test_nowarn ODMXMLTools.itemdescription(mdb; lang = ["", "en", "ru"])

    @test_nowarn ODMXMLTools.itemquestion(mdb; lang = ["", "en", "ru"])

    @test_nowarn ODMXMLTools.nodedesq(mdb, :FormDef, :Description; lang = ["", "en", "ru"])


    @test_nowarn ODMXMLTools.studyinfo(odm; io = io)
    @test_nowarn ODMXMLTools.studyinfo(odm, "ST_1_1";  io = io)

    # CHECK
    vodm = ODMXMLTools.validateodm(odm)
    @test length(vodm.log) == 0
    @test_nowarn show(io, vodm)


    cdv = ODMXMLTools.checkdatavalues(odm)
    @test length(cdv) == 0

    checkidlog = ODMXMLTools.checkmdbid!(mdb)
    @test length(checkidlog.log) == 0

    # Write
    ODMXMLTools.writenode(io, odm)

    @test_nowarn ODMXMLTools.writenode("test_file.xml", odm)

    # SPSS
    spssvallab =  ODMXMLTools.spss_form_value_labels(mdb, "FORM_VD_1"; variable = :OID)
    @test_nowarn show(io, spssvallab)
    spssvallab =  ODMXMLTools.spss_form_value_labels(mdb, "FORM_DEAN_1"; variable = :OID)
    @test_nowarn show(io, spssvallab)

    spssvarlab = ODMXMLTools.spss_form_variable_labels(mdb, "FORM_DEAN_1"; variable = :SASFieldName)
    @test_nowarn show(io, spssvarlab)

    spssevlab = ODMXMLTools.spss_events_value_labels(mdb; variable = "StudyEventOID", value = :OID, label = :Name)
    @test_nowarn show(io, spssevlab)

    # Add user defuned labels
    vlabs = [
    "SubjectKey" => "Скрининговый номер",
    "StudyEventOID" => "Визит",
    "ItemGroupRepeatKey" => "Номер процедуры"]
    spssvarlab = ODMXMLTools.spss_form_variable_labels(mdb, "FORM_DEAN_1", vlabs)
    @test_nowarn show(io, spssvarlab)

    # Test Openclinica form list (experimental)
    @test_nowarn ODMXMLTools.oclformdetailslist(mdb)

    @test_nowarn ODMXMLTools.sortelements!(odm)

    # DELETE ClinicalData
    cdel = ODMXMLTools.findelements(odm, :ClinicalData)
    @test_nowarn show(io, cdel)
    @test length(cdel) == 3
    ODMXMLTools.deleteclinicaldata!(odm, "ST_1_1")
    cdel = ODMXMLTools.findelements(odm, :ClinicalData)
    @test length(cdel) == 2

    # DELETE Study
    cdel = ODMXMLTools.findelements(odm, :Study)
    @test length(cdel) == 3
    ODMXMLTools.deletestudy!(odm, "ST_1_1")
    cdel = ODMXMLTools.findelements(odm, :Study)
    @test length(cdel) == 2

    # deleteat!
    deleteat!(odm, 7)
    @test length(odm.el) == 6

    # Tree interface
    c = ODMXMLTools.children(odm)
    @test c == odm.el
    @test ODMXMLTools.isroot(odm) == true
    @test ODMXMLTools.isroot(c[1]) == false

    # Make node and add to root
    
    cld = ODMXMLTools.mekenode!(odm, :ClinicalData, Dict(:StudyOID => "S1", :MetaDataVersionOID => "MD.1"))
    @test ODMXMLTools.name(cld) == :ClinicalData
    @test ODMXMLTools.attribute(cld, :StudyOID) == "S1"
    @test ODMXMLTools.attribute(cld, :MetaDataVersionOID) == "MD.1"
    @test ODMXMLTools.name(cld) == :ClinicalData
    cdel = ODMXMLTools.findelements(odm, :ClinicalData)
    @test length(cdel) == 2

    newcldat = ODMXMLTools.makeclinicaldata!(odm, "TestSOID", "TestMOID")
    @test ODMXMLTools.isClinicalData(newcldat)

    #@test ODMXMLTools.ischild(c[1], odm)
    # Node information

    @test_nowarn show(io, ODMXMLTools.NODEINFO[:Study])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:GlobalVariables])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:StudyName])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:StudyDescription])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ProtocolName])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:BasicDefinitions])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:MeasurementUnit])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:Symbol])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:TranslatedText])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:MetaDataVersion])
    #...#
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:StudyEventDef])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:FormRef])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:FormDef])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemGroupRef])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemGroupDef])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemRef])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemDef])
    #...#
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:RangeCheck])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:CheckValue])
    #...#
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:CodeList])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:CodeListItem])
    #...#
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ClinicalData])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:SubjectData])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:StudyEventData])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:FormData])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemGroupData])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemData])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemDataAny])
    @test_nowarn show(io, ODMXMLTools.NODEINFO[:ItemDataString])

    ###
    # Validation, Warnings and Errors
    ##

    odmt = ODMXMLTools.importxml(joinpath(dirname(@__FILE__), "nvtest.xml"))
    mdbt = ODMXMLTools.buildmetadata(odmt, "ST_1_1", "mdv_1")
    vodm = ODMXMLTools.validateodm(odmt)
    @test length(vodm.log) == 7
    @test_nowarn show(vodm, :INFO)
    @test_nowarn show(io, vodm, :WARN)
    @test_nowarn show(io, vodm, :ERROR)
    @test_nowarn show(io, vodm, :SKIP)

    cdv  = ODMXMLTools.checkdatavalues(odmt)
    @test length(cdv) == 3

end

#=
using  EzXML
doc = EzXML.readxml(joinpath(dirname(@__FILE__), "test.xml"))
dtdn = EzXML.readdtd(joinpath(dirname(@__FILE__), "test-schema.dtd"))
EzXML.validate(doc, dtdn)
=#


#=
txt = """<?xml version="1.0" encoding="UTF-8"?>
 <t1>
    <t2 xml:name="Homo"></t2>
    <t2 b:name="Homo"></t2>
 </t1>"""
root(EzXML.parsexml(txt));
=#