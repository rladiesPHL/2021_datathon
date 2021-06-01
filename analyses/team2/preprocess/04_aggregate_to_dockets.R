# Create a data set with docket as unit of analysis

# Get ready to use packages without attaching them to the namespace, throw an
# error if they're missing.
loadNamespace("rprojroot")
loadNamespace("readr")

# load tidyverse
library(tidyverse)

# Find the root directory and throw a (hopefully) more helpful error message if
# this isn't an RStudio project.
project_root <- tryCatch(rprojroot::find_root(rprojroot::is_rstudio_project),
                         error = function(e) stop("This script must be run in an RStudio project"))

# Source the functions
source(file.path(rprojroot::find_root(rprojroot::is_rstudio_project),
                 "analyses", "team2", "preprocess", "sa_functions.R"))

# Make sure the source file (cleaned dispositions data) exists
source_file <- file.path(rprojroot::find_root(rprojroot::is_rstudio_project),
                         "data", "offenses_dispositions_v3_grades.csv")
stopifnot(file.exists(source_file))

# Make sure the target file (aggregated docket data) does not exist
target_file <- file.path(rprojroot::find_root(rprojroot::is_rstudio_project),
                         "data", "docket_details.csv")
stopifnot(!file.exists(target_file))

# Read the dispositions file
dispositions <- read_csv(file.path(rprojroot::find_root(rprojroot::is_rstudio_project),
                                   "data", "offenses_dispositions_v3_grades.csv"),
                         col_types = cols(
                           #X1 = col_double(),
                           docket_id = col_double(),
                           description = col_character(),
                           statute_description = col_character(),
                           statute_name = col_character(),
                           sequence_number = col_double(),
                           grade = col_character(),
                           disposition = col_character(),
                           disposing_authority__first_name = col_character(),
                           disposing_authority__middle_name = col_character(),
                           disposing_authority__last_name = col_character(),
                           disposing_authority__title = col_character(),
                           disposing_authority__document_name = col_character(),
                           disposition_method = col_character(),
                           min_period = col_character(),
                           max_period = col_character(),
                           period = col_character(),
                           credit = col_double(),
                           sentence_type = col_character(),
                           min_period_parsed = col_character(),
                           max_period_parsed = col_character(),
                           min_period_days = col_character(),
                           max_period_days = col_double(),
                           grade_backfilled = col_character()
                         ))


# Read dockets-defendants file
dddcols = cols(
  docket_id = col_double(),
  gender = col_character(),
  race = col_character(),
  date_of_birth = col_date(format = ""),
  arrest_date = col_date(format = ""),
  complaint_date = col_date(format = ""),
  disposition_date = col_date(format = ""),
  filing_date = col_date(format = ""),
  initiation_date = col_date(format = ""),
  status_name = col_character(),
  court_office__court__display_name = col_character(),
  current_processing_status__processing_status = col_character(),
  current_processing_status__status_change_datetime = col_date(format = ""),
  municipality__name = col_character(),
  municipality__county__name = col_character(),
  judicial_districts = col_character(),
  court_office_types = col_character(),
  court_types = col_character(),
  representation_type = col_character()
)
dockets <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details.csv',
                           col_types = dddcols)


# Read defendant-docket-ids file
ddidscols = cols(
  defendant_id = col_double(),
  docket_id = col_double()
)

dockets_defendants_ids <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_ids.csv',
                                          col_types = ddidscols)


# Generate the docket level file
dockets_data <- aggregate_offenses_to_dockets(dispositions, dockets, dockets_defendants_ids)


# Write it to a new file
readr::write_csv(dockets_data, target_file)