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

//foreach submodel in "plininter" "decinter" "p80elecinter" {
 
foreach submodel in  "coldside" {

	global submodel "`submodel'"
	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/stacked.do
} 


********************************************************************************
* Step 2: Plot Energy Temperature Response
********************************************************************************
 
foreach product in "other_energy" "electricity" {		
	global product "`product'"
<<<<<<< HEAD
	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_plininter.do
	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_plininter_2099.do
	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_decinter.do
	foreach submodel in "p80elecinter" "codeside" {
		global submodel "`submodel'"
		do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_post1980.do
		do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_post1980_2099.do
	}
=======
//	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_plininter.do
//	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_plininter_2099.do
//	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_decinter.do
//	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_p80elecinter.do
//	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_stacked_p80elecinter_2099.do

>>>>>>> bb159e9d38b13b3d43b6803a85c6f7f72b2b8bdd
}


********************************************************************************
* Step 3: Plot Marginal Effect of Time on Energy Temperature Response 
* for Temporal Trend Model
********************************************************************************
  
 foreach product in "other_energy" "electricity" {
	global product "`product'"
//	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_time_marginal_effect_plininter.do
//	do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_time_marginal_effect_over_time_plininter.do
	
} 

global product "electricity"
//do $root/4_misc/referee_comment_replies/time_interaction_alt_forms/interacted_regression/plot_time_marginal_effect_p80elecinter.do

