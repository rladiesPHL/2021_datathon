# Functions to help with data preprocessing

#' Clean the sentencing period data and split it into a minimum and maximum.
#'
#' When only a single sentence length (e.g., "2 years") is given, the minimum
#' will be left blank. The `min_period` and `max_period` columns are used to
#' fill missing data (when `period` is "Other") and are ignored otherwise.
#'
#' @param period A character vector giving messy sentencing periods
#' @param min_period A character vector giving some minimum periods
#' @param max_period A character vector giving some minimum periods
#'
#' @return A two-column character matrix with the minimum and maximum period.
#'   Missing data is returned as `NA`.
#' @export
clean_dispositions_periods <- function(period, min_period, max_period) {
  clean_periods <- period
  
  period_is_other <- !is.na(clean_periods) &
    tolower(clean_periods) == "other"
  clean_periods[period_is_other &
                  !is.na(min_period) &
                  !is.na(max_period)] <-
    paste(min_period[period_is_other &
                       !is.na(min_period) &
                       !is.na(max_period)],
          "-",
          max_period[period_is_other &
                       !is.na(min_period) &
                       !is.na(max_period)])
  clean_periods[period_is_other &
                  is.na(min_period) &
                  !is.na(max_period)] <-
    max_period[period_is_other &
                 is.na(min_period) &
                 !is.na(max_period)]
  clean_periods[period_is_other &
                  !is.na(min_period) &
                  is.na(max_period)] <-
    min_period[period_is_other &
                 !is.na(min_period) &
                 is.na(max_period)]
  clean_periods[period_is_other] <- stringr::str_replace_all(clean_periods[period_is_other],
                                                             "\\.00", "")
  
  # Do basic cleanup
  clean_periods <- tolower(clean_periods)
  clean_periods <- stringr::str_replace_all(clean_periods, "[[:blank:]]+", " ")
  clean_periods <- stringr::str_replace(clean_periods, "^ ", "")
  clean_periods <- stringr::str_replace(clean_periods, " $", "")
  
  # FOR NOW we're going to throw out extra information about IPP
  clean_periods <- stringr::str_replace(clean_periods,
                                        "day modification of ipp sentence", "days")
  
  # Make life without parole more token-like
  clean_periods <- stringr::str_replace(clean_periods,
                                        "life without the possibility of parole",
                                        "life_no_parole")
  
  # Deal with the many ways of writing ".5"
  clean_periods <- stringr::str_replace_all(clean_periods, "([[:digit:]]+) - 1/2", "\\1.5")
  clean_periods <- stringr::str_replace_all(clean_periods, "([[:digit:]]+) 1/2", "\\1.5")
  clean_periods <- stringr::str_replace_all(clean_periods, "([[:digit:]]+) and a half", "\\1.5") 
  
  # Tokenize "time in"/"time-in", "time served" and some typos
  clean_periods <- stringr::str_replace(clean_periods, "tiime", "time")
  clean_periods <- stringr::str_replace(clean_periods, "tim\\b", "time")
  clean_periods <- stringr::str_replace(clean_periods, "time[ -]?(served|in)", "time_served")
  clean_periods <- stringr::str_replace(clean_periods, "balance of backtime", "time_served")
  clean_periods <- stringr::str_replace(clean_periods, "back time", "time_served")
  
  # Standardize units
  clean_periods <- stringr::str_replace_all(clean_periods, "hrs", "hours")
  clean_periods <- stringr::str_replace_all(clean_periods, "hour(?!s)",  "hours")
  clean_periods <- stringr::str_replace_all(clean_periods, "day(?!s)",   "days")
  clean_periods <- stringr::str_replace_all(clean_periods, "month(?!s)", "months")
  clean_periods <- stringr::str_replace_all(clean_periods, "year(?!s)",  "years")
  
  # Remove "flat"
  clean_periods <- stringr::str_replace(clean_periods, " flat", "")
  
  # Remove "BCP"
  clean_periods <- stringr::str_replace(clean_periods, " bcp", "")
  
  # Standardize the "time arithmetic"
  clean_periods <- stringr::str_replace_all(clean_periods, ", ", " plus ")
  clean_periods <- stringr::str_replace_all(clean_periods, " and ", " plus ")
  clean_periods <- stringr::str_replace_all(clean_periods, " less ", " minus ")
  
  # This one's tricky, in part because str_replace_all is greedier than it should
  # be. Turn entries like "2 years 6 months" into "2 years plus six months".
  operator_insertion_regexp <- "^([[:digit:]]+) ([[:alpha:]]+) ([[:digit:]]+) ([[:alpha:]]+)$"
  needs_operator_inserted <- !is.na(clean_periods) &
    stringr::str_detect(clean_periods, operator_insertion_regexp) & 
    (stringr::str_replace(clean_periods, operator_insertion_regexp, "\\2") != "to")
  clean_periods[needs_operator_inserted] <- stringr::str_replace_all(clean_periods[needs_operator_inserted],
                                                                     operator_insertion_regexp,
                                                                     "\\1 \\2 plus \\3 \\4")
  
  # Split the periods using "-" or "to"
  clean_periods_split <- stringr::str_split_fixed(clean_periods, "\\s?((\\bto\\b)|-)\\s?", 2)
  
  # If the beginning period is missing a time unit (days, months, years), grab it from the end period
  is_missing_units <- stringr::str_detect(clean_periods_split[, 1], "^[[:digit:]]+(\\.5)?$")
  # Pulling out the first units word is a bit tricky
  missing_units <-  stringr::str_extract(stringr::str_extract(clean_periods_split[is_missing_units, 2], 
                                                              "^[[:digit:]]+(\\.5)? [[:alpha:]]+"), 
                                         "[[:alpha:]]+$")
  clean_periods_split[is_missing_units, 1] <- paste(clean_periods_split[is_missing_units, 1],
                                                    missing_units, sep = " ")
  
  # Replace the blanks with explicit NAs when period was NA
  clean_periods_split[is.na(period), ] <- NA
  
  # If there's only one entry, str_split puts it in the first column, have it
  # swap spaces with the second and set the min_period to NA
  is_missing_max <- !is.na(clean_periods_split[, 2]) & 
    clean_periods_split[, 2] == "" &
    clean_periods_split[, 1] != ""
  clean_periods_split[is_missing_max, 2] <- clean_periods_split[is_missing_max, 1]
  clean_periods_split[is_missing_max, 1] <- NA
  
  clean_periods_split
}


