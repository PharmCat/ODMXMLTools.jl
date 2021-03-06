# ODMXMLTools.jl

ODMXMLTools.jl is a simple tool set for working with ODM-XML.

[![Latest docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://pharmcat.github.io/ODMXMLTools.jl/dev/)

[ODM-XML](https://www.cdisc.org/standards/data-exchange/odm) is a vendor-neutral, platform-independent format for exchanging and archiving clinical and translational research data, along with their associated metadata, administrative data, reference data, and audit information. ODM-XML facilitates the regulatory-compliant acquisition, archival and exchange of metadata and data. It has become the language of choice for representing case report form content in many electronic data capture (EDC) tools.

The ODM has been designed to be compliant with guidance and regulations published by the FDA for computer systems used in clinical studies.

See [CDISK](https://www.cdisc.org/) site for more information.

This program comes with absolutely no warranty. No liability is accepted for any loss and risk to public health resulting from use of this software.

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

#Get ClinicalData list
ODMXMLTools.clinicaldatalist(odm)

#Get data from ClinicalData in "long" format
ODMXMLTools.clinicaldatatable(odm, "ST1", "v2")
```
