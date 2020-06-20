/*
Creator: Maya Norman
Date last modified: 3/26/19 
Last modified by: Maya Norman

Purpose: Master Do File for Projection Set Up

Create CSVV's - 
*/

clear all
set more off
macro drop _all
pause off

* Download a command for dealing with matrices 
* qui net install http://www.stata.com/stb/stb56/dm79.pkg

//SET UP RELEVANT PATHS
// path to energy-code-release repo 
global root "C:/Users/TomBearpark/Documents/energy-code-release-2020"


//install global programs
do $root/2_projection/0_packages_programs_inputs/projection_set_up/csvv_generation_stacked.do

******** Choose model *****************************

//Model type-- Options: TINV_clim_lininter, TINV_clim_lininter_double
local model_tt "TINV_clim"


************************************************
*Step 1: Set up common resources across scripts
************************************************

// ster stem for desired projection 
local stem = "FD_FGLS_inter"

// path to analysis data 
local DATA "$root/data"	

// path to csvv output
local output_csvv "$root/projection_inputs"

// path to dataset with information about income deciles and income spline knot location
local break_data "$root/data/break_data_TINV_clim.dta"



***************************************************
*Step 2: Generate CSVV
***************************************************

// step 1: write csvvs

foreach product in "other_energy" "electricity" {

	write_csvv , datapath("`DATA'")	outpath("`output_csvv'") root("$root") ///
		model("`model_tt'") clim_data("GMFD") spec_stem("`stem'") ///
		grouping_test("semi-parametric") product("`product'") bknum("break2") ///
		zero_case("Exclude") issue_case("_all-issues") data_type("replicated_data")	
	
	local coefficientlist_`product' `s(coef_list)'

}

// step 2: write stacked regression full vcv 

//get number of coefficients
preserve

	load_spec_csv , specpath("$root/2_projection/0_packages_programs_inputs/projection_set_up") model("`model_tt'")
	local num_coefficients = `r(nc)'
	local all_coefficients = 2 * `num_coefficients' * 20 // 2 poly order, 10 income deciles, 2 products
	return clear

restore

//write file full vcv. This is combined for electricity and other_energy
file open csvv using "`output_csvv'/`model_tt'/`stem'_OTHERIND_`model_tt'.csvv", write replace

write_vcv , ///
	coefficientlist(" `coefficientlist_other_energy' `coefficientlist_electricity' ") ///
	 num_coefficients(`all_coefficients')

file close csvv
