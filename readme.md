Community Well-Being Dashboard
======

Initialized December 27 2022

Code associated with the UW PHI & Social Weather "Community Well-Being Dashboard."

## Project Purpose
-----
The Community Well-Being Dashboard presents trends and patterns in county-level indicators for various data sources. 
The dashboard can be accessed at this link: [https://rsc.csde.washington.edu/content/2c9873aa-4bc3-4d6e-b6fb-b9e574682016].

## Basic Organization
-----

This repository is organized according to the major steps necessary to prepare the project's data and create an R Shiny Dashboard to explore the data. 


### The folders include:

#### 01_raw_data/

  * This folder contains all of the original data files that were used in this project. 

#### 02_data_processing/

  * This folder contains all of the scripts that were used to prep the data for the project. These scripts were written in the R programming language and Python. Documentation is included in each script to describe the exact way that each variable needs to be processed. 

#### new_sw_app/

  * This folder contains all of the code necessary to create the R Shiny Dashboard. 

 ## Key considerations
 -----
 
Currently the dashboard is hosted on a server at the University of Washington. You can also run the dashboard locally as the code included here is self-contained. 
Future edits and modifications to the public dashboard will require publishing the dashboard to a new R Shiny Server. 

There are ten data sources that were prepped and included as part of this project. The following six were initially selected but ultimately not included: 
* Dataset ID 2: Adjusted Cohort Graduation Rate
* Dataset ID 7: Residential Fixed Internet Access
* Dataset ID 12: Insurance Rates
* Dataset ID 13: Cost-Burdened Households
* Dataset ID 15: Percent Voted in Previous Election
* Dataset ID 16: Violent Crime Rate

