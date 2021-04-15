# Workspace ----
library(tidyverse)
library(glue)
library(rvest)
library(xml2)

raw_offenses <-
  read_csv("https://storage.googleapis.com/jat-rladies-2021-datathon/offenses_dispositions_v3.csv")

statutes <- 
  raw_offenses$statute_name %>%
  unique() %>%
  # head(100) %>%
  str_remove_all("§§.*") %>% 
  str_replace_all("[^[A-Z0-9\\-\\.]]+", "_") %>% 
  str_remove("_$") %>% 
  print()

titles <-
  statutes %>% 
  discard(str_detect, "^(CO|LO|0)") %>%
  str_extract("^[^_]*") %>% 
  unique() %>% 
  str_pad(width = 2, pad = "0") %>% 
  sort() %>% 
  print()

# Get URL Contents ----
# url <- "https://www.legis.state.pa.us/cfdocs/legis/LI/consCheck.cfm?txtType=HTM"
# title_urls <- glue("{url}&ttl={titles}")

#' @examples 
#' get_url_text(title_id = "18")
get_url_text <- function(title_id) {
  print(title_id)
  url <- "https://www.legis.state.pa.us//WU01/LI/LI/CT/HTM/"
  title_url <- glue("{url}{title_id}/{title_id}.HTM")

  title_contents <- xml2::read_html(title_url)

  tibble(
    title_id = title_id,
    text =
      title_contents %>%
      html_nodes("p") %>%
      html_text() %>%
#      head(200) %>%
      trimws() %>%
      tolower()
  ) %>%
    filter(nchar(text) > 1)
}

# * all_title_contents ----
all_title_contents <- map_dfr(titles, get_url_text)

# missing titles ----
titles %>% 
  subset(!. %in% unique(all_title_contents$title_id))

# find count of missing
table(
  str_pad(str_extract(raw_offenses$statute_name, "^[^ ]*"), 2, "l", "0")
  %in% 
    c(
        10 # charities
      , 43 # labor
      , 47 # liquor
      , 50 # mental health
      , 52 # mines and mining
      , 73 # townships
      , 77 # workmen's comp
  )
)


#' @examples
#' find_subsection(df = all_title_contents, "part", "level_1")
find_subsection <- function(df, string, new, prior = NULL) {
  x <- df[["text"]]
  find_new <- glue("^{string} .*")
  
  new_cols <-
    tibble("{new}" := str_extract(x, find_new)) %>% 
    #fill(1) %>% 
    separate(
      new,
      into =
        glue(
          "{new}_{col_names}",
          col_names = c("id", "text")
        ),
      sep = "\\. ",
      remove = TRUE
    ) %>% 
    mutate_all(trimws)
  
  new_df <- bind_cols(df, new_cols) 
  
  if (!is.null(prior)) {
    new_df <-
      new_df %>% 
      mutate(
        "{new}_id" := ifelse(!is.na(get(prior)), "-", get(glue("{new}_id"))),
        "{new}_text" := ifelse(!is.na(get(prior)), "-", get(glue("{new}_text")))
      )
  }
  
  new_df 
  # %>% 
  #   fill(
  #     glue("{new}_id"), 
  #     glue("{new}_text")
  #   )
}

#' @examples 
#' fill_left(6, all_levels)
fill_left <- function(i, df) {
  use_df <- df
  missing_values <- (df[[i]] == "-")
  use_df[[i]] <- ifelse(missing_values, df[[i + 2]], df[[i]])
  use_df[[i + 2]] <- ifelse(missing_values, "-", df[[i + 2]])
  
  use_df
}

# * all_levels ----
all_levels <- 
  all_title_contents %>% 
  mutate(title_text = ifelse(str_detect(lag(text), "^title "), text, NA)) %>% 
  fill(title_text) %>% 
  find_subsection("part", "level_1", NULL) %>%
  find_subsection(string = "article", new = "level_2", prior = "level_1_id") %>% 
  find_subsection(string = "chapter", new = "level_3", prior = "level_2_id") %>% 
  find_subsection(string = "subchapter", new = "level_4", prior = "level_3_id") %>% 
  find_subsection(string = "§", new = "section", prior = NULL) %>% 
  fill(starts_with("level")) %>% 
  #filter(str_detect(text, "^§")) %>% 
  #slice(2350:2370) %>% 
  print(n = 30)



# * levels_adjusted ----
levels_adjusted <- all_levels
level_cols <- which(str_detect(names(levels_adjusted), "level_[1-3]")) 

for (i in (level_cols)) {
  levels_adjusted <- fill_left(i, levels_adjusted)
}

# * final_statutes ----
final_statutes <-
  levels_adjusted %>% 
  mutate_all(trimws) %>% 
  filter(str_detect(text, "^§")) %>%
  #filter(title_id == "75") %>% 
  mutate(
    section_id = str_remove_all(section_id, "§ "),
    statute = glue("{title_id}_{section_id}")
  ) %>% 
  select(-text) %>% 
  relocate(statute, .before = title_id) %>% 
  distinct()

write_csv(final_statutes, "data/statute_hierarchy.csv")
