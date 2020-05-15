* TOM TO DO - change this so we use the function from the DF repo. 


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
	* 3) Runs a second regression in which GMST is interacted linearly with time. This regression uses
			only data from the second half of the century, given irregular early year behavior documented
			in mortality
	* 4) Predicts damage function coefficients for all years 2015-2300, with post-2100 extrapolation 
			conducted using the linear temporal interaction model and pre-2100 using the nonparametric model
	* 5) Saves a csv of damage function coefficients to be used by the SCC calculation derived from the FAIR 
			simple climate model
	
Note on input file names: This script expects a .csv with a filename formatted as follows:

		'sector'_'scale'_damages_with_gmt_anom_'ff'_SSP'num'.csv 
	
		Where 'sector' is the sector of impacts -- e.g. "mortality" or "energy"
		Where 'scale' is either "global" or "local"
		Where 'ff' is "poly4" or "bins" or ... (other functional forms)
		Where 'num' is the number of the SSP -- e.g. 3 
		
* T. Carleton 2018-06-17

*** NOTE: Updated 10-08-18 to include a constraint that the fitted functions pass
*** 	  through (0,0) where 0 on the x-axis refers to the 2001-2010 GMST value

*/

**********************************************************************************
* SET UP -- Change paths and input choices to fit desired output
**********************************************************************************
* Tom - updating code to work for energy 
* Run quantile regs on battuta!

clear all
set more off
set scheme s1color

glob DB "C:/Users/TomBearpark/Dropbox"
glob DB_data "$DB/GCP_Reanalysis/ENERGY/code_release_data"
glob dir "$DB_data/damage_function_estimation/resampled_data"

glob root "C:/Users/TomBearpark/Documents/energy-code-release"
glob output "$root/figures/"

* SSP
loc ssp = "3" 

* What year do we use data for determining DF estimates used for the out of sample extrapolation
loc subset = 2085

* list of the variables we want to run a damage function for 
if("`ssp'" = "SSP3") {
	loc pricelist = "price014 price0 price03 WITCHGLOBIOM42 MERGEETL60 REMINDMAgPIE1730 REMIND17CEMICS REMIND17" 
}

**********************************************************************************
* STEP 1: Pull in and format each price scenarios csv
**********************************************************************************
foreach price in 


import delim "$input/global_damages_SSP`ssp'.csv", clear


merge m:1 year rcp gcm using "$dbroot/Global ACP/damage_function/GMST_anomaly/GMTanom_all_temp_2001_2010", nogen keep(3)

* line *energy year if rcp == "rcp85" & iam == "high" & gcm == "ACCESS1-0"

sort rcp gcm iam year 
drop if year < 2010
ren temp anomaly

tempfile clean_damages
save "`clean_damages'", replace

* loc yr = 2016

**********************************************************************************
* STEP 3: Regressions & construction of time-varying damage function coefficients 
**********************************************************************************


**  INITIALIZE FILE WE WILL POST RESULTS TO
capture postutil clear
tempfile coeffs
postfile damage_coeffs str20(var_type) year cons beta1 beta2 anomalymin anomalymax using "`coeffs'", replace

gen t = year-2010

timer clear
timer on 1


** Regress, and output coeffs	
foreach vv in `vvlist' {
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
	
	* Linear extrapolation for years post-2100 (use only later years bc Sol thinks fit will be better)
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
* STEP 4: WRITE AND SAVE OUTPUT 
**********************************************************************************

* save and write out results
clear 
use "`coeffs'", clear
replace var_type = substr(var_type, 1, strpos(var_type,"_")-1)
if "`quantilereg'" == "false" {
	gen placeholder = "ss"
	ren var_type growth_rate
	order year placeholder growth_rate
	outsheet using "$output/df_mean_output_SSP`ssp'.csv", comma replace	
	di "saving at $output/df_mean_output_SSP`ssp'.csv"
}
else if "`quantilereg'" == "true" {
	outsheet using "$output/qreg/qreg_output_SSP`ssp'.csv", comma replace	
}

