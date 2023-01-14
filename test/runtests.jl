using ODMXMLTools

using Test

#path = dirname(@__FILE__)
#cd(path)

@testset "ODMXMLTools.jl" begin

    io = IOBuffer();
    odm = ODMXMLTools.importxml(joinpath(dirname(@__FILE__), "test.xml"))
    @test_nowarn show(io, odm)

    @test_nowarn ODMXMLTools.metadatalist(odm)
    st1 =  ODMXMLTools.findstudy(odm, "ST1")
    @test_nowarn show(io, st1)

    @test_nowarn ODMXMLTools.findelement(st1, :MetaDataVersion, "v2")
    @test_nowarn ODMXMLTools.findstudymetadata(odm, "ST1", "v2")

    @test_nowarn ODMXMLTools.buildmetadata(odm, "DEFS", "v1")
    mdb = ODMXMLTools.buildmetadata(odm, "ST1", "v2")
    @test_nowarn show(io, mdb)


    @test_nowarn ODMXMLTools.studylist(odm; categ = true)
    @test_nowarn ODMXMLTools.eventlist(mdb; categ = true)
    @test_nowarn ODMXMLTools.eventlist(mdb; optional = true, categ = true)
    @test_nowarn ODMXMLTools.formlist(mdb; categ = true)
    @test_nowarn ODMXMLTools.formlist(mdb, attrs =  (:OID, :Name), categ = true)
    @test_nowarn ODMXMLTools.itemgrouplist(mdb; categ = true)
    @test_nowarn ODMXMLTools.itemgrouplist(mdb; optional = true)
    @test_nowarn ODMXMLTools.itemlist(mdb; categ = true)
    @test_nowarn ODMXMLTools.itemlist(mdb; optional = true)
    @test_nowarn ODMXMLTools.itemlist(mdb.el)

    @test_nowarn ODMXMLTools.itemgroupcontent(mdb, "IG_1")
    @test_nowarn ODMXMLTools.formcontent(mdb, "FORM_1")
    @test_nowarn ODMXMLTools.itemformcontent(mdb, "FORM_1"; optional = true)
    @test_nowarn ODMXMLTools.findelement(mdb, :ItemGroupDef, "IG_1")

    @test_nowarn ODMXMLTools.validateodm(odm)

    @test_nowarn ODMXMLTools.clinicaldatatable(odm, addstudyid= true, addstudyidcol = true)

    cdat = ODMXMLTools.findclinicaldata(odm, "ST1", "v2")
    cdat2 = ODMXMLTools.findclinicaldata(odm, "ST1")
    @test cdat2 == ODMXMLTools.findclinicaldata(odm, "ST1")
  

    @test_nowarn ODMXMLTools.clinicaldatatable(cdat)
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, "ST1")
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, [1])
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, 1:2)
    @test_nowarn ODMXMLTools.clinicaldatatable(odm, "ST1", "v2")

    @test_nowarn ODMXMLTools.subjectdatatable(odm; attrs = [:SubjectKey, :StudySubjectID])

    @test_nowarn ODMXMLTools.studyinfo(odm; io = io)
    @test_nowarn ODMXMLTools.studyinfo(odm, "ST1";  io = io)

    #
    spssvallab =  ODMXMLTools.spss_form_value_labels(mdb, "FORM_1"; variable = :SASFieldName)
    @test_nowarn show(io, spssvallab)

    spssvarlab = ODMXMLTools.spss_form_variable_labels(mdb, "FORM_1"; variable = :SASFieldName)
    @test_nowarn show(io, spssvarlab)

    spssevlab = ODMXMLTools.spss_events_value_labels(mdb; variable = "StudyEventOID", value = :OID, label = :Name)
    @test_nowarn show(io, spssevlab)


    cdel = ODMXMLTools.findelements(odm, :ClinicalData)
    @test_nowarn show(io, cdel)

    @test length(cdel) == 2
    ODMXMLTools.deleteclinicaldata!(odm, "DEFS")
    cdel = ODMXMLTools.findelements(odm, :ClinicalData)
    @test length(cdel) == 1

    cdel = ODMXMLTools.findelements(odm, :Study)
    @test cdel == findall(odm, :Study)
    @test length(cdel) == 2
    ODMXMLTools.deletestudy!(odm, "DEFS")
    cdel = ODMXMLTools.findelements(odm, :Study)
    @test length(cdel) == 1

    c = ODMXMLTools.children(odm)
    @test c == odm.el
    @test ODMXMLTools.isroot(odm) == true
    @test ODMXMLTools.isroot(c[1]) == false

    #@test ODMXMLTools.ischild(c[1], odm)

end
