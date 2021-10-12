
**********************************************************************************
* 1 SET UP -- Change paths and input choices to fit desired output
**********************************************************************************

clear all
set more off
set scheme s1color

glob DB "/mnt"
glob DB_data "$DB/CIL_energy/code_release_data_pixel_interaction"
glob dir "$DB_data/projection_system_outputs/damage_function_estimation"
glob dir_output "$DB_data/referee_comments/damage_function_estimation"

glob root "/home/liruixue/repos/energy-code-release-2020"
glob output "$OUTPUT/figures/referee_comments"


* **********************************************************************************
* 2 Feather plot for pre- and post-2100 damage functions
* **********************************************************************************

* import and reformat the gmst anomaly data, used for defining the range of GMST we plot each damage funciton for 
insheet using "$DB_data/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010_smooth.csv", comma names clear
tempfile GMST_anom
save `GMST_anom', replace
preserve
	qui bysort year: egen minT=min(temp)
	qui bysort year: egen maxT=max(temp)
	qui replace minT=round(minT,0.1)
	qui replace maxT=round(maxT,0.1)
	qui keep year minT maxT
	qui duplicates drop year, force
	tempfile ref
	qui save `ref', replace
restore

* Load in damage function coefficients, and subset to just price014 (main model) 
insheet using "$dir_output/coefficients/df_mean_output_SSP3_t_cubic.csv", comma names clear
keep if growth_rate == "price014"

* Create expanded dataset by valuation and by year
* Just keep data every 5 years
gen roundyr = round(year, 5)
keep if year==roundyr
drop roundyr

* Expand to get obs every quarter degree
expand 40, gen(newobs)
sort year

* Generate anomaly and prediction for every quarter degree
bysort year: gen anomaly = _n/4
gen y = cons + beta1*anomaly + beta2*anomaly^2

* Merge in range and drop unsupported temperature 
merge m:1 year using `ref'
qui replace y=. if anomaly<minT & year<=2099
qui replace y=. if anomaly>maxT & year<=2099

* initialise graphing local
loc gr 
* Pre-2100 nonparametric lines
foreach yr of numlist 2015(10)2099 {
di "`yr'"
loc gr `gr' line y anomaly if year == `yr', color(edkblue) ||
}

* Post-2100 extrapolation line
foreach yr of numlist 2150 2200 2250 2300 {
loc gr `gr' line y anomaly if year == `yr', color(gs5*.5) ||
}

* 2100 line
loc gr `gr' line y anomaly if year == 2100, color(black) ||
sort anomaly

* Plot and save
graph tw `gr', yline(0, lwidth(vthin)) 	ytitle("Bn 2019 USD" ) xtitle("GMST Anomaly") title("Total Energy Damage Function, Evolution Over Time", size(small)) xscale(r(0(1)10)) xlabel(0(1)10) legend(off) scheme(s1mono) ylabel(, labsize(small)) 

graph export "$output/fig_Appendix-E1_total_energy_damage_function_evolution_SSP3-price014_t_cubic.pdf", replace 
graph drop _all



