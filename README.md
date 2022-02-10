# ODMXMLTools.jl

ODM-XML Tools.

# Install

```
import Pkg; Pkg.add(url="https://github.com/PharmCat/ODMXMLTools.jl.git")
```

# Usage

```
#import ODM xml file.
odm = ODMXMLTools.importxml("odm.xml")

#Get table of MetaDataVersion
ODMXMLTools.metadatalist(odm)

#Find study element
st1 =  ODMXMLTools.findstudy(odm, "ST1")

#Find MetaDataVersion element in study `st1`
ODMXMLTools.findelement(st1, :MetaDataVersion, "v2")

#Find MetaDataVersion element version `v2` in study `st1`
ODMXMLTools.findstudymetadata(odm, "ST1", "v2")

#Build MetaDataVersion - recursive resolve all includes
mdb = ODMXMLTools.buildmetadata(odm, "ST1", "v2")

#Study list
ODMXMLTools.studylist(odm)

#Events table
ODMXMLTools.eventlist(mdb)

#Forms table
ODMXMLTools.formlist(mdb)

#ItemGroups table
ODMXMLTools.itemgrouplist(mdb)

#Items table
ODMXMLTools.itemlist(mdb)

#Items table with optional attributes
ODMXMLTools.itemlist(mdb; optional = true)

#Items table within ItemGoup "IG_1"
ODMXMLTools.itemgroupcontent(mdb, "IG_1")

#Study subject information
ODMXMLTools.subjectdatatable(odm)

#Study information
ODMXMLTools.studyinfo(odm; io = io)
```
