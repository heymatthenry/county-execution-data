library(dplyr)
library(stringr)
library(lubridate)
library(rjson)
library(tidyr)

executions <- read.csv("data/execution_database.csv", stringsAsFactors = FALSE)
executions$Date <- as.Date(executions$Date, format = "%m/%d/%Y")

fix_county_names <- function(county_name) {
  breaking_str <- " (City|County|Parish)$"
  return(str_replace(county_name, breaking_str, ""))
}

county_execution_counts <- executions %>%
  mutate(Year = year(Date), county = County, state = State) %>%
  filter(State != "FE" & complete.cases(.)) %>%
  mutate_at(.vars = vars(County), .funs = funs(fix_county_names)) %>%
  count(County, State, Year) %>%
  arrange(Year)

county_names <- unique(county_execution_counts$County)
states <- unique(county_execution_counts$State)
json_obj <- list()

for (i in 1:length(states)) {
  state_obj <- list()
  current_state <- states[i]
  print(current_state)
  
  state_obj$State <- current_state
  filter_by_state <- county_execution_counts %>% filter(State == current_state)
  state_counties <- unique(filter_by_state$County)
  
  for (j in 1:length(state_counties)) {
    county_obj <- list()
    county_executions_per_year <- list()
    current_county <- state_counties[j]
    
    filter_by_county <- filter_by_state %>% filter(County == current_county)
    wide_filter_by_county <- filter_by_county %>% spread(Year, n)
    select_county_years <- wide_filter_by_county %>% select(matches("[1-9]+"))
    year_keys <- paste("year", names(select_county_years), sep = "")
    
    for (k in 1:length(year_keys)) {
      county_executions_per_year[[year_keys[k]]] <- select_county_years[[k]]
    }
    
    county_obj$County <- current_county
    county_obj$ExecutionsPerYear <- county_executions_per_year
    state_obj$Counties[[j]] <- county_obj
  }
  
  json_obj[[i]] <- state_obj
}

# print(toJSON(json_obj))
write(toJSON(json_obj), "data/county_executions.json")