using ODMXMLTools
using Test

path = dirname(@__FILE__)
cd(path)

@testset "ODMXMLTools.jl" begin
    odm = ODMXMLTools.importxml(joinpath(path, "test.xml"))

    @test_nowarn ODMXMLTools.metadatalist(odm)
    st1 =  ODMXMLTools.findstudy(odm, "ST1")
    @test_nowarn ODMXMLTools.findelement(st1, :MetaDataVersion, "v2")
    @test_nowarn ODMXMLTools.findstudymetadata(odm, "ST1", "v2")

    @test_nowarn ODMXMLTools.buildmetadata(odm, "DEFS", "v1")
    mdb = ODMXMLTools.buildmetadata(odm, "ST1", "v2")

    @test_nowarn ODMXMLTools.eventlist(mdb)
    @test_nowarn ODMXMLTools.formlist(mdb)
    @test_nowarn ODMXMLTools.itemgrouplist(mdb)
    @test_nowarn ODMXMLTools.itemlist(mdb)
    @test_nowarn ODMXMLTools.itemlist(mdb; optional = true)
    @test_nowarn ODMXMLTools.itemlist(mdb.el)
    @test_nowarn ODMXMLTools.itemgroupcontent(mdb, "IG_1")
    @test_nowarn ODMXMLTools.findelement(mdb, :ItemGroupDef, "IG_1")

    @test_nowarn ODMXMLTools.validateodm(odm)

    cdat = ODMXMLTools.findclinicaldata(odm, "ST1", "v2")
    @test_nowarn ODMXMLTools.clinicaldatatable(cdat)
end
