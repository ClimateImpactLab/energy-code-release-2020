
/*
Purpose: Estimate and Plot stacked income decile energy-temperature response
*/

clear all
set more off
macro drop _all

/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

global REPO: env REPO
global DATA: env DATA 
global OUTPUT: env OUTPUT
global LOG: env LOG
log using $LOG/1_analysis/2_decile_regression.log, replace


* path to energy-code-release repo:

global root "${REPO}/energy-code-release-2020"

/////////////////////////////////////////////////////////////////////////////////////////////////

******Set Script Toggles********************************************************

// What model do you want? TINV_clim or TINV_clim_EX
global model "TINV_clim"

********************************************************************************
* Step 1: Estimate Response
********************************************************************************

do $root/1_analysis/decile_regression/stacked.do

********************************************************************************
* Step 2: Plot Response
********************************************************************************

do $root/1_analysis/decile_regression/plot_stacked.do

********************************************************************************
* Step 3: Plot Response separately for electricity and other energy
********************************************************************************

do $root/1_analysis/decile_regression/plot_stacked_1A_separate.do

log close _all

