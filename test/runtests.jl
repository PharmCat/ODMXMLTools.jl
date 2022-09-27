using ODMXMLTools
using Test

#path = dirname(@__FILE__)
#cd(path)

@testset "ODMXMLTools.jl" begin

    io = IOBuffer();
    odm = ODMXMLTools.importxml(joinpath(dirname(@__FILE__), "test.xml"))

    @test_nowarn ODMXMLTools.metadatalist(odm)
    st1 =  ODMXMLTools.findstudy(odm, "ST1")
    @test_nowarn ODMXMLTools.findelement(st1, :MetaDataVersion, "v2")
    @test_nowarn ODMXMLTools.findstudymetadata(odm, "ST1", "v2")

    @test_nowarn ODMXMLTools.buildmetadata(odm, "DEFS", "v1")
    mdb = ODMXMLTools.buildmetadata(odm, "ST1", "v2")

    @test_nowarn ODMXMLTools.studylist(odm)
    @test_nowarn ODMXMLTools.eventlist(mdb)
    @test_nowarn ODMXMLTools.eventlist(mdb; optional = true)
    @test_nowarn ODMXMLTools.formlist(mdb)
    @test_nowarn ODMXMLTools.formlist(mdb, attrs =  (:OID, :Name), categ = true)
    @test_nowarn ODMXMLTools.itemgrouplist(mdb)
    @test_nowarn ODMXMLTools.itemgrouplist(mdb; optional = true)
    @test_nowarn ODMXMLTools.itemlist(mdb)
    @test_nowarn ODMXMLTools.itemlist(mdb; optional = true)
    @test_nowarn ODMXMLTools.itemlist(mdb.el)
    @test_nowarn ODMXMLTools.itemgroupcontent(mdb, "IG_1")
    @test_nowarn ODMXMLTools.findelement(mdb, :ItemGroupDef, "IG_1")
    @test_nowarn ODMXMLTools.formcontent(mdb, "FORM_1")
    @test_nowarn ODMXMLTools.itemformcontent(mdb, "FORM_1"; optional = true)

    @test_nowarn ODMXMLTools.validateodm(odm)

    cdat = ODMXMLTools.findclinicaldata(odm, "ST1", "v2")

    @test_nowarn ODMXMLTools.clinicaldatatable(cdat)

    @test_nowarn ODMXMLTools.subjectdatatable(odm; attrs = [:SubjectKey, :StudySubjectID])

    @test_nowarn ODMXMLTools.studyinfo(odm; io = io)
end
