* video explainer data
*some graphics are being prepared for video explainers of each sector. 
*for energy, get in a spreadsheet the IEA data 
*on UK per capita electricity consumption for every year (1971-2010)
clear all
set more off
macro drop _all
pause on
cap ssc install rangestat

cilpath
/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

// path to energy-code-release repo 
local root "$REPO/energy-code-release-2020"


/////////////////////////////////////////////////////////////////////////////////////////////////

* Step 0: Define code and dataset paths

// code path referenced by multiple files
global dataset_construction "`root'/0_make_dataset/"

// output data path
local DATA "`root'/data"

use "`DATA'/IEA_Merged_long_GMFD.dta", clear

keep if country == "GBR"
keep if product == "electricity"

keep country product year load_pc

save "`DATA'/IEA_GBR_electricity_loadpc.dta", replace
export delimited using "`DATA'/IEA_GBR_electricity_loadpc.csv", replace