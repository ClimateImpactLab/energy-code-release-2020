/*
Creator: Maya Norman
Date last modified: 12/17/18 
Last modified by: 

Purpose: Make marginal effect plots

Plots ME for time (TINV_clim*_lininter), income (TINV_clim_ui), and climate

In the set model parameters section, specify ster related spec. In the set script toggles
set plotting specs.

*/

clear all
set more off
macro drop _all
set scheme s1color
pause on

//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{
	local DROPBOX "/Users/`c(username)'/Dropbox"
}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
}

******Set Model Parameters******************************************************

//Set data type ie historic or replicated
global data_type "replicated_data"
local data_type $data_type

//Set zero subset case
//Number of data subsets used to estimate
local bknum "break2"
local case "Exclude" // "Exclude" "Include"
local IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues

//income grouping test (visual or iterative-ftest)

global grouping_test "semi-parametric"
local grouping_test $grouping_test

//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
global model "TINV_clim_income_spline"
local model $model

//Climate Data type
global clim_data "GMFD"
local clim_data $clim_data

//Define if covariates are MA15 or TINV
if ("$model" != "TINV_both") {
	//Climate Var Average type
	local ma_clim "TINV"
	//Income Var Average type
	local ma_inc "MA15"
}
else if ("$model" == "TINV_both") {
	//Climate Var Average type
	local ma_clim "TINV"

	//Income Var Average type
	local ma_inc "TINV"	
}

******Set Script Toggles********************************************************

/*
You have two options: change the submodel to ui or lininter to plot ME income or time 
respectiviely or change the submodel to "" and the code will plot the ME of climate 
for whatever model you specified.
*/

//Submodel type-- (Default: "")
global submodel "lininter"
local submodel $submodel
				
//Which products do you want to plot?
local product_list "electricity other_energy"

if (inlist("$submodel", "ui", "lininter", "smooth_linincome")) {
	local submodel "_`submodel'"
	local effect "$submodel"
}
else {
	local effect "climate"
}

//confirm script is set up to plot specification
assert (inlist("$submodel", "ui", "lininter","")) //ensure toggles set within capabilities of script
	
********************************************************************************

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis"	
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Output/`clim_data'/rationalized_code/$data_type/figures/marginal_effect_plots/"	

//Load data and set up plotting colors and overlays
	
if (inlist("`model'","TINV_clim","TINV_clim_ui","TINV_clim_lininter","TINV_clim_income_spline", "TINV_clim_decinter")) {
	use "`data'/`clim_data'/rationalized_code/$data_type/data/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_TINV_clim_`data_type'_regsort.dta", clear
}
else {
	use "`data'/`clim_data'/rationalized_code/$data_type/data/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'_regsort.dta", clear
}
	
estimates use "`data'/`clim_data'/rationalized_code/$data_type/sters/FD_FGLS/FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model'`submodel'.ster"
ereturn display
pause

//Prepare to plot

//Sets values for plotting.
local min = -5
local max = 35
local omit = 20 //zeroed
local obs = `max' + abs(`min') + 1
local midcut = 20 

//set up data for plotting
drop if _n > 0
set obs `obs'
replace temp1_`clim_data' = _n + `min' -1
gen above`midcut' = (temp1_`clim_data' >= `midcut') //above 20 indicator
gen below`midcut' = (temp1_`clim_data' < `midcut') //below 20 indicator


//set up locals based on effect type plotting
if ("`effect'" == "lininter") {
	
	local tt = "time"
	di "`model' `grouping_test'"
	local typelist = " FD_year "
	
	if ("`grouping_test'" == "semi-parametric" & "`model'" == "TINV_clim") {
		local end = 2
		local start = 1
	}
	else if ("`grouping_test'" == "semi-parametric" & "`model'" == "TINV_clim_income_spline") {
		local start = 1
		local end = 5
	}

	replace above`midcut' = 1 //do not need temp dummy for effect
	replace below`midcut' = 1 //do not need temp dummy for effect

} 
else if ("`effect'" == "ui") {

	local typelist = " FD_lgdppc_`ma_inc' "
	local tt = "income"
	local end = 3 //number of income groups
	local start = `end' //income only interacted for top income group
	replace above`midcut' = 1 //do not need temp dummy for effect
	replace below`midcut' = 1 //do not need temp dummy for effect

}
else if ("`effect'" == "climate") {

	local typelist = " FD_cdd20_`ma_clim' FD_hdd20_`ma_clim' "
	local tt = "climate"
	local end = 3 //number of income groups
	local start = 1

	if ( "`grouping_test'" == "semi-parametric" ) {
		local end = 2
	}

}

