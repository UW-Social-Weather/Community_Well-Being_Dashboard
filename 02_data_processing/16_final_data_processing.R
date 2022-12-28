# Name: 16_final_processing_map_data.R
# Purpose: add data that is necessary for plotting in a map
# Date: December 13 2022
rm(list=ls())

library(rgeos)
library(rgdal)
library(maptools)
library(dplyr)
library(leaflet)
library(scales)
library(sp)
library(tidyverse)

# load the final prepped data
dat <- readRDS(file="./03_final_data/15_sw_merged_data.RDS")

# rename the fips code to facilitate merge later
colnames(dat)[3] <- "GEOID"

# rescale the following variables to range from 0 to 100: food insecurity and Days with Good Air
dat$fi_rate <- dat$fi_rate*100
dat$good_aqi <- dat$good_aqi*100

# Download county shape file from Tiger.
# https://www.census.gov/geo/maps-data/data/cbf/cbf_counties.html
us.map <- readOGR(dsn = "./01_raw_data/location_maps/shapefiles_20m", layer = "cb_2018_us_county_20m", stringsAsFactors = FALSE)
               
# remove a few areas not needed such as: Puerto Rico (72), Guam (66), Virgin Islands (78), American Samoa (60)
#  Mariana Islands (69), Micronesia (64), Marshall Islands (68), Palau (70), Minor Islands (74)
us.map <- us.map[!us.map$STATEFP %in% c("72", "66", "78", "60", "69",
                                        "64", "68", "70", "74"),]

# Make sure other outling islands are removed.
us.map <- us.map[!us.map$STATEFP %in% c("81", "84", "86", "87", "89", "71", "76",
                                        "95", "79"),]


# save the dataset
saveRDS(dat, file = "./03_final_data/16_final_data_for_maps.RDS")

# save the shapefile for mapping
saveRDS(us.map, file = "./03_final_data/17_county_shapefile.RDS")
