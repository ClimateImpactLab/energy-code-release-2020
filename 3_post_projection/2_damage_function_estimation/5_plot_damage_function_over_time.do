*****************************************
* DAMAGE FUNCTION PLOTTING , for appendix, plots of how damage function evolves across time
*****************************************

**********************************************************************************
* SET UP -- Change paths and input choices to fit desired output
**********************************************************************************

clear all
set more off
set scheme s1color

glob DB "C:/Users/TomBearpark/SynologyDrive"
glob DB_data "$DB/GCP_Reanalysis/ENERGY/code_release_data"
glob dir "$DB_data/damage_function_estimation"

* SSP toggle 
loc ssp = "SSP3" 

* Model toggle 
loc model = "main"


******* PLOTTING OPTIONS *******
loc ymin1 = -20000
loc ymax1 = 120000
loc ystep1 = 20000



* **********************************************************************************
* * Feather plot for pre- and post-2100 damage functions
* **********************************************************************************

* import the gmst anomaly data
insheet using "$gmstdir/GMTanom_all_temp_2001_2010.csv", comma names clear

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


local types = "other_energy electricity total"
local types = " total "
foreach t in `types' {

	if ("`t'" == "total") {
		import delim "$damage_dir/df_mean_output_SSP3.csv", clear
		keep if growth_rate == "price014"
		loc ytit = "Bn 2019 USD" 
		loc title "Total Energy Damage Function, Evolution Over Time"
		loc save_as "total_energy_df_price014.pdf"
	}
	else{
		if("`t'" == "other_energy"){
			import delim "$impacts_dir/damage_TINV_clim_income_spline_semi-parametric_impacts_npc_value_other_energy_coefficients_quad_global_SSP3", clear
		}

		if("`t'" == "electricity"){
			import delim "$impacts_dir/damage_TINV_clim_income_spline_semi-parametric_impacts_npc_value_electricity_coefficients_quad_global_SSP3", clear
		}

		* Convert to gigajoules
		* foreach var in cons beta1 beta2 {
		* 	replace `var' = `var' * 0.0036
		* }
		loc ytit = "Gigajoules"
	}

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

	    di "`ymax'"
	    sort anomaly
		
	    graph tw `gr', yline(0, lwidth(vthin)) ///
	    		ytitle("`ytit'") xtitle("GMST Anomaly") ///
	            title("`title'", size(small)) ///
	            name("`t'", replace) xscale(r(0(1)10)) xlabel(0(1)10) legend(off) scheme(s1mono) ///
	            ylabel(, labsize(small)) 
	            * yscale(r(`ymin1'(`ystep1')`ymax1')) ylabel(`ymin1'(`ystep1')`ymax1', labsize(small)) 
	   graph export "$outputdir/`save_as'", replace 
}

graph combine electricity other_energy total, scheme(s1mono)  rows(1) // ycomm
* graph export "$outputdir/scc/`prc'_allyear_combined_dfs_SSP3.pdf", replace
