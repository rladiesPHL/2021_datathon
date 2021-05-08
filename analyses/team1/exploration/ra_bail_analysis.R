library(tidyverse)
bail <- read.csv("baildata.csv")
bail$action_date <- as.Date(bail$action_date)
colnames(bail) <- c("docket_ID", "action_date", "action_type", "type_name", "percentage",
                    "total_amount", "registry_code", "judge_title", "judge_lastname", "judge_firstname")
bail$docket_ID <- as.factor(bail$docket_ID)
bail$type_name <- as.factor(bail$type_name)
bail$registry_code <- as.factor(bail$registry_code)
bail$action_type <- as.factor(bail$action_type)

#--- Create data frame
#Combine judge title and name variables
bail_judge_combined <- bail %>%
  filter(grepl("Judge", judge_title)) %>%
  filter(action_type %in% c("Decrease Bail Amount", "Increase Bail Amount")) %>%
  mutate(
    judge = paste(judge_title, judge_firstname, judge_lastname, sep = " "),
  )

#Create data frame with only necessary variables
bail_net_change <- bail_judge_combined %>%
  filter(grepl("Judge", judge_title)) %>%
  filter(action_type %in% c("Decrease Bail Amount", "Increase Bail Amount")) %>%
  group_by(judge) %>%
  summarize(
    n = n(),
    decrease_count = sum(action_type == "Decrease Bail Amount"),
    increase_count = sum(action_type == "Increase Bail Amount"),
    net_change = sum(increase_count + (-1*(decrease_count))),
    action_type,
    judge
  ) %>%
  filter(n > 20) %>%
  arrange(net_change)

#Select first row for each judge
bail_net_change_by_judge <- bail_net_change %>%
  group_by(judge) %>%
  slice(n = 1)

saveRDS(bail_net_change_by_judge, "bailnetchangebyjudge.rds")

#--- Plot
#Plot all judges in data frame
bail_net_change_by_judge %>%
  ggplot(aes(y=net_change, x=reorder(judge, -net_change), fill=n)) +
  geom_bar(stat='identity', width=.5) +
  labs(fill = "Total # of Bail Amount Changes",
       caption = "This plot shows the cumulative total of bail increases and decreases by a given judge.
          Increases equal 1 while decreases equal -1. Judges that increase bail amounts more often
          than they decrease them have a positive value, while the opposite is true for judges
          that decrease bail amounts more often. The bar fill indicates the total number of 
          bail changes (both increases and decreases") +
  xlab("Judges") +
  ylab("Cumulative Total of Bail Increases and Decreases") +
  theme(
    plot.caption = element_text(hjust = 0)
  )

#Plot selected judge(s)
input_judges <- c("Judge Ann Butchart", "Judge Abbe Fletman")

bail_net_change_by_judge %>%
  filter(judge %in% input_judges) %>%
  ggplot(aes(y=net_change, x=reorder(judge, -net_change), fill=n)) +
  geom_bar(stat='identity', width=.5) +
  labs(fill = "Total # of Bail Amount Changes",
       caption = "This plot shows the cumulative total of bail increases and decreases by a given judge.
          Increases equal 1 while decreases equal -1. Judges that increase bail amounts more often
          than they decrease them have a positive value, while the opposite is true for judges
          that decrease bail amounts more often. The bar fill indicates the total number of 
          bail changes (both increases and decreases)") +
  xlab("Judges") +
  ylab("Cumulative Total of Bail Increases and Decreases") +
  theme(
    plot.caption = element_text(hjust = 0)
  )
