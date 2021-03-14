## Context

**Municipal Court**: 

- Municipal court is the place where lower-level crimes are adjudicated in the City of Philadelphia. Cases that involve only misdemeanor charges are adjudicated entirely in Municipal court, and then the defendant has the option to appeal the decision to the Court of Common Pleas. Cases that involve felonies start in Municipal Court, where the judge makes an initial determination of whether the Commonwealth has shown probable cause that the defendant committed the crimes. If so, the charges are "held for court" and then move on to the Court of Common Pleas.

**Court of Common Pleas?**:

- The Court of Common Pleas is the primary trial court in each county in Pennsylvania, including Philadelphia. Criminal cases that involve felonies are adjudicated in the court of common pleas, in addition to appeals from municipal court trials. 

**Court Docket**:

- A court docket contains information about a single criminal case that was initiated with a single charging document and usually relates to a single incident, even if it involves multiple criminal charges. It includes a list of hearings and filings in the case and shows the outcome and sentence for each charge. 

**Court Summary**:

- A court summary summarizes the criminal record of a particular defendant. It shows the charges and outcome, where applicable, for each of that defendant's cases. Cases that were in Municipal court and then hold for court and transferred to Common Pleas Court will show twice, once for each court. The Court Summary also includes some demographic information about the defendant. 

**Crime classifications**:

- In order of most serious to least serious, Pennsylvania crime classifications include:
    * Murder
    * Felony (1st Degree) (F1)
    * Felony (2nd Degree) (F2)
    * Felony (3rd Degree) (F3)
    * Ungraded Felony (F3)
    * Misdemeanor (1st Degree) (M1)
    * Misdemeanor (2nd Degree) (M2)
    * Misdemeanor (3rd Degree) (M3)
    * Ungraded Misdemeanor (M3)
    * Summary Offenses

- The mandatory minimum and maximum penalties for a criminal conviction depend on the classification of crime. Each criminal classification includes sentencing guidelines, which the court considers in determining the appropriate sentence for an offender. This includes considering the Offense Gravity Score, Prior Record Score, and any enhancements, and aggravating or mitigating circumstances.

# Data

## defendant_docket_details.csv

