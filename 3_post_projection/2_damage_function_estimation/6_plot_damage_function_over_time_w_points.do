/*

figure 3C new - all damage functions with all points overlayed
*/

clear all
set more off
set scheme s1color

glob DB "/mnt"

glob DB_data "$DB/CIL_energy/code_release_data_pixel_interaction"
glob dir "$DB_data/projection_system_outputs/damage_function_estimation/resampled_data"

glob root "/home/liruixue/repos/energy-code-release-2020"
glob output "$root/figures/"


//Load in GMTanom data file, save as a tempfile 
insheet using "$DB_data/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010.csv", comma names clear
drop if year < 2015 | year > 2099
tempfile GMST_anom
save `GMST_anom', replace

* **********************************************************************************
* * STEP 1: Pull in Damage CSVs and Merge with GMST Anomaly Data
* **********************************************************************************

foreach fuel in "total_energy_price014" {

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
* * STEP 2: Estimate damage functions and plot, pre-2100
* **********************************************************************************

cap rename temp anomaly

* Use this local to determine whether we want consistent scales across other energy
* and electricity plots
loc scale_type = "-not_comm"
local fuel "total_energy_price014" 
preserve

if "`fuel'" == "total_energy_price014" {
	loc title = "Total Energy"
	loc ytitle = "bn USD (2019$)"
	loc ystep = 4000 
	loc ymax = 4000 
	loc ymin = -8000
}


* Nonparametric model for use pre-2100 
foreach yr of numlist 2099/2099 {
        qui reg `fuel' c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2 
        cap qui predict yhat_`fuel'_`yr' if year>=`yr'-2 & year <= `yr'+2 
}

loc gr
loc gr `gr' sc `fuel' anomaly if rcp == "rcp85" & year>=2095 & plot_number == 1, mlcolor(red%30) msymbol(O) mlw(vthin) mfcolor(red%30) msize(vsmall) ||       
loc gr `gr' sc `fuel' anomaly if rcp == "rcp45" & year>=2095 & plot_number == 1, mlcolor(ebblue%30) msymbol(O) mlw(vthin) mfcolor(ebblue%30) msize(vsmall)   ||
*loc gr `gr' line yhat_`fuel'_2099 anomaly if year == 2099 & plot_number == 1, yaxis(1) color(black) lwidth(medthick) ||

* convert to trillion
replace `fuel' = `fuel' / 1000


di "Graphing time..."
sort anomaly

gen plot_number = 1
tempfile lines
save `lines', replace

*graph twoway `gr', yline(0, lwidth(vthin)) ytitle(`ytitle') xtitle("GMST Anomaly") legend(order(1 "RCP 8.5" 2 "RCP 4.5" 3 "2099 damage fn.") size(*0.5)) name("`fuel'", replace)  xscale(r(0(1)10)) xlabel(0(1)10) scheme(s1mono) title("`title' Damage Function, End of Century", tstyle(size(medsmall))) yscale(r(`ymin'(`ystep')`ymax')) ylabel(`ymin'(`ystep')`ymax')  
*graph export "$output/fig_3/fig_3C_test_damage_function_`fuel'_2099_SSP3.pdf", replace 



**********************************************************************************
* 1 SET UP -- Change paths and input choices to fit desired output
**********************************************************************************

*clear all
set more off
set scheme s1color

glob DB "/mnt"
glob DB_data "$DB/CIL_energy/code_release_data_pixel_interaction"
glob dir "$DB_data/projection_system_outputs/damage_function_estimation"

glob root "/home/liruixue/repos/energy-code-release-2020"
glob output "$root/figures/"


* **********************************************************************************
* 2 Feather plot for pre- and post-2100 damage functions
* **********************************************************************************

* import and reformat the gmst anomaly data, used for defining the range of GMST we plot each damage funciton for 
insheet using "$DB_data/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010.csv", comma names clear
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
insheet using "$dir/coefficients/df_mean_output_SSP3.csv", comma names clear
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

* convert to trillion
replace y = y / 1000

* Merge in range and drop unsupported temperature 
merge m:1 year using `ref'
qui replace y=. if anomaly<minT & year<=2099
qui replace y=. if anomaly>maxT & year<=2099

* initialise graphing local
loc gr2 
* Pre-2100 nonparametric lines
foreach yr of numlist 2015(10)2099 {
di "`yr'"
loc gr2 `gr2' line y anomaly if year == `yr' & plot_number == 2, color(edkblue) ||
}

* Post-2100 extrapolation line
foreach yr of numlist 2150 2200 2250 2300 {
loc gr2 `gr2' line y anomaly if year == `yr' & plot_number == 2, color(gs5*.5) ||
}

* 2100 line
loc gr2 `gr2' line y anomaly if year == 2100 & plot_number == 2, color(black) ||
sort anomaly
gen plot_number = 2

append using `lines'

* Plot and save
graph tw  `gr' || `gr2', yline(0, lwidth(vthin)) ytitle("Trillion USD ($2019)" ) xtitle("GMST Anomaly") title("Total Consumption", size(small)) xscale(r(0(1)10)) xlabel(0(1)10) yscale(r(-10(2)4)) ylabel(-10(2)4) legend(off) scheme(s1mono) ylabel(, labsize(small)) 


graph export "$output/fig_3/fig_3C_all_damage_functions_`fuel'_2099_SSP3_w_points.pdf", replace 

