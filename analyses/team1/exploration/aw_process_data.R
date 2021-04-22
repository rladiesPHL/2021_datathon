# This is a script to read in the data...
# Perform some initial data cleaning...
# Save a merged file as Rds for visualizations

# It is highly likely that this will break when run on different local environments with 
# different versions. See the session info.
# Also make sure to start a new session, clear the global environment before running

# Note that a package like `targets` is really nice
# for building this type of data pipeline
# But I want to keep it simple. So we just call some R functions

# Load packages ----
library(readr)
library(dplyr)

# Source scripts - file paths are relative to project directory ----
# Set your working directory there
source('analyses/team1/exploration/aw_functions.R')

#
# Read in the data from internet - define readr cols for parsing failures ----
#

odcols <- cols(
  docket_id = col_double(),
  description = col_character(),
  statute_description = col_character(),
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
  sentence_type = col_character()
)
od <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_v3.csv',
                      col_types = odcols)

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
ddd <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details.csv',
                       col_types = dddcols)

bailcols <- readr::cols(
  docket_id = col_double(),
  action_date = col_date(format = ""),
  action_type_name = col_character(),
  type_name = col_character(),
  percentage = col_double(),
  total_amount = col_double(),
  registry_entry_code = col_character(),
  participant_name__title = col_character(),
  participant_name__last_name = col_character(),
  participant_name__first_name = col_character()
)
bail <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/bail.csv',
                        col_types = bailcols)

defendants <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_ids.csv')
# There is a statutes.csv file in the repo - NOT NEEDED IF USING V3 DATA
# statute_map <- readr::read_csv(here::here('data/statutes.csv'))

# Alison created a file to map the statutes
statute_codes <- openxlsx::read.xlsx(here::here('analyses/team1/exploration/Statute_Codes.xlsx'))
statute_codes <- tidyr::separate(statute_codes, col=Title.Chapter, 
                                 into=c("statute_title","statute_chapter"),sep="-")
# Will merge in only the title descriptions, so shorten to just that
statute_codes <- select(statute_codes, statute_title, title_description = Title_Description) %>% unique()

#
# Clean files and summarize ----
#

# Use team 2 function to fill in missing grades!
source(here::here('analyses/team2/preprocess/ec_functions.R'))

od$grade_backfilled <- backfill_disposions_grades(od$grade,
                                                            od$statute_name)

# Because we care about judges, I decided to remove all the dockets w/o a disposition
# These have no judges - reduces data size a lot
# Note that there are still offenses here with NA disposition
od_clean <- od %>% 
  group_by(docket_id) %>% 
  mutate(no_disposition = all(is.na(disposition))) %>% 
  ungroup() %>% 
  filter(no_disposition==FALSE)

# statute_name has some interesting characters, let's remove those and split into parts
od_clean <- od_clean %>% 
  tidyr::separate(statute_name, remove=FALSE,
                  into=c("statute_title","statute_section","statute_pt3"), 
                  sep= " § | §§ | ยง | ยงยง ", fill = "right") %>% 
  dplyr::left_join(statute_codes, 
                   by = "statute_title")

# clean the sentencing fields
od_clean <- clean_periods(od_clean)

# Small clean up to reduce the number of unique offense descriptions
# There are 1243 unique 'description_clean' values versus 1654 in the original
# There are 870 statute_description fields
# FROM JAT ON CONSPIRACY: What does “conspiracy” mean? There is statute 18, section 903 that are all conspiracy, but some of the descriptions include more details. Should we just treat these all the same? 
# Rebecca H: In very non-technical terms, conspiracy is when two or more people get together and plan to do a crime. 18 Pa CS 903 is the statute that says that it’s illegal to do this, but then a conspiracy has what’s called an “object offense,” aka what you conspiring to do. So that’s why you are seeing above, conspiracy to commit murder vs conspiracy to commit retail theft are obviously very different things and the grades should reflect the grade of the object offense. So I think if possible it would be good to sort based on the object offense.


od_clean <- clean_descriptions(od_clean) %>% 
  # rename and a field
  dplyr::mutate(judge = disposing_authority__document_name)


# Merge into one file (one docket:judge combo per row) ----
# Note: It probably does not make sense to have one docket per row
# Here there can be multiple rows per docket if there were multiple judges on the disposition (rare)
# Example docket with 3 judges: 	14284
# Example docket with 3 dispositions: 5134
# not all dockets will be included here - some filtered out
# od_agg <- aggregate_od(od_clean)
# bail_agg <- aggregate_bails(bail)
# merged <- left_join(od_agg, bail_agg, by = "docket_id") %>% 
#   left_join(ddd, by = "docket_id") 

# Write out ddd + defendants
ddd <- left_join(ddd, defendants)



# This is offenses & dispositions data that has been cleaned up
od_clean <- od_clean %>% 
  # Depending on what you want, remove rows/offenses with NA disposition
  dplyr::filter(!is.na(disposition)) # This will remove many rows

# Doing this outside app to load into app
merged <- od_clean %>% 
  dplyr::left_join(ddd, by = "docket_id") %>% 
  dplyr::mutate(disposition_year = lubridate::year(disposition_date)) %>% 
  # We don't end up using most the data in the current app
  dplyr::select(judge, disposition_year, docket_id, grade, description_clean,
                gender, defendant_id, race, grade, sentence_type, min_period_days,
                max_period_days, grade_backfilled)

# Save out: -----
LOCAL_LOCATION <- '~/Documents/'
saveRDS(merged, paste0(LOCAL_LOCATION, "merged_shiny.Rds"))
# Probably better to save separate

# Minimal versions for dashboard 
saveRDS(od_clean, paste0(LOCAL_LOCATION, "od_clean.Rds"))
saveRDS(ddd, paste0(LOCAL_LOCATION, "ddd.Rds"))


# Information
sessionInfo()

# R version 4.0.5 (2021-03-31)
# Platform: x86_64-apple-darwin17.0 (64-bit)
# Running under: macOS Big Sur 10.16
# 
# Matrix products: default
# LAPACK: /Library/Frameworks/R.framework/Versions/4.0/Resources/lib/libRlapack.dylib
# 
# locale:
#   [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
# 
# attached base packages:
#   [1] stats     graphics  grDevices utils     datasets  methods   base     
# 
# other attached packages:
#   [1] dplyr_1.0.5 readr_1.4.0
# 
# loaded via a namespace (and not attached):
#   [1] Rcpp_1.0.6       rstudioapi_0.13  magrittr_2.0.1   hms_1.0.0        tidyselect_1.1.0
# [6] here_1.0.1       R6_2.5.0         rlang_0.4.10     fansi_0.4.2      stringr_1.4.0   
# [11] tools_4.0.5      utf8_1.2.1       cli_2.4.0        DBI_1.1.1        ellipsis_0.3.1  
# [16] assertthat_0.2.1 rprojroot_2.0.2  tibble_3.1.0     lifecycle_1.0.0  crayon_1.4.1    
# [21] zip_2.1.1        purrr_0.3.4      tidyr_1.1.3      vctrs_0.3.7      curl_4.3        
# [26] glue_1.4.2       openxlsx_4.2.3   stringi_1.5.3    compiler_4.0.5   pillar_1.6.0    
# [31] generics_0.1.0   lubridate_1.7.10 pkgconfig_2.0.3  