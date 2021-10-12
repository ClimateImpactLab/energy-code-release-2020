*****************************************
* Quantile regression for SCC uncertainty 
* CALCULATION INCLUDING POST-2100 EXTRAPOLATION
*****************************************
/* 
This script does the following:
	* 1) Pulls in a .csv containing damages at global or impact region level. The .csv 
			should be SSP-specific, and contain damages in current year USD for every
			RCP-GCM-IAM-year combination. 
	* 2) Runs a quantile regression in which the quantiles of the damage function are 
			nonparametrically estimated for each year 't'
			using data only from the 5 years around 't'
	* 3) Runs a second regression in which GMST is interacted linearly with time. 
	* 4) Predicts quantile regression coefficients for all years 2015-2300, with post-2100 extrapolation 
			conducted using the linear temporal interaction model and pre-2100 using the nonparametric model
	* 5) Saves a csv of quantile regression coefficients to be used by the SCC uncertainty calculation derived from the FAIR 
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

* Note: this code is only set up to run quantile regressions for SSP3-main model. 
loc model = "main"
loc ssp = "SSP3" 

******************************************
* Set locals based on options 

if("`model'" == "main") {
	loc model_tag = ""
}

* list of the scenarios we want to run a damage function for 
if("`ssp'" == "SSP3") {
	loc pricelist price014 price0 price03 WITCHGLOBIOM42 MERGEETL60 REMINDMAgPIE1730 REMIND17CEMICS REMIND17
}

* Get a list of the quantiles we want to run the quantile regression for 
forvalues pp = 5(5)95 {
	di "`pp'"
	loc p = `pp'/100
	loc quantiles_to_eval "`quantiles_to_eval' `p'"
}
di "`quantiles_to_eval'"

**********************************************************************************
* STEP 1: Pull in and format randomly sampled damages csvs
**********************************************************************************


foreach price in `pricelist' {
	di "`price'"
	import delim "$dir/resampled_data/gcm_damages_OTHERIND_total_energy_`price'_`ssp'`model_tag'-100-draws.csv", clear case(preserve)
	keep rcp year gcm iam `price'value batch
	ren `price'value `price'
	tempfile `price'
	save ``price'', replace 
}

local price1 : word 1 of `pricelist'
local pricelist_sub: list pricelist- `price1'

use ``price1'', clear
foreach price in `pricelist_sub' {
	merge m:1 rcp year gcm iam batch using ``price'', nogen assert(3)
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

**********************************************************************************
* STEP 2: Quantile regressions & construction of time-varying damage function coefficients 
**********************************************************************************


* What year do we use data from for determining DF estimates used for the out of sample extrapolation
loc subset = 2085

**  INITIALIZE FILE WE WILL POST RESULTS TO
capture postutil clear
tempfile coeffs
postfile damage_coeffs str20(var_type) year pctile cons beta1 beta2 anomalymin anomalymax using "`coeffs'", replace		


** Regress, and output coeffs	
gen t = year-2010

timer clear
timer on 1

foreach vv in `pricelist' {
	foreach pp of numlist `quantiles_to_eval' {
		di "`pp'"
		* Nonparametric model for use pre-2100 
		foreach yr of numlist 2015/2099 {	
			di "`vv' `yr' `pp'"		
			* Need to save the min and max temperature for each year for plotting
			qui summ anomaly if year == `yr', det 
			loc amin = `r(min)'
			loc amax =  `r(max)'
			
			cap qreg `vv' c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2, quantile(`pp')

			if _rc!=0 {
				di "didn't converge first time, so we are upping the iterations and trying again"
				cap qui qreg `vv' c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2, quantile(`pp') wlsiter(20)
				if _rc!=0 {
					di "didn't converge second time, so we are upping the iterations and trying again"
					cap qui qreg `vv' c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2, quantile(`pp') wlsiter(40)
					if _rc!=0 {
						di "didn't converge after trying some pretty high numbers for iterations - somethings probably wrong here!"
						break
					}
				}
			}
		
			* Save coefficients for all years prior to 2100
			post damage_coeffs ("`vv'") (`yr') (`pp') (_b[_cons]) (_b[anomaly]) (_b[c.anomaly#c.anomaly]) (`amin') (`amax')
		}
		
		* Linear extrapolation for years post-2100 
		qui qreg `vv' c.anomaly##c.anomaly##c.t if year >= `subset', quantile(`pp')

		foreach yr of numlist 2100/2300 {
			di "`vv' `yr' `pp'"
			loc cons = _b[_cons] + _b[t]*(`yr'-2010)
			loc beta1 = _b[anomaly] + _b[c.anomaly#c.t]*(`yr'-2010)
			loc beta2 = _b[c.anomaly#c.anomaly] + _b[c.anomaly#c.anomaly#c.t]*(`yr'-2010)
			
			* NOTE: we don't have future min and max, so assume they go through all GMST values 	
			post damage_coeffs ("`vv'") (`yr') (`pp') (`cons') (`beta1') (`beta2') (0) (11)		
		}
	}
}

postclose damage_coeffs
timer off 1
timer list
di "Time to completion = `r(t1)'"

**********************************************************************************
* STEP 3: WRITE AND SAVE OUTPUT 
**********************************************************************************
 
use "`coeffs'", clear
outsheet using "$dir/coefficients/df_qreg_output_`ssp'`model_tag'.csv", comma replace
