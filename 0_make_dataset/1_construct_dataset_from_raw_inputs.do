/*

Creator: Yuqi Song
Date last modified: 5/6/19 
Last modified by: Maya Norman

Purpose: Master Do File for Dataset Construction

This script takes in raw data input files either downloaded from the internet or constructed using merge_transform_average.py
(https://bitbucket.org/ClimateImpactLab/climate_data_aggregation/src/master/). Please use 0_Clim_Config_Gen.do to write configs
that are passed into the Climate Data Aggregation code.

Before this do file is run the following steps need to be completed:

1) Load, population, and income data must be extracted.
	-Please refer to https://paper.dropbox.com/doc/Energy-Replication-Data-Extraction-and-Clean--AcW~Qw9B5VVB29k4PJCYL1I3Ag-VAYyKKRjKXNub5MzctYgB
	for data extraction instructions.

2) Climate Data Must be Generated
	- Climate Data is generated to reflect geographical regions used in the load data. 
	See the dropbox paper referenced above as well as the aggregated climate data cleaning code to understand how the 
	climate data is generated to reflect load data specific geographic regions.

What happens in the do files called in this script:

Step 1) Construct Population, Income, Load, and Climate Datasets
Step 2) Merge Population, Income, Load and Climate Datasets

*/

clear all
set more off
macro drop _all
pause on

/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

if "`c(username)'" == "mayanorman"{

	local ROOT "/Users/`c(username)'"
	local DROPBOX "`ROOT'/Dropbox"
	local GIT "`ROOT'/Documents/Repos/gcp-energy/"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local ROOT "/home/`c(username)'"
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
	local GIT "`ROOT'/repos/gcp-energy/"
}

/////////////////////////////////////////////////////////////////////////////////////////////////

* Step 0: Define code and dataset paths

// code path referenced by multiple files
global dataset_construction "`GIT'/rationalized/0_make_dataset/"


// output data path

local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"



********************************************************************************************************************************************
*Step 1: Construct Population/Income, Load, and Climate Datasets
********************************************************************************************************************************************

//Part A: Climate Data Construction
do "$dataset_construction/climate/1_clean_climate_data.do"
clean_climate_data, clim("GMFD")

//save here for spot checking (can delete once confident in code)
save "`DATA'/Climate_Data/rationalized_code/IEA_Climate_Data_GMFD.dta", replace

tempfile climate_data
save `climate_data', replace

//Part B: Population and Income Data Construction

do "$dataset_construction/pop_and_income/extract_and_clean.do"

tempfile population_and_income_data
save `population_and_income_data', replace

//Part C: Load Data Clean and Prepare For Merge with Pop, Inc, and Climate Data

do $dataset_construction/energy_load/1_extract_clean_energy_load_data

//Restrict Dataset to specified years (increase balance in dataset)
drop if year>2012 | year < 1971

tempfile energy_load_data
save `energy_load_data', replace

******************************************************************************************************************************************
*Step 2: Merge Pop, Inc and Climate Data with Load Data and Clean Dataset Based on Specification
******************************************************************************************************************************************

//Part A: Merge Data
use `energy_load_data', clear

merge m:1 country year using `population_and_income_data'
keep if _merge!=2
pause
drop _merge
**climate**
merge m:1 year country using `climate_data'
keep if _merge!=2
drop _merge


//Part B: Construct Per Capita and log_pc

//Constructing per capita and log(pc) measures
foreach var of varlist coal* oil* natural_gas* electricity* heat_other* biofuels* solar* {
	qui gen double `var'_pc = `var' / pop
	qui gen double `var'_log_pc = log(`var'_pc)
} 

//Part C: Complete Specification Specific Data Set Cleaning Steps

do "$dataset_construction/merged/0_break2_clean.do"  
drop if year > 2010 | year < 1971


//Part D: Construct Time Invariant Income Data measure

bysort country: egen double m_lgdppc_TINV = mean(lgdppc) if load_pc!=.
bysort country: egen double lgdppc_TINV = max(m_lgdppc_TINV)
drop m_*

save "`DATA'/Analysis/GMFD/rationalized_code/replicated_data/data/IEA_Merged_long_GMFD.dta", replace

