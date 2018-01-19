library(dplyr)
library(stringr)
library(lubridate)

executions <- read.csv("data/execution_database.csv", stringsAsFactors = FALSE)
executions$Date <- as.Date(executions$Date, format = "%m/%d/%Y")

county_execution_counts <- executions %>%
  mutate(Year = year(Date), county = County, state = State) %>%
  filter(State != "FE") %>%
  mutate_at(.vars = vars(County), .funs = funs(str_replace(County, " City", ""))) %>%
  count(County, State, Year) %>%
  arrange(Year) %>%
  write.csv("data/county_execution_counts.csv", row.names = FALSE)