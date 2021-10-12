clear all
set more off
macro drop _all
cilpath

global root "${REPO}/energy-code-release-2020"
global model "TINV_clim"

local product "other_energy"
* in "other_energy" "electricity" {
local submodel  ""
* in "" "EX" "lininter" {

global submodel_ov "`submodel'"
global product "`product'"

set scheme s1color

****** Set Model Specification Locals ******************************************

local model_main = "$model" 
local var = "$product" 
local submodel_ov = "$submodel_ov" 

****** Set Plotting Toggles ****************************************************

local col_electricity "dknavy"
local col_electricity_ov "red"
local col_other_energy "dkorange"
local col_other_energy_ov "black"

local col_main "`col_`var''"
local col_ov "`col_`var'_ov'"

*local year = 2099
			
********************************************************************************
* Step 1: Load Data and Clean for Plotting
********************************************************************************
		
use "$DATA/regression/GMFD_`model_main'_regsort.dta", clear

local obs = 35 + abs(-5) + 1

drop if _n > 0
set obs `obs'

replace temp1_GMFD = _n - 6

foreach k of num 1/2 {
	rename temp`k'_GMFD temp`k'
	replace temp`k' = temp1 ^ `k'
}

gen above20 = (temp1 >= 20) 
gen below20 = (temp1 < 20) 

********************************************************************************
* Step 2: Set up for plotting by: 
	* a) finding knot location 
	* b) assigning whether to plot an overlay or not
********************************************************************************

* Get Income Spline Knot Location 
	
preserve
use "$DATA/regression/break_data_`model_main'.dta", clear
summ maxInc_largegpid_`var' if largegpid_`var' == 1
local ibar_main = `r(max)'
restore

if ( "`submodel_ov'" == "EX"  ) {
	preserve
	use "$DATA/regression/break_data_`model_main'_`submodel_ov'.dta", clear
	summ maxInc_largegpid_`var' if largegpid_`var' == 1
	local ibar_ov = `r(max)'
	restore
}
else {
	local ibar_ov = `ibar_main'
}

* Set plotting locals and name tags 

local colorGuide " Model Spec: `model_main' (`col_main') "
local plot_title "`model_main'"

local type_list " _main "

if ( "`submodel_ov'" != "" ) {
	
	local type_list " _ov `type_list' "
	
	local colorGuide "`colorGuide' Overlay Spec: `model_main'_`submodel_ov' (`col_ov') "

	local plot_title "main_model_`plot_title'_overlay_model_`submodel_ov'"

	if "`submodel_ov'" == "lininter" {
		local fig "fig_Appendix-G3B"
	}
	if "`submodel_ov'" == "EX" {
		local fig "fig_Appendix-G2"
	}

}
else{
	local fig "fig_1C"
}		

********************************************************************************
* Step 3: Plot, Plot, Plot
********************************************************************************

local graphicM=""
local graphicM_noSE=""

forval lg=3(-1)1 {	
	forval tr=3(-1)1 {	

		local cellid=`lg'+`tr'*100
		
		preserve
		use "$DATA/regression/break_data_`model_main'.dta", clear
		duplicates drop tpid tgpid, force
		sort tpid tgpid 
		local tr_index = `tr' * 3
		local subCDD = avgCDD_tpid[`tr_index']
		local subHDD = avgHDD_tpid[`tr_index']
		local subInc = avgInc_tgpid[`lg']
		restore
			
		loc SE ""
		loc noSE ""
		
		if "`var'"=="electricity" {
			local pg=1
		}
		else if "`var'"=="other_energy" {
			local pg=2
		}

		foreach type in `type_list' {
			*di "`type_list'"
			
			if (strpos("`type'", "ov") > 0) {
				local plot_model = "`model_main'_`submodel_ov'"
			}
			else {
				local plot_model = "`model_main'"
			}
			
			local deltacut_subInc = `subInc' - `ibar`type''

			if `subInc' > `ibar`type'' local ig = 2
			else if `subInc' <= `ibar`type'' local ig = 1

			local line ""
			local add ""
			
			foreach k of num 1/2 {
				
				local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
				local line = "`line' + above20*_b[c.indp`pg'#c.indf`fg'#c.FD_cdd20_TINVtemp`k'_GMFD]*`subCDD' * (temp`k' - 20^`k')"
				local line = "`line' + below20*_b[c.indp`pg'#c.indf`fg'#c.FD_hdd20_TINVtemp`k'_GMFD]*`subHDD' * (20^`k' - temp`k')"
				local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"

				if (strpos("`plot_model'", "lininter") > 0) {
					local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_yeartemp`k'_GMFD] * (temp`k' - 20^`k')*`year'"
					local line = "`line' + _b[c.indp`pg'#c.indf`fg'#c.FD_dc1_lgdppc_MA15yearI`ig'temp`k']*`deltacut_subInc'*`year'*(temp`k' - 20^`k')"
				}
				local add " + "
			}
			
			estimates use "$OUTPUT/sters/FD_FGLS_inter_`plot_model'"
			predictnl yhat`cellid'`type' = `line', se(se`cellid'`type') ci(lower`cellid'`type' upper`cellid'`type')
				
			if (`tr' != 2) & (`lg' == 2) {
				di "`product'"
				di "income `lg'"
				di "temp `tr'"
				list temp1 yhat`cellid'`type' if temp1 == 0
			}	
		}
	}
}


graph drop _all	
