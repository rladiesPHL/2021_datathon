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
details$status_change_time <- as.Date(details$status_change_time)



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

names(sort(-table(bail$judge_lastname)))
#Among the top 20 most frequently occurring judges are blank, Arraignment Court Magistrate, Director Office of Judicial Records,
#Trial Commissioner, District Court Administrator, District Attorney, Clerk Typist, President Judge. Many additional records
#that are not judges

#Registry code does not appear to have any NA or missing values
length(subset(bail$registry_code, is.na(bail$registry_code)))
length(subset(bail$registry_code, is_empty(bail$registry_code)))

#Most frequent status change time within details data set is 0001-01-01, appearing 12351 times. None are NA or missing.
names(sort(-table(details$status_change_time)))
length(subset(details$status_change_time, details$status_change_time == "0001-01-01"))
length(subset(details$status_change_time, is.na(details$status_change_time)))
length(subset(details$status_change_time, is_empty(details$status_change_time)))


#----- Combining datasets
str(bail)

#Merge details with dispositions
combined <- merge(details, dispositions, by.x = "docket_ID", by.y = "docket_ID")

#Merge combined with ids
combined <- merge(combined, ids, by.x="docket_ID", by.y="docket_ID")

#Merge combined with bail
combined <- merge(combined, bail, by.x="docket_ID", by.y="docket_ID")

str(combined)
summary(combined)


#----- Calculating intervals
str(details)

#- View dockets where disposition equals status_change_time. Unsure when/why these dates do or don't match
combined %>%
  filter(!is.na(disposition_date) & !is.na(status_change_time),
         disposition_date == status_change_time)

#- Arrange data frame from most recent to least recent status_change_time. Add column with arrest-to-disposition time interval
combined <- combined %>%
  arrange(desc(status_change_time)) %>%
  mutate(
    time_to_disposition = disposition_date - arrest_date
  )

str(combined)

#- Create new data frame with just the first record per docket_ID
no_duplicates <- combined[!duplicated(combined$docket_ID), ]

summary(as.integer(no_duplicates$time_to_disposition), na.rm=T) #Median time to disposition is 123 days, mean is 231.9 days
IQR(as.integer(no_duplicates$time_to_disposition), na.rm=T) #Outliers start above 363

#- Visualize time to disposition with suspected without suspected outliers
no_duplicates %>%
  filter(time_to_disposition <= 363) %>%
  ggplot() + geom_histogram(aes(x=as.integer(time_to_disposition)), binwidth=30)



#----- Bail Change Exploration
bail %>%
  arrange(docket_ID) %>%
  group_by(docket_ID) %>%
  filter(docket_ID != docket_ID) %>%
  select(total_amount)
