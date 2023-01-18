# ODM

Description of main structural parts provided bellow. Only few elements descibed and only for imformation purpose. **An official version of ODM specificatoion document is available on the ODM page of the CDISC website http://www.cdisc.org/odm.**


## Body

	(Study*, AdminData*, ReferenceData*, ClinicalData*, Association*, ds:Signature*)

## Attributes

*	Description 	text 	(optional) 	The sender should use the Description attribute to record any information that will help the receiver interpret the document correctly.
*	FileType 	( Snapshot | Transactional ) 		Snapshot means that the document contains only the current state of the data and metadata it describes, and no transactional history. A Snapshot document may include only one instruction per data point. For clinical data, TransactionType in a Snapshot file must either not be present or be Insert. Transactional means that the document may contain more than one instruction per data point. Use a Transactional document to send both what the current state of the data is, and how it came to be there.
*	Granularity 	( All | Metadata | AdminData | ReferenceData | AllClinicalData | SingleSite | SingleSubject ) 	(optional) 	Granularity is intended to give the sender a shorthand way to describe the breadth of the information in the document, for certain common types of documents. All means the entire study; Metadata means the MetaDataVersion element; AdminData and ReferenceData mean the corresponding elements; AllClinicalData, SingleSite, and SingleSubject are successively more tightly focused subset of the study's clinical data. If these shorthand categories are not sufficient, use the Description attribute to give details.
*	Archival 	(Yes | No) 	(optional) 	Set this attribute to Yes to indicate that the file is intended to meet the requirements of an electronic record as defined in 21 CFR 11. See Single Files and Collections for an fuller discussion of the meaning of this attribute, as well as its interaction with other ODM attributes.
* 	FileOID 	oid 		A unique identifier for this file.
*	CreationDateTime 	datetime 		Time of creation of the file containing the document.
*	PriorFileOID 	oidref 	(optional)	Reference to the previous file (if any) in a series.
*	AsOfDateTime 	datetime 	(optional)	The date/time at which the source database was queried in order to create this document.
*	ODMVersion 	( 1.2 | 1.2.1 | 1.3 | 1.3.1 | 1.3.2 ) 	(optional)	The version of the ODM standard used.
*	Originator 	text 	(optional)	The organization that generated the ODM file.
*	SourceSystem 	text 	(optional) 	The computer system or database management system that is the source of the information in this file.
*	SourceSystemVersion 	text 	(optional)	The version of the "SourceSystem" above.
*	ID 	ID 	(optional) 	May be used by the ds:Signature element to refer back to this element. 


An element group consists of one or more element names (or element groups) enclosed in parentheses, and separated with commas or vertical bars. Commas indicate that the elements (or element groups) must occur in the XML sequentially in the order listed in the group. Vertical bars indicate that exactly one of the elements (or element groups) must occur. An element or element group can be followed by a ? (meaning optional), a * (meaning zero or more occurrences), or a + (meaning one or more occurrences).

Based on 
Specification for the Operational Data Model (ODM)
Version 1.3.2 Production
Source File: ODM1-3-2.htm
Last Update: 2013-12-01  Copyright © CDISC 2013.
http://www.cdisc.org/odm