#' Convert a (cleaned) disposition period into a number of days.
#'
#' Take the output of `clean_dispositions_periods()` (with strings like "2 years
#' plus 6 months") and convert them into a number of days. The mean number of
#' days in a year/month is used for the conversion. The string "time_served" is
#' substituted with the value passed to `time_served`. Strings that don't
#' conform to the pattern (including valid sentence periods, such as "life") are
#' returned as `NA`.
#'
#' @param period_clean A character column returned by
#'   `clean_dispositions_periods()`
#' @param time_served A numeric column giving the time served
#'
#' @return A numeric vector.
#' @export
clean_period_to_days <- function(period_clean, time_served = NA) {
  # Helper function to convert, e.g. "1 month" to ~30 days.
  units_to_days <- function(x, y) {
    duration_match <- stringr::str_match(x, 
                                         "^(-?[[:digit:]]+(\\.[[:digit:]]+)?) ([[:alpha:]]+)$")
    duration_numeric <- as.numeric(duration_match[, 2])
    duration_multiplicand <- dplyr::case_when(duration_match[, 4] == "years" ~ (366 * 97 + 365 * (400 - 97)) / 400,
                                              duration_match[, 4] == "months" ~ (366 * 97 + 365 * (400 - 97)) / (400*12),
                                              duration_match[, 4] == "days" ~ 1,
                                              duration_match[, 4] == "hours" ~ 1/24,
                                              TRUE ~ NA_real_)
    
    ifelse(x == "time_served",
           y,
           duration_numeric * duration_multiplicand)
  }
  
  period_split <- stringr::str_split(stringr::str_replace_all(period_clean, 
                                                              " minus ", 
                                                              " plus -"),
                                     " plus ")

  purrr::map2_dbl(period_split, time_served, ~sum(units_to_days(.x, .y)))
}


#' Replace missing grades with the most common `grade` for a given
#' `statute_name`.
#'
#' This only makes the replacement when a `statute_name` is associated with the
#' same `grade` 100% of the time.
#'
#' @param grade A character column of dispositions grades
#' @param statute_name A character column of associated dispositions statute names
#'
#' @return A new character column of dispositions grades
#' @export
backfill_disposions_grades <- function(grade, statute_name) {
  # Clean up a quick transcription error
  statute_name <- stringr::str_replace_all(statute_name, "ยง", "§")
  
  statute_df <- dplyr::tibble(grade, statute_name)
  
  # Identify the unique statute_names that are always associated with the same
  # grade.
  statute_top_grade <- dplyr::filter(statute_df,
                                     !is.na(grade), !is.na(statute_name))
  statute_top_grade <- dplyr::distinct(statute_top_grade)
  statute_top_grade <- dplyr::group_by(statute_top_grade, statute_name)
  statute_top_grade <- dplyr::mutate(statute_top_grade, 
                                     id = dplyr::row_number(grade))
  statute_top_grade <- dplyr::filter(statute_top_grade,
                                     id == max(id),
                                     id == 1)
  statute_top_grade <- dplyr::select(statute_top_grade,
                                     statute_name, top_grade = grade)
  
  statute_df <- dplyr::left_join(statute_df, statute_top_grade,
                                 by = "statute_name")
  statute_df <- dplyr::mutate(statute_df,
                              grade = ifelse(is.na(grade),
                                             top_grade,
                                             grade))

  statute_df$grade
}