This dataset contains details about a [docket](#docket) (i.e., a "case"), including basic demographics on the defendant as well as the history of the case at a broad level (eg when the defendant was arrested, the court and municipality where the case was processed, whether the case is still active or has been adjudicated, and what type of representation the defendant had). This dataset does not include information on the offenses, as these are provided separately in another dataset.

Note: there is one giant .csv with the data for all years, as well as smaller .csvs with short time spans.  All can be downloaded at [data_links.md](data_links.md)

| Variable | Description |
| ----------------| ---------------------------------------- |
| [docket](#docket)_id | Unique identifier of docket |
| gender  | Defendant gender; one of NULL, "Male", "Female" |
| race | Defendant race; one of: NULL, "Asian", "Black", "White", "Bi-Racial", "Unknown/Unreported", "Asian/Pacific Islander", "Native American/Alaskan Native" |
| date_of_birth | Year is preserved, month and day are set to 1/1 provide some de-identification. |
| arrest_date | Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| complaint_date | Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| [disposition](#disposition)_date | Year and month are accurate, day is set to the first of the month to provide some de-identification. |
| filing_date | Year and month are accurate, day is set to the first of the month to provide some de-identification. |
| initiation_date | Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| status_name |  One of "Decided/Active", "Active", "Closed", "Inactive", "Adjudicated" |
| court_office__court__display_name | One of "Municipal Court - Philadelphia County", "Philadelphia County Court of Common Pleas" |
| current_processing_status__processing_status | 	Discrete field with values like "Awaiting Trial", "Sentenced" |
| current_processing_status__status_change_datetime | Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| municipality__name | e.g. "Philadelphia City", "Warminster Township" |
| municipality__county__name |e.g. "Philadelphia", "Bucks" |
| judicial_districts | aggregation of all the districts (`court_office__county__judicial_district__name`) in which this docket has been adjudicated
| court_office_types | aggregation of all the court office types (`court_office__court_office_type`) in which this docket has been adjudicated
| [court_types](#court-type) | aggregation of all the court  types (`court_office__court__court_type`) in which this docket has been adjudicated
| representation_type | aggregation of all the representation types (`representation_type`) for this docket


## offenses_dispositions.csv

This dataset provides information on the offenses on any given docket, and the dispositions associated with each sentence. One docket can include one or more offenses, of which one or more can receive a disposition (ie, a decision). The disposition can also include a sentence type, a sentence duration, and a minimum and maximum sentence duration. 

Note: there is one giant .csv with the data for all years, as well as smaller .csvs with short time spans.  All can be downloaded at [data_links.md](data_links.md)

| Variable | Description |
| ----------------| ---------------------------------------- |
| [docket](#docket)_id | Unique identifier of docket |
| description	| Offense description, e.g. "Unsworn Falsification to Authorities" |
| statute_description | Offense description, e.g. "Unsworn Falsification to Authorities"|
| sequence_number | Order in which the offense is listed on the docket |
| [grade](#offense-grade)| Offense grade; letter-number combos like "M2", "F1"|
| [disposition](#disposition) | Offense-related decision; discrete field with values like "Nolo Contendere", "Transferred to Another Jurisdiction"  |
| disposing_authority__first_name | Judge/magistrate name |
| disposing_authority__middle_name | Judge/magistrate name |
| disposing_authority__last_name | Judge/magistrate name |
| disposing_authority__title | Judge/magistrate title |
| disposing_authority__document_name | Judge/magistrate name |
| disposition_method | Method by which offense-related decision was reached; discrete field with values like "Open Stipulated Trial", "Withdrawn by DA" |
| min_period  | Minimum period for sentence, for offense; Number + Units, e.g. "12.00 Months" or "30.00 Days" |
| max_period | Maximum period for sentence, for offense; Number + Units, e.g. "12.00 Months" or "30.00 Days" |
| period | Sentenced period for offense; Seemingly free text field with values like "LIFE", "3 days flat", "9 - 23 months" |
| sentence_type | Sentence type for offense; One of: "Confinement", "Probation", "No Further Penalty", "Merged", "IPP" |

## bail.csv

This dataset includes information on the [bail](#bail) history of a docket. Bail is set per docket (not per individual offense). There are multiple actions that occur in relation to bail, e.g. bail is first set, bail is increased/decreased, bail type is changed, or revoked, etc. 

Note: there is one giant .csv with the data for all years, as well as smaller .csvs with short time spans.  All can be downloaded at [data_links.md](data_links.md)

| Variable | Description |
| ----------------| ---------------------------------------- |
| [docket](#docket)_id | Unique identifier of docket |
| action_date | date of bail-related action.  Year and month are preserved, day is set to 1 for some level of deidentification|
| action_type_name | type of bail action taken (e.g. "Increase Bail", "Change Bail Type", "Reinstate", "Revoke", etc.) |
| [type_name](#bail-types) | type of bail (e.g. "ROR", "Monetary", "Unsecured", etc.) |
| percentage | percent of total_amount that must be paid in order to have the defendant released from detention |
| total_amount | total bail amount |
| registry_entry_code | free text, often contains a more detailed description of the action |
| participant_name__title | title of actors (e.g. "Judge", "President Judge", "District Attorney", etc.) |
| participant_name__last_name | last name of actor |
| participant_name__first_name | We first name of actor |

# Terminology

### docket
a sheet that provide a general overview of who is involved in a case and what actions they have taken, including docket number, court, case_status, who is the judge, related cases, case type, two parties, represented attorneys and contact information, filing list (date, number, description), etc.

![](https://s3.amazonaws.com/libapps/accounts/12889/images/Docket_sheet.png)

### disposition
the current status or final outcome of an arrest or prosecution
There are 6 discrete types of dispositions listed in the data, which were listed under column names `sentence_type` in disposition-relevant sheets or `disposition` in summary sheets.

- **IPP**: The Intermediate Punishment Program (IPP) is an alternative to jail time. It includes constant probation supervision, community service, drug or alcohol treatment, and even electronic monitoring
- **Merged**: In criminal law, if a defendant commits a single act that simultaneously fulfills the definition of two separate offenses, merger will occur. This means that the lesser of the two offenses will drop out, and the defendant will only be charged with the greater offense
- **Probation**: the release of an offender from detention, subject to a period of good behavior under supervision
- **Confinement**: confinement to a jail, prison or other penal institution or correctional facility
- **No Further Penalty**: No Further Penalty
- **NULL**: NULL

### offense grade
In Pennsylvania, all crimes are grading as a summary (S), misdemeanor (M), or a felony (F) offense. Their corresponding sentence guide can be found [here](https://www.lampmanlaw.com/offense-gradings-and-procedures)

In summary data, there are 6 discrete values associated with offense grade, under column name `grade_type`

- **M**: misdemeanor 
- **F**:felony
- **S**: summary; minor infractions. Examples of these offenses are: disorderly conduct, public drunkenness, harassment, retail theft (first offense), underage drinking
- **C**: ???
- **H**: Homicide
- **NULL**

### bail

"Bail is the tool, which the courts use to assure a defendant’s appearance at future court dates. [...] Bail is set in all misdemeanor and felony cases, while a defendant is not entitled to bail if he is charged with an offense punishable by death or life in prison. If a judge sets cash bail, the defendant can be released from detention in county jail when someone posts that amount on the defendant’s behalf. The person posting bail is known as the “surety.” In some cases, the judge may allow the defendant to post only 5% or 10% of the total bail amount." (see ["Bail Basics in Pennsylvania"](https://www.mattmlaw.com/blog/2013/04/bail-basics-in-pennsylvania/) for more info.)

### bail types

7 discrete values such as "ROR" and "Monetary". 

Standard 7 bail types listed [here](https://herbertbailbonds.com/7-types-bail-bonds-obtained/) 
- **ROR**: “released on own recognizance”, which means that a defendant must simply promise to appear at all future court dates
- **Surety Bonds**
- **Cash Bail Bonds**
- **Property Bonds**
- **Citation Release**
- **Immigration Bail Bonds**
- **Federal Bail Bonds**

### court type
In this dataset, there are 3 discrete values associated with court type: "PAC", "CP", "MC", under column name `court_office__court__court_type`

- **PAC**: Pennsylvania Appellate Court (Superior, Commonwealth, Supreme)
- **CP**: Court of Common Pleas
- **MC**: Municipal Court
