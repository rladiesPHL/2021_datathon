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
              first_bail_action_date = min(action_date, na.rm = T),
              last_bail_action_date = max(action_date, na.rm = T),
              action_type_list = list(action_type_name)) %>% 
    ungroup()
}




#' Aggregate the Offenses and Dispositions dataset
#' 
#' Converts the dataset to a one docket per row dataset by aggregating. 
#' This may not be what we want but for the purpose of illustration and 
#' moving fast, this is what I did.
#'
#' @param data Offenses and Dispositions data.frame from the original dataset
#'
#' @return data.frame with min_grade and max_grade columns
#'

aggregate_od <- function(data){
  grade_levels <- c("IC","S","S3","S2","S1",
                    "M","M3","M2","M1",
                    "F","F3","F2","F1",
                    "H","H2","H1")
  data %>% 
    # distinct(docket_id, grade, .keep_all = TRUE) %>% 
    # convert grade to factor - low to high
    mutate(grade = factor(grade, levels = grade_levels)) %>% 
    group_by(docket_id) %>% 
    arrange(grade) %>% 
    summarise(min_grade = grade[1],
              max_grade = grade[n()],
              min_period_list = list(min_period_mos),
              max_period_list = list(max_period_mos),
              description_list = list(desc_main),
              sentence_type_list = list(sentence_type),
              judge_list = list(unique(disposing_authority__document_name))) %>% 
    ungroup() %>% 
    unique()
  
}

#' Clean the sentence period variables
#' @description This function takes in a data.frame with min, max period variables and 
#' transforms to be easier to work with. 
#'  
#' @param data Offenses and Dispositions data.frame from the original dataset
#' @return  modified data.frame with cleaned min_period_mos and max_period_mos. These are the cleaned values in the unit of months
#' 
#' 
clean_periods <- function(data){
  if (!all(c("min_period", "max_period") %in% colnames(data))) stop('variables missing from input data')
  
  clean_od<- data %>% 
    mutate(minperiod_years = stringr::str_extract(min_period, ".+?(?=Year)"),
           minperiod_months = stringr::str_extract(min_period, 
                                                   "(\\d+.\\d+)[^\\d]+?(?=Month)|(\\d+)[^\\d]+?(?=Month)"),
           minperiod_days = stringr::str_extract(min_period, 
                                                 "(\\d+.\\d+)[^\\d]+?(?=Day)|(\\d+)[^\\d]+?(?=Day)"),
    ) %>% 
    #Combine min_period_1 and min_period_2 and min_period_3
    mutate_at(vars(starts_with("minper")), as.numeric) %>%
    mutate(minperiod_years = ifelse(is.na(minperiod_years), 0, minperiod_years),
           minperiod_months = ifelse(is.na(minperiod_months), 0, minperiod_months),
           minperiod_days = ifelse(is.na(minperiod_days), 0, minperiod_days),
           min_period_mos = minperiod_years*12 + minperiod_months + minperiod_days/30) %>% 
    select(-minperiod_years, -minperiod_months, -minperiod_days) %>% 
    mutate(maxperiod_years = stringr::str_extract(max_period, ".+?(?=Year)"),
           maxperiod_months = stringr::str_extract(max_period, 
                                                   "(\\d+.\\d+)[^\\d]+?(?=Month)|(\\d+)[^\\d]+?(?=Month)"),
           maxperiod_days = stringr::str_extract(max_period, 
                                                 "(\\d+.\\d+)[^\\d]+?(?=Day)|(\\d+)[^\\d]+?(?=Day)"),
    ) %>% 
    #Combine max_period_1 and max_period_2 and max_period_3
    mutate_at(vars(starts_with("maxper")), as.numeric) %>%
    mutate(maxperiod_years = ifelse(is.na(maxperiod_years), 0, maxperiod_years),
           maxperiod_months = ifelse(is.na(maxperiod_months), 0, maxperiod_months),
           maxperiod_days = ifelse(is.na(maxperiod_days), 0, maxperiod_days),
           max_period_mos = maxperiod_years*12 + maxperiod_months + maxperiod_days/30) %>% 
    select(-maxperiod_years, -maxperiod_months, -maxperiod_days)
  
  clean_od
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




