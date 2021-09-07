/*
Purpose: Estimate and Plot stacked global energy-temperature response
*/

clear all
set more off
macro drop _all
global LOG: env LOG
log using $LOG/1_analysis/1_uninteracted_regression.log, replace


/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

global REPO: env REPO
global DATA: env DATA 
global OUTPUT: env OUTPUT 

// path to energy-code-release repo 

global root "${REPO}/energy-code-release-2020"

/////////////////////////////////////////////////////////////////////////////////////////////////

******Set Script Toggles********************************************************

// What model do you want? TINV_clim or TINV_clim_EX
global model "TINV_clim"

********************************************************************************
* Step 1: Estimate Response
********************************************************************************

do $root/1_analysis/uninteracted_regression/stacked.do

********************************************************************************
* Step 2: Plot Response
********************************************************************************

do $root/1_analysis/uninteracted_regression/plot_stacked.do

log close _all
