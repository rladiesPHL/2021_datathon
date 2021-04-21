library(tidyverse)
library(ggplot2)

offenses <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_v3.csv')
docket.info <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details.csv')


source("aw_functions.R") ##functions from Alice

#########################
####clean up offenses####
#########################

##split description into main offense and details, get rid of extraneous columns
offenses_clean <- offenses %>% separate(description, into = c("Main_Offense","Details"), "-", remove = F, extra = "merge", fill = "right") %>% 
  mutate(Main_Offense = trimws(Main_Offense), Details = trimws(Details)) %>% #select(-statute_description) %>% 
  ##remove extraneous columns 
  select(-c(sequence_number, disposing_authority__first_name, 
            disposing_authority__middle_name, disposing_authority__last_name)) %>% 
  ##rename the full Judge ID, remove rows with no judge, not helpful
  rename(Judge = disposing_authority__document_name) %>% filter(!is.na(Judge)) %>% distinct()


###add TRUE/FALSE disposition--from Alice
offenses_clean <- offenses_clean %>% 
  group_by(docket_id) %>% 
  mutate(no_disposition = all(is.na(disposition))) %>% 
  ungroup() %>% 
  filter(no_disposition==FALSE)




###incorporate mapped statute codes
prefix <- "D://Dropbox (SBG)/"
statute.codes <- xlsx::read.xlsx(paste0(prefix,'2021_datathon/analyses/team1/exploration/Statute_Codes.xlsx'), sheetIndex = 1)

offenses_clean_statutes <- offenses_clean %>% 
  tidyr::separate(statute_name, 
                  into=c("statute_title","statute_section","statute_pt3"), 
                  sep= " � | �� ", fill = "right",remove = FALSE) #%>% 
              #sep= " § | §§ | ยง | ยงยง ", fill = "right")
  #distinct(statute_description, .keep_all = T) # note this removes some rows
# We will merge this into offenses/dispos data by statute_description - so make sure that is 1:1
# nrow(statute_map) == n_distinct(statute_map$statute_description)
# There were some 1:many for statute_description to statute, but they are super similar
# e.g. "Child Pornograpy" maps to both 18	6312	D and 18	6312	D1


offenses_clean_statutes <- offenses_clean_statutes %>% mutate(Chapter = substr(statute_section,1,2)) %>% relocate(Chapter, .before = statute_section)
offenses_clean_statutes <- offenses_clean_statutes %>% mutate(Title.Chapter = paste(statute_title,Chapter, sep = "-")) %>% relocate(Title.Chapter, .before = statute_section)

offenses_map_codes <- left_join(offenses_clean_statutes, statute.codes)


# clean the sentencing fields-from alice 
od_clean <- clean_periods(offenses_map_codes)

###updated from Alice
aggregate_od.AM <- function(data){
  grade_levels <- c("IC","S","S3","S2","S1",
                    "M","M3","M2","M1",
                    "F","F3","F2","F1",
                    "H","H2","H1")
  widened <- data %>% 
    distinct(docket_id, min_period_days,max_period_days,sentence_type) %>% 
    # Have cases with 2 rows per docket_id, sentence_type
    filter(!is.na(sentence_type), sentence_type %in% c("Confinement","Probation")) %>% 
    tidyr::pivot_wider(names_from = sentence_type, values_from = contains("period"),
                       values_fn = max_nona) 
  grades <- data %>% 
    # convert grade to factor - low to high
    mutate(grade = factor(grade, levels = grade_levels)) %>% 
    group_by(docket_id) %>% 
    arrange(grade) %>% 
    summarise(min_grade = grade[1],
              max_grade = grade[n()]) %>% 
    ungroup() 
  
  summarise_cols <- intersect(names(data), c("desc_main","description_clean", "sentence_type", "disposition", 
                                             "disposition_method", "statute_title","statute_description", 
                                             "statute_chapter", "Title_Description",
                                             "Main_Offense","Details","statute_name","Chapter","Title.Chapter","statute_section","Chapter_Description"))
  other_info <- data %>% 
    distinct(across(all_of(c("docket_id",summarise_cols)))) %>% 
    group_by(docket_id) %>% 
    summarise(across(summarise_cols, ~list(unique(na.omit(.))))) %>% 
    ungroup() 
  
  judges <- data %>% 
    distinct(docket_id, Judge) %>% 
    filter(!is.na(Judge))
  
  merge(merge(judges, merge(widened, grades, by = "docket_id", all.x=T, all.y=T), 
              by = "docket_id", all.x=T, all.y=T),other_info, all.x=T, all.y=T)
  
}

