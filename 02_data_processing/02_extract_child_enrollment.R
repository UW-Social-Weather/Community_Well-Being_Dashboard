# Name: 02_extract_child_enrollment.R
# Purpose: extract and prep data on childhood enrollment
# Date: November 14 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset2_Children aged 3-4 enrolled in school"
raw_file <- "County.csv"

# load raw data
dt <- read.csv(file = paste0(raw_data_dir, containing_folder, "/", raw_file))

# split location names into county and state
dt$state <- str_split_fixed(dt$name, ", ", n=2)[,2]
dt$county <- str_split_fixed(dt$name, ", ", n=2)[,1]

# add variable name
dt$variable <- "child_enrollment"

# identify value column
dt$value <- dt$total_est

# split out county identifiers
dt$location_code <- str_split_fixed(dt$geoid, "US", n=2)[,2]

# load location map
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

# merge standard county naming on dataset
merged_dt <- inner_join(dt, location_map, by="location_code")

# subset final columns
final_dt <- merged_dt %>% select(state_name, location_name, location_code, year, variable, value)

# pivot wider format
final_dt_wide <- final_dt %>% pivot_wider(names_from = variable, values_from = value)

# rename columns before saving
final_dt_wide <- rename(final_dt_wide,
                        county_name = location_name,
                        fips_code = location_code)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "02_prepped_child_enrollment_data.xlsx"

# save final dataset
write_xlsx(final_dt_wide, path = paste0(prepped_data_dir, prepped_file_name))
