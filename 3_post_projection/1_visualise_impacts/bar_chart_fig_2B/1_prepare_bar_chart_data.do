/* 
Purpose: Generate a CSV of country level impacts of climate change on enerngy consumption, to use for plotting
the bar chart in Figure 2B
*/

clear all
set more off

//SET UP RELEVANT PATHS


global REPO: env REPO
global DATA: env DATA 
global OUTPUT: env OUTPUT 


glob root "${REPO}/energy-code-release-2020"
loc data "$OUTPUT/projection_system_outputs"
loc output "$OUTPUT/figures"

**************************************
* 1. Population data
**************************************

* Get population data for converting Per capita impacts into levels 
import delim "`data'/covariates/SSP3_IR_level_population.csv", clear 

* Our population estimates are done using a step function. We only have data for each 5th year
* Therefore, we assign 2099 population the values of population from 2095
replace year  = 2099 if year == 2095
keep if inlist(year,2010, 2099)

preserve
	keep if year == 2099
	rename pop population
	tempfile population
	save `population', replace
restore

* Collapse to the country level (the level of the bar chart's data)
* The first three letters of a region's name identifies it's country
gen country = substr(region, 1, 3)
collapse (sum) pop , by(country year)
tempfile iso_pop
save `iso_pop', replace

**************************************
* 2. 2010 current consumption - from the analysis data  
**************************************

use "${DATA}/regression/IEA_Merged_long_GMFD.dta", clear
keep if year == 2010

keep country product load_pc year
rename load_pc consumption_
reshape wide consumption_, i(country year) j(product) string
foreach var in "other_energy" "electricity" {
	ren consumption_`var' `var'
}
tempfile twenty_10
save `twenty_10', replace
di "2010 Per Capita country level consumption saved"

**************************************
* 2. 2099 impacts
**************************************


foreach prod in "electricity" "other_energy" {

	* Get the 2099 impact region level impacts data
	insheet using "`data'/projection_system_outputs/mapping_data/main_model-`prod'-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv", clear
	
	* Collapse to the country level, weighting impacts according to IR level population
	gen country = substr(region,1,3)
	merge 1:1 region year using "`population'", assert(3) nogen
	ren mean `prod'
	ren q5 `prod'_q5
	ren q95 `prod'_q95

	ren q10 `prod'_q10
	ren q90 `prod'_q90

	collapse (mean) `prod' `prod'_q5 `prod'_q95 `prod'_q10 `prod'_q90 [aw=pop], by(country year)
	keep country year `prod' `prod'_q5 `prod'_q95 `prod'_q10 `prod'_q90
	tempfile `prod'_impacts
	save ``prod'_impacts', replace
	di "saving `prod' 2099 impacts tempfile"
}



**************************************
* 2. Merge it all together and save
**************************************

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
tempfile impacts
save `impacts', replace

* Clean up shop
merge m:1 country using "`key'", nogen
keep if key == 1
drop key
di "impacts saved"

* Generate levels, by multiplying country level population with the PC impacts 
foreach prod in "electricity" "other_energy" { 
	gen levels_`prod' = `prod' * pop
	gen levels_`prod'_q5 = `prod'_q5 * pop
	gen levels_`prod'_q95 = `prod'_q95 * pop

	gen levels_`prod'_q10 = `prod'_q10 * pop
	gen levels_`prod'_q90 = `prod'_q90 * pop

}
* Save as a csv for plotting in R using ggplot
export delimited using "`data'/intermediate_data/figure_2B_bar_chart_data.csv", replace
