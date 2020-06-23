/*

Purpose: Master Do File for writing projection system configs 

Creates:
- run configs, 
- model configs, 
- aggregate configs, 
- extraction configs.

note: script currently assumes your repos on sac are located at 
/home/`uname'/repos/ or on brc at /global/scratch/`uname'/repos/ conform 
or add the functionality to get the code to conform to your needs... i'm happy with either

*/

clear all
set more off
macro drop _all
pause on

// path to energy-code-release repo 
* global root "C:/Users/TomBearpark/Documents/energy-code-release-2020"
global root "/home/tbearpark/repos/energy-code-release-2020"

loc uname "tbearpark"

* Set root location where config and shell files will be generated
loc GIT $root/projection_inputs

//install global programs
qui do $root/2_projection/0_packages_programs_inputs/projection_set_up/write_projection_file.do

// which ssps do you want to project results for?
local ssp_list  "SSP3" //"[SSP2, SSP4] " //"'SSP3'"


******Set Script Toggles********************************************************

// do you want to write module/model, run, and aggregation configs?
local write_projection_files "TRUE"

// do you want to write extraciton configs?
local write_extraction_files "TRUE"

// which prices do you want to generate aggregation and extraction configs for? 
local price_list = " price014 price0 price03 WITCHGLOBIOM42_rcp45 WITCHGLOBIOM42_rcp85 REMINDMAgPIE1730_rcp85 REMINDMAgPIE1730_rcp45 REMIND17CEMICS_rcp85 REMIND17CEMICS_rcp45 REMIND17_rcp85 REMIND17_rcp45 MERGEETL60_rcp85 MERGEETL60_rcp45 "


******** Set parameters for model specification *****************************

//Set data type ie historic or replicated
local data_type "replicated_data"

//What happens to Zeroes: currently dealt with in 0_merge so here we just drop the 
//zeroes that were to set to zero previously based on Exclude rule
//exclude rule: 0 if TOTOTHER or TOTIND is missing or zero
local case "Exclude" //"Exclude" "Include"

//Breakdown of fuels and products: break2 --> only two groups other_energy and electricity
local bknum "break2"

//income grouping test: 
local grouping_test "semi-parametric" 

//Issue Fix	
local IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues

//Model type-- Options: TINV_clim_income_spline, TINV_clim_income_spline_lininter, TINV_clim_income_spline_lininter_double
local model_tt "TINV_clim_income_spline"

//Climate Data type
local clim_data "GMFD"

****************************************************************************************

************************************************
*Step 1: Set up common resources across scripts
************************************************
local CSVVpath_output_sacagawea "/shares/gcp/social/parameters/energy/incspline0719/`clim_data'/`model_tt'" 

// ster stem for desired projection 
local stem = "FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2"

// path to analysis data 
local DATA "$root/data"	

// Set up config and shell file storage
local model_bc "`bknum'_`case'" 

foreach file_type in "configs" "shells" {
	
	local OUTPUT "`GIT'/`file_type'"
	cap mkdir "`OUTPUT'"
	
	foreach file in "clim_data" "model_tt" "model_bc" "grouping_test" {
		di "`file'"
		local OUTPUT "`OUTPUT'/``file''"
		cap mkdir "`OUTPUT'"
	}

	global OUTPUT_`file_type' "`OUTPUT'"
	di "$OUTPUT_`file_type'"
}

// path to dataset with information about income deciles and income spline knot location
local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/`data_type'/"	
local break_data "`DATA'/data/break10_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_TINV_clim_`data_type'.dta"

pause

// path to dataset with information about income deciles and income spline knot location
local break_data "$root/data/break_data_TINV_clim.dta"

// paths to where to store two different types of configs
local projection_config_output "$OUTPUT_configs/Projection_Configs"
local extraction_config_output "$OUTPUT_configs/Extraction_Configs"

***************************************************
*Step 2: Generate Projection Inputs
***************************************************

