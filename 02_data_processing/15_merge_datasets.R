# Name: merge_datasets.R
# Purpose: merge the extracted data for Social Weather Dashboard
# Date: November 14 2022

# set-up
rm(list=ls())

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)
library(data.table)

# load important file paths
prepped_data_dir <- "./03_final_data/"

# load the location map and create year frame
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

location_map <- location_map %>% filter(location_type=="County")

# create a datatable to keep the data frame
years_of_data <- (2000:2022)
years <- matrix(nrow = 3240, ncol = 23)
colnames(years) <- years_of_data
years <- data.table(years)
frame <- cbind(location_map, years)
frame <- as.data.table(frame)
frame_long <- melt(frame, id.vars=c('location_code', 'location_name', 'location_type', 'state_name', 'geoid'), variable.factor = FALSE)
frame_long$year <- as.numeric(frame_long$variable)

# Remove blank value from frame
frame_long <- frame_long[,-c(7)]

# rename the columns in the frame and subset necessary values
frame_long <- frame_long %>% select(state_name, location_name, location_code, year) %>%
  rename(county_name=location_name,
         fips_code=location_code)

# load the respective datasets
prepped_file_01 <- read_xlsx(paste0(prepped_data_dir, "01_prepped_gdp_data.xlsx")) # first file contains duplicates that need to be cleaned up
prepped_file_02 <- read_xlsx(paste0(prepped_data_dir, "02_prepped_child_enrollment_data.xlsx"))
prepped_file_03 <- read_xlsx(paste0(prepped_data_dir, "03_prepped_risk_score_data.xlsx"))
prepped_file_05 <- read_xlsx(paste0(prepped_data_dir, "05_prepped_food_insecurity_data.xlsx"))
prepped_file_07 <- read_xlsx(paste0(prepped_data_dir, "07_prepped_aqi_data.xlsx"))
prepped_file_08 <- read_xlsx(paste0(prepped_data_dir, "08_prepped_tot_jail_pop_data.xlsx"))
prepped_file_09 <- read_xlsx(paste0(prepped_data_dir, "09_prepped_income_ratio_data.xlsx"))
prepped_file_10 <- read_xlsx(paste0(prepped_data_dir, "10_prepped_affordable_housing_data.xlsx"))
prepped_file_11 <- read_xlsx(paste0(prepped_data_dir, "11_prepped_emergency_visit_data.xlsx"))
# prepped_file_13 <- read_xlsx(paste0(prepped_data_dir, "13_prepped_cost_burdened_household_data.xlsx")) # can't be merged because data is not at county level
prepped_file_14 <- read_xlsx(paste0(prepped_data_dir, "14_prepped_pop_living_alone_data.xlsx"))

# merge the datasets
mergeVars <- c("state_name", "county_name", "fips_code", "year")

merged_data <- frame_long %>% 
  full_join(prepped_file_01, by=mergeVars) %>%
  full_join(prepped_file_02, by=mergeVars) %>%
  full_join(prepped_file_03, by=mergeVars) %>%
  # full_join(prepped_file_04, by=mergeVars) %>%
  full_join(prepped_file_05, by=mergeVars) %>%
  # full_join(prepped_file_06, by=mergeVars) %>%
  full_join(prepped_file_07, by=mergeVars) %>%
  full_join(prepped_file_08, by=mergeVars) %>%
  full_join(prepped_file_09, by=mergeVars) %>%
  full_join(prepped_file_10, by=mergeVars) %>%
  full_join(prepped_file_11, by=mergeVars) %>%
  full_join(prepped_file_14, by=mergeVars)

# maybe drop missing rows
merged_data <- merged_data %>% filter(!is.na(child_enrollment) | !is.na(risk_score) | !is.na(fi_rate) | !is.na(good_aqi) |
                         !is.na(total_jail_pop) | !is.na(top_to_bottom_ratio) | !is.na(aaa_per100) | !is.na(pop_liv_alone))

# load the location map with state abbreviations
state_abbreviation_data <- readRDS("./01_raw_data/location_maps/prepped_data/01_state_names.rds")

final_data <- merged_data %>% left_join(state_abbreviation_data, by="state_name")

# create name combination that will be used for plotting
final_data$name <- tolower(paste0(final_data$state_name, ",", final_data$county_name))

# drop locations that are at the state-level

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "15_sw_merged_data.xlsx"
prepped_file_name_rds <- "15_sw_merged_data.RDS"

# save final dataset
write_xlsx(final_data, path = paste0(prepped_data_dir, prepped_file_name))
saveRDS(final_data, paste0(prepped_data_dir, prepped_file_name_rds))
