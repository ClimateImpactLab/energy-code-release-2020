
/*
Creator: Maya Norman
Date last modified: 12/19/19 
Purpose: Estimate and Plot stacked global energy-temperature response
*/

clear all
set more off
macro drop _all

/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

* path to energy-code-release repo:

global root "/Users/`c(username)'/Documents/repos/energy-code-release"

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