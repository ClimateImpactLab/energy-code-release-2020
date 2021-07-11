/*

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
cap ssc install rangestat

/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

// path to energy-code-release repo 
local root "$REPO/energy-code-release-2020"


/////////////////////////////////////////////////////////////////////////////////////////////////

* Step 0: Define code and dataset paths

// code path referenced by multiple files
global dataset_construction "`root'/0_make_dataset/"

// output data path
local DATA 

********************************************************************************************************************************************
*Step 1: Construct Population/Income, Load, and Climate Datasets
********************************************************************************************************************************************

//Part A: Climate Data Construction

do "$dataset_construction/climate/1_clean_climate_data.do"
clean_climate_data, clim("GMFD") programs_path("$dataset_construction/climate/programs")

// *****************************
// code to check the difference between pixel-level vs normal interacted terms
gen old_polyBelow1_x_hdd = polyBelow1_GMFD * hdd20_GMFD
gen old_polyBelow2_x_hdd = polyBelow2_GMFD * hdd20_GMFD

gen old_polyAbove1_x_cdd = polyAbove1_GMFD * cdd20_GMFD
gen old_polyAbove2_x_cdd = polyAbove2_GMFD * cdd20_GMFD

gen new_polyBelow1_x_hdd = polyBelow1_x_hdd_GMFD
gen new_polyBelow2_x_hdd = polyBelow2_x_hdd_GMFD

gen new_polyAbove1_x_cdd = polyAbove1_x_cdd_GMFD
gen new_polyAbove2_x_cdd = polyAbove2_x_cdd_GMFD



foreach v in polyBelow1_x_hdd polyBelow2_x_hdd polyAbove1_x_cdd polyAbove2_x_cdd {
	di "variable: `v'"
	qui corr old_`v' new_`v'
	di "all: `r(rho)'"
	qui corr old_`v' new_`v' if country == "USA"
	di "USA: `r(rho)'"
	qui corr old_`v' new_`v' if country == "CHN"
	di "CHN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "FRA"
	di "FRA: `r(rho)'"
	qui corr old_`v' new_`v' if country == "RUS"
	di "RUS: `r(rho)'"
	qui corr old_`v' new_`v' if country == "JPN"
	di "JPN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "IND"
	di "IND: `r(rho)'"
	qui corr old_`v' new_`v' if country == "MEX"
	di "MEX: `r(rho)'"
	qui corr old_`v' new_`v' if country == "BRA"
	di "BRA: `r(rho)'"
	qui corr old_`v' new_`v' if country == "CAN"
	di "CAN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "FIN"
	di "FIN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "GRL"
	di "GRL: `r(rho)'"
	qui corr old_`v' new_`v' if country == "DNK"
	di "DNK: `r(rho)'"
	
	di ""

}

//gen diff = new_interaction - old_interaction
//gen diff_pct = diff / old_interaction
//sum old_interaction new_interaction diff*
// *****************************

tempfile climate_data
save `climate_data', replace
save "`DATA'/climate_data", replace
//Part B: Population and Income Data Construction
use "`DATA'/climate_data", clear

do "$dataset_construction/pop_and_income/1_extract_and_clean.do"

tempfile population_and_income_data
save `population_and_income_data', replace

//Part C: Load Data Clean and Prepare For Merge with Pop, Inc, and Climate Data

do $dataset_construction/energy_load/1_extract_clean_energy_load_data.do

//Restrict Dataset to specified years (increase balance in dataset)
drop if year > 2010 | year < 1971

tempfile energy_load_data
save `energy_load_data', replace

******************************************************************************************************************************************
*Step 2: Merge Pop, Inc and Climate Data with Load Data and Clean Dataset Based on Specification
******************************************************************************************************************************************

//Part A: Merge Data
use `energy_load_data', clear

merge m:1 country year using `population_and_income_data'
keep if _merge!=2
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

di "mission complete :)"
save "`DATA'/IEA_Merged_long_GMFD.dta", replace

