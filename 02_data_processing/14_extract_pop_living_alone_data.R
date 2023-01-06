# Name: 14_extract_pop_living_alone_data.R
# Purpose: extract and prep data on proportion of those living alone
# Date: November 30 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)
library(stringr)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset14_living_alone/"
raw_file <- "Continental US_Full Data_data.csv"

# read in the file
dt <- read.csv(file=paste0(raw_data_dir, containing_folder, raw_file))

# rename columns
names(dt)[1] <- "county"

# load location map
location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")

# extract county name
dt$county_name <- gsub(" County", "", dt$county)

# create a merge code for the data
dt$merge_code <- tolower(gsub(" ", "",paste0(dt$county_name, dt$state), fixed = TRUE))
dt$merge_code <- gsub("[[:punct:]]", "", dt$merge_code)
dt$merge_code <- gsub("censusarea", "", dt$merge_code)
dt$merge_code <- gsub("municipality", "", dt$merge_code)
dt$merge_code <- gsub("cityandborough", "", dt$merge_code)
dt$merge_code <- gsub("borough", "", dt$merge_code)
dt$merge_code <- gsub("parish", "", dt$merge_code)
dt$merge_code <- gsub("caalaska", "alaska", dt$merge_code)
dt$merge_code <- gsub("\\.", "", dt$merge_code)

# create a merge code within the location map
location_map$merge_code <- tolower(gsub(" ", "",paste0(location_map$location_name, location_map$state_name), fixed = TRUE))
location_map$merge_code <- gsub("[[:punct:]]", "", location_map$merge_code)
location_map$merge_code <- gsub("caalaska", "alaska", location_map$merge_code)
location_map$merge_code <- gsub("\\.", "", location_map$merge_code)

# manually edit a few merge codes in the extracted data to match what is in the locaiton map
dt <- dt %>% mutate(merge_code = case_when(
  county=="Wade Hampton Census Area" & state==" Alaska" ~ "kusilvakalaska",
  county=="Hillsborough County" & state==" Florida" ~ "hillsboroughflorida",
  county=="Carson City" & state==" Nevada" ~ "carsoncitycitynevada",
  county=="Hillsborough County" & state==" New Hampshire" ~ "hillsboroughnewhampshire",
  county=="Doña Ana County" & state==" New Mexico" ~ "doñaananewmexico",
  county=="Shannon County" & state==" South Dakota" ~ "oglalalakotasouthdakota",
  TRUE ~ merge_code
))

# dropping district of columbia and Bedford City from the dataset since these 
# are not included in the official list of counties
dt <- dt %>% filter(county!="District of Columbia") %>% filter(county!="Bedford city")

# double check that all
map_check <- paste0(location_map$merge_code)
data_check <- paste0(dt$merge_code)
unmapped_locs <- dt[!data_check%in%map_check,]

if(nrow(unmapped_locs)>0){
  print(unique(unmapped_locs[, c("county", "state", "merge_code")]))
  # print(unique(unmapped_codes$file_name)) #For documentation in the comments above. 
  stop("You have locations in the data that aren't in the official list of counties!")
}

# merge the dataset and the location codebook
merged_dt <- inner_join(dt, location_map, by="merge_code")

# subset columns
final_dt <- merged_dt %>% select(state_name, location_name, location_code, 
                                 percent2000_display, percent2010_display)

# re-shape the data
final_dt <- final_dt %>% pivot_longer(!state_name:location_code, names_to = "year", values_to = "value")

# recode year values
final_dt <- final_dt %>% mutate(year=case_when(
  year=="percent2000_display" ~ 2000,
  year=="percent2010_display" ~ 2010,
))

# rename variables in the file
final_dt <- rename(final_dt, county_name=location_name,
             fips_code=location_code,
             pop_liv_alone=value)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "14_prepped_pop_living_alone_data.xlsx"

# save final dataset
write_xlsx(final_dt, path = paste0(prepped_data_dir, prepped_file_name))
