# Queries

These queries, run in BigQuery, provide the base tables upon which we constructed the RLadies hackathon data.  

## Updates

Added a new table in BQ, `rladies.confidential_defendant_id_table` for the purposes of tracking multiple offenses, based on:

```
WITH unique_defendants AS (SELECT distinct lower(participant_name__document_name) as name, primary_date_of_birth as dob FROM `reclaim-philadelphia-data.dockets.do_case_participants` where role__name = "Defendant")

SELECT ROW_NUMBER() over (Order by dob ASC) as defendant_id, name, dob FROM unique_defendants
```

Then  we used that table to match defendants to dockets and create `rladies.defendant_docket_ids`:

```SELECT distinct defendant_id, do_docket_id as docket_id
FROM `reclaim-philadelphia-data.dockets.do_case_participants`  
JOIN `reclaim-philadelphia-data.rladies.confidential_defendant_id_table`
on lower(participant_name__document_name)  = name AND
primary_date_of_birth  = dob
```

## Notes

After discussion with JAT, we removed the `WHERE` clause limiting the data to just Closed / Adjudicated cases.

Question: is the `description`, `statute_description`, and `sequence_number` the same across the `offenses` and `disposition_sentence_judge` composite tables?

Answer: it seems highly likely.  An inner join based on `docket_id`, `description`, `statute_description`, and `sequence_number` yields 439,769 rows, which is very close to the smaller of the two tables, `disposition_sentence_judge`, which has 439,742 rows.

----

## Queries --> Tables

There are three tables:

* `defendant_docket_details`
* `offenses_dispositions`
* `bails`

----

### `defendant_docket_details`

It can be helpful to get defendant demographics, date, location and other status information about dockets.  