foreach var in `product_list' {

	local xs = 0 //counter for combine graph plotting (xaxis size)
	if "`var'"=="electricity" {
		local stit="Electricity"
		local pg=1
		local fg=1
		local IG=3
	}
	else if "`var'"=="other_energy" {
		local stit="Non-Electricity"
		local pg=2
		local IG=3
		local fg=1
	}
	
	//Make Plots by income Group
	foreach type in `typelist' {

		local name = substr("`type'", strpos("`type'", "_") + 1,.)
		local name = substr("`name'", 1 , strpos("`name'", "_") - 1)
		local `name'MEgraphic=""

		forval lg = `start'/`end' { //large income group
		
			local line ""
			local add ""
			local real_lg = `lg'

			if (inlist("`submodel'", "_income_spline") ///
			| inlist("`model'","TINV_clim_income_spline")) {
				local t = ""
			}
			else {
				local t = "I`lg'"
			}

			if (("`submodel'" == "_income_spline" | inlist("`model'","TINV_clim_income_spline"))  ///
					& "`grouping_test'" == "semi-parametric" & "`effect'" == "lininter") {
				preserve
				local break_data "`data'/`clim_data'/rationalized_code/$data_type/data"
				if (inlist("`model'","TINV_clim","TINV_clim_ui","TINV_clim_lininter", "TINV_clim_decinter","TINV_clim_income_spline") ///
					& inlist("`grouping_test'", "visual", "semi-parametric")) {
					di "Using visual TINV_clim breaks."
					use "`break_data'/break10_clim`clim_data'_`case'`IF'_`bknum'_visual_TINV_clim_`data_type'.dta", clear
				}
				else {
					di "Using main spec breaks."
					use "`break_data'/break10_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'.dta", clear
				}
				
				forval i=1/2 {
					summ maxInc_largegpid_`var' if largegpid_`var' == `i'
					local ibar`i' = `r(max)'
				}

				keep if qgpid==`real_lg'
				duplicates drop qgpid, force
				summ largegpid_`var'

				if `r(max)' >= 2 local lg = 2
				if `r(max)' < 2 local lg = 1 

				local subInc=avgInc_qgpid[1]

				forval i=1/2 {
					local deltacut`i'_subInc= abs(`subInc' - `ibar`i'')
				}

				foreach note in "avgInc" "maxInc" "minInc" {
					replace `note'_largegpid_`var'=round(`note'_largegpid_`var',0.01)
					tostring `note'_largegpid_`var', force replace format(%12.2f)
					local `note'_`var'=`note'_largegpid_`var'[1]
				}

				restore
				
			}

			foreach k of num 1/2 {
				
				//add plus sign in front of first term only if not first term in loop
				if `k' > 1 local add "+"
				if `k' == 1 local add ""

				qui replace temp`k'_`clim_data' = temp1_`clim_data' ^ `k'

				if ("`name'" == "hdd20") {
					local temp_var`k' "(`omit'^`k' - temp`k'_`clim_data')"
					local dummy "below"
				} 
				else {
					local temp_var`k' "(temp`k'_`clim_data' - `omit'^`k')"
					local dummy "above"
				}

				local line " `line' `add' `dummy'`midcut'*_b[c.indp`pg'#c.indf`fg'#c.`type'`t'temp`k'_`clim_data'] * `temp_var`k'' "
				if (("`submodel'" == "_income_spline" | inlist("`model'","TINV_clim_income_spline"))  ///
					& "`grouping_test'" == "semi-parametric" & "`effect'" == "lininter") {
					local line "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_`ma_inc'yearI`lg'temp`k']*`deltacut1_subInc'*`temp_var`k''"
				}

			}

			** Predict
			predictnl yhat = `line', se(se) ci(lower upper)

			tw rarea upper lower temp1_`clim_data', col(ltbluishgray) || line yhat temp1_`clim_data', lc (dknavy) ///
			yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
			ylabel(, labsize(vsmall) nogrid) legend(off) ///
			subtitle("Income Group `lg'", size(vsmall) color(dkgreen)) ///
			ytitle("", size(small)) xtitle("", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) nodraw ///
			name(`name'MEaddgraph`real_lg', replace)			
					
			**add graphic**
			local `name'MEgraphic= "``name'MEgraphic' `name'MEaddgraph`real_lg'"
			
			drop yhat se lower upper
			
			local xs = `xs' + 1 //counter for plot size
		}

	}
	
	local xs = `xs' * 3 //xaxis size for plotting
	
	if (!inlist("`name'", "hdd20", "cdd20")) {
		graph combine `MEgraphic', imargin(zero) ycomm rows(1) xsize(`xs') ysize(3) ///
		subtitle("`tt' Marginal Effect `stit' (`model' `submodel')", size(small)) ///
		plotregion(color(white)) graphregion(color(white)) name(comb`i', replace)
		graph export "`output'/ME_`tt'_`var'_`grouping_test'_`model'_`effect'.pdf", replace
	}
	else if (inlist("`name'", "hdd20", "cdd20")) {
		
		foreach dd in "cdd20" "hdd20" {
			graph combine ``dd'MEgraphic', imargin(zero) ycomm rows(1) xsize(6) ysize(2) ///
			subtitle(" `dd' ", size(small)) ///
			plotregion(color(white)) graphregion(color(white)) nodraw name(comb`dd', replace)
		}

		graph combine combcdd20 combhdd20 , imargin(zero) ycomm rows(2) xsize(6) ysize(5) /// 
		title("Marginal Climate Effects Interacted Model (`model')", size(small)) ///
		subtitle("", size(vsmall)) ///
		graphregion(color(gs16)) 
		graph export "`output'/ME_`tt'_`var'_`grouping_test'_`model'.pdf", replace

	}
	
	graph drop _all

}
