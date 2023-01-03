# Name: 11_extract_emergency_visit_data.R
# Purpose: Finalize prepping the intermediate GDP data already prepped
# Date: December 5 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset11_emergency department visits/All/"
# raw_file <- "dataset11_emergency_department_visits.csv"

# create list of files to include 
files <- list.files(path=paste0(raw_data_dir, containing_folder), pattern = ".csv" , full.names=TRUE, recursive=FALSE)

# create a loop that will run through each file and extract the necessary columns
for (i in 1: length(files)){
  # uncomment below to troubleshoot
  # i <- 1
  
  # load data file
  raw_file <- files[i]
  dt <- read.csv(file=paste0(raw_file), na.strings=c("","NA"))
  
  # subset columns of interest
  dt <- dt %>% select(year, fips, county, state, analysis_value)
  
  # Fips codes should be minimum five digits
  dt$fips_tooshort <- ifelse(nchar(dt$fips)<5, "TRUE", "FALSE")
  
  # add a leading zero to the locations with fips codes that are too short
  dt <- dt %>% mutate(
      fips_code = case_when(
        fips_tooshort==TRUE ~ paste0("0", fips),
        fips_tooshort==FALSE ~ paste0(fips))
    )
  
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

# fix issues here
extracted_data <- extracted_data %>% mutate(fips_code = case_when(
  county=="Oglala Lakota County" ~ "46102",
  county=="Wade Hampton Census Area" ~ "02158",
  TRUE ~ fips_code
))

# drop rows that are not at proper county-level data (missing county information)
extracted_data <- extracted_data %>% filter(!is.na(county)) %>%
  filter(county!=TRUE)

# Bedford City, Virginia is no longer an independent county
extracted_data <- extracted_data %>% filter(fips_code!=51515)

# check for fips codes that are not in the location map
map_check <- paste0(location_map$location_code)
data_check <- paste0(extracted_data$fips_code)
unmapped_locs <- extracted_data[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("state", "county", "fips_code")]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above.
  stop("You have locations in the data that aren't in the codebook!")
}

# merge the location map data with the extracted data
final_dt <- extracted_data %>% inner_join(location_map, by=c("fips_code"="location_code"))

# subset the columns of interest
final_dt <- final_dt %>% select(fips_code, location_name, state_name, year, analysis_value)

# rename certain columns
final_dt <- final_dt %>% rename(county_name=location_name,
                                emergency_visits=analysis_value)

# save the final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "11_prepped_emergency_visit_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))