foreach product in "electricity" "other_energy" {

	local single_folder "single-OTHERIND_`product'_FD_FGLS_719_`case'`IF'_`bknum'_`grouping_test'_`model_tt'_`clim_data'"
	local median_folder "median_OTHERIND_`product'_`model_tt'_`clim_data'"
	local csvv "`stem'_OTHERIND_`product'_`model_tt'"
	
	foreach proj_mode in "_dm" "" {

		foreach proj_type in "median" "diagnostics" {
			foreach sys in "sacagawea" {

				di "Writing run configs..."

			 	write_run_config , product("`product'") proj_type("`proj_type'") proj_mode("`proj_mode'") break_data("`break_data'") ///
			 	 single_folder("`single_folder'") median_folder("`median_folder'") proj_model("`model_tt'") sys("`sys'") ///
			 	 config_output("`projection_config_output'") uname("`uname'") ///
			 	 do_farmers("true") ssp_list("`ssp_list'")

			 	 foreach unit in "impactpc" "damagepc" "damage" {

			 	 	if strpos("`unit'", "damage") > 0 local price_list_edited `price_list'
					else local price_list_edited ""

				 	 foreach price_scen in "" `price_list_edited' {
				 	 	
				 	 	di "Writing aggregation configs..."

						if (("`price_scen'" != "" & strpos("`unit'", "damage") > 0) |  (strpos("`unit'", "impact") > 0 & "`price_scen'" == "")) {

							write_aggregate_config ,  product("`product'") sys("`sys'") proj_type("`proj_type'") proj_model("`model_tt'") unit("`unit'") ///
							 price_scen("`price_scen'") proj_mode("`proj_mode'") config_output("`projection_config_output'") /// 
							 uname("`uname'") single_folder("`single_folder'") median_folder("`median_folder'")
						}
				 	 }
				 }

				di "Writing model configs..."
				write_model_config , product("`product'") proj_type("`proj_type'") proj_mode("`proj_mode'") break_data("`break_data'") ///
				 csvv("`csvv'") proj_model("`model_tt'") config_output("`projection_config_output'") ///
				 csvv_path("`CSVVpath_output_`sys''") brief_output("TRUE")

			}
		}
		
		foreach unit in "-damage" "-damagepc" "-impactpc" {

			if strpos("`unit'", "damage") > 0 local price_list_edited `price_list'
			else local price_list_edited ""

			foreach price_scen in "" `price_list_edited' {
				foreach geo_level in "-levels" "-aggregated" {
					foreach uncertainty in "values" "full" "climate" {

							get_evalqvals , uncertainty("`uncertainty'")
							local evalqvals `s(evqvs)'
							return clear

							****** break out of loop if combination of parameters that we don't want configs for

							* can't generate damages if price scenario is blank 
							if ("`price_scen'" == "" & strpos("`unit'", "damage") > 0) {
								continue, break
							}

							* can't generate impacts if price scenario is not blank

							if ("`price_scen'" != "" & strpos("`unit'", "impact") > 0) {
								continue, break
							}

							* at the moment we don't generate dm output for full or climate uncertainty

							if (inlist("`uncertainty'", "climate", "full") & strpos("`proj_mode'", "dm")) {
								continue, break
							}


							di "Writing extraction configs"
							
							if (strpos("`unit'", "impact") == 0) local ps_name "-`price_scen'" 
							else local ps_name ""

							write_extraction_config , product("`product'") proj_mode("`proj_mode'") median_folder("`median_folder'") price_scen("`ps_name'") ///
							  geo_level("`geo_level'") uncertainty("`uncertainty'") unit("`unit'") proj_model("`model_tt'") ///
							  config_output("`extraction_config_output'") ///
							  csvv("`csvv'") ///
							  extraction_output("/shares/gcp/social/parameters/energy/extraction/multi-models/rationalized_code/`bknum'_`case'`IF'_`grouping_test'/`model_tt'_`clim_data'/`median_folder'") ///
							  evalqvals("`evalqvals'")
					}
				}
			}
		}
	
	}
}

* Total energy extraction

foreach unit in "-damage" "-damagepc" {
	foreach price_scen in `price_list' {

		if (strpos("`unit'", "impact") == 0) local ps_name "-`price_scen'" 

		foreach geo_level in "-levels" "-aggregated" {
			foreach uncertainty in "full" "values" "climate" {

				get_evalqvals , uncertainty("`uncertainty'")
				local evalqvals `s(evqvs)'
				return clear

				// order here matters with respect to the full uncertainty _dm break below
				foreach proj_mode in "" "_dm" {

					// median folder implicitly: "median_OTHERIND_`product'_`model_tt'_`clim_data'" adjust if desired in write_2product_results_root()

					// do not put proj_mode _dm in when getting full uncertainty... both modes for full uncertainty anyways
					if ( "`proj_mode'" == "_dm" & "`uncertainty'" == "full" ) {
						continue, break
					}

					* can't generate damages if price scenario is blank 
					if ("`price_scen'" == "" & strpos("`unit'", "damage") > 0) {
						continue, break
					}

					di "writing config for `uncertainty' uncertainty..."

					write_extraction_config , product_list(" other_energy electricity ") proj_mode("`proj_mode'") price_scen("`ps_name'") ///
					  geo_level("`geo_level'") uncertainty("`uncertainty'") unit("`unit'") proj_model("`model_tt'") ///
					  config_output("`extraction_config_output'") two_product("TRUE") ///
					  csvv("`csvv'") csvv_path("`CSVVpath_output_sacagawea'") ///
					  extraction_output("/shares/gcp/social/parameters/energy/extraction/multi-models/rationalized_code/`bknum'_`case'`IF'_`grouping_test'/`model_tt'_`clim_data'/total_energy") ///
					  evalqvals("`evalqvals'")
				}
			}
		}
	}
}


