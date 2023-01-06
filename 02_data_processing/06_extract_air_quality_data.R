# Name: 06_extract_air_quality_data.R
# Purpose: Initial extraction of the air quality data
# This file will replace the previous file 
# Date: December 5 2022

# load necessary packages
library(tidyverse)
library(readxl)
library(writexl)

# save necessary filepaths
raw_data_dir <- "./01_raw_data/"
containing_folder <- "dataset6_AQI by County 1980-2021/"
# raw_file <- "Air Qulality_Compiled Counties.xlsx"

# each year is stored in a seperate file so will need to create a list of all the files
files <- list.files(path=paste0(raw_data_dir, containing_folder), pattern = ".csv" , full.names=TRUE, recursive=FALSE)

for (i in 1:length(files)){
  # uncomment below to troubleshoot
  # i <- 1
  
  raw_file <- files[i]
  
  dt <- read.csv(file=paste0(raw_file))
  
  # bind data together 
  if(i==1){
    extracted_data <- dt
  } else {
    extracted_data <- rbind(extracted_data, dt, use.names=TRUE, fill = TRUE)
  }
  
  print(paste0("Prepped: ", i, " ", files[i])) ## if the code breaks, you know which file it broke on
  
}

# # set file path and file name of final data
prepped_data_dir <- "./01_raw_data/dataset6_AQI by County 1980-2021/"
prepped_file_name <- "Air Qulality_Compiled Counties.xlsx"

# save intermediate dataset in the raw data folder
write_xlsx(extracted_data, path = paste0(prepped_data_dir, prepped_file_name))
