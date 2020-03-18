/*
Creator: Yuqi Song
Date last modified: 11/12/19 
Last modified by: Maya Norman

Plot 12 City response array

*/
 
clear all
set more off
pause off

//SET UP RELEVANT PATHS

loc DB "C:/Users/TomBearpark/Dropbox"
loc DROPBOX "C:/Users/TomBearpark/Dropbox"
loc DB_data "`DB'/GCP_Reanalysis/ENERGY/code_release_data"
loc GIT "C:/Users/TomBearpark/Desktop/gcp-energy/rationalized"
loc git "C:/Users/TomBearpark/Documents/energy-code-release"
loc data "`git'/data"
loc output "`git'/figures"


******Set Script Toggles********************************************************

// set dataset specification

local case "Exclude" // "Exclude" "Include"
local data_type "replicated_data"
local bknum "break2"
local IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues

// set model specification

local grouping_test "semi-parametric" 
local model "TINV_clim" //Options: TINV_clim, TINV_both, TINV_clim_EX
local submodel "income_spline"
if "`submodel'" != "" local submodel "_`submodel'"

//Climate Data type
local clim_data "GMFD"

//plotting specification

local product_list "electricity other_energy" // which products to create plots for
local scenario_list " noadapt fulladapt " // what scenarios to plot response functions for

********************************************************************************

//Setting path shortcuts

local misc_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Miscellaneous"
local analysis_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/replicated_data/"
local covariates "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Projection/covariates/FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_income_spline.csv"
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Miscellaneous/12_cities_temperature_response"

//loading necessary programs

do `GIT'/1_analysis/get_line_for_plotting.do

***********************************************************************************
*Step 1: Load in city information and save as tempfile for plotting purposes later
***********************************************************************************

//Part Z: save covar data as tempfile

import delim using "`DB_data'/stockholm_guangzhou_covariates_2015_2099.csv"
tempfile covar_data
save `covar_data', replace

//Part A: Obtain daily tavg distribution for each city for 2015

import delim using "`DB_data'/stockholm_guangzhou_2015_min_max.csv", clear 

rename mint minT
rename maxt maxT
keep city maxT minT
tempfile minmax
qui save `minmax', replace

//Part B: Sort cities into climate and income groups using insample climate and income group cutoffs

// i) load in insample climate and income group cutoffs
* use "`analysis_data'/data/break10_clim`clim_data'_Exclude`IF'_`bknum'_`grouping_test'_`model'_`data_type'.dta", clear
use "`data'/break_data_TINV_clim.dta", clear




//break code if there aren't 3 income groups for each product (...currently code is not set up for other numbers of large income groups)
foreach var in `product_list' {
	sum largegpid_`var' 
	assert `r(max)' == 2
	
	summ maxInc_largegpid_`var' if largegpid_`var' == 1
	local ibar_`var' = `r(max)'
}

// ii) Get insample climate and income group cutoffs
* foreach gp of varlist tpid largegpid_electricity largegpid_other_energy {

* Removed tpid from loop 
foreach gp of varlist largegpid_electricity largegpid_other_energy {

	if substr("`gp'",1,strpos("`gp'" , "_" ) - 1) == "largegpid" {
		local mn="Inc"
	}
	else if "`gp'"=="tpid" {
		local mn="CDD"
	}
	di "check"
	preserve
		qui duplicates drop `gp', force
		sort `gp'
		local `gp'_bound0=-3
		forval i=1/2 {
			local `gp'_bound`i'=max`mn'_`gp'[`i']
		}
	restore
}

local gpid_bound0=0

qui duplicates drop gpid, force
sort gpid

* forval i=1/9 {
* 	local gpid_bound`i'=maxInc_gpid[`i']
* }

* local gpid_bound10=99

// iii) extract covariates (original location = allcalcs file)
* insheet using "`misc_data'/City_List.csv", comma names clear
import delim using "`DB_data'/stockholm_guangzhou_region_names_key.csv", clear varnames(1)

//load in covariates for present day 
// you can make this much more efficient by just keeping if year in list once.. 
// it was just originally setup to plot responses for a year list rather than adaptation scenarios

* rename hierid region
pause

foreach yr of num 2099 2015 {
	di "`yr'"

	qui merge 1:m region using "`covar_data'"
	assert _merge!=1
	qui keep if _merge==3
	qui keep if year == `yr'
	drop _merge
	reshape wide loggdppc climtascdd20 climtashdd20, i(city proposal country region) j(year) 
}

qui collapse (mean) loggdppc* climtascdd* climtashdd* , by(city proposal country)


// iv) assign groups using ii and iii
foreach yr in 2099 2015 {
	di "`yr'"

	foreach var in `product_list' {
		di "hello `var'"
		qui gen lg_`var'`yr' = .
		qui replace lg_`var'`yr'=1 if loggdppc`yr'<=`largegpid_`var'_bound1'
		qui replace lg_`var'`yr'=2 if loggdppc`yr'>`largegpid_`var'_bound1' 
		assert lg_`var'`yr' != .

	}
	* di "done loop"
	* qui gen decile`yr'=.
	* forval i=1/10 {
	* 	local j=`i'-1
	* 	qui replace decile`yr'=`i' if loggdppc`yr'<=`gpid_bound`i'' & loggdppc`yr'>`gpid_bound`j''
	* }
	* assert decile`yr'!=.
}


// v) clean up shop
**Save**
order city country proposal lg* // decile*
sort proposal

