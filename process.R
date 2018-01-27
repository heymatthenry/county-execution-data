library(dplyr)
library(stringr)
library(lubridate)
library(rjson)
library(tidyr)

executions_df<- read.csv("data/execution_database.csv", stringsAsFactors = FALSE)
executions_df$Date <- as.Date(executions$Date, format = "%m/%d/%Y")

fix_county_names <- function(county_name) {
  breaking_str <- regex(" (City|County|Parish)$", ignore_case = TRUE)
  return(str_replace(county_name, breaking_str, ""))
}

summarize_county_executions <- function(executions_df) {
  county_execution_counts <- executions_df %>%
    mutate(Year = year(Date), county = County, state = State) %>%
    filter(State != "FE" & complete.cases(.)) %>%
    mutate_at(.vars = vars(County), .funs = funs(fix_county_names)) %>%
    count(County, State, Year) %>%
    arrange(Year)
  
  return(county_execution_counts)
}

execution_json <- function(executions_df) {
  county_execution_counts <- summarize_county_executions(executions_df)
  county_names <- unique(county_execution_counts$County)
  states <- unique(county_execution_counts$State)
  json_obj <- list()
  
  for (i in 1:length(states)) {
    state_obj <- list()
    current_state <- states[i]
    
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
  return(toJSON(json_obj))
}

# write(execution_json(executions_df), "data/county_executions.json")

add_geoids <- function(executions_df) {
  county_execution_counts <- summarize_county_executions(executions_df)
  county_list <- read.csv("data/county_list.csv", stringsAsFactors = FALSE) %>%
    select(-H1)
  names(county_list) <- c("State", "State_ID", "County_ID", "County")
  county_list$County <- fix_county_names(county_list$County)
  executions_with_ids <- county_list %>%
    right_join(county_execution_counts, c("State", "County"))

  executions_with_ids$County_ID <- str_pad(as.character(executions_with_ids$County_ID), 3, "left", pad = "0")
  executions_with_ids$State_ID <- str_pad(as.character(executions_with_ids$State_ID), 2, "left", pad = "0")

  executions_with_ids <- executions_with_ids %>%
    unite(GEOID, c("State_ID", "County_ID"), sep = "")

  executions_with_ids %>% spread(Year, n)
}

write.table(add_geoids(executions_df), sep = "\t", row.names = FALSE, file = "data/county_executions.tsv")
