# Name: 05_extract_food_insecurity.R
# Purpose: extract and prep data on food insecurity
# Date: November 16 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset5_Food Insecurity Rate/Map the Meal Gap Data/"

# each year is stored in separate file so will need to create a list of the  files
# directory path will need to be updated for each user
files <- list.files(path=paste0(raw_data_dir, containing_folder), pattern = ".xlsx" , full.names=TRUE, recursive=FALSE)

# create a loop that will prep each file
for (i in 1:length(files)){
  
  # use this to troubleshoot
  # i = 10
  
  raw_file <- files[i]
  
  if (files[i]=="./01_raw_data/dataset5_Food Insecurity Rate/Map the Meal Gap Data/MMG2020_2018Data_ToShare.xlsx"){
    dt <- read_xlsx(path=raw_file, skip = 1)
  } else {
    dt <- read_xlsx(path=raw_file)
  }
    
  # save file name within the dataset
  dt$file_name <- files[i]
  
  # extract year of data from file names
  dt$year <- substr(dt$file_name, 112, 115)
  
  # save as numeric value
  dt$year <- as.numeric(dt$year)
  
  # grab correct columns of interest
  state_col <- grep("state", tolower(names(dt)))[1]
  county_col <- grep("county", tolower(names(dt)))[1]
  fips_col <- grep("fips", tolower(names(dt)))[1]
  rate_col <- grep("rate", tolower(names(dt)))[1]
  year_col <- grep("year", tolower(names(dt)))
  
  # rename columns
  names(dt)[state_col] <- "state_abbreviation"
  names(dt)[county_col] <- "county"
  names(dt)[fips_col] <- "fips_code"
  names(dt)[rate_col] <- "fi_rate"
  
  # subset columns of interest
  dt <- dt %>% select(state_abbreviation, county, fips_code, year, fi_rate, file_name)
  
  # drop locations that are completely blank
  dt <- dt %>% filter(!is.na(state_abbreviation) & !is.na(county) & !is.na(fips_code))
  
  # bind data together 
  if(i==1){
    extracted_data = dt
  } else {
    extracted_data = rbind(extracted_data, dt, use.names=TRUE, fill = TRUE)
  }
  
  print(paste0("Prepped: ", i, " ", files[i])) ## if the code breaks, you know which file it broke on
  
}

# drop locations that are not properly coded
extracted_data <- extracted_data %>% filter(year%in%c(2009:2019))

# Fips codes should be minimum five digits
extracted_data$fips_tooshort <- ifelse(nchar(extracted_data$fips_code)<5, "TRUE", "FALSE")

# add a leading zero to the locations with fips codes that are too short
extracted_data <- extracted_data %>% 
  mutate(
    fips_code = case_when(
        fips_tooshort==TRUE ~ paste0("0", fips_code),
        TRUE ~ fips_code)
  )

# load the location map
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

# drop the state-level data from the location map
location_map <- location_map %>% filter(location_type=="County")

# check for fips codes that are not in the location map
map_check <- paste0(location_map$location_code)
data_check <- paste0(extracted_data$fips_code)
unmapped_locs <- extracted_data[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("state_abbreviation", "county", "fips_code"), with= FALSE]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above. 
  stop("You have locations in the data that aren't in the codebook!")
}

# merge dataset with the complete location map
merged_dt <- inner_join(extracted_data, location_map, by=c("fips_code"="location_code"))

# subset columns
final_dt <- merged_dt %>% select(state_name, location_name, fips_code, year, fi_rate)

# rename certain columns to match final protocol
final_dt <- rename(final_dt, county_name=location_name)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "05_prepped_food_insecurity_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))
