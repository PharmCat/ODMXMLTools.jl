## Body

	(Description?, Question?, ExternalQuestion?, MeasurementUnitRef*, RangeCheck*, CodeListRef?, Role* Deprecated, Alias*)

## Attributes

*	OID 	oid 		
*	Name 	name 		
*	DataType 	(text | integer | float | date | time | datetime | string | boolean | double | hexBinary | base64Binary | hexFloat | base64Float | partialDate | partialTime | partialDatetime | durationDatetime | intervalDatetime | incompleteDatetime | incompleteDate | incompleteTime | URI ) 		
*	Length 	positiveInteger 	(optional) 	
*	SignificantDigits 	nonNegativeInteger 	(optional)	
*	SASFieldName 	sasName 	(optional) 	
*	SDSVarName 	sasName 	(optional) 	
*	Origin 	text 	(optional) 	
*	Comment 	text 	(optional) 	

# Contained in

*	MetaDataVersion

An ItemDef describes a type of item that can occur within a study. Item properties include name, datatype, measurement units, range or codelist restrictions, and several other properties.

Based on 
Specification for the Operational Data Model (ODM)
Version 1.3.2 Production
Source File: ODM1-3-2.htm
Last Update: 2013-12-01  Copyright © CDISC 2013.
http://www.cdisc.org/odm