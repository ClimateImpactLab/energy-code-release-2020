* get SSP3 growth rate
/* 
import delimited using "/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv", clear
gen growth_rate_yearly = gdp / gdp[_n-1] - 1
gen growth_rate_15yr = (gdp[91] / gdp[76])^(1/15)
gen gdp_2300 = gdp[91] * (growth_rate_15yr)^200 
*/


clear all
set more off
set scheme s1color

glob DB "/mnt"

glob dir_temp "/mnt/CIL_energy/code_release_data_pixel_interaction/referee_comments/damage_function_estimation/"
glob DB_data "$DB/CIL_energy/code_release_data_pixel_interaction"
glob dir "$DB_data/projection_system_outputs/damage_function_estimation"
glob dir_output "/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/"

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
			loc pricelist price014 
			*price0 price03 WITCHGLOBIOM42 MERGEETL60 REMINDMAgPIE1730 REMIND17CEMICS REMIND17
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


	* get gdp and convert to the same unit as damages (billion 2019 USD)
	import delimited using "/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv", clear
	replace gdp = gdp  / 100 / 1000000000
	drop if year == 2100

	merge 1:n year using `raw'

	* CHECK: create percent gdp variable
	foreach price in `pricelist_sub' {
		gen p_`price' = `price' / gdp
	}

	**********************************************************************************
	* STEP 2: Regressions & construction of time-varying damage function coefficients 
	**********************************************************************************

	**  INITIALIZE FILE WE WILL POST RESULTS TO
	capture postutil clear
	tempfile coeffs
	postfile damage_coeffs str20(var_type) year cons beta1 beta2 anomalymin anomalymax using "`coeffs'", replace

	gen t = year-2010

	* create variables to plot later
	foreach v of numlist 1/5 {
		gen p_yh_`v' = .
		gen d_yh_`v' = .
	}

	** Regress, and output coeffs	
	foreach vv in `pricelist' {
		* Nonparametric model for use pre-2100 
		foreach yr of numlist 2015/2099 {
			di "`vv' `yr'"
			loc year_start = `yr'-2
			loc year_end = `yr'+2
			
			qui reg p_`vv' c.anomaly##c.anomaly if year>=`year_start' & year <= `year_end' 
			
			* Need to save the min and max temperature for each year for plotting
			qui summ anomaly if year == `yr', det 
			loc amin = `r(min)'
			loc amax =  `r(max)'
			
			* Save coefficients for all years prior to 2100
			post damage_coeffs ("`vv'") (`yr') (_b[_cons]) (_b[anomaly]) (_b[c.anomaly#c.anomaly]) (`amin') (`amax')
			
			* CHECK: the following lines compute predicted %gdp for observations used in regression
			* and multiply with gdp
			predictnl p_yh_`yr'df = xb() if year>=`year_start' & year <= `year_end'
			replace p_yh_`yr'df = p_yh_`yr'df * gdp if year>=`year_start' & year <= `year_end'
		}
	}




	** Regress, and output coeffs	
	foreach vv in `pricelist' {
		* Nonparametric model for use pre-2100 
		foreach yr of numlist 2015/2099 {
			di "`vv' `yr'"
			loc year_start = `yr'-2
			loc year_end = `yr'+2
			
			qui reg `vv' c.anomaly##c.anomaly if year>=`year_start' & year <= `year_end' 
			
			* Need to save the min and max temperature for each year for plotting
			qui summ anomaly if year == `yr', det 
			loc amin = `r(min)'
			loc amax =  `r(max)'
			
			* Save coefficients for all years prior to 2100
			post damage_coeffs ("`vv'") (`yr') (_b[_cons]) (_b[anomaly]) (_b[c.anomaly#c.anomaly]) (`amin') (`amax')
			
			* CHECK: the following lines compute predicted damage for observations used in regression
			predictnl d_yh_`yr'df = xb() if year>=`year_start' & year <= `year_end'
		
		}
	}

	save "$dir_temp/percent_gdp_vs_dollar_df_comparison_`subset'.dta", replace
	use "$dir_temp/percent_gdp_vs_dollar_df_comparison_`subset'.dta", clear


	* CHECK:
	* put all the predicted %gdp and damages into variables
	* such that p_yh_1 and d_yh_1 correspond to the predicted %gdp and damage in year t-2 (t is the year of the damage function)
	* p_yh_2 and d_yh_2 correspond to the predicted %gdp and damage in year t-1
	* all the way up to p_yh_5 and d_yh_5

	foreach yr_df of numlist 2015/2099 {
		loc year_start = `yr_df'-2
		loc year_end = `yr_df'+2
		foreach yr_yh of numlist `year_start'/`year_end' {
			loc temp = `yr_yh' - `yr_df' + 3
			replace p_yh_`temp' = p_yh_`yr_df'df if year == `yr_yh'
			replace d_yh_`temp' = d_yh_`yr_df'df if year == `yr_yh'
		}
	}

	* drop temp vars
	drop d_yh*df p_yh*df

	export delimited using "$dir_output/percent_gdp_vs_dollar_df_comparison_`subset'.csv", replace


	graph tw scatter p_yh_1 d_yh_1, msymbol(circle)|| scatter p_yh_2 d_yh_2, msymbol(diamond) || scatter p_yh_3 d_yh_3, msymbol(triangle) || scatter p_yh_4 d_yh_4 , msymbol(plus)||scatter p_yh_5 d_yh_5, msymbol(X) || line p_yh_5 d_yh_5, sort
	graph export "$dir_output/percent_gdp_vs_dollar_df_comparison_`subset'.pdf", replace
}


