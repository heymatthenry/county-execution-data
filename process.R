library(dplyr)
library(lubridate)

executions <- read.csv("data/execution_database.csv", stringsAsFactors = FALSE)
executions$Date <- as.Date(executions$Date, format = "%m/%d/%Y")

county_execution_counts <- executions %>%
                            mutate(Year = year(Date), county = County, state = State) %>%
                            count(County, State, Year) %>%
                            arrange(Year) %>%
                            write.csv("data/county_execution_counts.csv", row.names = FALSE)