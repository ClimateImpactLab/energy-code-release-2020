/*
Purpose: 
	1. Estimate and Plot stacked income x climate energy-temperature response for 
	piecewise linear time effect and decadal time interaction
	2. Plot change in energy temp response per year for Temporal Trend Model
*/

clear all
set more off
macro drop _all
cilpath
/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

* path to energy-code-release repo:

global root "${REPO}/energy-code-release-2020"

/////////////////////////////////////////////////////////////////////////////////////////////////

******Set Script Toggles********************************************************

// What model do you want?
global model "TINV_clim"

********************************************************************************
* Step 1: Estimate Energy Temperature Response
********************************************************************************

foreach submodel in "plininter" "decinter"  {

	global submodel "`submodel'"
	do $root/4_misc/time_interaction_alt_forms/interacted_regression/stacked.do
} 


********************************************************************************
* Step 2: Plot Energy Temperature Response
********************************************************************************

/* foreach product in "other_energy" "electricity" {
	foreach submodel in  "plininter" "decinter"  {
		
		global submodel_ov "`submodel'"
		global product "`product'"
		do $root/4_misc/time_interaction_alt_forms/plot_stacked.do

	}
}
  */
********************************************************************************
* Step 3: Plot Marginal Effect of Time on Energy Temperature Response 
* for Temporal Trend Model
********************************************************************************
 
/* foreach product in "other_energy" "electricity" {
	foreach submodel in  "plininter" "decinter"  {
		global product "`product'"
		do $root/4_misc/time_interaction_alt_forms/plot_time_marginal_effect.do
//	do $root/1_analysis/interacted_regression_year_centered/plot_time_marginal_effect.do
//	do $root/1_analysis/interacted_regression_year_centered/plot_time_marginal_effect_quadinter.do

}
 */

********************************************************************************
* Step 4: Extra Plots Energy Temperature Response (insample)
********************************************************************************
 
/* foreach product in "other_energy" "electricity" {
	foreach submodel in "lininter" "quadinter" {
		
		global submodel_ov "`submodel'"
		global product "`product'"
		do $root/1_analysis/interacted_regression_year_centered/plot_stacked_insample.do

	}
}
 */
