# Name: 13_extract_cost_burdened_households_data.R
# Purpose: extract and prep data on cost-burdened households
# Date: November 29 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset13_cost burdens/"
raw_file <- "Cost Burdens (SON 2020).xlsx"

# load the data file
dt <- read_xlsx(path=paste0(raw_data_dir, containing_folder, raw_file))

# select the columns of interest
dt_subset <- dt %>% select(1, 2, 18:31)

# standardize name columns
names(dt_subset)[3] <- "2006"

# reshape columns
dt_long <- dt_subset %>% pivot_longer(cols=!GEOID:`Metro Name`, names_to = "year", values_to = "cost_burdened_hh")

# split out state name
dt_long$state <- str_split_fixed(dt_long$`Metro Name`, ", ", n=2)[,2]
dt_long$metro <- str_split_fixed(dt_long$`Metro Name`, ", ", n=2)[,1]

# data is at the metro area will not be able to be merged with other datasets

# # load location map
# location_map <- read_xlsx("./01_raw_data/location_maps/prepped_data/02_county_location_map.xlsx")
# 
# # merge map onto data
# dt_long$GEOID <- as.character(dt_long$GEOID)
# dt_merge <- dt_long %>% full_join(location_map, by=c("GEOID"="location_code"))

# save columns of interest
dt_long <- dt_long %>% select(GEOID, metro, state, year, cost_burdened_hh)

# set file path and file name of final data
prepped_data_dir <- "./03_final_data/"
prepped_file_name <- "13_prepped_cost_burdened_household_data.xlsx"

# save final dataset
write_xlsx(dt_long, path = paste0(prepped_data_dir, prepped_file_name))
