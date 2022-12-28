# 17_prep_lat_long.R
# prep the coordinates that will help filter specific locations on the map

# clear workspace
rm(list=ls())

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "location_maps/raw_data/"
state_file <- "lat_long_usa.xlsx"
county_file <- "lat_long_counties.xlsx"

# load the data file
raw_state_file <- read_xlsx(path=paste0(raw_data_dir, containing_folder, state_file))

# rename columns
names(raw_state_file) <- c("place_name", "lat", "long", "zoom")

# split out the state names from each place-name
raw_state_file$state_name <- str_split_fixed(raw_state_file$place_name, ", ",n=2)[,1]

# add location type variable
raw_state_file$county_name <- "Select County"

# subset columns of interest
final_state_dt <- raw_state_file %>% select(state_name, county_name, lat, long, zoom)

# load county level data
raw_county_dt <- read_xlsx(path=paste0(raw_data_dir, containing_folder, county_file))

# subset the file
raw_county_dt <- raw_county_dt %>% select(`County [2]`, FIPS, Latitude, Longitude)

# # add location type
# county_dt$location_type <- "county"

# re-code one county that has been re-named since the data was published 
raw_county_dt <- raw_county_dt %>% mutate(FIPS = case_when(
  FIPS==2270 ~ 02158, 
  TRUE ~ FIPS
))

# clean up the fips code
raw_county_dt$fips_tooshort <- ifelse(nchar(raw_county_dt$FIPS)<5, "TRUE", "FALSE")

# add a leading zero to the locations with fips codes that are too short
raw_county_dt$fips_code <- NA

raw_county_dt <- raw_county_dt %>% 
  mutate(
    fips_code = case_when(
      fips_tooshort==TRUE ~ paste0("0", FIPS),
      fips_tooshort==FALSE ~ paste0(FIPS))
  )

# load the location map to standardize the names
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

map_check <- paste0(location_map$location_code)
data_check <- paste0(raw_county_dt$fips_code)
unmapped_locs <- raw_county_dt[!data_check%in%map_check,]


if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("County [2]", "FIPS", "fips_code")]))
  # print(unique(unmapped_codes$file_name)) 
  # For documentation in the comments above. 
  stop("You have locations in the data that aren't in the codebook!")
}

# merge the location map onto the codebook
final_county_dt <- raw_county_dt %>% inner_join(location_map, by=c("fips_code"="location_code"))

# subset final_county_dt
final_county_dt <- final_county_dt %>% select(location_name, Latitude, Longitude, state_name)

# re-name the final_county_dt columns
final_county_dt <- rename(final_county_dt, county_name=location_name,
       lat=Latitude,
       long=Longitude)

# add a zoom column
final_county_dt$zoom <- 9

# re-format the variables for long and lat
final_county_dt$lat <- gsub("°", "", final_county_dt$lat)
final_county_dt$long <- gsub("°", "", final_county_dt$long)
final_county_dt$long <- gsub("-", "-", final_county_dt$long)

final_county_dt$lat <- as.numeric(final_county_dt$lat)
final_county_dt$long <- as.numeric(final_county_dt$long)


# bind the two datasets together
final_dt <- rbind(final_state_dt, final_county_dt)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_state_file <- "18_prepped_lat_long_data_states.RDS"
prepped_county_file <- "19_prepped_lat_long_data_counties.RDS"

# save final dataset
saveRDS(final_state_dt, file = paste0(prepped_data_dir, prepped_state_file))
saveRDS(final_dt, file = paste0(prepped_data_dir, prepped_county_file))
