# Name: 01_extract_gdp_data.R
# Purpose: Extract the GDP data 
# Date: December 22 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset1_GDP/"
raw_file <- "lagdp1222.xlsx"

# load the raw data
raw_data <- read_xlsx(paste0(raw_data_dir, containing_folder, raw_file))

# rename columns of interest
names(raw_data)[1] <- "location"
names(raw_data)[2] <- "2018"
names(raw_data)[3] <- "2019"
names(raw_data)[4] <- "2020"
names(raw_data)[5] <- "2021"

# load the county index
gdp_county_index <- read_xlsx(paste0(raw_data_dir, containing_folder, "gdp_county_indices.xlsx"))

# add index
raw_data$index <- seq(1, 3226)

# Add state name to the rows using a loop
raw_data$state_name <- NA

for (i in 1:50){
  # i <- 1
  start <- gdp_county_index$start_row[i]
  end   <- gdp_county_index$end_row[i]
  
  raw_data[start:end,]$state_name <- gdp_county_index$state_name[i]
}

# inspect dropped locations to make sure that there are none that we want to keep
dropped_locs <- filter(raw_data, is.na(state_name))

# drop empty rows 
raw_data <- raw_data %>% filter(!is.na(state_name))

# inspect header rows (that don't have any data in 2018)
header_rows <- filter(raw_data, is.na(`2018`))

# drop header rows
raw_data <- raw_data %>% filter(!is.na(`2018`))

# subset columns of interest
raw_data <- raw_data %>% select(location, state_name, `2018`, `2019`, `2020`, `2021`)

# create merge id in order to match the fips code
raw_data$merge_id <- tolower(paste0(raw_data$location, raw_data$state_name))

# load location map data
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx") %>% filter(location_type=="County")

# create new merge id to match to the raw_data
location_map$merge_id <- tolower(paste0(location_map$location_name, location_map$state_name))

# remove blank characters from the merge ids
raw_data$merge_id <- gsub(" ", "", raw_data$merge_id)
raw_data$merge_id <- gsub("cityandboroughalaska", "alaska", raw_data$merge_id) # the word borough is not in the location map for alaska
raw_data$merge_id <- gsub("boroughalaska", "alaska", raw_data$merge_id) # the word borough is not in the location map for alaska
raw_data$merge_id <- gsub("censusareaalaska", "(ca)alaska", raw_data$merge_id) # replace census area with abbreviation in alaska
raw_data$merge_id <- gsub("municipalityalaska", "alaska", raw_data$merge_id) # replace census area with abbreviation in alaska
raw_data$merge_id <- gsub("petersburgalaska", "petersburgboroughalaska", raw_data$merge_id) # replace census area with abbreviation in alaska
raw_data$merge_id <- gsub("\\(includesyellowstonenationalpark\\)idaho", "idaho", raw_data$merge_id) # replace census area with abbreviation in alaska
# raw_data$merge_id <- gsub("baltimorecitymaryland", "baltimoremaryland", raw_data$merge_id) # need to fix richmond city and richmond city virginia first

# location map
location_map$merge_id <- gsub(" ", "", location_map$merge_id) # remove blank characters
location_map$merge_id <- gsub("\\(city\\)virginia", "virginia", location_map$merge_id) # remove the city and parenthesis in virginia data
location_map$merge_id <- gsub("\\(city\\)missouri", "citymissouri", location_map$merge_id) # remove the city and parenthesis in virginia data
location_map$merge_id <- gsub("\\(city\\)maryland", "citymaryland", location_map$merge_id) # remove the city and parenthesis in virginia data
location_map$merge_id <- gsub("\\(city\\)nevada", "nevada", location_map$merge_id) # remove the city and parenthesis in virginia data
location_map$merge_id <- gsub("charlesvirginia", "charlescityvirginia", location_map$merge_id) # remove the city and parenthesis in virginia data

# mutate sure richmond city virginia matches richmond city in the location map
raw_data <- raw_data %>% mutate(merge_id = case_when(
  location=="Richmond" & `2018`==20309537 ~ "richmondcityvirginia",
  TRUE ~ merge_id
))

location_map <- location_map %>% mutate(merge_id = case_when(
  location_code==51760 ~ "richmondcityvirginia",
  TRUE ~ merge_id
))
# raw_data <- raw_data %>% mutate(merge_id = case_when(
#   location=="Alexandria" ~ "alexandriacityvirginia",
#   location=="Chesapeake" ~ "chesapeakecityvirginia",m
#   location=="Hampton" ~ "hamptoncityvirginia",
#   location=="Newport News" ~ "newportnewscityvirginia",
#   location=="Norfolk" ~ "norfolkcityvirginia",
#   location=="Portsmouth" ~ "portsmouthcityvirginia",
#   location=="Suffolk" ~ "suffolkcityvirginia",
#   location=="Virginia Beach" ~ "virginiabeachcityvirginia",
#   TRUE ~ merge_id))

# check to see which county and state combinations do not line up
map_check <- paste0(location_map$merge_id)
data_check <- paste0(raw_data$merge_id)
unmapped_locs <- raw_data[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("state_name", "location", "merge_id"), with= FALSE]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above.
  stop("You have locations in the data that aren't in the codebook!")
}

# remove state name from raw data before merge
raw_data <- raw_data %>% select(-state_name)

# merge the location map to standardize the naming information on the raw data
final_dt <- raw_data %>% inner_join(location_map, by="merge_id")

# subset columns of interest
final_dt <- final_dt %>% select(location_name, state_name, location_code, `2018`, `2019`, `2020`, `2021`)

# convert values to numeric for a quick test
final_dt$`2018` <- as.numeric(final_dt$`2018`)
final_dt$`2019` <- as.numeric(final_dt$`2019`)
final_dt$`2020` <- as.numeric(final_dt$`2020`)
final_dt$`2021` <- as.numeric(final_dt$`2021`)

# re-shape data to be long
final_dt <- final_dt %>% pivot_longer(!c(location_name, state_name, location_code), names_to = "year", values_to = "gdp")

# re-name some of the columns
final_dt <- rename(final_dt, county_name=location_name,
                   fips_code=location_code)

# save year value as numeric
final_dt$year <- as.numeric(final_dt$year)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "01_prepped_gdp_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))
