# Check that all datasets are the correct dim
library(readr)

# 1 ----
file_paths <- c(
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2010.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2011.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2012.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2013.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2014.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2015.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2016.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2017.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2018.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2019.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/bail_2020.csv"
  )


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
data_list <- lapply(file_paths, function(x) readr::read_csv(x, col_types = bailcols))

# sapply(data_list, dim)
# [,1]    [,2]    [,3]   [,4]   [,5]   [,6]   [,7]   [,8]   [,9]  [,10] [,11]
# [1,] 950961 1015504 1045949 961370 900293 842120 745527 695868 572661 517203 62086
# [2,]     10      10      10     10     10     10     10     10     10     10    10

# 2 =----
od_file_paths <- c(
  "https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2010_2011.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2012_2013.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2014_2015.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2016_2017.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2018_2019.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_2020.csv"
)

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
data_list <- lapply(od_file_paths, function(x) readr::read_csv(x, col_types = odcols))
# sapply(data_list, dim)
# [,1]   [,2]   [,3]   [,4]   [,5]  [,6]
# [1,] 321099 328284 286635 224782 238753 41333
# [2,]     16     16     16     16     16    16

# sapply(data_list, names)

# 3 ----
ddd_file_paths <- c(
  "https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details_2010_2011.csv",   "https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details_2012_2013.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details_2014_2015.csv",   "https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details_2016_2017.csv",
  "https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details_2018_2019.csv",   "https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details_2020.csv"
)
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
data_list <- lapply(ddd_file_paths, function(x) readr::read_csv(x, col_types = dddcols))
# sapply(data_list, dim)
# [,1]  [,2]  [,3]  [,4]  [,5]  [,6]
# [1,] 80975 80294 68977 58077 65817 11973
# [2,]    19    19    19    19    19    19

# sapply(data_list, names)
