# This is a script to read in the data...
# Perform some initial data cleaning...
# Save a merged file as Rds for visualizations

# It is highly likely that this will break when run on different local environments with 
# different versions. See the session info.
# Also make sure to start a new session, clear the global environment before running

# Note that a package like `targets` is really nice
# for building this type of data pipeline
# But I want to keep it simple. So we just call some R functions

# Load packages
library(dplyr)

# Source scripts - file paths are relative to project directory
# Set your working directory there
source('analyses/team1/exploration/aw_functions.R')


# Read in the data from internet
od <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions.csv')
ddd <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details.csv')
bail <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/bail.csv')


# Clean files and summarize
od_clean <- clean_periods(od)
od_clean <- clean_descriptions(od_clean)
# Because we care about JUDGES. I will go ahead and remove all the dockets w/o a disposition
# These have no judges
od_clean <- od_clean %>% 
  group_by(docket_id) %>% 
  mutate(no_disposition = all(is.na(disposition))) %>% 
  ungroup() %>% filter(no_disposition==FALSE)

od_agg <- aggregate_od(od_clean)
bail_clean <- aggregate_bails(bail)
# We could add functions to "augment" the data:
# Add additional variables (e.g., time differences)

# Merge into one file (one docket:judge combo per row)
# Note: It probably does not make sense to have one docket per row
# Here there can be multiple rows per docket if there were multiple judges (rare)
# not all dockets will be included here - some filtered out
merged <- left_join(od_agg, bail_clean,by = "docket_id") %>% 
  left_join(ddd,by = "docket_id")

# Example docket with 3 judges: 	14284
# Example docket with 3 dispositions: 5134


# Save out:
LOCAL_LOCATION <- '~/Documents/'
saveRDS(merged, paste0(LOCAL_LOCATION, "merged_jat.Rds"))

# Information
sessionInfo()

# R version 3.6.2 (2019-12-12)
# Platform: x86_64-apple-darwin15.6.0 (64-bit)
# Running under: macOS  10.16
# 
# Matrix products: default
# LAPACK: /Library/Frameworks/R.framework/Versions/3.6/Resources/lib/libRlapack.dylib
# 
# locale:
#   [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
# 
# attached base packages:
#   [1] stats     graphics  grDevices utils     datasets  methods   base     
# 
# other attached packages:
#   [1] dplyr_1.0.2
# 
# loaded via a namespace (and not attached):
#   [1] Rcpp_1.0.3       crayon_1.3.4     R6_2.4.1         lifecycle_0.2.0  magrittr_1.5    
# [6] pillar_1.4.3     rlang_0.4.10     curl_4.3         rstudioapi_0.11  generics_0.0.2  
# [11] vctrs_0.3.6      ellipsis_0.3.0   forcats_0.5.1    tools_3.6.2      readr_1.3.1     
# [16] glue_1.4.2       purrr_0.3.4      hms_0.5.3        compiler_3.6.2   pkgconfig_2.0.3 
# [21] tidyselect_1.1.0 tibble_3.0.6   