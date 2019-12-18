/*
Creator: Maya Norman
Date last modified: 12/17/19 
Last modified by: 

Purpose: Make time marginal effect plots

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

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis"	
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/GMFD/rationalized_code/$data_type/marginal_effect_plots/"	

//Load data
	
use "`data'/GMFD/rationalized_code/replicated_data/data/climGMFD_Exclude_all-issues_break2_semi-parametric_TINV_clim_replicated_data_regsort.dta", clear

estimates use "`data'/GMFD/rationalized_code/replicated_data/sters/FD_FGLS/FD_FGLS_inter_climGMFD_Exclude_all-issues_break2_semi-parametric_poly2_TINV_clim_income_spline_lininter.ster"
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
replace temp1_GMFD = _n + `min' -1

foreach var in "electricity other_energy" {

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

	forval lg = 1/3 { //large income group
		
		local real_lg = `lg'

		//extract info for plotting
		preserve
		
		di "Using visual TINV_clim breaks."
		use "`data'/GMFD/rationalized_code/replicated_data/data/break10_climGMFD_Exclude_all-issues_break2_visual_TINV_clim_replicated_data.dta", clear

		summ maxInc_largegpid_`var' if largegpid_`var' == 1
		local ibar = `r(max)'

		duplicates drop tpid tgpid, force
		sort tpid tgpid 

		local subInc = avgInc_tgpid[`lg']

		local deltacut_subInc = `subInc' - `ibar'

		restore

		local line ""
		local add ""
		
		foreach k of num 1/2 {

			qui replace temp`k'_GMFD = temp1_GMFD ^ `k'

			if ("`name'" == "hdd20") {
				local temp_var`k' "(`omit'^`k' - temp`k'_GMFD)"
				local dummy "below"
			} 
			else {
				local temp_var`k' "(temp`k'_GMFD - `omit'^`k')"
				local dummy "above"
			}

			local line " `line' `add' _b[c.indp`pg'#c.indf`fg'#c.FD_yeartemp`k'_GMFD] * `temp_var`k'' "
			local line "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_MA15yearI`lg'temp`k']*`deltacut1_subInc'*`temp_var`k''"
			local add "+"
		}

		** Predict
		predictnl yhat = `line', se(se) ci(lower upper)

		tw rarea upper lower temp1_GMFD, col(ltbluishgray) || line yhat temp1_GMFD, lc (dknavy) ///
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
	
	local xs = `xs' * 3 //xaxis size for plotting
	
	graph combine `MEgraphic', imargin(zero) ycomm rows(1) xsize(`xs') ysize(3) ///
	subtitle("time Marginal Effect `stit' (TINV_clim_income_spline_lininter)", size(small)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb`i', replace)
	graph export "`output'/ME_time_`var'_semi-parametric_TINV_clim_income_spline_lininter.pdf", replace

	
	graph drop _all

}

