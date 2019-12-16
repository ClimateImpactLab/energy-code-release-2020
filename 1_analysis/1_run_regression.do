/*

Creator: Maya Norman
Date last modified: 3/25/19 
Last modified by: Maya Norman

Purpose: Master Do File for Analysis

Clean Data, Produce dataset ready for regressions, Run Regressions

Climate Data Options: GMFD
Model Options: TINV_clim, TINV_clim_EX, TINV_both
Model Subset Option: decinter, lininter, ui

Input Data Options: IEA_Merged_long_`IF'_`temp'.dta or 
IEA_Merged_long_IssueFix_ClimFix.dta (for BEST) or `dataset'_EX.dta for
robustness.

*/


clear all
set more off
macro drop _all
pause on


//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"
	local GIT "/Users/`c(username)'/Documents/Repos/gcp-energy"

}
else if "`c(username)'" == "manorman"{
	
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
	local GIT "/home/`c(username)'/gcp-energy"

}

******Set Script Toggles********************************************************

//Set data type ie historic or replicated
global data_type "replicated_data"
local data_type $data_type

//Set Data type

//What happens to Zeroes: currently dealt with in 0_merge so here we just drop the 
//zeroes that were to set to zero previously based on Exclude rule
//exclude rule: 0 if TOTOTHER or TOTIND is missing or zero

global case "Exclude" //"Exclude" "Include"

//Breakdown of fuels and products: break2 --> only two groups other_energy and electricity

global bknum "break2"

//Issue Fix
	
global IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues

//income grouping test: 

/*

Income grouping options and Implications:

iterative-ftest: 
-all-issues, break2, Exclude, TINV_clim: other_energy (3-2) and electricity (1-2-1-1)
-first-reading-issues, break2, Exclude, TINV_clim: other_energy (4-1) and electricity (3-1-1)

visual:
-all-issues, break2, Exclude, TINV_clim: other_energy and electricity (3-1-1)

*/

global grouping_test "semi-parametric" 

//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX, TINV_clim_ui, TINV_clim_income_spline
global model "TINV_clim_income_spline"
global submodel "decinter" // ui decinter lininter income_spline

if "$submodel" == "decinter" | "$submodel" == "lininter" {
			
	global time_dummy "" // "" "wtimeDummy"
			
}

//Climate Data type
global clim_data "GMFD"

******Set Model Parameters******************************************************

global FD "FD" // FD vs noFD
global qt 10 //5 or 10 quantile
global t "I" // C or I climate or income quantile regression

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

//run regressions
do `GIT'/rationalized/1_analysis/interacted_regression/generate_ster/stacked.do


if ("$submodel" == "" & "$IF" == "_all-issues" & "$clim_interaction" != "_continuous") {

	forval i=2/4 {

		global o = `i'
		do `GIT'/rationalized_code/1_analysis/quantile_regression/stacked.do
		
	}

	foreach region in "global" "OECD" {
		
		global region "`region'"
		do `GIT'/rationalized_code/1_analysis/global_polynomial_regression/Stacked.do

	}
}


