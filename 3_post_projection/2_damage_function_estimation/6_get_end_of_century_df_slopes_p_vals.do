
/*

Purpose: get the slope and p values (or confidence intervals) of damage function at end of century

*/

clear all
set more off
set scheme s1color




global REPO: env REPO
global DATA: env DATA 
global OUTPUT: env OUTPUT 

global LOG: env LOG
log using $LOG/3_post_projection/2_damage_function_estimation/plot_damage_function_fig_3.log, replace


glob dir "$OUTPUT/projection_system_outputs/damage_function_estimation/resampled_data"
glob root "${REPO}/energy-code-release-2020"
glob output "$OUTPUT/figures/"


* Load in GMTanom data file, save as a tempfile 
insheet using "$OUTPUT/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010_smooth.csv", comma names clear
drop if year < 2015 | year > 2099
drop if temp == .
tempfile GMST_anom
save `GMST_anom', replace

* **********************************************************************************
* * STEP 1: Pull in Damage CSVs and Merge with GMST Anomaly Data
* **********************************************************************************

foreach fuel in "total_energy_price014" "electricity" "other_energy" {

	di "`fuel'"

	if("`fuel'"=="total_energy_price014"){
		loc type = "damages"
	}
	else{
		loc type = "impacts"
	}
	
	import delim using "$dir/gcm_`type'_OTHERIND_`fuel'_SSP3-15-draws.csv", clear
	drop if year < 2015 | year > 2099
	merge m:1 year gcm rcp using `GMST_anom', nogen assert(3)

	tempfile master`fuel'
	save `master`fuel'', replace

	qui bysort year: egen minT=min(temp)
	qui bysort year: egen maxT=max(temp)
	qui replace minT=round(minT,0.1)
	qui replace maxT=round(maxT,0.1)
	qui keep year minT maxT
	qui duplicates drop year, force

	merge 1:m year using `master`fuel'', nogen assert(3)
	ren *alue `fuel'
	save `master`fuel'', replace
}
use `mastertotal_energy_price014'
foreach fuel in  "electricity" "other_energy"{
	merge 1:1 year minT maxT rcp gcm iam batch temp using `master`fuel'', nogen assert(3)
}

tempfile master
save `master', replace

* **********************************************************************************
* * STEP 2: Estimate damage functions and plot, compute slope and p values
* **********************************************************************************

cap rename temp anomaly

* Use this local to determine whether we want consistent scales across other energy
* and electricity plots

foreach fuel in "total_energy_price014" "other_energy" "electricity" {
	preserve


		if "`fuel'" == "electricity" || "`fuel'" == "other_energy" {
			replace `fuel' = `fuel'/ 1000000000
		}

		* Display the slope of this damage function in 2099
		loc yr 2097
		reg `fuel' c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2 

		predict yhat_`fuel'_`yr' if year>=`yr'-2 & year <= `yr'+2 

		* Get min and max values of the anomaly and fitted values, calcualte the slope.
		sum anomaly if year>=`yr'-2 & year <= `yr'+2 
		loc xmax = r(max)
		loc xmin = r(min)
		loc Dx = r(max) - r(min)
		sum yhat_`fuel'_`yr' if year>=`yr'-2 & year <= `yr'+2 
		loc Dy = r(max) - r(min)

		loc slope = `Dy'/`Dx'
		di "average slope is `slope'"

		* Calculate the standard error (and p value) of the slope using predict
		predictnl slope = _b[anomaly]  + _b[anomaly#c.anomaly] * (`xmax' ^2 - `xmin' ^2) / (`Dx') if year>=`yr'-2 & year <= `yr'+2  , p(p) ci(lower upper) 

		scatter yhat_`fuel'_`yr' anomaly if year>=`yr'-2 & year <= `yr'+2, title("`fuel'")

		* Clean up and save as a temp file 
		keep slope p lower upper
		keep if slope  != .
		duplicates drop
		gen fuel = "`fuel'"
		gen year = "`yr'"
		tempfile `fuel'
		save ``fuel'', replace
		di "********************************"
		list

	restore
}




