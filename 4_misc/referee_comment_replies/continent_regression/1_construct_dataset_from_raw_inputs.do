clear all
set more off
macro drop _all
pause on
cap ssc install rangestat

cilpath
/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

// path to energy-code-release repo 
local root "$REPO/energy-code-release-2020/"


/////////////////////////////////////////////////////////////////////////////////////////////////

* Step 0: Define code and dataset paths

// code path referenced by multiple files
global dataset_construction "`root'/4_misc/referee_comment_replies/continent_regression/"

// output data path
local DATA "`root'/data"

********************************************************************************************************************************************
*Step 1: Construct Population/Income, Load, and Climate Datasets
********************************************************************************************************************************************

//Part A: Climate Data Construction

do "$dataset_construction/climate/1_clean_climate_data.do"
clean_climate_data, clim("GMFD") programs_path("$dataset_construction/climate/programs")

tempfile climate_data
save `climate_data', replace




