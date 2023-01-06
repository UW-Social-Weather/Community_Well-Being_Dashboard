# Name: 09_extract_income_ratio.R
# Purpose: extract and prep data on top and bottom income ratio
# Date: November 18 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset9_income ratio/"
raw_file <- "Ratio of top 1_ income to bottom 99_ income for all U.S. counties, 2015.xlsx"

# load raw data
extracted_data <- read_xlsx(paste0(raw_data_dir, containing_folder, raw_file))

# split county from state names
extracted_data$county_name <- str_split_fixed(extracted_data$County, ",", n=2)[,1]
extracted_data$state_abbreviation <- str_split_fixed(extracted_data$County, ", ", n=2)[,2]

# rename columns
names(extracted_data)[5] <- "top_to_bottom_ratio"

# subset columns of interest
extracted_data <- extracted_data %>% select(county_name, state_abbreviation, top_to_bottom_ratio)

# add year variable
extracted_data$year <- "2015"

# load the location map
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")
state_alpha_map <- readRDS("./01_raw_data/location_maps/prepped_data/01_state_names.RDS")

# merge the alphanumeric code 
location_map_final <- left_join(location_map, state_alpha_map, by='state_name')

# modify the merge codes to ensure that the location maps can be combined
extracted_data$merge_code <- trimws(tolower(paste0(extracted_data$county_name, extracted_data$state_abbreviation)))
extracted_data$merge_code <- gsub(" ", "", extracted_data$merge_code, fixed=TRUE)
extracted_data$merge_code <- gsub("[[:punct:]]", "", extracted_data$merge_code)
extracted_data$merge_code <- gsub("censusarea", "", extracted_data$merge_code)
extracted_data$merge_code <- gsub("caak", "ak", extracted_data$merge_code)

# modify the merge codes to ensure that the location maps can be combined
location_map_final$merge_code <- trimws(tolower(paste0(location_map_final$location_name, location_map_final$state_alpha_code)))
location_map_final$merge_code <- gsub(" ", "", location_map_final$merge_code, fixed = TRUE)
location_map_final$merge_code <- gsub("[[:punct:]]", "", location_map_final$merge_code)
location_map_final$merge_code <- gsub("caak", "ak", location_map_final$merge_code)
location_map_final$merge_code <- gsub("caak", "ak", location_map_final$merge_code)

# manually edit a few merge codes in the extracted data to match what is in the locaiton map
extracted_data <- extracted_data %>% mutate(merge_code = case_when(
  county_name=="Wrangell City and Borough" & state_abbreviation=="AK" ~ "wrangellak",
  county_name=="Petersburg Census Area" & state_abbreviation=="AK" ~ "petersburgboroughak",
  county_name=="Carson City" & state_abbreviation=="NV" ~ "carsoncitycitynv",
  county_name=="Radford" & state_abbreviation=="VA" ~ "radfordcityva",
  county_name=="Dona Ana" & state_abbreviation=="NM" ~ "doÃ±aananm",
  county_name=="Montgomery County" & state_abbreviation=="AR" ~ "montgomeryar",
  TRUE ~ merge_code 
))

# drop the dc location which is not included in final dataset
extracted_data <- extracted_data %>% filter(county_name!="District of Columbia")

map_check <- paste0(location_map_final$merge_code)
data_check <- paste0(extracted_data$merge_code)
unmapped_locs <- extracted_data[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("state_abbreviation", "county_name", "merge_code"), with= FALSE]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above. 
  stop("You have locations in the data that aren't in the codebook!")
}

# merge dataset with the complete location map
merged_dt <- inner_join(extracted_data, location_map_final, by="merge_code")

# subset columns
final_dt <- merged_dt %>% select(state_name, location_name, location_code, year, top_to_bottom_ratio)

# rename certain columns to match final protocol
final_dt <- rename(final_dt, county_name=location_name,
                   fips_code=location_code)

final_dt$year <- as.numeric(final_dt$year)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "09_prepped_income_ratio_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))

