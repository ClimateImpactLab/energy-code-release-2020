* li paper comparison damage function

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
glob dir "$DB_data/referee_comments/li_et_al"

* SSP toggle - options are "SSP2", "SSP3", or "SSP4"
*loc ssp = "SSP3" 

* Model toggle  - options are "main", "lininter", or "lininter_double"
*loc model = "lininter_double"

* What year do we use data from for determining DF estimates used for the out of sample extrapolation
*loc subset = 2085


**********************************************************************************
* STEP 1: Pull in and format each price scenarios csv
**********************************************************************************
foreach ver in shanghai_impact shanghai_impact_nosurrogates {
	import delim "${dir}/`ver'_2097_electricity.csv", clear
	keep rcp year gcm iam value

	* Merge in GMST anomaly data 
	preserve
		insheet using "$DB_data/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010.csv", comma names clear
		tempfile GMST
		save `GMST', replace
	restore

	merge m:1 year rcp gcm using `GMST', nogen keep(3)
	sort rcp gcm iam year 
	keep if year >= 2095 & year <= 2099
	ren temp anomaly
	ren value impact_pct
	loc pricelist impact_pct

	**********************************************************************************
	* STEP 2: Regressions & construction of time-varying damage function coefficients 
	**********************************************************************************

	**  INITIALIZE FILE WE WILL POST RESULTS TO
	capture postutil clear
	tempfile coeffs
	postfile damage_coeffs str20(var_type) year cons beta1 beta2 anomalymin anomalymax using "`coeffs'", replace

	gen t = year-2010

	** Regress, and output coeffs	
	foreach vv in `pricelist' {
		* Nonparametric model for use pre-2100 
		foreach yr of numlist 2095/2095 {
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
	    qui reg `vv' c.anomaly##c.anomaly##c.t  	
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

	outsheet using "${dir}/`ver'_2097_electricity_damage_function_coefficients.csv", comma replace
}	
