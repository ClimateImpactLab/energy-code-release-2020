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

glob dir_output "$DB_data/referee_comments/damage_function_estimation"
glob dir "$DB_data/projection_system_outputs/damage_function_estimation"

* SSP toggle - options are "SSP2", "SSP3", or "SSP4"
loc ssp = "SSP3" 

* Model toggle  - options are "main", "lininter", or "lininter_double", "lininter_half"
loc model = "main"

* What year do we use data from for determining DF estimates used for the out of sample extrapolation
*loc subset = 2085


foreach subset in 2085 2050 2010 {
	******************************************
	* Set locals based on options 
	* We run only the price014 scenario, except for SSP3 main model

	if("`model'" == "main") {
		
		loc model_tag = ""

		if ("`ssp'" == "SSP3") {
			loc pricelist price014 price0 price03 WITCHGLOBIOM42 MERGEETL60 REMINDMAgPIE1730 REMIND17CEMICS REMIND17
		}
		else {
			loc pricelist price014 
		}
	} 
	else if (inlist("`model'", "lininter", "lininter_double", "lininter_half")){
		loc model_tag = "_`model'"
		assert("`ssp'" == "SSP3")
		loc pricelist price014 
	}

	**********************************************************************************
	* STEP 1: Pull in and format each price scenarios csv
	**********************************************************************************
	foreach price in `pricelist' {
		di "`price'"
		import delim "$dir/impact_values/gcm_damages_OTHERIND_total_energy_`price'_`ssp'`model_tag'.csv", clear
		keep rcp year gcm iam mean
		ren mean `price'
		tempfile `price'
		save ``price'', replace 
	}

	local price1 : word 1 of `pricelist'
	local pricelist_sub: list pricelist- `price1'

	use ``price1'', clear
	foreach price in `pricelist_sub' {
		merge 1:1 rcp year gcm iam using ``price'', nogen assert(3)
	}

	* Merge in GMST anomaly data 
	preserve
		insheet using "$DB_data/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010_smooth.csv", comma names clear
		tempfile GMST
		save `GMST', replace
	restore
	merge m:1 year rcp gcm using `GMST', nogen keep(3)
	sort rcp gcm iam year 
	drop if year < 2010
	ren temp anomaly
	tempfile raw
	save `raw'


	import delimited using "/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv", clear
	replace gdp = gdp  / 100 / 1000000000
	drop if year == 2100

	merge 1:n year using `raw'

	foreach price in `pricelist_sub' {
		replace `price' = `price' / gdp
	}

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
		foreach yr of numlist 2015/2099 {
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
	di "$dir_output/coefficients/df_mean_output_`ssp'`model_tag'_percent_gdp_`subset'.csv"

	outsheet using "$dir_output/coefficients/df_mean_output_`ssp'`model_tag'_percent_gdp_`subset'.csv", comma replace	
}



