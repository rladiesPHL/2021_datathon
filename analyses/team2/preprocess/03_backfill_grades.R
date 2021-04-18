# Fill in missing `grade` entries using `statute_name`

# Get ready to use packages without attaching them to the namespace, throw an
# error if they're missing.
loadNamespace("rprojroot")
loadNamespace("readr")

# Find the root directory and throw a (hopefully) more helpful error message if
# this isn't an RStudio project.
project_root <- tryCatch(rprojroot::find_root(rprojroot::is_rstudio_project),
                         error = function(e) stop("This script must be run in an RStudio project"))

# Source the functions
source(file.path(rprojroot::find_root(rprojroot::is_rstudio_project),
                 "analyses", "team2", "preprocess", "ec_functions.R"))

# Make sure the source file (raw dispositions data) exists
source_file <- file.path(rprojroot::find_root(rprojroot::is_rstudio_project),
                         "data", "offenses_dispositions_v3_periods.csv")
stopifnot(file.exists(source_file))

# Make sure the target file (parsed dispositios data) does not exist
target_file <- file.path(rprojroot::find_root(rprojroot::is_rstudio_project),
                         "data", "offenses_dispositions_v3_grades.csv")
stopifnot(!file.exists(target_file))

# Read the dispositions file
dispositions <- readr::read_csv(source_file,
                                col_types = readr::cols(
  X1 = readr::col_double(),
  docket_id = readr::col_double(),
  description = readr::col_character(),
  statute_description = readr::col_character(),
  statute_name = readr::col_character(),
  sequence_number = readr::col_double(),
  grade = readr::col_character(),
  disposition = readr::col_character(),
  disposing_authority__first_name = readr::col_character(),
  disposing_authority__middle_name = readr::col_character(),
  disposing_authority__last_name = readr::col_character(),
  disposing_authority__title = readr::col_character(),
  disposing_authority__document_name = readr::col_character(),
  disposition_method = readr::col_character(),
  min_period = readr::col_character(),
  max_period = readr::col_character(),
  period = readr::col_character(),
  credit = readr::col_double(),
  sentence_type = readr::col_character(),
  min_period_parsed = readr::col_character(),
  max_period_parsed = readr::col_character(),
  min_period_days = readr::col_double(),
  max_period_days = readr::col_double()
))

# Backfill the missing grade information
dispositions$grade_backfilled <- backfill_disposions_grades(dispositions$grade,
                                                            dispositions$statute_name)

# Write it to a new file
readr::write_csv(dispositions, target_file)
