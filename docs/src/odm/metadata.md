### Body

(Include?, Protocol?, StudyEventDef*, FormDef*, ItemGroupDef*, ItemDef*, CodeList*, ImputationMethod*Deprecated, Presentation*, ConditionDef*, MethodDef*)

### Attributes

* OID 	oid 		
* Name 	name 		
* Description 	text 	(optional) 	

### Contained in:

* Study

A metadata version defines the types of study events, forms, item groups, and items that form the study data.

The Include element references a prior metadata version. This causes all the definitions in that prior metadata version to be automatically included in this one. Any of the included definitions can be replaced (overridden) by explicitly giving a new version of the definition (with the same OID) in the new metadata version. See Include for more information on how the Include element works. New definitions (with new OIDs) can be added in the same way.

Based on 
Specification for the Operational Data Model (ODM)
Version 1.3.2 Production
Source File: ODM1-3-2.htm
Last Update: 2013-12-01  Copyright © CDISC 2013.
http://www.cdisc.org/odm