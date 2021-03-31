# R-ladies Philly Datathon_ Kulbir Kaur 

# Packages used ----
library(readr)
library(tidyverse)
library(tidyselect)

# Data added from R ladies Philly ---- 
# kept the names of the data set sama as RA 
# disposition is the decision reached. In the disposition data there is guilty, guilty plea negotiated vs non-negotitated (may be something to check out)

ids <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_ids.csv')

disposition <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions.csv')

bail <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/bail.csv')

details <- readr::read_csv('https://storage.googleapis.com/jat-rladies-2021-datathon/defendant_docket_details.csv')

# census data for the Bucks, Philadelphia, Chester & Delaware county 

library(here)


str(ids)
str(disposition)
str(bail)

# Exploration of data  ----
#converted character to factors https://tladeras.shinyapps.io/learning_tidyselect/#section-doing-more-with-multiple-columns-using-tidyselect 

disposition <- disposition %>%  mutate(across(where(is.character), as.factor))

levels(disposition$disposing_authority__title)
levels(disposition$sentence_type)
levels(disposition$description)
levels(disposition$disposition)
levels(disposition$disposition_method)
levels(disposition$sentence_type)

details <- details %>% mutate(across(where(is.character), as.factor)) 

levels(details$municipality__name)
levels(details$municipality__county__name)



disposition %>%  ggplot(aes(x = disposing_authority__title, y = disposition, color = sentence_type)) +
  geom_point() +
  theme(axis.text.x= element_text(angle = 45, hjust = 1), legend.position = "bottom")


  
  

