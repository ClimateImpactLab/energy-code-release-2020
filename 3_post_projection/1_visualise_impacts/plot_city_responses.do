/*

Purpose: Plot response functions for 2015 and 2099 overlaid, for Stockholm and Guangxzhou
done sep 2020
*/

clear all
set more off
set scheme s1color
local clim_data "GMFD"

//SET UP RELEVANT PATHS

global REPO: env REPO
global DATA: env DATA 
global OUTPUT: env OUTPUT 

global LOG: env LOG
log using $LOG/3_post_projection/1_visualise_impacts/plot_city_responses.log, replace


glob root "${REPO}/energy-code-release-2020"
loc output "$OUTPUT/figures"


***********************************************************************************
*Step 1: Load in city information and save as tempfile for plotting purposes later
***********************************************************************************

//Part A: save income and climate covariate data as tempfile

import delim using "${DATA}/miscellaneous/stockholm_guangzhou_covariates_2015_2099.csv"
tempfile covar_data
save `covar_data', replace

//Part B: Load in daily tavg distribution min and max for 2015
import delim using "${DATA}//miscellaneous/stockholm_guangzhou_2015_min_max.csv", clear 
rename mint minT
rename maxt maxT
keep city maxT minT
tempfile minmax
qui save `minmax', replace


//Part B: Sort city-years into climate and income groups using insample climate and income group cutoffs

// i) load in insample climate and income group cutoffs
use "${DATA}/regression/break_data_TINV_clim.dta", clear

// Get income group knot locations
foreach var in "electricity" "other_energy" {
	summ maxInc_largegpid_`var' if largegpid_`var' == 1
	local ibar_`var' = `r(max)'
	di "`ibar_`var''"
}

// ii) extract covariates 
import delim using "${DATA}/miscellaneous/stockholm_guangzhou_region_names_key.csv", clear varnames(1)

//load in covariates
foreach yr of num 2099 2015 {
	merge 1:m region using "`covar_data'", nogen assert(3)
	qui keep if year == `yr'
	reshape wide loggdppc climtascdd20 climtashdd20, i(city proposal country region) j(year) 
}
// Take an average across the impact regions that make up each city 
qui collapse (mean) loggdppc* climtascdd* climtashdd* , by(city proposal country)

// iv) assign groups using i and ii
foreach yr in 2099 2015 {
	di "`yr'"

	foreach var in "electricity" "other_energy" {
		qui gen lg_`var'`yr' = .
		qui replace lg_`var'`yr'=1 if loggdppc`yr'<= `ibar_`var''
		qui replace lg_`var'`yr'=2 if loggdppc`yr'>`ibar_`var''
		assert lg_`var'`yr' != .
	}
}

// Part B) Merge City Info datasets and save as tempfile for later use
qui merge 1:1 city using `minmax', nogen assert(3)
tempfile cities
save `cities', replace

**************************************************************************************
*Step 2: Prepare for plotting
**************************************************************************************

//load analysis data 
use "${DATA}/regression/GMFD_TINV_clim_regsort.dta", clear

//set local values for plotting
*temp bounds
local min = -15
local max = 40
local omit = 20
local obs = `max' + abs(`min') + 1
local midcut=20

*climate group colors
local Hotcol "cranberry"
local Coldcol "midblue"

//prepare dataset for plotting 

qui drop if _n > 0
qui set obs `obs'
qui replace temp1_`clim_data' = _n + `min' -1

//above 20 indicator
qui gen above`midcut'=(temp1_`clim_data'>=`midcut')
//below 20 indicator 
qui gen below`midcut'=(temp1_`clim_data'<`midcut') 
foreach k of num 1/2 {
	rename temp`k'_`clim_data' temp`k'
	replace temp`k' = temp1 ^ `k'
}

**************************************************************************************
*Step 3: Plot 
**************************************************************************************

