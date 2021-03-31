#----- Load data and libraries
library(tidyverse)
bail <- read.csv('baildata.csv')
details <- read.csv('defendant_docket_details.csv')
ids <- read.csv('defendant_docket_ids.csv')
dispositions <- read.csv('offenses_dispositions.csv')



#----- Assign Date type to dates
bail$action_date <- as.Date(bail$action_date)
details$date_of_birth <- as.Date(details$date_of_birth)
details$arrest_date <- as.Date(details$arrest_date)
details$complaint_date <- as.Date(details$complaint_date)
details$disposition_date <- as.Date(details$disposition_date)
details$filing_date <- as.Date(details$filing_date)
details$initiation_date <- as.Date(details$initiation_date)



#----- Renaming and assigning Factor type
colnames(bail) <- c("docket_ID", "action_date", "action_type", "type_name", "percentage", "total_amount", "registry_code", "judge_title", "judge_lastname", "judge_firstname")
bail$docket_ID <- as.factor(bail$docket_ID)
bail$type_name <- as.factor(bail$type_name)
bail$registry_code <- as.factor(bail$registry_code)
bail$action_type <- as.factor(bail$action_type)
str(bail)

colnames(details) <- c("docket_ID", "gender", "race", "date_of_birth", "arrest_date", "complaint_date", "disposition_date", "filing_date",
                       "initiation_date", "status", "court_office", "processing_status", "status_change_time", "municipality_name",
                       "municipality_county", "judicial_districts", "court_office_types", "court_types", "representation")
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



#----- Remove unnecessary or unhelpful columns
details <- subset(details, select = -c(municipality_name, municipality_county, judicial_districts))



#----- Cleaning up strings/categorical variables

#- Combining judge names/title in bail data set into single categorical variable
str(bail)
bail$judge <- paste(bail$judge_title, bail$judge_firstname, bail$judge_lastname, sep=" ")
bail$judge <- as.factor(bail$judge)
str(bail$judge)
names(sort(-table(bail$judge)))
#Among the top 20 most frequently occurring judges are blank, Arraignment Court Magistrate, Director Office of Judicial Records,
#Trial Commissioner, District Court Administrator, District Attorney, Clerk Typist, President Judge. Many additional records
#that are not judges
#Isolate 4685336 records not containing "Judge"
bail$judge[c(!grepl("Judge", bail$judge_title))]

#Registry code does not appear to have any NA or missing values
length(subset(bail$registry_code, is.na(bail$registry_code)))
length(subset(bail$registry_code, is_empty(bail$registry_code)))

#Most frequent status change time within details data set is 0001-01-01, appearing 12351 times. None are NA or missing.
names(sort(-table(details$status_change_time)))
length(subset(details$status_change_time, details$status_change_time == "0001-01-01"))
length(subset(details$status_change_time, is.na(details$status_change_time)))
length(subset(details$status_change_time, is_empty(details$status_change_time)))


#----- Calculating intervals
str(details)

#- Difference in days between initiation date and arrest date
date_diff <- details$initiation_date - details$arrest_date #calculate difference in days
date_diff
date_diff <- as.numeric(date_diff) #convert to numeric type
date_diff <- subset(date_diff, date_diff > 0) #filter out negative or zero values
date_diff <- subset(date_diff, date_diff < 135) #filter out outliers
date_diff_months <- date_diff/31 #convert to months
ggplot(data=NULL, aes(x=date_diff)) + geom_boxplot()
ggplot(data=NULL, aes(x=date_diff)) + geom_histogram()
ggplot(data=NULL, aes(x=date_diff_months)) + geom_boxplot()
ggplot(data=NULL, aes(x=date_diff_months)) + geom_histogram()


#----- Combining datasets
str(bail)

#Merge details with dispositions
combined <- merge(details, dispositions, by.x = "docket_ID", by.y = "docket_ID")

#Merge combined with ids
combined <- merge(combined, ids, by.x="docket_ID", by.y="docket_ID")

#Merge combined with bail
combined <- merge(combined, bail, by.x="docket_ID", by.y="docket_ID")

subset(combined$docket_ID, is.na(combined$defendant_ID))
duplicated(combined$docket_ID) #This does not return TRUE for the first time a duplicate variable appears (i.e., first
#4 items in array are "1" but item 1 in the array returns FALSE)

str(combined)
summary(combined)


#----- Bail total amount histogram
filt <- bail[bail$total_amount < 250000,]
ggplot(data = filt, aes(x=total_amount)) + geom_histogram(binwidth = 10000)

ggplot(data=details, aes(x=filing_datey)) + geom_histogram(binwidth = 1) + xlim(2009,2021)
                                                                              