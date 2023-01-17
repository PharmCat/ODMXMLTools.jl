using ODMXMLTools

using Test

#path = dirname(@__FILE__)
#cd(path)

@testset "ODMXMLTools.jl" begin

    io = IOBuffer();
    odm = ODMXMLTools.importxml(joinpath(dirname(@__FILE__), "test.xml"))
    @test_nowarn show(io, odm)

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
    # No optional
    evl = ODMXMLTools.eventlist(mdb; categ = true)
    @test collect(evl[1, :]) == ["SE_VIZIT1"
    "Vizit 1"
    "No"
    "Scheduled"]
    # Optional
    evl = ODMXMLTools.eventlist(mdb; optional = true, categ = true)
    @test collect(evl[1, :]) == ["SE_VIZIT1"
    "Vizit 1"
    "No"
    "Scheduled"
    ""]

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


    st1 =  ODMXMLTools.findstudy(odm, "ST_1_1")
    @test_nowarn show(io, st1)

    el = ODMXMLTools.findelement(st1, :GlobalVariables)
    @test_nowarn show(io, el)
    el = ODMXMLTools.findelement(el, :StudyName)
    @test_nowarn show(io, el)
    @test ODMXMLTools.content(el) == "Study 1"

    mdv = ODMXMLTools.findelement(st1, :MetaDataVersion, "mdv_1")
    @test mdv == ODMXMLTools.findstudymetadata(odm, "ST_1_1", "mdv_1")

    @test_nowarn ODMXMLTools.buildmetadata(odm, "TEMPLATE_ST_01", "mvd_tpl_1")
    mdb = ODMXMLTools.buildmetadata(odm, "ST_2_1", "mdv_2")
    @test_nowarn show(io, mdb)

    igc = ODMXMLTools.itemgroupcontent(mdb, "VIT_IG_1")
    @test igc[:, 1] == ["I_1"
    "I_2"
    "I_3"]

    fc = ODMXMLTools.formcontent(mdb, "FORM_VD_1")
    ifc =  ODMXMLTools.itemformcontent(mdb, "FORM_VD_1"; optional = true)
    igd =  ODMXMLTools.findelement(mdb, :ItemGroupDef, "AN_IG_2")
    @test ODMXMLTools.name(igd) == :ItemGroupDef

    @test_nowarn ODMXMLTools.validateodm(odm)

    @test_nowarn ODMXMLTools.clinicaldatatable(odm, addstudyid= true, addstudyidcol = true)

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

    @test_nowarn ODMXMLTools.studyinfo(odm; io = io)
    @test_nowarn ODMXMLTools.studyinfo(odm, "ST_1_1";  io = io)

    #
    spssvallab =  ODMXMLTools.spss_form_value_labels(mdb, "FORM_VD_1"; variable = :OID)
    @test_nowarn show(io, spssvallab)
    spssvallab =  ODMXMLTools.spss_form_value_labels(mdb, "FORM_DEAN_1"; variable = :OID)
    @test_nowarn show(io, spssvallab)

    spssvarlab = ODMXMLTools.spss_form_variable_labels(mdb, "FORM_DEAN_1"; variable = :SASFieldName)
    @test_nowarn show(io, spssvarlab)

    spssevlab = ODMXMLTools.spss_events_value_labels(mdb; variable = "StudyEventOID", value = :OID, label = :Name)
    @test_nowarn show(io, spssevlab)


    @test_nowarn ODMXMLTools.oclformdetailslist(mdb)

    # DELETE ClinicalData
    cdel = ODMXMLTools.findelements(odm, :ClinicalData)
    @test_nowarn show(io, cdel)
    @test length(cdel) == 3
    ODMXMLTools.deleteclinicaldata!(odm, "ST_1_1")
    cdel = ODMXMLTools.findelements(odm, :ClinicalData)
    @test length(cdel) == 2

    # DELETE Study
    cdel = ODMXMLTools.findelements(odm, :Study)
    @test cdel == findall(odm, :Study)
    @test length(cdel) == 3
    ODMXMLTools.deletestudy!(odm, "ST_1_1")
    cdel = ODMXMLTools.findelements(odm, :Study)
    @test length(cdel) == 2

    c = ODMXMLTools.children(odm)
    @test c == odm.el
    @test ODMXMLTools.isroot(odm) == true
    @test ODMXMLTools.isroot(c[1]) == false

    #@test ODMXMLTools.ischild(c[1], odm)

    @test_nowarn show(io, ODMXMLTools.NODEINFO[:Study])
end
