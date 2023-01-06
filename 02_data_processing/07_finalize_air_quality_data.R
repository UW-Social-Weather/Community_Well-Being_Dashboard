# Name: 07_finalize_air_quality_data.R
# Purpose: Finalize prepping the air quality data
# Date: December 5 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset6_AQI by County 1980-2021/"
raw_file <- "Air Qulality_Compiled Counties.xlsx"

# load raw data - that was previously prepped
extracted_data <- read_xlsx(paste0(raw_data_dir, containing_folder, raw_file))

# subset data
dt_subset <- extracted_data %>% select(State, County, Year, Days.with.AQI, Good.Days)

# drop rows pertaining to locations that are not standardized in other datasets/in the location map
dt <- dt_subset %>% filter(State != "Canada" 
                           & State != "Country Of Mexico" 
                           & State != "District Of Columbia"
                           & County != "MOBILE MONITORS"
                           & State != "Puerto Rico"
                           & State != "TRUE")
# dt %>% filter(State=="District of Columbia")

# create merge code from county name and state name
dt$merge_code <- tolower(gsub(" ", "",paste0(dt$County, dt$State), fixed = TRUE))
dt$merge_code <- gsub("saint", "st", dt$merge_code)
dt$merge_code <- gsub("[[:punct:]]", "", dt$merge_code)
dt$merge_code <- gsub("\\.", "", dt$merge_code)

# load location map
location_map <- read_rds("./01_raw_data/location_maps/prepped_data/02_county_location_map.rds")

location_map$merge_code <- tolower(gsub(" ", "",paste0(location_map$location_name, location_map$state_name), fixed = TRUE))
location_map$merge_code <- gsub("[[:punct:]]", "", location_map$merge_code)
location_map$merge_code <- gsub("citycity", "city", location_map$merge_code) 
location_map$merge_code <- gsub("\\.", "", location_map$merge_code)

# manually edit a few merge codes in the extracted data to match what is in the location map
dt <- dt %>% mutate(merge_code = case_when(
  County=="Valdez-Cordova" & State=="Alaska" ~ "valdezcordovacaalaska",
  County=="Dona Ana" & State=="New Mexico" ~ "doñaananewmexico",
  County=="Charles" & State=="Virginia" ~ "charlescityvirginia",
  County=="Skagway-Hoonah-Angoon" & State=="Alaska" ~ "skagwayalaska",
  County=="Wrangell Petersburg" & State=="Alaska" ~ "wrangellalaska",
  County=="Yukon-Koyukuk" & State=="Alaska" ~ "yukonkoyukukcaalaska",
  County=="Bethel" & State=="Alaska" ~ "bethelcaalaska",
  TRUE ~ merge_code
))

map_check <- paste0(location_map$merge_code)
data_check <- paste0(dt$merge_code)
unmapped_locs <- dt[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("State", "County", "merge_code")]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above. 
  stop("You have locations in the data that aren't in the codebook!")
}

# merge the dataset and the location codebook
merged_dt <- inner_join(dt, location_map, by="merge_code")

# calculate: good days aqi
merged_dt$good_aqi <- merged_dt$Good.Days/merged_dt$Days.with.AQI

# subset columns of interest
final_dt <- merged_dt %>% select(state_name, location_name, location_code, 
                                 good_aqi, Year)

# rename variables in the file
final_dt <- rename(final_dt, county_name=location_name,
                   fips_code=location_code,
                   year=Year)

# filter years of final dataset
final_dt <- final_dt %>% filter(year>=2012)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "07_prepped_aqi_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))

