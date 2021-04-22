# R-ladies Philly Datathon_ Kulbir Kaur 

# Packages used ----

library(readr)
library(tidyverse)
library(tidyselect)
library(here)
library(broom)
library(janitor)
library(stringr)
library(tidyr)

# Data added from R ladies Philly ---- 
# kept the names of the data set same as RA 
# disposition is the decision reached. In the disposition data there is guilty, guilty plea negotiated vs non-negotitated (may be something to check out)

ids <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_ids.csv')

disposition <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions.csv')

bail <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/bail.csv')

details <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details.csv')

# looking at the data prior to cleaning & manipulations

str(ids)
str(disposition)
str(bail)
str(details)

details %>% group_by(municipality__county__name) %>% 
  tally()

details %>% group_by(judicial_districts) %>% 
  tally()

details %>% group_by(race) %>% 
  tally()

disposition %>% group_by(disposing_authority__document_name) %>% 
  tally()

disposition %>% group_by(disposition) %>% 
  tally()

disposition %>% group_by(grade) %>% 
  tally()

disposition %>% group_by(sentence_type) %>% 
  tally()

# i looked at the disposition data to look at the relation of race & sentence received for the different grade of offenses. 

disposition <- disposition %>% na.omit()

# select the variables that we will use from the details dataset (this dataset contains the race variable that i would use in the plot)

details_sel <- details [c("docket_id", "gender","race", "municipality__name", "municipality__county__name", "judicial_districts")]

# join the two data frames

dispo_det <- inner_join(disposition, details_sel, by = "docket_id")%>% 
  distinct(docket_id, .keep_all = TRUE)

# ALICE: I saved this dispo_det out for the app
saveRDS(dispo_det, '../2021_datathon_dashboard/data/kk_dispo_det.Rds')

# I chose to look at two races (White & Black) 

dispo_race<- dispo_det %>% filter(str_detect(race, "White|Black" )) 

# Calculating the percentage of the sentence by the grade

perct <- dispo_race %>% 
  add_count(sentence_type, name = "sentence_ct") %>% 
  count(race, grade, sentence_type,sentence_ct, sort = TRUE) %>% 
  mutate(pct_sentence = n /sentence_ct) 

p <- ggplot(perct) +
  aes(x = grade, fill = race, weight = pct_sentence) +
  geom_bar(position = "dodge") +
  scale_fill_hue() +
  labs(y = "percentage") +
  theme_light() + 
  scale_y_continuous(labels = scales::percent_format(accuracy = 1))+
  coord_flip() +
  facet_wrap(vars(sentence_type))

ggsave(p, filename = "plot1.png", height = 6, width = 6)

