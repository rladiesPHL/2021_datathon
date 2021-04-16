# Download the data and store it in the `data` folder. This has grown into
# something pretty clunky and over-engineered, but it only downloads data that
# hasn't already been saved. This could have been a makefile.

# Get ready to use rprojroot without attaching it to the namespace, and throw an
# error if it's missing.
loadNamespace("rprojroot")

# Find the root directory and throw a (hopefully) more helpful error message if
# this isn't an RStudio project.
project_root <- tryCatch(rprojroot::find_root(rprojroot::is_rstudio_project),
                         error = function(e) stop("This script must be run in an RStudio project"))

base_uri <- "https://storage.googleapis.com/jat-rladies-2021-datathon"

for (file_name in c("defendant_docket_ids.csv",
                    # I'm replacing this with the `_v1` file that combines yearly files
                    #"offenses_dispositions.csv",
                    # This is erroring-out, so we're gonna handle it separately
                    #"offenses_dispositions_v2.csv",
                    "defendant_docket_details.csv",
                    "bail.csv")) {
  f_out <- file.path(project_root, "data", file_name)
  if (!file.exists(f_out)) {
    download.file(paste(base_uri, file_name, sep = "/"), f_out)
  }
}

# Instead of downloading the single combined file for the dispositions, we'll
# download the yearly files and concatenate them.
year_sequence <- c("2010_2011", "2012_2013", "2014_2015", "2016_2017", "2018_2019", "2020")

# If you only want to download a specific version of the data, comment out this
# chunk and just set dispositions_file_root to the version you want.
dispositions_file_root <- c("offenses_dispositions",
                            "offenses_dispositions_v2",
                            "offenses_dispositions_v3")

for (f in dispositions_file_root) {
  # Append a "_v1" to the first version of the data
  f_out <- file.path(project_root, "data",
                     ifelse(f == "offenses_dispositions",
                            "offenses_dispositions_v1.csv",
                            paste0(f, ".csv")))
  
  # Don't download anything we already have
  if (!file.exists(f_out)) {
    # Download each yearly data file and store them all in a list
    dat_list <- lapply(year_sequence, 
                       function(x) read.csv(paste0(base_uri, "/", f, "_", x, ".csv"),
                                            stringsAsFactors = FALSE))
    
    # Combine th elist of data frames into a single data frame
    dat <- do.call(rbind, dat_list)
    
    # Write out the data
    write.csv(dat, f_out)
  }
}
