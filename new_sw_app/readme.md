

Community Well-Being Dashboard
======
Initialized December 27 2022

Code associated with the UW PHI Social Weather Project: Community Well-Being Dashboard. 


## Project Purpose
The Community Well-Being Dashboard presents trends and patterns in county-level indicators for various data sources. The dashboard can be accessed at this link:

## Basic Organization

This repository is organized according to the major steps necessary to prepare the project's data and create an R Shiny Dashboard to explore the data. 


### The folders include:

#### 01_raw_data/

  * This folder contains all of the original data files that were used in this project as well as a file describing the source. 

#### 02_data_processing/

  * This folder contains all of the scripts that were used to prep the data for the project. These scripts were written in the R programming language. Documentation is included in each script to describe the exact way that each variable needs to be processed. 

#### 03_final_data/

  * This folder contains all of the final data sets as well as the files that are necessary to create the visuals and plot the data.

#### rsconnect/

  * This folder contains the necessary metadata to publish the dashboard to the existing server at the University of Washington.

#### www/

  * This folder contains the necessary HTML files that are used to modify the appearance of the dashboard.

     1. **assests/**: this folder includes stylesheets to modify the web page, images that are loaded onto the dashboard (such as logos), and other javascript libraries that might be useful.
     2. **index**: this file needs to be updated if there are any changes to the appearance of the dashboard (i.e., the header or footer).
     
### app.R

 * This is the code to construct the R Shiny Dashboard.

 ## Key considerations
 
Currently the dashboard is hosted on a server at the University of Washington. You can also run the dashboard locally as the code included here is self-contained. 
Future edits and modifications to the public dashboard will require publishing the dashboard to a new R Shiny Server. 

There are ten data sources that were prepped and included as part of this project. The following six were initially selected but ultimately not included: 
* Dataset ID 2: Adjusted Cohort Graduation Rate
* Dataset ID 7: Residential Fixed Internet Access
* Dataset ID 12: Insurance Rates
* Dataset ID 13: Cost-Burdened Households
* Dataset ID 15: Percent Voted in Previous Election
* Dataset ID 16: Violent Crime Rate