foreach var in "electricity" "other_energy" {

	if "`var'"=="electricity" {
		local stit="Electricity"
		local pg=1
	}
	else if "`var'"=="other_energy" {
		local stit="Other Fuels"
		local pg=2
	}

	local plotgraph ""

	foreach city in "Stockholm" "Guangzhou"  {
		if("`city'" == "Guangzhou") {
			loc climtag "Hot"
		}
		else if("`city'" == "Stockholm") {
			loc climtag "Cold"
		}

		//locals for plotting options
		local plotline = ""
		local gray_scale 8 
		local intensity_scale 40 

		foreach scen in "noadapt" "fulladapt"  {
			
			//extract city specific info 			
			if "`scen'" == "fulladapt" {
				local clim_yr 2099
				local inc_yr 2099
			}
			else if "`scen'" == "noadapt" {
				local clim_yr 2015
				local inc_yr 2015
			}

			preserve
				qui use `cities', clear
				keep if city == "`city'"
				local country= country[1]
				local subInc=loggdppc`inc_yr'[1]
				local subCDD=climtascdd20`clim_yr'[1]
				local subHDD=climtashdd20`clim_yr'[1]
				local ig=lg_`var'`inc_yr'[1]
				local mincut=minT[1]
				local maxcut=maxT[1]
				local deltacut_subInc= `subInc' - `ibar_`var''
			restore

			local line ""
			local add ""
			
			foreach k of num 1/2 {
				
				local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
				local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*`subCDD' * (temp`k' - 20^`k')"
				local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*`subHDD' * (20^`k' - temp`k')"
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"

				local add " + "
			}
			* Load in ster file, to get response function coefficients
			estimates use "$OUTPUT/sters/FD_FGLS_inter_TINV_clim.ster"

			* Get predicted values, and SEs
			predictnl yhat_`var'`scen' = `line', se(se_`var'`scen') ci(lower_`var'`scen' upper_`var'`scen')
			qui gen double yhat_full_`var'`scen' = yhat_`var'`scen'
			
			qui replace yhat_`var'`scen'=. if (temp1<`mincut' | temp1>`maxcut')

			* For 2015 response (ie noadapt), we include standard errors on the plot

			if ("`scen'" == "noadapt") {
				** Local line
				local plotline="`plotline' (line yhat_full_`var'`scen' temp1, lcolor(``climtag'col') lwidth(0.5) lpattern(shortdash)) "
				local plotline="`plotline' (line yhat_`var'`scen' temp1, lcolor(``climtag'col') lwidth(0.5))"
				local plotline="`plotline' (rarea upper_`var'`scen' lower_`var'`scen' temp1, col(``climtag'col'%30)) "
			} 
			else {
				local col = "gs`gray_scale' % `intensity_scale'"
				local gray_scale = `gray_scale' + 4
				local intensity_scale = `intensity_scale' - 20

				** Local line
				local plotline="`plotline' (line yhat_full_`var'`scen' temp1, lcolor(`col') lwidth(0.5) lpattern(shortdash)) "
				local plotline="`plotline' (line yhat_`var'`scen' temp1, lcolor(`col') lwidth(0.5))"
			}
		}
		twoway `plotline', ///
				yline(0) xlabel(`min'(5)`max', labsize(vsmall)) ///
				ylabel(, labsize(vsmall)) legend(off) ///
				ytitle("GJ PC", size(small)) xtitle("Temperature[C]", size(small)) ///
				title("`city', `country'", size(small)) ///
				subtitle(, size(vsmall)) ///
				graphregion(color(gs16)) nodraw ///
				name(`city', replace)

		local plotgraph " `plotgraph' `city'"

		//clean up shop before plotting next response functions
		drop yhat_*	se_* lower_* upper_*	
	}		

	**combine cells**
	graph combine `plotgraph', ycomm rows(1) ///
		graphregion(color(gs16) m(zero))  name(`var') ///
		title("`stit'") imargin(zero)
}

* Combine plots, and save
graph combine electricity other_energy, rows(2)
graph export "$OUTPUT/figures/fig_2A_city_response_functions_2015_and_2099.pdf", replace
graph drop _all	