od_agg <- aggregate_od.AM(od_clean)


od_agg <- od_agg %>% mutate_if(is.list, funs(lapply(.,toString)))

od_agg <- unnest(od_agg,cols = c(Main_Offense, Details, statute_description, statute_name, statute_title,Chapter, 
                           Title.Chapter, statute_section,disposition, disposition_method, sentence_type, 
                           Title_Description, Chapter_Description), keep_empty = TRUE)

#########################
####clean docket info####
#########################

docket.info_clean <- docket.info %>% mutate("Age_at_Arrest"=lubridate::time_length(difftime(arrest_date, date_of_birth),"years")) %>% 
  relocate("Age_at_Arrest", .after = "arrest_date") %>% mutate("Time_to_Deposition_(Wk)" = abs(lubridate::time_length(difftime(disposition_date, complaint_date),"weeks"))) %>% 
  relocate("Time_to_Deposition_(Wk)", .after = "disposition_date") %>% mutate("Time_to_Initiation_(day)" = abs(lubridate::time_length(difftime(initiation_date, filing_date),"days"))) %>% 
  relocate("Time_to_Initiation_(day)", .after = "initiation_date")

#get rid of court location info--all pretty much Philadelphia? 
docket.info_clean <- docket.info_clean %>% select(-c(municipality__name, municipality__county__name, judicial_districts))




####merge offenses and docket info into one#### 
merged <- left_join(od_agg, docket.info_clean)

####catgories of interest, possible filters

#judge --choose a specific judge, compare against all others, list and separate to compare multiple
#race
#age
#gender

#crime -- go by title/chapter descriptons ~ write to find inexact matches 

filter_judge <- c("O'Neill","Jimenez","Anhalt","Padilla")
judges_of_interest <- c("")
crime_descriptions <- c("Assault","Robbery")
title_descriptions <- c("Crimes and Offenses")


x.axis <- "in_select_judges"
facet <- "Chapter_Description"

merged %>% 
  #filter based on selection
  mutate(select_judges = grepl(paste(judges_of_interest, collapse = "|"),Judge)) %>% 
  mutate(Confinement_Time = max_period_days_Confinement/365) %>% 
  mutate(in_select_judges = ifelse(grepl(paste(judges_of_interest, collapse = "|"),Judge), Judge, FALSE)) %>% 
  filter(grepl(paste(filter_judge, collapse = "|"), Judge)) %>% 
  filter(grepl(paste(crime_descriptions, collapse = "|"), Chapter_Description)) %>% 
  filter(grepl(paste(title_descriptions, collapse = "|"), Title_Description)) %>% 
  #plot
  ggplot(aes(x = eval(parse(text = x.axis)), y = Confinement_Time, fill = race, size = Age_at_Arrest, shape = gender)) +
  geom_quasirandom(pch = 21, groupOnX = TRUE) + 
  theme_minimal() + theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) + 
  labs(y="Max Confinement Time (Years)", x = paste(x.axis)) +
  guides(fill = guide_legend(override.aes = list(size = 5))) +
  #facet based on indicated column
  facet_wrap(.~eval(parse(text = facet)))
  NULL
  
  

  ####because of the way it lists and the multiple crimes per docket, the unique() lists get really long depending on the combinations
  ####need some way to simplify this if we want to facet by crime time or something like that 


