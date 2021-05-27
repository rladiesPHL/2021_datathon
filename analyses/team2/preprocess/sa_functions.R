# Functions to help with data preprocessing

#' Create docket level dataset.
#'
#' Take defendant-docket data, defendant-ids data, and cleaned disposition data.
#' Life sentence is treated as confinement of 90 years, regardless whether the sentence 
#' is life sentence with or life sentence without parole. 1 year = 365.2425 days
#' (as calculated in ec_sentence_period.Rmd). Included in the resulting (output) dataset:
#' a) dockets that have missing values in `credit` and the value of `max_period_parsed` 
#' does not include "time_served"; b) dockets that the value of `max_period_parsed`
#' is not "other"; c) dockets that the value of `max_period_parsed` is not
#' "death penalty imposed". A docket must have at least one of its
#' offenses' `sentence_type` not `NA` to be included in the resulting dataset.
#' Dockets that have defendant age that is less than 10 years old are removed - this removes
#' dockets that have negative defendant age. 
#' 
#'
#' @param dispositions A cleaned disposition data frame
#' @param dockets A defendant-docket data frame
#' @param dockets_defendants_ids A defendant-docket-ids data frame
#'
#' @return A data frame with docket as the unit of analysis.
#' @export
aggregate_offenses_to_dockets <- function(dispositions, dockets, dockets_defendants_ids){
  # create total_confinement_days and max_confinement_days
  dockets_confinement <- dispositions %>% 
    filter(!is.na(sentence_type)) %>%
    mutate(has_time_served = str_detect(max_period_parsed, "time_served"),
           missing_credit = is.na(credit),
           has_max_period_parsed = !is.na(max_period_parsed)) %>% 
    filter(!(has_max_period_parsed & has_time_served & missing_credit)) %>% 
    filter((!has_max_period_parsed) | (max_period_parsed != "other")) %>% 
    filter((!has_max_period_parsed) | (max_period_parsed != "death penalty imposed")) %>% 
    mutate(max_period_days = if_else(str_detect(max_period_parsed, "life"), (90*365.2425),
                                     max_period_days)) %>% 
    group_by(docket_id) %>%
    mutate(confinement_days = if_else(sentence_type == "Confinement", max_period_days, 0)) %>% 
    mutate(total_confinement_days = sum(confinement_days, na.rm = TRUE),
           max_confinement_days = max(confinement_days, na.rm = TRUE)) %>% 
    ungroup() %>% 
    select(docket_id, total_confinement_days, max_confinement_days) %>% 
    distinct(docket_id, .keep_all = TRUE)
  
  # create number of grade offenses
  dockets_grades <- dispositions %>% 
    select(docket_id, grade_backfilled) %>% 
    filter(!is.na(grade_backfilled)) %>% 
    count(docket_id, grade_backfilled) %>% 
    pivot_wider(names_from = grade_backfilled, values_from = n) %>% 
    mutate(across(2:16, ~replace_na(., 0)))
  
  # create docket - judge_id
  dockets_judges <- dispositions %>% 
    filter(!is.na(disposing_authority__last_name)) %>% 
    arrange(disposing_authority__last_name, disposing_authority__first_name) %>% 
    mutate(judge_id = group_indices(., disposing_authority__last_name,
                                    disposing_authority__middle_name,
                                    disposing_authority__first_name)) %>% 
    select(docket_id, judge_id, disposing_authority__last_name, disposing_authority__first_name, 
           disposing_authority__middle_name) %>% 
    distinct(docket_id, .keep_all = TRUE) %>% 
    arrange(docket_id)
  
  # create number of prior dockets
  dockets_prior <- dockets %>%
    left_join(dockets_defendants_ids) %>% 
    select(defendant_id, docket_id, filing_date) %>% 
    group_by(defendant_id) %>% 
    arrange(defendant_id, filing_date) %>% 
    mutate(tmp1 = row_number(),
           number_prior_dockets = tmp1 - 1) %>% 
    ungroup() %>% 
    select(docket_id, number_prior_dockets)
  
  # create additional variables and join the docket level information
  dockets_output_data <- dockets %>% 
    left_join(dockets_grades) %>% 
    left_join(dockets_judges) %>% 
    left_join(dockets_prior) %>% 
    left_join(dockets_confinement) %>% 
    mutate(age = lubridate::year(filing_date) - lubridate::year(date_of_birth)) %>% 
    mutate(court_types_cp = if_else(str_detect(court_types, "CP"), 1, 0)) %>% 
    mutate(court_types_mc = if_else(str_detect(court_types, "MC"), 1, 0)) %>% 
    mutate(court_types_pac = if_else(str_detect(court_types, "PAC"), 1, 0)) %>% 
    mutate(court_office_types_commonwealth = if_else(str_detect(court_office_types, "Commonwealth"), 1, 0)) %>% 
    mutate(court_office_types_criminal = if_else(str_detect(court_office_types, "Criminal"), 1, 0)) %>% 
    mutate(court_office_types_municipal = if_else(str_detect(court_office_types, "Municipal"), 1, 0)) %>% 
    mutate(court_office_types_supreme = if_else(str_detect(court_office_types, "Supreme"), 1, 0)) %>%
    mutate(court_office_types_suprerior = if_else(str_detect(court_office_types, "Superior"), 1, 0))
  
  # cleanup age
  dockets_output_data <- dockets_output_data %>% 
    filter(age > 10)
  
  return(dockets_output_data)
}


#' Subset docket level dataset.
#'
#' Take the output of `aggregate_offense_to_docket()`. Exclude year 2020. 
#' Include only completed dockets (`status_name` is "Closed" or "Adjudicated").
#' Drop cases in the subset that have any missing values.
#'
#' @param dockets A docket level data frame
#'
#' @return A data frame
#' @export
subset_dockets <- function(dockets){
  # subset by year and docket status
  dockets <- dockets %>% 
    mutate(year = lubridate::year(filing_date),
           month = lubridate::month(filing_date, label = TRUE, abbr = TRUE)) %>% 
    filter(year < 2020) %>% 
    filter(status_name %in% c("Closed", "Adjudicated"))
  
  # subset variables for analyses
  dockets_output_data <- dockets[,c("docket_id", "total_confinement_days", "max_confinement_days",
                             "gender", "age","race","number_prior_dockets", "M", "M1", "M2", "M3",
                             "F", "F1", "F2", "F3", "S", "S1", "S2", "S3", "IC", "H1", "H2",
                             "court_types_cp", "court_types_mc", "court_types_pac", "year", "month",
                             "judge_id")]
  
  # drop cases with any missing values
  dockets_output_data <- na.omit(dockets_output_data)
  
  return(dockets_output_data)
}

#' Tidy judge fixed effects.
#'
#' Take a fixed effect model. Judge fixed effect estimates that are not statistically 
#' different from zero at alpha 0.1 is replaced with zeros.
#'
#' @param model the fitted fixed effect model.
#'
#' @return A data frame
#' @export
tidy_judge_fe <- function(model){
  tidied <- broom::tidy(model) %>% 
    mutate(is_judge = stringr::str_detect(term, pattern = "judge_id")) %>% 
    filter(is_judge) %>% 
    mutate(judge_id = stringr::str_extract(term, "(\\d)+"),
           judge_fe = if_else(p.value < 0.1, estimate, 0)) %>% 
    select(judge_id, judge_fe)
  
  return(tidied)
}
  
  