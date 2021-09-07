/*

Purpose: Create CSVV's required for projections  
*/

clear all
set more off
macro drop _all
pause off
global LOG: env LOG
log using $LOG/2_projection/1_prepare_projection_files/1_generate_csvv.log, replace

* Download a command for dealing with matrices 
qui net install http://www.stata.com/stb/stb56/dm79.pkg

//SET UP RELEVANT PATHS

global REPO: env REPO
global DATA: env DATA 
global OUTPUT: env OUTPUT 

// path to energy-code-release repo 
global root "${REPO}/energy-code-release-2020"

//install global programs
do $root/2_projection/0_packages_programs_inputs/projection_set_up/csvv_generation_stacked.do


************************************************
*Step 1: Set up common resources across models
************************************************

// ster stem for desired projection  
local ster_stem = "FD_FGLS_inter"

// path to analysis data 
local DATA "$DATA"

// path to csvv output
local output_csvv "$root/projection_inputs/csvv"
cap mkdir "`output_csvv'"

// path to dataset with information about income deciles and income spline knot location
local break_data "$DATA/regression/break_data_TINV_clim.dta"

* Loop over model type - creating csvvs for each type. 
* Note TINV_clim_lininter_double and TINV_clim_lininter_half are exactly the same csvv as TINV_clim_lininter
* Hence we copy the csvv made for TINV_clim_lininter
* 
foreach model_tt in "TINV_clim" "TINV_clim_lininter" "TINV_clim_lininter_double" "TINV_clim_lininter_half" {
	
	di "`model_tt'"
	if(inlist("`model_tt'", "TINV_clim", "TINV_clim_lininter")){

		***************************************************
		*Step 2: Generate CSVV
		***************************************************

		// step 1: write csvvs

		foreach product in "other_energy" "electricity" {

			write_csvv , datapath("`DATA'/regression/")	outpath("`output_csvv'") root("$root") ///
				model("`model_tt'") clim_data("GMFD") spec_stem("`ster_stem'") ///
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
		file open csvv using "`output_csvv'/`model_tt'/`ster_stem'_OTHERIND_`model_tt'.csv", write replace
		write_vcv , ///
			coefficientlist(" `coefficientlist_other_energy' `coefficientlist_electricity' ") ///
			 num_coefficients(`all_coefficients')
		di "test"
		file close csvv
	}
	else if("`model_tt'" == "TINV_clim_lininter_double"){

		cap mkdir "`output_csvv'/TINV_clim_lininter_double"
		foreach product in "_other_energy" "_electricity"{
			copy "`output_csvv'/TINV_clim_lininter/FD_FGLS_inter_OTHERIND`product'_TINV_clim_lininter.csvv" ///
				"`output_csvv'/TINV_clim_lininter_double/FD_FGLS_inter_OTHERIND`product'_TINV_clim_lininter_double.csvv", replace 
		}
		copy "`output_csvv'/TINV_clim_lininter/FD_FGLS_inter_OTHERIND_TINV_clim_lininter.csv" ///
		"`output_csvv'/TINV_clim_lininter_double/FD_FGLS_inter_OTHERIND_TINV_clim_lininter_double.csv", replace 
	}
 	else if("`model_tt'" == "TINV_clim_lininter_half"){
 		cap mkdir "`output_csvv'/TINV_clim_lininter_half"
		foreach product in "_other_energy" "_electricity"{
			copy "`output_csvv'/TINV_clim_lininter/FD_FGLS_inter_OTHERIND`product'_TINV_clim_lininter.csvv" ///
				"`output_csvv'/TINV_clim_lininter_half/FD_FGLS_inter_OTHERIND`product'_TINV_clim_lininter_half.csvv", replace 
		}
		copy "`output_csvv'/TINV_clim_lininter/FD_FGLS_inter_OTHERIND_TINV_clim_lininter.csv" ///
			"`output_csvv'/TINV_clim_lininter_half/FD_FGLS_inter_OTHERIND_TINV_clim_lininter_half.csv", replace 
	}
}

log close _all

