# Name: 08_extract_total_jail_pop.R
# Purpose: extract and prep data on jail incarceration rates
# Date: November 17 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset8_incarceration_rate/"
raw_file <- "incarceration_trends.xlsx"

# load raw data
extracted_data <- read_xlsx(paste0(raw_data_dir, containing_folder, raw_file))

# subset columns of interest
extracted_data <- extracted_data %>% select(state, county_name, fips, year, total_jail_pop)

# load the location map
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

# check for fips codes that are not in the location map
map_check <- paste0(location_map$location_code)
data_check <- paste0(extracted_data$fips)
unmapped_locs <- extracted_data[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("state", "county_name", "fips"), with= FALSE]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above. 
  stop("You have locations in the data that aren't in the codebook!")
}

# merge dataset with the complete location map
merged_dt <- inner_join(extracted_data, location_map, by=c("fips"="location_code"))

# subset columns
final_dt <- merged_dt %>% select(state_name, location_name, fips, year, total_jail_pop)

# rename certain columns to match final protocol
final_dt <- rename(final_dt, county_name=location_name,
                   fips_code=fips)

# filter out the years of interest
final_dt <- final_dt %>% filter(year>=2012)

# # set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "08_prepped_tot_jail_pop_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))
