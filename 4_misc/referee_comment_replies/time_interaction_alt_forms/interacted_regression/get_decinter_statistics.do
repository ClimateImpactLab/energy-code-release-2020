

set scheme s1color


****** Set Model Specification Locals ******************************************

local model_main = "TINV_clim" 
local var = "other_energy" 
local submodel_ov = "decinter"
****** Set Plotting Toggles ****************************************************

local col_electricity "red"
local col_electricity_ov0 "olive_teal"
local col_electricity_ov1 "midgreen"
local col_electricity_ov2 "green"
local col_electricity_ov3 "dkgreen"

local col_other_energy "red"
local col_other_energy_ov0 "olive_teal"
local col_other_energy_ov1 "midgreen"
local col_other_energy_ov2 "green"
local col_other_energy_ov3 "dkgreen"

local col_main "`col_`var''"
local col_ov0 "`col_`var'_ov0'"
local col_ov1 "`col_`var'_ov1'"
local col_ov2 "`col_`var'_ov2'"
local col_ov3 "`col_`var'_ov3'"

global root "/home/liruixue/repos/energy-code-release-2020"

use "$DATA/regression/GMFD_`model_main'_regsort.dta", clear

local obs = 35 + abs(-5) + 1

drop if _n > 0
set obs `obs'

replace temp1_GMFD = _n - 6
replace polyBelow1_GMFD = 20 - temp1_GMFD
replace polyBelow1_GMFD = 0 if polyBelow1_GMFD < 0
replace polyAbove1_GMFD = temp1_GMFD - 20
replace polyAbove1_GMFD = 0 if polyAbove1_GMFD < 0

foreach k of num 1/2 {
	rename temp`k'_GMFD temp`k'
	replace temp`k' = temp1 ^ `k'
	rename polyBelow`k'_GMFD polyBelow`k'
	replace polyBelow`k' = 20 ^ `k' - temp1 ^ `k'
	replace polyBelow`k' = 0 if polyBelow`k' < 0
	rename polyAbove`k'_GMFD polyAbove`k'
	replace polyAbove`k' = temp1 ^ `k' - 20 ^ `k'
	replace polyAbove`k' = 0 if polyAbove`k' < 0

}


gen above20 = (temp1 >= 20)
gen below20 = (temp1 < 20) 

preserve
use "$DATA/regression/break_data_`model_main'.dta", clear
summ maxInc_largegpid_`var' if largegpid_`var' == 1
local ibar_main = `r(max)'
restore

local ibar_ov0 = `ibar_main'
local ibar_ov1 = `ibar_main'
local ibar_ov2 = `ibar_main'
local ibar_ov3 = `ibar_main'

* Set plotting locals and name tags 

local colorGuide " Model Spec: `model_main' (`col_main') "
local plot_title "`model_main'"

local type_list " _main "

local type_list " _ov0 _ov1 _ov2 _ov3`type_list' " 

local colorGuide "`colorGuide' Overlay Spec: `model_main'_`submodel_ov' 1970(`col_ov0') 1980(`col_ov1') 1990(`col_ov2') 2000(`col_ov3') "

local plot_title "main_model_`plot_title'_overlay_model_`submodel_ov'"

local fig "fig_Appendix-G3B"

********************************************************************************
* Step 3: Plot, Plot, Plot
********************************************************************************

local graphicM=""
local graphicM_noSE=""

tempname memhold
tempfile results
*postfile `memhold' str(model lg tr temp yhat) using "`results'"

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

			if (strpos("`type'", "ov") > 0) {
				local plot_model = "`model_main'_`submodel_ov'"
				local pt = substr("`type'", -1, .)
			}
			 else {
				local plot_model = "`model_main'"
			}
			local deltacut_subInc = `subInc' - `ibar`type''

			if `subInc' > `ibar`type'' local ig = 2
			else if `subInc' <= `ibar`type'' local ig = 1

			local line ""
			local line`cellid'`type' ""
			local add ""
			
			foreach k of num 1/2 {
				
				local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
				local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*`subCDD' * (temp`k' - 20^`k')"
				local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*`subHDD' * (20^`k' - temp`k')"
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"

				* statistical tests: 
				* line`cellid'`type' is the local used for statistical testing
				* it's the same as the plotting expression, only with temp replaced with 35
				* above20 replaced with 1, below20 replaced with 0
				local line`cellid'`type' = " `line`cellid'`type'' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (35^`k' - 20^`k')"
				local line`cellid'`type' = "`line`cellid'`type'' + 1*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*`subCDD' * (35^`k' - 20^`k')"
				local line`cellid'`type' = "`line`cellid'`type'' + 0*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*`subHDD' * (20^`k' - 35^`k')"
				local line`cellid'`type' = "`line`cellid'`type'' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(35^`k' - 20^`k')"
				

				if "`plot_model'" == "TINV_clim_decinter" {
					local line = "`line' + _b[`pt'.indd#c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
					local line = "`line' + _b[`pt'.indd#c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(temp`k' - 20^`k')"

					local line`cellid'`type' = "`line`cellid'`type'' + _b[`pt'.indd#c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (35^`k' - 20^`k')"
					local line`cellid'`type' = "`line`cellid'`type'' + _b[`pt'.indd#c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*`deltacut_subInc'*(35^`k' - 20^`k')"

				}

				local add " + "
			}

			*di "`type'"
			estimates use "$OUTPUT/sters/FD_FGLS_inter_`plot_model'"
			*di "$OUTPUT/sters/FD_FGLS_inter_`plot_model'"

			qui predictnl yhat`cellid'`type' = `line', se(se`cellid'`type') ci(lower`cellid'`type' upper`cellid'`type')
			*list yhat`cellid'`type' if temp1 == 35
			qui sum yhat`cellid'`type' if temp1 == 35
			local yhat = cond(r(min)==r(max),r(min),.)

			qui sum lower`cellid'`type' if temp1 == 35
			local lower = cond(r(min)==r(max),r(min),.)

			qui sum upper`cellid'`type' if temp1 == 35
			local upper = cond(r(min)==r(max),r(min),.)

	*		post `memhold'  ("`type'") ("`lg'") ("`tr'") ("35") ("`yhat'") 
			* display the statistics
			di "model:`type' inc:`lg' clim:`tr' temp:35 yhat:" %6.5f `yhat' "  lower:" %6.5f `lower'  "  upper:" %6.5f `upper'
		}
	}
}


* statistical tests:
estimates use "$OUTPUT/sters/FD_FGLS_inter_TINV_clim_decinter"
testnl `line103_ov0' = `line103_ov1' = `line103_ov2' = `line103_ov3'


*postclose `memhold'
*use "`results'", clear

