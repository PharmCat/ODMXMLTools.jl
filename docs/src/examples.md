
```@example odmexample
using ODMXMLTools;

path = joinpath(dirname(pathof(ODMXMLTools)), "..", "test")

nothing; # hide
```

### First step - load XML

```@example odmexample
using ODMXMLTools;

# Load XML file

odm = ODMXMLTools.importxml(joinpath(path, "test.xml"))
```

```@example odmexample
# Get metadata list
ODMXMLTools.metadatalist(odm)
```

### Second step - build metadata

```@example odmexample
# Build metadata
mdb = ODMXMLTools.buildmetadata(odm, "ST1", "v2")
```

### Third step - get tables

```@example odmexample
# Find study
st1 =  ODMXMLTools.findstudy(odm, "ST1")
```

```@example odmexample
# Find element
ODMXMLTools.findelement(st1, :MetaDataVersion, "v2")
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

### Find clinical data and get observation data

```@example odmexample
# Find clinical data
cdat = ODMXMLTools.findclinicaldata(odm, "ST1", "v2")
```

```@example odmexample
# Get clinical data
ODMXMLTools.clinicaldatatable(cdat)
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
