# All the data processing functions



#' Aggregate bail dataset
#' 
#' There are many rows per docket in the bail data
#' This will summarize per docket whether there was monetary bail (Monetary, Unsecured) 
#' or not (ROR, Nonmonetary, Nominal)
#' This function will also summarize the initial set bail amount and percent, 
#' the overall min/max total_amounts, and the earliest/latest action dates.
#' 
#' Note that review of the dataset found that rarely Nonmonetary type have total_amount>0 (n=2)
#'
#' @param data 
#'
#' @return data.frame with one row per docket_id. Adds min_bail_amount, max_bail_amount and 
#' lists for type_name, action_type_name
#'

aggregate_bails <- function(data){
  data %>% 
    rename(bail_judge_title = participant_name__title) %>% 
    mutate(bail_judge = paste(participant_name__first_name, participant_name__last_name)) %>% 
    distinct(docket_id, total_amount, percentage, bail_judge_title,bail_judge,
             type_name, action_type_name, action_date, .keep_all = TRUE) %>% 

    group_by(docket_id) %>% 
    arrange(action_date) %>% 
    summarise(any_monetary_bail = ifelse(any(type_name %in% c("Monetary","Unsecured")),T,F),
              min_bail_amount = min(total_amount, na.rm=T),
              max_bail_amount = max(total_amount, na.rm=T),
              initial_set_bail_amount = total_amount[1],
              initial_set_bail_percent = percentage[1],
              type_name_list = list(type_name),
              initial_bail_judge = bail_judge[1],
              bail_judge_list = list(unique(bail_judge)),
              # percentage_list = list(percentage),
              first_bail_action_date = min(action_date, na.rm = T),
              last_bail_action_date = max(action_date, na.rm = T),
              action_type_list = list(action_type_name)) %>% 
    ungroup()
}


#' Don't like nas or returning -Inf
max_nona <- function(x){
  if (all(is.na(x))) {
    NA
  } else {
    max(x, na.rm = TRUE)
  }
}



#' Aggregate the Offenses and Dispositions dataset
#' 
#' Converts the dataset to a one row per docket_id:judge
#' #' This may not be what we want but for the purpose of illustration and 
#' moving fast, this is what I did.
#' Not all offenses have a corresponding sentence.
#' We end up with a summarization of all the information as nested lists.
#' We also spread to wide to add columns for min, max periods from each sentence type
#' (Confinement, Probation). When there were mutliple of these sentences, then took max value.
#' NOTE: Need to understand better way to combine sentences! ADD them or MAX
#'
#' @param data Offenses and Dispositions data.frame from the original dataset after adding the cleaned min_period_days, max_period_days variables. If the statute data is added, lists those too.
#'
#' @return data.frame with min_grade and max_grade columns and nested lists
#'
aggregate_od <- function(data){
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
  
  summarise_cols <- intersect(names(data), c("desc_main","description", "sentence_type", "disposition", 
                                             "disposition_method", "statute_title", 
                                             "statute_chapter", "Title_Description","Chapter_Description"))
  other_info <- data %>% 
    distinct(across(all_of(c("docket_id",summarise_cols)))) %>% 
    group_by(docket_id) %>% 
    summarise(across(summarise_cols, ~list(unique(na.omit(.))))) %>% 
    ungroup() 
  
  judges <- data %>% 
    distinct(docket_id, disposing_authority__document_name) %>% 
    rename(judge = disposing_authority__document_name) %>% 
    filter(!is.na(judge))
  
  merge(merge(judges, merge(widened, grades, by = "docket_id", all.x=T, all.y=T), 
        by = "docket_id", all.x=T, all.y=T),other_info, all.x=T, all.y=T)
  
}


#' Augment Offenses and Dispositions data to add time internals and ages
#'
#' @param data Offenses and Dispositions data.frame from the original dataset
#' @return  modified data.frame with new variables (age_at_arrest)
#'
augment_dispositions <- function(data){
  
}

#' @example
#' extract_days(x = "2 weeks and 1 day")
#' Author: jake (Thank you)
extract_days <- function(x) {
  tolower(x) %>% 
    stringr::str_remove("and ") %>% 
    lubridate::duration() %>% 
    lubridate::seconds_to_period() %>% 
    lubridate::day()
}

#' Clean the sentence period variables
#' @description This function takes in a data.frame with min, max period variables and 
#' transforms to be easier to work with. 
#' This function NEEDS MORE TESTING
#'  
#' @param data Offenses and Dispositions data.frame from the original dataset
#' @return  modified data.frame with cleaned min_period_days and max_period_days. These are the cleaned values in the unit of months
#' 
#' 
clean_periods <- function(data){
  if (!all(c("min_period", "max_period") %in% colnames(data))) stop('variables missing from input data')
  
  data %>% 
    mutate(min_period_days = extract_days(min_period),
           max_period_days = extract_days(max_period)) %>%
  # Some cases have NA for min/max, but values for period
  # These tend to be a mess: "dd to dd years" or "dd YEARS - dd YEARS" or "LIFE"
    mutate(period = tolower(period),
           period = stringr::str_replace(period, " to "," - "),
           life_sentence = grepl("life",period)) %>% 
    tidyr::separate(period, remove = F, into = c("min_temp","max_temp"),
                    sep = " - ", fill = "left") %>% 
    mutate(min_temp = case_when(
      grepl("month|year|day", min_temp) ~ min_temp,
      grepl("month|year|day", max_temp) ~ paste(min_temp, stringr::str_extract(max_temp, "month|year|day"))
    ),
    max_temp = extract_days(max_temp),
    min_temp = extract_days(min_temp),
    max_period_days = coalesce(max_period_days, max_temp),
    min_period_days = coalesce(min_period_days, min_temp)) %>% 
    select(-min_temp, -max_temp)
    
}


#' Clean the sentence period variables
#' @description This function takes in a data.frame with description variable and 
#' transforms to be easier to work with. This does not reduce the number of unique 
#' values in description very much.
#'  
#' @param data Offenses and Dispositions data.frame from the original dataset
#' @return  modified data.frame with cleaned desc_main variable.
#' 
#' 

clean_descriptions <- function(data){
  if (!all(c("description") %in% colnames(data))) stop('variables missing from input data')
  
  clean_od <- data %>% 
    mutate(desc_main = ifelse(grepl("-",description),
                              stringr::str_extract(description, ".+?(?=-)"),
                              description))
  
  clean_od
}




