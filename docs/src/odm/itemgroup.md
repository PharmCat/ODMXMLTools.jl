### Body

(Description?, ItemRef*, Alias*)

### Attributes

* OID 	oid 		
* Name 	name 		
* Repeating 	(Yes | No) 		
* IsReferenceData 	(Yes | No) 	(optional) 	
* SASDatasetName 	sasName 	(optional) 	
* Domain 	text 	(optional) 	
* Origin 	text 	(optional)	
* Role 	name 	(optional) 	Deprecated
* Purpose 	text 	(optional)	
* Comment 	text 	(optional) 	

### Contained in

* MetaDataVersion

An ItemGroupDef describes a type of item group that can occur within a study.

The Repeating flag indicates that this type of item group can occur repeatedly within the containing form (or reference data).

If IsReferenceData is Yes, this type of item group can occur only within a ReferenceData element. If IsReferenceData is No, this type of item group can occur only within a ClinicalData element. The default for this attribute is No.

The Domain, Origin, Purpose, and Comment attributes carry submission information as described in the CDISC Submission Metadata Model located in the SDTM Metadata Submission Guidelines.

Note: The Role attribute can be considered a synonym for Purpose. New applications should use Purpose rather than Role.

Based on 
Specification for the Operational Data Model (ODM)
Version 1.3.2 Production
Source File: ODM1-3-2.htm
Last Update: 2013-12-01  Copyright © CDISC 2013.
http://www.cdisc.org/odm