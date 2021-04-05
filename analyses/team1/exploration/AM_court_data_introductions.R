####Visualization of Criminal Data --R Ladies Team 1####
#links to data https://github.com/awalsh17/2021_datathon/blob/main/data/data_links.md


library(tidyverse)
library(ggplot2)

#####################
####Read in Data#####
#####################


##bail
bail <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/bail.csv')
# bail.10 <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2010.csv')
# bail.20 <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2020.csv')


##offenses
offenses <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions.csv')
# offenses.10.11 <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2010_2011.csv')
# offenses.18.19 <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2018_2019.csv')


##docket info
docket.info <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details.csv')

apply(bail, 2, function(x)(length(unique(x))))
apply(offenses, 2, function(x)(length(unique(x))))

##192 judges
##962 descriptions
#16 grades
##241 periods
##6 sentence types

apply(docket.info, 2, function(x)(length(unique(x))))
## 370313 different dockets 




#########################
####Cleaning Offenses####
#########################

##cleaning description, she uses a fancy regex to separate by the dash
#check if description and statue_description are the same, separate description into main offense and sub category 
length(unique(offenses$description))
length(unique(offenses$statute_description))

##when are they not the same? 
offenses %>% filter(description != statute_description) %>% select(c("docket_id","description","statute_description")) %>% head()

##discard statute description and split description into main offense and details, get rid of extraneous columns
offenses_clean <- offenses %>% separate(description, into = c("Main_Offense","Details"), "-", remove = F, extra = "merge", fill = "right") %>% 
  mutate(Main_Offense = trimws(Main_Offense), Details = trimws(Details)) %>% #select(-statute_description) %>% 
  ##remove extraneous columns 
  select(-c(sequence_number, disposing_authority__first_name, 
                               disposing_authority__middle_name, disposing_authority__last_name)) %>% 
  ##rename the full Judge ID, remove rows with no judge, not helpful
  rename(Judge = disposing_authority__document_name) %>% filter(!is.na(Judge)) %>% distinct()

##wow lots dont have judges on there....

##still need to clean periods, summarize the grade?, way to further parse down offenses? 
####need to understand the issue with multiple docket IDs, why? why are there different offenses on the same? multiple crimes?




##########################
####Cleaning Docket ID####
##########################

##unique docket IDs already

##create ages and times between processing 
docket.info_clean <- docket.info %>% mutate("Age_at_Arrest"=lubridate::time_length(difftime(arrest_date, date_of_birth),"years")) %>% 
  relocate("Age_at_Arrest", .after = "arrest_date") %>% mutate("Time_to_Deposition_(Wk)" = abs(lubridate::time_length(difftime(disposition_date, complaint_date),"weeks"))) %>% 
  relocate("Time_to_Deposition_(Wk)", .after = "disposition_date") %>% mutate("Time_to_Initiation_(day)" = abs(lubridate::time_length(difftime(initiation_date, filing_date),"days"))) %>% 
  relocate("Time_to_Initiation_(day)", .after = "initiation_date")


#get rid of court location info--all pretty much Philadelphia? 
docket.info_clean <- docket.info_clean %>% select(-c(municipality__name, municipality__county__name, judicial_districts))



#####################
####Cleaning Bail####
#####################


##there are a lot of different entries for a docket ID.......lots of registry entries, different judges, how important is this? 
                              



#####################################
####Bring in Statutes Annotations####
#####################################

prefix <- "D://Dropbox (SBG)/"
# There is a statutes.csv file in the repo
statute_map <- readr::read_csv(paste0(prefix,'2021_datathon/data/statutes.csv'))
# Clean files and summarize ----
# statute file has some interesting characters, let's remove those and split into parts
statute_map <- statute_map %>% 
  tidyr::separate(statute_name, 
                  into=c("statute_pt1","statute_pt2","statute_pt3"), 
                  sep= " § | §§ | ?????? | ???????????? ", fill = "right",remove = FALSE) %>% 
  distinct(statute_description, .keep_all = T) # note this removes some rows
# We will merge this into offenses/dispos data by statute_description - so make sure that is 1:1
# nrow(statute_map) == n_distinct(statute_map$statute_description)
# There were some 1:many for statute_description to statute, but they are super similar
# e.g. "Child Pornograpy" maps to both 18	6312	D and 18	6312	D1


statute_map <- statute_map %>% mutate(Chapter = substr(statute_pt2,1,2)) %>% relocate(Chapter, .before = statute_pt2)
statute_map <- statute_map %>% mutate(Title.Chapter = paste(statute_pt1,Chapter, sep = "-")) %>% relocate(Title.Chapter, .before = statute_pt2)

statute_map %>% select(statute_name, statute_pt1, Chapter, Title.Chapter) %>% distinct() %>% arrange(Chapter) %>% arrange(statute_pt1) %>% head()

statute.codes <- xlsx::read.xlsx(paste0(prefix,'2021_datathon/analyses/team1/exploration/Statute_Codes.xlsx'), sheetIndex = 1)

statute_map_codes <- left_join(statute_map, statute.codes)



###join mapped statute codes to descriptions in offenses df
offenses_coded <- full_join(statute_map_codes,offenses_clean)