**Take the Tag of Naming**
qui gen tag=""
qui replace tag="Left-Cranberry" if proposal=="Poor-Hot"
qui replace tag="Left-Midblue" if proposal=="Poor-Cold"
qui replace tag="Left-Orange" if proposal=="Poor-Extreme"
qui replace tag="Left-Midgreen" if proposal=="Poor-Moderate"
qui replace tag="Middle-Cranberry" if proposal=="Middle-Hot"
qui replace tag="Middle-Midblue" if proposal=="Middle-Cold"
qui replace tag="Middle-Orange" if proposal=="Middle-Extreme"
qui replace tag="Middle-Midgreen" if proposal=="Middle-Moderate"
qui replace tag="Right-Cranberry" if proposal=="Rich-Hot"
qui replace tag="Right-Midblue" if proposal=="Rich-Cold"
qui replace tag="Right-Orange" if proposal=="Rich-Extreme"
qui replace tag="Right-Midgreen" if proposal=="Rich-Moderate"
assert tag!=""

qui gen incstr=substr(proposal,1,strpos(proposal,"-")-1)
qui gen climstr=substr(proposal,strpos(proposal,"-")+1,.)

// Part B) Merge City Info datasets and save as tempfile for later use
qui merge 1:1 city using `minmax'
assert _merge==3
drop _merge
drop if country == "Egypt" //change to India to swap in cairo for mumbai
tempfile cities
qui save `cities', replace


**************************************************************************************
*Step 2: Prepare for plotting
**************************************************************************************

//load analysis data 

use "`data'/GMFD_TINV_clim_regsort.dta", clear
//set local valuse for plotting

*temp bounds
local min = -15
local max = 40
local omit = 20
local obs = `max' + abs(`min') + 1
local midcut=20

*climate group colors
local Hotcol "cranberry"
local Coldcol "midblue"
local Extremecol "orange"
local Moderatecol "midgreen"

local electricitycol "dknavy"
local other_energycol "dknavy"

//prepare dataset for plotting 

qui drop if _n > 0
qui set obs `obs'
qui replace temp1_`clim_data' = _n + `min' -1
qui gen above`midcut'=(temp1_`clim_data'>=`midcut') //above 20 indicator
qui gen below`midcut'=(temp1_`clim_data'<`midcut') //below 20 indicator

foreach k of num 1/4 {
	rename temp`k'_`clim_data' temp`k'
	replace temp`k' = temp1 ^ `k'
}

**************************************************************************************
*Step 3: Plot 
**************************************************************************************



foreach var in `product_list' {

	local fg = 1 //only one flow

	if "`var'"=="electricity" {
		local stit="Electricity"
		local pg=1
		//identify number of income groups
		local IG = 2
	}
	else if "`var'"=="other_energy" {
		local stit="Non-Electricity"
		local pg=2
		//identify number of income groups
		local IG = 2
	}

	local plotgraph ""

	foreach city in "Guangzhou" "Stockholm" {
		if("`city'" == "Guangzhou") {
			loc climtag "Hot"
		}
		if("`city'" == "Guangzhou") {
			loc climtag "Cold"
		}

			//local for plotting climate group specific responses
			local plotline = ""
			local gray_scale 8 //0
			local intensity_scale 40 //100

			foreach scen in `scenario_list' {
				
				//extract city specific info (only one city for each climate x income gropu)
				
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
					local lg=lg_`var'`inc_yr'[1]
					local mincut=minT[1]
					local maxcut=maxT[1]
					local deltacut_subInc= `subInc' - `ibar_`var''
				restore

				di "`inctag' `climtag' large income group: `lg' `var'"
				
				if ("`submodel'" == "_income_spline" | "model" == "TINV_clim_income_spline") {
					local tt "I`lg'"
				}
				
				local ster "FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model'`submodel'"
				get_interacted_response , model("`ster'") product("`var'") income_group(`lg') n_income_group(`IG') ///
				subInc(`subInc') subCDD(`subCDD') subHDD(`subHDD') deltacut_subInc(`deltacut_subInc') myyear(`inc_yr')
				
				local line `s(interacted_response_line)'

				** Predict
				estimates use "`analysis_data'/sters/FD_FGLS/`ster'.ster"
				di "`line'"
				pause
				predictnl yhat_`var'`scen' = `line', se(se_`var'`scen') ci(lower_`var'`scen' upper_`var'`scen')
				qui gen double yhat_full_`var'`scen' = yhat_`var'`scen'
				qui replace yhat_`var'`scen'=. if (temp1<`mincut' | temp1>`maxcut')

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
					//local plotline="`plotline' (rarea upper_`var' lower_`var' temp1, col(``climtag'col'%30)) "
				}
			}
		twoway `plotline', ///
				yline(0) xlabel(`min'(5)`max', labsize(vsmall)) ///
				ylabel(, labsize(vsmall)) legend(off) ///
				ytitle("`ytag'", size(small)) xtitle("Temperature[C]", size(small)) ///
				title("`city', `country'", size(vsmall)) ///
				subtitle(, size(vsmall)) ///
				graphregion(color(gs16)) nodraw ///
				name(`city', replace)

		local plotgraph " `plotgraph' `city'"

		//clean up shop before plotting next income level
		drop yhat_*	se_* lower_* upper_*	
		
	}		

	**combine cells**
	graph combine `plotgraph', ycomm rows(4) xsize(3) ysize(3) ///
		graphregion(color(gs16) m(zero)) iscale(*.9) imargins(2 2 2 2) 
		
	* graph export "`output'/FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`var'_poly2_`model'`submodel'_Response_Array_12_Cities_3scen_v2.pdf", replace

	* graph drop _all	

}
