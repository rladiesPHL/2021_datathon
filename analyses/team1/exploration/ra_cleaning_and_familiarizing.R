#Load data and libraries
bail <- read.csv("baildata.csv")
details <- read.csv("defendant_docket_details.csv")
ids <- read.csv("defendant_docket_ids.csv")
dispositions <- read.csv("offenses_dispositions.csv")
library(ggplot2)

str(bails)
str(details)
str(ids)
str(dispositions)

#Separate dates into separate integer columns for year, month, and date
bail$action_datey <- as.integer(substr(bail$action_date,1,4))
bail$action_datem <- as.integer(substr(bail$action_date,6,7))
bail$action_dated <- as.integer(substr(bail$action_date,9,10))
details$DOBy <- as.integer(substr(details$date_of_birth,1,4))
details$DOBm <- as.integer(substr(details$date_of_birth,6,7))
details$DOBd <- as.integer(substr(details$date_of_birth,9,10))
details$arrest_datey <- as.integer(substr(details$arrest_date,1,4))
details$arrest_datem <- as.integer(substr(details$arrest_date,6,7))
details$arrest_dated <- as.integer(substr(details$arrest_date,9,10))
details$complaint_datey <- as.integer(substr(details$complaint_date,1,4))
details$complaint_datem <- as.integer(substr(details$complaint_date,6,7))
details$complaint_dated <- as.integer(substr(details$complaint_date,9,10))
details$disposition_datey <- as.integer(substr(details$disposition_date,1,4))
details$disposition_datem <- as.integer(substr(details$disposition_date,6,7))
details$disposition_dated <- as.integer(substr(details$disposition_date,9,10))
details$filing_datey <- as.integer(substr(details$filing_date,1,4))
details$filing_datem <- as.integer(substr(details$filing_date,6,7))
details$filing_dated <- as.integer(substr(details$filing_date,9,10))
details$initiation_datey <- as.integer(substr(details$initiation_date,1,4))
details$initiation_datem <- as.integer(substr(details$initiation_date,6,7))
details$initiation_dated <- as.integer(substr(details$initiation_date,9,10))


#Renaming and factoring columns
colnames(bail) <- c("docket_ID", "full_date", "action_type", "type_name", "percentage", "total_amount", "registry_code", "judge_title", "judge_lastname", "judge_firstname", "year", "month", "date")
bail$docket_ID <- as.factor(bail$docket_ID)
bail$type_name <- as.factor(bail$type_name)
bail$registry_code <- as.factor(bail$registry_code)
bail$action_type <- as.factor(bail$action_type)
str(bail)

colnames(details) <- c("docket_ID", "gender", "race", "DOB", "arrest_date", "complaint_date", "disposition_date", "filing_date",
                       "initiation_date", "status", "court_office", "processing_status", "status_change_time", "municipality_name",
                       "municipality_county", "judicial_districts", "court_office_types", "court_types", "representation", "DOBy", "DOBm", "DOBd",
                       "arrest_datey", "arrest_datem", "arrest_dated", "complaint_datey", "complaint_datem", "complaint_dated", "disposition_datey",
                       "disposition_datem", "disposition_dated", "filing_datey", "filing_datem", "filing_dated", "initiation_datey",
                       "initiation_datem", "initiation_dated")
details$gender <- as.factor(details$gender)
details$race <- as.factor(details$race)
details$status <- as.factor(details$status)
details$court_office <- as.factor(details$court_office)
details$court_office_types <- as.factor(details$court_office_types)
details$court_types <- as.factor(details$court_types)
details$representation <- as.factor(details$representation)
str(details)

colnames(ids) <- c("defendant_ID", "docket_ID")
ids$defendant_ID <- as.factor(ids$defendant_ID)
ids$docket_ID <- as.factor(ids$docket_ID)
str(ids)

colnames(dispositions) <- c("docket_ID", "description", "statute_description", "sequence_number", "grade", "disposition",
                            "disposing_auth_first", "disposing_auth_middle", "disposing_auth_last", "disposing_auth_title", "disposing_auth_docname",
                            "disposition_method", "min_period", "max_period", "period", "sentence_type")
dispositions$docket_ID <- as.factor(dispositions$docket_ID)
dispositions$description <- as.factor(dispositions$description)
dispositions$statute_description <- as.factor(dispositions$statute_description)
dispositions$grade <- as.factor(dispositions$grade)
dispositions$disposition <- as.factor(dispositions$disposition)
dispositions$disposition_method <- as.factor(dispositions$disposition_method)
dispositions$min_period <- as.factor(dispositions$min_period)
dispositions$max_period <- as.factor(dispositions$max_period)
dispositions$period <- as.factor(dispositions$period)
dispositions$sentence_type <- as.factor(dispositions$sentence_type)
str(dispositions)

#Remove unnecessary or unhelpful columns
bail <- subset(bail, select = -c(date))

details <- subset(details, select = -c(DOB, arrest_date, complaint_date, disposition_date, filing_date, initiation_date,
                                       municipality_name, municipality_county, judicial_districts, DOBm, DOBd, arrest_datey,
                                       complaint_dated, disposition_dated, filing_dated, initiation_dated))


#Bail total amount histogram
filt <- bail[bail$total_amount < 250000,]
ggplot(data = filt, aes(x=total_amount)) + geom_histogram(binwidth = 10000)

ggplot(data=details, aes(x=filing_datey)) + geom_histogram(binwidth = 1) + xlim(2009,2021)
                                                                              