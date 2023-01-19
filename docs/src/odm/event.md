### Body

(Description?, FormRef*, Alias*)

### Attributes

* OID 	oid
* Name 	name
* Repeating 	(Yes | No)
* Type 	(Scheduled | Unscheduled | Common)
* Category 	text 	(optional) 


### Contained in

* MetaDataVersion

A StudyEventDef packages a set of forms. Scheduled Study Events correspond to sets of forms that are expected to be collected for each subject as part of the planned visit sequence for the study. Unscheduled Study Events are designed to collect data that may or may not occur for any particular subject such as a set of forms that are completed for an early termination due to a serious adverse event. A common Study Event is a collection of forms that are used at several different data collection events such as an Adverse Event or Concomitant Medications log.

The Repeating flag indicates that this type of study event can occur repeatedly within any given subject.

The Category attribute is typically used to indicate the study phase appropriate to this type of study event. Examples might include Screening, PreTreatment, Treatment, and FollowUp.

Based on 
Specification for the Operational Data Model (ODM)
Version 1.3.2 Production
Source File: ODM1-3-2.htm
Last Update: 2013-12-01  Copyright © CDISC 2013.
http://www.cdisc.org/odm
