
clear all
set more off
set scheme s1color

glob DB "/mnt"

glob DB_data "$DB/CIL_energy/code_release_data_pixel_interaction"
glob dir "$DB_data/referee_comments/li_et_al"

glob root "/home/liruixue/repos/energy-code-release-2020"
glob output "/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/li_et_al_shanghai_comparison"


* Load in GMTanom data file, save as a tempfile 
insheet using "$DB_data/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010_smooth.csv", comma names clear
drop if year < 2015 | year > 2099
tempfile GMST_anom
save `GMST_anom', replace

* **********************************************************************************
* * STEP 1: Pull in Damage CSVs and Merge with GMST Anomaly Data
* **********************************************************************************

foreach fuel in "shanghai_impact" "shanghai_impact_no_srg" {
*foreach fuel in "shanghai_impact" {

	di "`fuel'"
	*loc fuel shanghai_impact
	loc type = "impacts"
	
	import delim using "$dir/`fuel'_2097_electricity.csv", clear
	drop if year < 2080 | year > 2099
	merge m:1 year gcm rcp using `GMST_anom', nogen keep(3)

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
use `mastershanghai_impact', clear
*use `mastershanghai_impact_no_srg', clear

*merge 1:1 year minT maxT rcp gcm iam temp using `mastershanghai_impact_no_srg'

tempfile master
gen shanghai_impact_no_srg = shanghai_impact
replace shanghai_impact_no_srg = . if strpos(gcm, "surrogate")>0 
save `master', replace

* **********************************************************************************
* * STEP 2: Estimate damage functions and plot, pre-2100
* **********************************************************************************

cap rename temp anomaly

* Use this local to determine whether we want consistent scales across other energy
* and electricity plots
loc scale_type = "-comm"

foreach fuel in "shanghai_impact" "shanghai_impact_no_srg"{
	preserve

	if "`fuel'" == "shanghai_impact" {
		loc title = "Shanghai Electricity"
		loc ytitle = "% of 2012 Electricity Donsumption"
		loc ystep = 50
		loc ymax = 200
		loc ymin = -50
	}

	if "`fuel'" == "shanghai_impact_no_srg"{
		loc title = "Shanghai Electricity (No Surrogate Models)"
		loc ytitle = "% of 2012 Electricity Consumption"
		loc ystep = 50
		loc ymax = 200
		loc ymin = -50	
	}

	* Nonparametric model for use pre-2100 
	di "`fuel'"
    reg `fuel' anomaly if year>=2080 & year <= 2099 
    predict yhat_`fuel' if year>=2080 & year <= 2099 

* 	loc gr
* 	loc gr `gr' sc `fuel' anomaly if rcp=="rcp85" & year>=2080, mlcolor(red%30) msymbol(O) mlw(vthin) mfcolor(red%30) msize(vsmall) ||       
* 	loc gr `gr' sc `fuel' anomaly if rcp=="rcp45"& year>=2080, mlcolor(ebblue%30) msymbol(O) mlw(vthin) mfcolor(ebblue%30) msize(vsmall)   ||
* 	loc gr `gr' line yhat_`fuel' anomaly if year == 2099 , yaxis(1) color(black) lwidth(medthick) ||
	
* 	di "Graphing time..."
* 	sort anomaly
* 	graph twoway `gr', yline(0, lwidth(vthin)) ytitle(`ytitle') xtitle("GMST Anomaly") legend(order(1 "RCP 8.5" 2 "RCP 4.5" 3 "2097 damage fn.") size(*0.5)) name("`fuel'", replace) xscale(r(0(1)10)) xlabel(0(1)10) scheme(s1mono) title("`title' Damage Function, End of Century", tstyle(size(medsmall))) yscale(r(`ymin'(`ystep')`ymax')) ylabel(`ymin'(`ystep')`ymax')  
	        
* 	capture drop vbl

	
* 	graph export "$output/li_et_al_comparison_damage_function_`fuel'_2099_SSP3.pdf", replace 
	restore
}
