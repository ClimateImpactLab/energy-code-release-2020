*****************************************
* DAMAGE FUNCTION ESTIMATION FOR SCC 
* CALCULATION INCLUDING POST-2100 EXTRAPOLATION
*****************************************
/* 
This script does the following:
	* 1) Pulls in a .csv containing damages at global or impact region level. The .csv 
			should be SSP-specific, and contain damages in current year USD for every
			RCP-GCM-IAM-year combination. 
	* 2) Runs a regression in which the damage function is nonparametrically estimated for each year 't'
			using data only from the 5 years around 't'
	* 3) Runs a second regression in which GMST is interacted linearly with time. 
	* 4) Predicts damage function coefficients for all years 2015-2300, with post-2100 extrapolation 
			conducted using the linear temporal interaction model and pre-2100 using the nonparametric model
	* 5) Saves a csv of damage function coefficients to be used by the SCC calculation derived from the FAIR 
			simple climate model
*/
**********************************************************************************
* SET UP -- Change paths and input choices to fit desired output
**********************************************************************************

clear all
set more off
set scheme s1color

glob DB "/mnt"
glob DB_data "$DB/CIL_energy/code_release_data_pixel_interaction"
glob dir "$DB_data/projection_system_outputs/damage_function_estimation"

* SSP toggle - options are "SSP2", "SSP3", or "SSP4"
loc ssp = "SSP3" 

* Model toggle  - options are "main", "lininter", "lininter_double", or "lininter_half","mixed"
loc model = "main"

* What year do we use data from for determining DF estimates used for the out of sample extrapolation
loc subset = 2085


import delim using "/home/liruixue/repos/labor-code-release-2020//data/misc/energy_damage_function_points_integration.csv", clear
rename global_damages_constant_model_co price014
**  INITIALIZE FILE WE WILL POST RESULTS TO
capture postutil clear
tempfile coeffs
postfile damage_coeffs str20(var_type) year cons beta1 beta2 anomalymin anomalymax using "`coeffs'", replace

gen t = year-2010

loc pricelist price014
destring anomaly, replace force


** Regress, and output coeffs	
foreach vv in `pricelist' {
	* Nonparametric model for use pre-2100 
	foreach yr of numlist 2020/2099 {
		di "`vv' `yr'"
		qui reg `vv' c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2 
		
		* Need to save the min and max temperature for each year for plotting
		qui summ anomaly if year == `yr', det 
		loc amin = `r(min)'
		loc amax =  `r(max)'
		
		* Save coefficients for all years prior to 2100
		post damage_coeffs ("`vv'") (`yr') (_b[_cons]) (_b[anomaly]) (_b[c.anomaly#c.anomaly]) (`amin') (`amax')
	}
	
	* Linear extrapolation for years post-2100 
    qui reg `vv' c.anomaly##c.anomaly##c.t  if year >= `subset'
	
	* Generate predicted coeffs for each year post 2100 with linear extrapolation
	foreach yr of numlist 2100/2300 {
		di "`vv' `yr'"
		loc cons = _b[_cons] + _b[t]*(`yr'-2010)
		loc beta1 = _b[anomaly] + _b[c.anomaly#c.t]*(`yr'-2010)
		loc beta2 = _b[c.anomaly#c.anomaly] + _b[c.anomaly#c.anomaly#c.t]*(`yr'-2010)
		
		* NOTE: we don't have future min and max, so assume they go through all GMST values 	
		post damage_coeffs ("`vv'") (`yr') (`cons') (`beta1') (`beta2') (0) (11)						
	}		
}

postclose damage_coeffs

**********************************************************************************
* STEP 3: WRITE AND SAVE OUTPUT 
**********************************************************************************

* Format for the specific requirements of the SCC code, and write out results 
use "`coeffs'", clear

gen placeholder = "ss"
ren var_type growth_rate
order year placeholder growth_rate

format cons beta1 beta2 %20.0f

outsheet using "$dir/coefficients/df_mean_output_`ssp'`model_tag'_integration.csv", comma replace	
