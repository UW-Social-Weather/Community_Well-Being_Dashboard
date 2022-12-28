# Name: 10_extract_affordable_housing_data.R
# Purpose: extract and prep data on affordable housing
# Date: November 18 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset10_affordable housing/"

# each year is stored in separate file so will need to create a list of the  files
# directory path will need to be updated for each user
files <- list.files(path=paste0(raw_data_dir, containing_folder), pattern = ".csv" , full.names=TRUE, recursive=FALSE)

for (i in 1: length(files)){
  # uncomment below to troubleshoot
  # i <- 1
  
  raw_file <- files[i]
  
  dt <- read.csv(file=paste0(raw_file))
  
  # rename columns
  names(dt)[4] <- "countyname"
  names(dt)[2] <- "fips_code"
  names(dt)[25] <- "state"
  
  # save file name within the dataset
  dt$file_name <- files[i]
  
  # extract year of data from file names
  dt$year <- substr(dt$file_name, 89, 92)
  
  # keep columns of interest
  dt <- dt %>% select(fips_code, countyname, state, year, per100)
  
  # subset to only counties with actual data
  # counties with missing data are too small and values are aggregated to
  # state only
  dt <- dt %>% filter(!is.na(per100))
  
  # bind data together 
  if(i==1){
    extracted_data = dt
  } else {
    extracted_data = rbind(extracted_data, dt, use.names=TRUE, fill = TRUE)
  }
  
  print(paste0("Prepped: ", i, " ", files[i])) ## if the code breaks, you know which file it broke on

}

# load the location map
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

# # check for fips codes that are not in the location map
# map_check <- paste0(location_map$location_code)
# data_check <- paste0(extracted_data$fips_code)
# unmapped_locs <- extracted_data[!data_check%in%map_check,]

# 
# if(nrow(unmapped_locs)>0){
#   print(unique(unmapped_locs[, c("state_abbreviation", "county", "fips_code"), with= FALSE]))
#   # print(unique(unmapped_codes$file_name)) #For documentation in the comments above. 
#   stop("You have locations in the data that aren't in the codebook!")
# }

# merge dataset with the complete location map
merged_dt <- inner_join(extracted_data, location_map, by=c("fips_code"="location_code"))

# subset columns
final_dt <- merged_dt %>% select(state_name, location_name, fips_code, year, per100)

# rename certain columns to match final protocol
final_dt <- rename(final_dt, county_name=location_name,
                   aaa_per100=per100)

# recode year variable
final_dt$year <- as.numeric(final_dt$year)

# # set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "10_prepped_affordable_housing_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))
