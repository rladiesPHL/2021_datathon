library(tidyverse)
library(lubridate)
library(DataExplorer)
library(vroom)
library(stringr)

larry_date <- as.Date("2018-01-02")
start_period_1 <- larry_date - period(2, "years")
end_period_2 <- larry_date + period(2, "years")
dat_dir <- "C:/Users/katri/Documents/GT/R-Ladies Datathon 2021/csv"

setwd("C:/Users/katri/Documents/GT/R-Ladies Datathon 2021/csv")

bail <- read.csv("bail.csv")
defendant_docket_details <- read.csv("defendant_docket_details.csv")
offenses_dispositions <- read.csv("offenses_dispositions_v3.csv")

clean_bail <-
  bail%>%
  mutate(action_type_name = action_type_name %>%
           as.factor() %>%
           relevel(ref = "Set")) %>%
  filter(
    participant_name__title == "Judge",
    !is.na(participant_name__first_name)
  ) %>%
  mutate(
    judge = paste(
      participant_name__last_name,
      participant_name__first_name,
      sep = ","
    ),
    action_date = ymd(action_date),
    action_type_name = factor(action_type_name)
  )

bail_grouped <- clean_bail %>%
  group_by(docket_id) %>%
  summarise( 
    date_first_bail = first(action_date),
    ROR_ever = ifelse(any(type_name == "ROR"), 1, 0) # did the case ever receive ROR
  )

def_subset <- defendant_docket_details %>% select(docket_id, race)

offense_grouped <- 
  offenses_dispositions %>%
  filter(!is.na(grade)) %>%
  group_by(docket_id) %>%
  summarise(
    most_ser_off = max(unique(grade))
  )

joined <- bail_grouped %>%
  left_join(def_subset, by = "docket_id") %>%
  left_join(offense_grouped, by = "docket_id") %>%
  filter(!is.na(ROR_ever)) %>%
  mutate(period = case_when(
    between(date_first_bail, start_period_1, larry_date) ~ "before",
    between(date_first_bail, larry_date, end_period_2) ~ "after",
    TRUE ~ NA_character_ 
  )) %>%
  mutate(period = period %>%
           as.factor() %>%
           relevel(ref = "before")) %>%
  mutate(grade = ifelse(most_ser_off %in% c("F1", "F2", "F3", "F"), "felony",
                        ifelse(most_ser_off %in% c("M1", "M2", "M3", "M"), "misdemeanor", NA)
  )) %>%
  filter(!is.na(period)) %>%
  filter(!is.na(grade))

library(rms)

joined$severity <- with(joined,case_when(most_ser_off %in% c("M3","M")~"M3/M",most_ser_off %in% c("F3","F")~"F3/F",TRUE~most_ser_off ))
joined$severity <- factor(joined$severity,levels=c("M3/M","M2","M1","F3/F","F2","F1"))
joined$race_cat <- with(joined,case_when(race %in% c("Asian","Asian/Pacific Islander")~"Asian",race %in% c("Black","White")~race,TRUE~"Other/Missing"))
joined$race_cat  <- relevel(factor(joined$race_cat),"White")

model1p <- update(model1,penalty=1.2,data=joined)

dd<-datadist(joined)
options(datadist="dd")

predictions <- Predict(model1p,period,race_cat,severity) %>%
  mutate(est_rate=plogis(yhat),lower_ci=plogis(lower),upper_ci=plogis(upper)) %>%as_tibble()

predictions %>% ggplot(aes(x=race_cat,color=period,y=est_rate))+geom_point()+geom_errorbar(aes(ymin=lower_ci,ymax=upper_ci)) +facet_wrap(~severity)  +theme_classic() + theme(axis.text.x=element_text(angle=45, vjust=0.5), legend.position = "bottom")

predictions%>% filter(race_cat %in% c("White","Black")) %>% ggplot(aes(x=race_cat,color=period,y=est_rate))+geom_point()+geom_errorbar(aes(ymin=lower_ci,ymax=upper_ci)) +facet_wrap(~severity)  +theme_classic() + theme(axis.text.x=element_text(angle=45, vjust=0.5), legend.position = "bottom")

joined$black <- joined$race=="Black"

with(filter(joined,period=="before"), mantelhaen.test(black,ROR_ever,severity,exact=TRUE))
with(filter(joined,period=="after"), mantelhaen.test(black,ROR_ever,severity,exact=TRUE))