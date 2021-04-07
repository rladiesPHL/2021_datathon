# Splitting Tables By Date

## Planning the split

We run the following query to understand date distribution of arrests:

```
SELECT extract(year from arrest_date) as arrest_year,
count(*) as num_dockets
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
GROUP BY arrest_year
order by arrest_year
```

This is the output, which has a distribution similar to other dates related to the docket.

| Row	| arrest_year |	num_dockets
| 1	| null| 77
| 2	| 1962| 1
| 3	| 1986| 1
| 4	| 1988| 2
| 5	| 1990| 1
| 6	| 1991| 2
| 7	| 1992| 1
| 8	| 1994| 2
| 9	| 1995| 2
| 10	| 1996| 1
| 11	| 1997| 3
| 12	| 1998| 7
| 13	| 1999| 11
| 14	| 2000| 20
| 15	| 2001| 25
| 16	| 2002| 21
| 17	| 2003| 26
| 18	| 2004| 49
| 19	| 2005| 51
| 20	| 2006| 99
| 21	| 2007| 171
| 22	| 2008| 371
| 23	| 2009| 3256
| 24	| 2010| 40278
| 25	| 2011| 40697
| 26	| 2012| 41502
| 27	| 2013| 38792
| 28	| 2014| 35650
| 29	| 2015| 33327
| 30	| 2016| 29615
| 31	| 2017| 28462
| 32	| 2018| 26618
| 33	| 2019| 39199
| 34	| 2020| 11973

## Executing the split in SQL

From this, we used these queries to get specific sub-tables by date range for the `defendant_docket_details` table:

```
CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.defendant_docket_details_2010_2011`
AS (
SELECT *
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2010, 2011));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.defendant_docket_details_2012_2013`
AS (
SELECT *
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2012, 2013));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.defendant_docket_details_2014_2015`
AS (
SELECT *
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2014, 2015));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.defendant_docket_details_2016_2017`
AS (
SELECT *
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2016, 2017));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.defendant_docket_details_2018_2019`
AS (
SELECT *
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2018, 2019));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.defendant_docket_details_2020`
AS (
SELECT *
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2020));
```

We used the below set of queries to get specific sub-tables by date range for other tables.  `bail` is particularly large and should be done in one-year increments.

```
# Offenses (original)

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_2010_2011`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2010, 2011))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_2012_2013`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2012, 2013))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_2014_2015`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2014, 2015))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_2016_2017`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2016, 2017))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_2018_2019`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2018, 2019))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_2020`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2020))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions` JOIN dockets
USING(docket_id));

# Offenses (v2)

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2_2010_2011`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2010, 2011))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2_2012_2013`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2012, 2013))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2_2014_2015`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2014, 2015))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2_2016_2017`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2016, 2017))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2_2018_2019`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2018, 2019))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2_2020`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2020))

SELECT * FROM
`reclaim-philadelphia-data.rladies.offenses_dispositions_v2` JOIN dockets
USING(docket_id));

# BAILS

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2010`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2010))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2011`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2011))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2012`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2012))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2013`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2013))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2014`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2014))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2015`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2015))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2016`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2016))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2017`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2017))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2018`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2018))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2019`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2019))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));

CREATE OR REPLACE TABLE
`reclaim-philadelphia-data.rladies.bail_2020`
AS (

WITH dockets AS
(SELECT docket_id
FROM `reclaim-philadelphia-data.rladies.defendant_docket_details`
WHERE extract(year from arrest_date) IN (2020))

SELECT * FROM
`reclaim-philadelphia-data.rladies.bail` JOIN dockets
USING(docket_id));
```

## Extracting and moving files to GCS

Then in cloud shell we run the following commands to add flat file / csvs to a cloud bucket:

### Offense Dispositions (original)

```
bq extract rladies.offenses_dispositions_2010_2011 gs://jat-rladies-2021-datathon/offenses_dispositions_2010_2011.csv
bq extract rladies.offenses_dispositions_2012_2013 gs://jat-rladies-2021-datathon/offenses_dispositions_2012_2013.csv
bq extract rladies.offenses_dispositions_2014_2015 gs://jat-rladies-2021-datathon/offenses_dispositions_2014_2015.csv
bq extract rladies.offenses_dispositions_2016_2017 gs://jat-rladies-2021-datathon/offenses_dispositions_2016_2017.csv
bq extract rladies.offenses_dispositions_2018_2019 gs://jat-rladies-2021-datathon/offenses_dispositions_2018_2019.csv
bq extract rladies.offenses_dispositions_2020 gs://jat-rladies-2021-datathon/offenses_dispositions_2020.csv
```
### Offense Dispositions (v2)

```
bq extract rladies.offenses_dispositions_v2_2010_2011 gs://jat-rladies-2021-datathon/offenses_dispositions_v2_2010_2011.csv
bq extract rladies.offenses_dispositions_v2_2012_2013 gs://jat-rladies-2021-datathon/offenses_dispositions_v2_2012_2013.csv
bq extract rladies.offenses_dispositions_v2_2014_2015 gs://jat-rladies-2021-datathon/offenses_dispositions_v2_2014_2015.csv
bq extract rladies.offenses_dispositions_v2_2016_2017 gs://jat-rladies-2021-datathon/offenses_dispositions_v2_2016_2017.csv
bq extract rladies.offenses_dispositions_v2_2018_2019 gs://jat-rladies-2021-datathon/offenses_dispositions_v2_2018_2019.csv
bq extract rladies.offenses_dispositions_v2_2020 gs://jat-rladies-2021-datathon/offenses_dispositions_v2_2020.csv
```


### Defendant Docket Details

```
bq extract rladies.defendant_docket_details_2010_2011 gs://jat-rladies-2021-datathon/defendant_docket_details_2010_2011.csv
bq extract rladies.defendant_docket_details_2012_2013 gs://jat-rladies-2021-datathon/defendant_docket_details_2012_2013.csv
bq extract rladies.defendant_docket_details_2014_2015 gs://jat-rladies-2021-datathon/defendant_docket_details_2014_2015.csv
bq extract rladies.defendant_docket_details_2016_2017 gs://jat-rladies-2021-datathon/defendant_docket_details_2016_2017.csv
bq extract rladies.defendant_docket_details_2018_2019 gs://jat-rladies-2021-datathon/defendant_docket_details_2018_2019.csv
bq extract rladies.defendant_docket_details_2020 gs://jat-rladies-2021-datathon/defendant_docket_details_2020.csv
```
### Bail

```
bq extract rladies.bail_2010 gs://jat-rladies-2021-datathon/bail_2010.csv
bq extract rladies.bail_2011 gs://jat-rladies-2021-datathon/bail_2011.csv
bq extract rladies.bail_2012 gs://jat-rladies-2021-datathon/bail_2012.csv
bq extract rladies.bail_2013 gs://jat-rladies-2021-datathon/bail_2013.csv
bq extract rladies.bail_2014 gs://jat-rladies-2021-datathon/bail_2014.csv
bq extract rladies.bail_2015 gs://jat-rladies-2021-datathon/bail_2015.csv
bq extract rladies.bail_2016 gs://jat-rladies-2021-datathon/bail_2016.csv
bq extract rladies.bail_2017 gs://jat-rladies-2021-datathon/bail_2017.csv
bq extract rladies.bail_2018 gs://jat-rladies-2021-datathon/bail_2018.csv
bq extract rladies.bail_2019 gs://jat-rladies-2021-datathon/bail_2019.csv
bq extract rladies.bail_2020 gs://jat-rladies-2021-datathon/bail_2020.csv
```
