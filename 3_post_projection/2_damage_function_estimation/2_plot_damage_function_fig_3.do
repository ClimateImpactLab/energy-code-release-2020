/*

Purpose: Figure 3 plotting, for energy sector total end of century damages 

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


//Load in GMTanom data file, save as a tempfile 
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
* * STEP 2: Estimate damage functions and plot, pre-2100
* **********************************************************************************

cap rename temp anomaly

* Use this local to determine whether we want consistent scales across other energy
* and electricity plots
loc scale_type = "-not_comm"

foreach fuel in "total_energy_price014" "other_energy" "electricity" {
	preserve

	if "`fuel'" == "total_energy_price014" {
		loc title = "Total Energy"
		loc ytitle = "bn USD (2019$)"
		loc ystep = 4000 
		loc ymax = 4000 
		loc ymin = -8000
	}

	if "`fuel'" == "electricity"{
		loc title = "Electricity"
		loc ytitle = "bn Gigajoules"
		* Convert to billion GJ
		replace `fuel' = `fuel'/ 1000000000

		if "`scale_type'" == "-not_comm" {
			loc ystep = 15
			loc ymax = 60
			loc ymin = 0
		}
		else{
			loc ystep = 80
			loc ymax = 80
			loc ymin = -200
		}
	}
	if "`fuel'" == "other_energy"{
		loc title = "Other Energy"
		loc ytitle = "bn Gigajoules"
		* Convert to billion GJ
		replace `fuel' = `fuel' / 1000000000
		if "`scale_type'" == "-not_comm" {
			loc ystep = 60
			loc ymax = 40 
			loc ymin = -200
		}
		else{
			loc ystep = 80
			loc ymax = 80
			loc ymin = -200
		}
	}

	* Nonparametric model for use pre-2100 
	foreach yr of numlist 2099/2099 {
	        qui reg `fuel' c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2 
	        cap qui predict yhat_`fuel'_`yr' if year>=`yr'-2 & year <= `yr'+2 
	        qreg `fuel'  c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2, quantile(0.05)
			predict y05_`fuel'_`yr' if year>=`yr'-2 & year <= `yr'+2
			qreg `fuel'  c.anomaly##c.anomaly if year>=`yr'-2 & year <= `yr'+2, quantile(0.95)
			predict y95_`fuel'_`yr' if year>=`yr'-2 & year <= `yr'+2
    
	}

	loc gr
	loc gr `gr' sc `fuel' anomaly if rcp=="rcp85" & year>=2095, mlcolor(red%30) msymbol(O) mlw(vthin) mfcolor(red%30) msize(vsmall) ||       
	loc gr `gr' sc `fuel' anomaly if rcp=="rcp45"& year>=2095, mlcolor(ebblue%30) msymbol(O) mlw(vthin) mfcolor(ebblue%30) msize(vsmall)   ||
	loc gr `gr' line yhat_`fuel'_2099 anomaly if year == 2099 , yaxis(1) color(black) lwidth(medthick) ||
	loc gr `gr' rarea y95_`fuel'_2099 y05_`fuel'_2099 anomaly if year == 2099 , col(grey%5) lwidth(none) ||
	
	di "Graphing time..."
	sort anomaly
	graph twoway `gr', yline(0, lwidth(vthin)) ///
	    	ytitle(`ytitle') xtitle("GMST Anomaly") ///
	        legend(order(1 "RCP 8.5" 2 "RCP 4.5" 3 "2099 damage fn.") size(*0.5)) name("`fuel'", replace) ///
	        xscale(r(0(1)10)) xlabel(0(1)10) scheme(s1mono) ///
	        title("`title' Damage Function, End of Century", tstyle(size(medsmall)))  ///
	        yscale(r(`ymin'(`ystep')`ymax')) ylabel(`ymin'(`ystep')`ymax')  
	        
	capture drop vbl

	* Display the slope of this damage function in 2099
	loc yr 2099
	qui sum anomaly if year>=`yr'-2 & year <= `yr'+2 
	loc xmax = r(max)
	loc xmin = r(min)
	loc Dx = r(max) - r(min)
	sum yhat_`fuel'_`yr' if year>=`yr'-2 & year <= `yr'+2 
	loc Dy = r(max) - r(min)
	loc slope = `Dy'/`Dx'
	di "average slope of `fuel' is `slope'"
	
	graph export "$output/fig_3/fig_3C_damage_function_`fuel'_2099_SSP3.pdf", replace 
	restore
}

**********************************************************************************
* STEP 3: HISTOGRAMS OF GMSTs 
**********************************************************************************

loc bw = 0.4
tw kdensity anomaly if rcp=="rcp45" & year>=2080, color(edkblue) bw(`bw') || ///
	kdensity anomaly if rcp=="rcp85" & year>=2080, color(red*.5) bw(`bw') || , /// 
	legend ( lab(1 "rcp45") lab(2 "rcp85")) scheme(s1mono) ///
	xtitle("Global mean temperature rise") 

graph export "$output/fig_3/fig_3C_anomaly_densities_GMST_end_of_century.pdf", replace 
graph drop _all




