
```@example odmexample
using ODMXMLTools;

path = joinpath(dirname(pathof(ODMXMLTools)), "..", "test")

nothing; # hide
```

### Load ODM-XML

ODMXMLTools.jl doesn't check correctness of *.xml file. 

```@example odmexample
using ODMXMLTools;

# Load XML file

odm = ODMXMLTools.importxml(joinpath(path, "test.xml"))
```
Then you can get MetaDataVersion list, Study list, ClinicalData list and other. 

```@example odmexample
# Get metadata list
ODMXMLTools.metadatalist(odm)
```

```@example odmexample
# Get study list
ODMXMLTools.studylist(odm)
```

```@example odmexample
# Get clinical data list
ODMXMLTools.clinicaldatalist(odm)
```

### Build metadata

```@example odmexample
# Build metadata
mdb = ODMXMLTools.buildmetadata(odm, "ST_2_1", "mdv_2")
```

### Find clinical data and get observation data

```@example odmexample
# Find clinical data
cdat = ODMXMLTools.findclinicaldata(odm, "ST_2_1", "mdv_2")
```

```@example odmexample
# Get clinical data
ODMXMLTools.clinicaldatatable(cdat)
```

### Get tables

```@example odmexample
# Find study
st1 =  ODMXMLTools.findstudy(odm, "ST_2_1")
```

```@example odmexample
# Find element
ODMXMLTools.findelement(st1, :MetaDataVersion, "mdv_2")
```

```@example odmexample
# Event list
ODMXMLTools.eventlist(mdb)
```

```@example odmexample
# Form list
ODMXMLTools.formlist(mdb)
```

```@example odmexample
# ItemGroup list
ODMXMLTools.itemgrouplist(mdb)
```

```@example odmexample
# Item list
ODMXMLTools.itemlist(mdb)
```

### Also

```@example odmexample
# Subject data
ODMXMLTools.subjectdatatable(odm; attrs = [:SubjectKey, :StudySubjectID])
```

```@example odmexample
# Study information
ODMXMLTools.studyinfo(odm)
```

### Validation

```@example odmexample
# Basic validation
ODMXMLTools.validateodm(odm)
```

```@example odmexample
# Data validation
ODMXMLTools.checkdatavalues(odm)
```

### SPSS features

```@example odmexample
# Value labesl
ODMXMLTools.spss_form_value_labels(mdb, "FORM_DEAN_1"; variable = :OID)
```

```@example odmexample
# Variable labels
ODMXMLTools.spss_form_variable_labels(mdb, "FORM_DEAN_1"; variable = :SASFieldName)
```

```@example odmexample
# Event value labels
ODMXMLTools.spss_events_value_labels(mdb; variable = "StudyEventOID", value = :OID, label = :Name)
```
