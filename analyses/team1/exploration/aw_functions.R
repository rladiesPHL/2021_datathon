# All the data processing functions



#' Aggregate bail dataset
#' 
#' This needs some work. Just an idea - dates are an issue.
#' We probably want to aggregrate by crime and not docket id
#'
#' @param data 
#'
#' @return data.frame with one row per docket_id. Adds min_bail_amount, max_bail_amount and 
#' lists for type_name, action_type_name
#'

aggregate_bails <- function(data){
  data %>% 
    distinct(docket_id, total_amount, 
             type_name, action_type_name, action_date, .keep_all = TRUE) %>% 

    group_by(docket_id) %>% 
    summarise(min_bail_amount = min(total_amount, na.rm=T),
              max_bail_amount = max(total_amount, na.rm=T),
              type_name_list = list(type_name),
              percentage_list = list(percentage),
              first_bail_action_date = min(action_date, na.rm = T),
              last_bail_action_date = max(action_date, na.rm = T),
              action_type_list = list(action_type_name)) %>% 
    ungroup()
}




#' Aggregate the Offenses and Dispositions dataset
#' 
#' Converts the dataset to a one row per docket_id:judge
#' Not all offenses have a corresponding sentence
#' There are multiple rows per offense when there are mult. sentences 
#' (i.e. confinement and probation)
#' This may not be what we want but for the purpose of illustration and 
#' moving fast, this is what I did.
#' We end up with a summarization of all the information as nested lists.
#' We also spread to wide to add columns for min, max periods from each sentence type
#' (Confinement, Probation). When there were mutliple of these sentences, then took max value.
#'
#' @param data Offenses and Dispositions data.frame from the original dataset after adding the cleaned desc_main and min_period_days, max_period_days variables.
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
    filter(!is.na(sentence_type), sentence_type %in% c("Confinement","Probation")) %>% 
    tidyr::pivot_wider(names_from = sentence_type, values_from = contains("period"),
                       values_fn = max) 
  grades <- data %>% 
    # convert grade to factor - low to high
    mutate(grade = factor(grade, levels = grade_levels)) %>% 
    group_by(docket_id) %>% 
    arrange(grade) %>% 
    summarise(min_grade = grade[1],
              max_grade = grade[n()],
              desc_main_list = list(unique(desc_main)),
              sentence_type_list = list(unique(sentence_type)),
              disposition_list = list(unique(disposition)),
              disposition_method_list = list(unique(na.omit(disposition_method)))) %>% 
    ungroup() 
  
  judges <- data %>% 
    distinct(docket_id, disposing_authority__document_name) %>% 
    rename(judge = disposing_authority__document_name) %>% 
    filter(!is.na(judge))
  
  merge(judges, merge(widened, grades, by = "docket_id", all.x=T, all.y=T), by = "docket_id", all.x=T, all.y=T)
  
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
#'  
#' @param data Offenses and Dispositions data.frame from the original dataset
#' @return  modified data.frame with cleaned min_period_days and max_period_days. These are the cleaned values in the unit of months
#' 
#' 
clean_periods <- function(data){
  if (!all(c("min_period", "max_period") %in% colnames(data))) stop('variables missing from input data')
  
  data %>% 
    mutate(min_period_days = extract_days(min_period),
           max_period_days = extract_days(max_period))
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




