/* Create the energy bar charts - of current pc consumption (2010), 2099 impacts, and 2099 impacts due to income.
Separate charts for electricity and other energy

CONTENTS:
Initialising, set up paths, program the countries we want to include 
0. Get the country level population data
1. Get and save 2010 consumption 
2. Load and save 2099 impacts - separate files for SGP and other countries 
3. NO LONDER DONE - check previous commit if we want this again: (Loop over Beta no adapt and beta no adapt (both hist clim) files, generate a variable of their different check ) 
4. Merge the three types of data
5. Plot the bar chart 
*/

clear all
set more off
if c(hostname) == "EPIC-14669" { 
	global DB "C:\Users\TomBearpark\Dropbox"
	global impacts "C:\Users\TomBearpark\Desktop\local_data"
	global impact_new "$impacts\new"
}
if c(hostname) == "sacagawea" { 
	global DB "/local/shsiang/Dropbox"
	global impacts "/shares/gcp/social/parameters/energy/extraction"
	global impacts_new "/shares/gcp/social/parameters/energy/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_income_spline_GMFD"
}
global current_data "$DB/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/GMFD/rationalized_code/replicated_data/data"
global price "/shares/gcp/social/baselines/energy"
global OUT "$DB/GCP_Reanalysis/ENERGY/IEA_Replication/Projection/eel_projection/GMFD/rationalized_code/replicated_data/TINV_clim_income_spline/semi-parametric/bars"
global pop_data "/shares/gcp/estimation/mortality/damage_function/data"


** TOGGLES **
loc yr = 2100



**************************************
* 0. Populatoin data
**************************************

* Get population data for pc impact conversion 
import delim "$pop_data/population_by_agegroup_SSP3_low.csv", clear //  rowrange(13:) varnames(13)
keep region year pop
keep if year == `yr' | year == 2010

preserve
	keep if year == `yr'
	rename pop population
	tempfile population
	save `population', replace
restore

gen country = substr(region, 1, 3)
collapse (sum) pop , by(country year)
tempfile iso_pop
save `iso_pop', replace
// reshape wide population, i(country) j(year)


**************************************
* 1. 2010 current consumption - from the main energy dataset 
**************************************
use "$current_data/IEA_Merged_long_GMFD.dta", clear
keep if year == 2010
keep if product == "other_energy" | product == "electricity"
keep country product load_pc year
rename load_pc consumption_
reshape wide consumption_, i(country year) j(product) string
foreach var in "other_energy" "electricity" {
	ren consumption_`var' `var'
}
// gen scn = "impact"
tempfile twenty_10
save `twenty_10', replace
di "twenty 10 impacts saved"

**************************************
* 2. 2099 impacts
**************************************

foreach prod in "electricity" "other_energy" {

	* Get the SGP impacts
	insheet using "$impacts_new/median_OTHERIND_`prod'_TINV_clim_income_spline_GMFD/rcp85-SSP3_median_high_fulladapt.csv", clear
	gen country = substr(region,1,3)
	keep if year == `yr'
	merge m:1 region year using "`population'", assert(3) nogen
	ren mean `prod'
	collapse (mean) `prod' [aw=pop], by(country year)
	keep country year `prod'

	tempfile `prod'_impacts
	save ``prod'_impacts', replace
	di "saving `prod'_impacts"
}
* append the elec and other energy impacts together
use `electricity_impacts', clear
preserve
	keep country
	merge 1:1 country using `twenty_10', keep(3) nogen
	keep country
	gen key = 1
	tempfile key
	save "`key'", replace
restore

merge 1:1 country year using `other_energy_impacts', nogen
append using `twenty_10'
merge m:1 country year using `iso_pop', nogen
// merge 1:1 country using `twenty_10', keep(1 3) nogen
tempfile impacts
save `impacts', replace
di "impacts saved"
merge m:1 country using "`key'", nogen
keep if key == 1
drop key

foreach prod in "electricity" "other_energy" { 

	gen levels_`prod' = `prod' * pop

}


export delimited using "$OUT/barchart_v2_output_v2.csv", replace