The table [`defendant_docket_details`](https://console.cloud.google.com/bigquery?project=reclaim-philadelphia-data&p=reclaim-philadelphia-data&d=rladies&t=defendant_docket_details&page=table), with 370,313 rows, was constructed using this query:

```
WITH defendants AS (

SELECT DISTINCT
  do_docket_id as docket_id
  ,gender
  ,race
  ,primary_date_of_birth
FROM `reclaim-philadelphia-data.dockets.do_case_participants`
WHERE role__name = "Defendant"),

courts AS (
  SELECT DISTINCT
  do_docket_id as docket_id
  ,STRING_AGG(distinct court_office__county__judicial_district__name, ", " ) as judicial_districts
  ,STRING_AGG(distinct court_office__court_office_type, ", " ) as court_office_types
  ,STRING_AGG(distinct court_office__court__court_type, ", " ) as court_types,
  FROM `reclaim-philadelphia-data.dockets.do_case_histories`
JOIN
`reclaim-philadelphia-data.dockets.do_dockets`
ON `reclaim-philadelphia-data.dockets.do_case_histories`.do_docket_id = `reclaim-philadelphia-data.dockets.do_dockets`.id
GROUP by docket_id),

representation AS (
SELECT
  do_docket_id as docket_id
  ,STRING_AGG(distinct representation_type, ", ") as representation_type
FROM `reclaim-philadelphia-data.dockets.do_case_participant_attorneys`
GROUP BY do_docket_id
  )

SELECT DISTINCT
  id as docket_id
  ,gender
  ,race
  ,date(timestamp_trunc(primary_date_of_birth, YEAR)) AS date_of_birth
  ,date(timestamp_trunc(arrest_date, MONTH)) AS arrest_date
  ,date(timestamp_trunc(complaint_date, MONTH)) AS complaint_date
  ,date(timestamp_trunc(disposition_date, MONTH)) AS disposition_date
  ,date(timestamp_trunc(filing_date, MONTH)) AS filing_date
  ,date(timestamp_trunc(initiation_date, MONTH)) AS initiation_date
  ,status_name
  ,court_office__court__display_name
  ,current_processing_status__processing_status
  ,date(timestamp_trunc(current_processing_status__status_change_datetime, MONTH)) AS current_processing_status__status_change_datetime
  ,municipality__name
  ,municipality__county__name
  ,judicial_districts
  ,court_office_types
  ,court_types
  ,representation_type
FROM `reclaim-philadelphia-data.dockets.do_dockets` JOIN defendants
ON defendants.docket_id = `reclaim-philadelphia-data.dockets.do_dockets`.id
JOIN courts
ON courts.docket_id = `reclaim-philadelphia-data.dockets.do_dockets`.id
LEFT JOIN representation
ON representation.docket_id  = `reclaim-philadelphia-data.dockets.do_dockets`.id
```

| Variable | Table of Origin | Description |
| ----------------| ------------------ | ---------------------------------------- |
| gender | do_case_participants | One of NULL, "Male", "Female" |
| race | do_case_participants | One of: NULL, "Asian", "Black", "White", "Bi-Racial", "Unknown/Unreported", "Asian/Pacific Islander", "Native American/Alaskan Native" |
| date_of_birth | do_case_participants | Year is preserved, month and day are set to 1/1 for ease of date math. |
| arrest_date | do_dockets | Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| complaint_date | do_dockets | Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| disposition_date | do_dockets |Year and month are accurate, day is set to the first of the month to provide some de-identification. |
| filing_date | do_dockets |	Year and month are accurate, day is set to the first of the month to provide some de-identification. |
| initiation_date | do_dockets |	Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| status_name | do_dockets | One of "Decided/Active", "Active", "Closed", "Inactive", "Adjudicated"; we may want to select only "Closed" or "Adjudicated"? |
| court_office__court__display_name | do_dockets |	One of "Municipal Court - Philadelphia County", "Philadelphia County Court of Common Pleas" |
| current_processing_status__processing_status | do_dockets |	Discrete field with values like "Awaiting Trial", "Sentenced" |
| current_processing_status__status_change_datetime | do_dockets | Year and month are accurate, day is set to the first of the month to provide some de-identification.|
| municipality__name | do_dockets | e.g. "Philadelphia City", "Warminster Township" |
| municipality__county__name | do_dockets | e.g. "Philadelphia", "Bucks" |
| judicial_districts | do_case_histories | aggregation of all the districts (`court_office__county__judicial_district__name`) in which this docket has been adjudicated
| court_office_types | do_case_histories | aggregation of all the court office types (`court_office__court_office_type`) in which this docket has been adjudicated
| court_types | do_case_histories | aggregation of all the court  types (`court_office__court__court_type`) in which this docket has been adjudicated
|representation_type | do_case_participant_attorneys | aggregation of all the representation types (`representation_type`) for this docket


-----
### `offenses_dispositions`

We want to capture details about offenses.  We also care about the outcome of a judicial action relating to an offense (the disposition, or guilt or innocence ruling, as well as the sentence), along with the judge's name, for each offense in a docket.  Not every offense will have a disposition, and this table reflects that.

The table [`offenses_dispositions`](https://console.cloud.google.com/bigquery?project=reclaim-philadelphia-data&p=reclaim-philadelphia-data&d=rladies&t=disposition_sentence_judge&page=table), with 1,465,113 rows, was constructed using this query:

```
WITH offenses as (
SELECT DISTINCT
  do_docket_id AS docket_id
  ,description
  ,statute_description
  ,sequence_number
  ,grade
FROM `reclaim-philadelphia-data.dockets.do_offenses` JOIN
`reclaim-philadelphia-data.dockets.do_dockets`
ON `reclaim-philadelphia-data.dockets.do_offenses`.do_docket_id = `reclaim-philadelphia-data.dockets.do_dockets`.id
),

dispositions as (
SELECT DISTINCT
  do_docket_id as docket_id
  ,description
  ,statute_description
  ,sequence_number
  ,`reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions`.disposition
  ,disposing_authority__first_name
  ,disposing_authority__middle_name
  ,disposing_authority__last_name
  ,disposing_authority__title
  ,disposing_authority__document_name
  ,disposition_method
  ,min_period
  ,max_period
  ,period
  ,sentence_type
FROM `reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions` JOIN
`reclaim-philadelphia-data.dockets.do_disposition_events`
ON `reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions`.do_disposition_event_id = `reclaim-philadelphia-data.dockets.do_disposition_events`.id
JOIN `reclaim-philadelphia-data.dockets.do_dockets` ON `reclaim-philadelphia-data.dockets.do_disposition_events`.do_docket_id = `reclaim-philadelphia-data.dockets.do_dockets`.id
JOIN `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentences` ON
`reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentences`.do_disposition_event__offense_disposition_id = `reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions`.id
JOIN `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentence__sentence_types` ON `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentence__sentence_types`.do_disposition_event__offense_disposition__sentence_id = `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentences`.id)

SELECT * FROM
offenses LEFT JOIN dispositions
USING(docket_id, description, statute_description, sequence_number)
```

| Variable | Table of Origin | Description |
| ----------------| ------------------ | ---------------------------------------- |
| description	|do_disposition_event__offense_dispositions, do_offenses |Short offense description, e.g. "Unsworn Falsification to Authorities" |
| statute_description | do_disposition_event__offense_dispositions, do_offenses   |  Short offense description, e.g. "Unsworn Falsification to Authorities"
 |
| sequence_number |do_disposition_event__offense_dispositions, do_offenses | Order in which listed|
| grade| do_offenses | Letter-number combos like "M2", "F1"|
| disposition | do_disposition_event__offense_dispositions | Discrete field with values like "Nolo Contendere", "Transferred to Another Jurisdiction"  |
| disposing_authority__first_name | do_disposition_events
 | Judge/magistrate name |
| disposing_authority__middle_name | do_disposition_events
 | Judge/magistrate name |
| disposing_authority__last_name | do_disposition_events
 | Judge/magistrate name |
| disposing_authority__title | do_disposition_events
 | Judge/magistrate title |
| disposing_authority__document_name | do_disposition_events
 | Judge/magistrate name |
| disposition_method | do_disposition_events
 | Discrete field with values like "Open Stipulated Trial", "Withdrawn by DA" |
| min_period | do_disposition_event__offense_disposition__sentence__sentence_types
 | Number + Units, e.g. "12.00 Months" or "30.00 Days" |
| max_period | do_disposition_event__offense_disposition__sentence__sentence_types
 | Number + Units, e.g. "12.00 Months" or "30.00 Days" |
| period | do_disposition_event__offense_disposition__sentence__sentence_types
 | Seemingly free text field with values like "LIFE", "3 days flat", "9 - 23 months" |
| sentence_type | do_disposition_event__offense_disposition__sentence__sentence_types
 | One of: "Confinement", "Probation", "No Further Penalty", "Merged", "IPP" |

---

### Offenses, dispositions, statute names

This is a separate query because it creates 4 additional rows and I don't feel like chasing them down:

The table [`offenses_dispositions_v2`](), with 1,465,117 rows, was constructed using this query:

```
CREATE OR REPLACE TABLE `reclaim-philadelphia-data.rladies.offenses_dispositions_v2` AS(

WITH offenses as (
SELECT DISTINCT
  do_docket_id AS docket_id
  ,description
  ,statute_description
  ,statute_name
  ,sequence_number
  ,grade
FROM `reclaim-philadelphia-data.dockets.do_offenses` JOIN
`reclaim-philadelphia-data.dockets.do_dockets`
ON `reclaim-philadelphia-data.dockets.do_offenses`.do_docket_id = `reclaim-philadelphia-data.dockets.do_dockets`.id
),

dispositions as (
SELECT DISTINCT
  do_docket_id as docket_id
  ,description
  ,statute_description
  ,statute_name
  ,sequence_number
  ,`reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions`.disposition
  ,disposing_authority__first_name
  ,disposing_authority__middle_name
  ,disposing_authority__last_name
  ,disposing_authority__title
  ,disposing_authority__document_name
  ,disposition_method
  ,min_period
  ,max_period
  ,period
  ,sentence_type
FROM `reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions` JOIN
`reclaim-philadelphia-data.dockets.do_disposition_events`
ON `reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions`.do_disposition_event_id = `reclaim-philadelphia-data.dockets.do_disposition_events`.id
JOIN `reclaim-philadelphia-data.dockets.do_dockets` ON `reclaim-philadelphia-data.dockets.do_disposition_events`.do_docket_id = `reclaim-philadelphia-data.dockets.do_dockets`.id
JOIN `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentences` ON
`reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentences`.do_disposition_event__offense_disposition_id = `reclaim-philadelphia-data.dockets.do_disposition_event__offense_dispositions`.id
JOIN `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentence__sentence_types` ON `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentence__sentence_types`.do_disposition_event__offense_disposition__sentence_id = `reclaim-philadelphia-data.dockets.do_disposition_event__offense_disposition__sentences`.id)

SELECT * FROM
offenses LEFT JOIN dispositions
USING(docket_id, description, statute_description, statute_name, sequence_number))
```

| Variable | Table of Origin | Description |
| ----------------| ------------------ | ---------------------------------------- |
| description	|do_disposition_event__offense_dispositions, do_offenses |Short offense description, e.g. "Unsworn Falsification to Authorities" |
| statute_description | do_disposition_event__offense_dispositions, do_offenses   |  Short offense description, e.g. "Unsworn Falsification to Authorities"
 |
 |statute_name | do_disposition_event__offense_dispositions, do_offenses | name / location in statute, e.g. 18 § 4904 §§ A|
| sequence_number |do_disposition_event__offense_dispositions, do_offenses | Order in which listed|
| grade| do_offenses | Letter-number combos like "M2", "F1"|
| disposition | do_disposition_event__offense_dispositions | Discrete field with values like "Nolo Contendere", "Transferred to Another Jurisdiction"  |
| disposing_authority__first_name | do_disposition_events
 | Judge/magistrate name |
| disposing_authority__middle_name | do_disposition_events
 | Judge/magistrate name |
| disposing_authority__last_name | do_disposition_events
 | Judge/magistrate name |
| disposing_authority__title | do_disposition_events
 | Judge/magistrate title |
| disposing_authority__document_name | do_disposition_events
 | Judge/magistrate name |
| disposition_method | do_disposition_events
 | Discrete field with values like "Open Stipulated Trial", "Withdrawn by DA" |
| min_period | do_disposition_event__offense_disposition__sentence__sentence_types
 | Number + Units, e.g. "12.00 Months" or "30.00 Days" |
| max_period | do_disposition_event__offense_disposition__sentence__sentence_types
 | Number + Units, e.g. "12.00 Months" or "30.00 Days" |
| period | do_disposition_event__offense_disposition__sentence__sentence_types
 | Seemingly free text field with values like "LIFE", "3 days flat", "9 - 23 months" |
| sentence_type | do_disposition_event__offense_disposition__sentence__sentence_types
 | One of: "Confinement", "Probation", "No Further Penalty", "Merged", "IPP" |



### Bails

The table [`bail`](https://console.cloud.google.com/bigquery?project=reclaim-philadelphia-data&pli=1&p=reclaim-philadelphia-data&d=rladies&t=bail&page=table), with 8,457,247 rows, was constructed using this query:

```
SELECT DISTINCT
      `reclaim-philadelphia-data.dockets.do_case_bails`.do_docket_id as docket_id,
      date(timestamp_trunc(action_date, MONTH)) AS action_date,
      action_type_name,
      type_name,
      percentage,
      total_amount,
      registry_entry_code,
      participant_name__title,
      CASE
        WHEN participant_name__title IN ("Judge", "Senior Judge", "Arresting Agency Officer", "Probation Officer", "Prosecution", "Bondsman", "Bail Assignment Attorney" )
        THEN participant_name__last_name
        ELSE NULL
      END as participant_name__last_name,
      CASE
        WHEN participant_name__title IN ("Judge", "Senior Judge", "Arresting Agency Officer", "Probation Officer", "Prosecution", "Bondsman", "Bail Assignment Attorney" )
        THEN participant_name__first_name
        ELSE NULL
      END as participant_name__first_name
    FROM
      `reclaim-philadelphia-data.dockets.do_case_bail__bail_records`
    JOIN
      `reclaim-philadelphia-data.dockets.do_case_bails`
    ON
      `reclaim-philadelphia-data.dockets.do_case_bail__bail_records`.do_case_bail_id =
      `reclaim-philadelphia-data.dockets.do_case_bails`.id
    JOIN
      `reclaim-philadelphia-data.dockets.do_registry_entries`
    ON
      `reclaim-philadelphia-data.dockets.do_registry_entries`.do_docket_id =
      `reclaim-philadelphia-data.dockets.do_case_bails`.do_docket_id
    JOIN
      `reclaim-philadelphia-data.dockets.do_registry_entry__filers`
    ON
      `reclaim-philadelphia-data.dockets.do_registry_entry__filers`.do_registry_entry_id =
      `reclaim-philadelphia-data.dockets.do_registry_entries`.id

```

| Variable | Table of Origin | Description |
| ----------------| ------------------ | ---------------------------------------- |
| docket_id | do_dockets | docket id, which we can use to look up docket number if needed. |
| action_date | do_case_bail__bail_records | date of bail-related action.  Year and month are preserved, day is set to 1 for some level of deidentification|
| action_type_name | do_case_bail__bail_records | type of bail action taken (e.g. "Increase Bail", "Change Bail Type", "Reinstate", "Revoke", etc.) |
| type_name | do_case_bail__bail_records | type of bail (e.g. "ROR", "Monetary", "Unsecured", etc.) |
| percentage | do_case_bail__bail_records | percent bail increase (?) |
| total_amount | do_case_bail__bail_records | total bail amount |
| registry_entry_code | do_registry_entries | free text, often contains a more detailed description of the action |
| participant_name__title | do_registry_entry__filers | title of actors (e.g. "Judge", "President Judge", "District Attorney", etc.) |
| participant_name__last_name | do_registry_entry__filers | last name of actor |
| participant_name__first_name | do_registry_entry__filers | first name of actor |
