### Body

(SubjectData*, AuditRecords*, Signatures*, Annotations*)

### Attributes

* StudyOID 	oidref 		References the Study that uses the data nested within this element.
* MetaDataVersionOID 	oidref 		References the MetaDataVersion (within the above Study) that governs the data nested within this element.

### Contained in

* ODM

Clinical data for multiple subjects.

The StudyOID and MetaDataVersionOID attributes select a particular metadata version. All metadata references (OIDs) occurring within this ClinicalData element refer to definitions within the selected metadata version.

Based on 
Specification for the Operational Data Model (ODM)
Version 1.3.2 Production
Source File: ODM1-3-2.htm
Last Update: 2013-12-01  Copyright © CDISC 2013.
http://www.cdisc.org/odm