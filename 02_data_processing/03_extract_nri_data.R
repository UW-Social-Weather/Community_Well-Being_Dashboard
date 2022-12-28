# Name: 04_prep_nri.R
# Purpose: finish prepping National Risk Index data
# Date: December 2 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset3_NRI/NRI_Table_Counties/"
raw_file <- "NRI_Table_Counties.csv"

# load data
dt <- read.csv(paste0(raw_data_dir, containing_folder, raw_file))

# subset columns
dt_subset <- dt %>% select(STATE, STATEABBRV, STATEFIPS, COUNTYFIPS, STCOFIPS, COUNTY, RISK_SCORE)

# merge location map
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

# Fips codes should be minimum five digits
dt_subset$fips_tooshort <- ifelse(nchar(dt_subset$STCOFIPS)<5, "TRUE", "FALSE")

# add a leading zero to the locations with fips codes that are too short
dt_subset$fips_code <- NA

for (i in 1:length(dt_subset)){
  dt_subset$fips_code[i] <- ifelse(dt_subset$fips_tooshort==TRUE, paste0("0", dt_subsetSTCOFIPS), STCOFIPS)
}

dt_subset$fips_code <- ifelse(dt_subset$fips_tooshort==TRUE, paste0("0", dt_subset$STCOFIPS), dt_subset$STCOFIPS)

# merge code book and data
map_check <- paste0(location_map$location_code)
data_check <- paste0(dt$fips_code)
unmapped_locs <- dt[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("county", "state", "merge_code")]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above. 
  stop("You have locations in the data that aren't in the codebook!")
}

# merge the dataset and the location codebook
merged_dt <- inner_join(dt_subset, location_map, by=c("fips_code"="location_code"))

# subset columnsRISK_SCORE
merged_dt <- merged_dt %>% select(state_name, location_name, fips_code, RISK_SCORE)

# add year variable
merged_dt$year <- 2020

# rename variables
final_dt <- merged_dt %>% rename(county_name=location_name,
                                 risk_score=RISK_SCORE)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "03_prepped_risk_score_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))
