
clear all
set more off
macro drop _all
cilpath
global root "${REPO}/energy-code-release-2020"
set scheme s1color

global estimate_with_nightlight_term "true"
global plot_only_1992 "true"

foreach temp in 35 0 {
	foreach fuel in "electricity" "other_energy" {

*		loc fuel "electricity"
*		loc temp 35
		* to get the ibar_main value
		preserve
		use "$DATA/regression/break_data_TINV_clim.dta", clear
		summ maxInc_largegpid_`fuel' if largegpid_`fuel' == 1
		local ibar_main = `r(max)'
		restore

		* read data, replace temperature with 35 or 0, generate above/below 20 indicators
		use "$DATA/regression/GMFD_TINV_clim_regsort_nightlight_1992.dta", clear
		if "$plot_only_1992" == "true" {
			drop if year != 1992
		}
		drop if product != "`fuel'"

		replace temp1_GMFD = `temp'

		foreach k of num 1/2 {
			rename temp`k'_GMFD temp`k'
			replace temp`k' = temp1 ^ `k'
		}

		gen above20 = (temp1 >= 20) 
		gen below20 = (temp1 < 20) 

		if "`fuel'"=="electricity" {
			local pg=1
		}
		else if "`fuel'"=="other_energy" {
			local pg=2
		}

		* this value in our plotting code is constructed using 
		* the average income in each cell minus ibar_main
		* so I constructed it by substracting the income of each observation with ibar_main
		gen deltacut_subInc = lgdppc_MA15 - `ibar_main'

		* nightlight model predictions
		estimates use "$OUTPUT/sters/FD_FGLS_inter_nightlight"

		local line ""
		local add ""

		* loop through polynomial order 1 and 2
		foreach k of num 1/2 {	


			local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
			* in the following two lines, I changed the average hdd/cdd in the cell to hdd/cdd of each observation
			local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*cdd20_TINV_GMFD * (temp`k' - 20^`k')"
			local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*hdd20_TINV_GMFD * (20^`k' - temp`k')"
			
			* loop through the large/small income groups
			* only one term will be non-zero for each observation because only one of largeind1 and largeind2 will be turned on
			foreach ig of num 1/2 {
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*deltacut_subInc*largeind`ig'*(temp`k' - 20^`k')"
			}
			* nightlight terms
			if "$estimate_with_nightlight_term" == "true" {
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD#c.nightlight]* nightlight * (temp`k' -20^`k')"
			}
			local add " + "
		}

		predictnl yhat_nl = `line', se(se_nl) ci(lower_nl upper_nl)

		* main model predictions, everything the same except for removing the nightlight line

		estimates use "$OUTPUT/sters/FD_FGLS_inter_TINV_clim"
		
		local line ""
		local add ""

		foreach k of num 1/2 {
			local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
			local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*cdd20_TINV_GMFD * (temp`k' - 20^`k')"
			local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*hdd20_TINV_GMFD * (20^`k' - temp`k')"
			foreach ig of num 1/2 {
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*deltacut_subInc*largeind`ig'*(temp`k' - 20^`k')"
			}
		 	local add " + "
		}

		predictnl yhat_main = `line', se(se_main) ci(lower_main upper_main)

		* plot
		graph tw scatter yhat_nl yhat_main if largeind1==1, msize(vtiny) || scatter yhat_nl yhat_main if largeind1==0, msize(vtiny)  || line yhat_nl yhat_nl, sort legend(lab(1 "small income") lab(2 "large income") lab(3 "45 degree line")) ytitle("nightlight") xtitle("main model") title("`fuel' `temp'C") aspectratio(1) 
		graph export "$OUTPUT/figures/referee_comments/nightlight/main_vs_nightlight_`fuel'_at_`temp'_pred_w_nl_term_${estimate_with_nightlight_term}_only_1992_${plot_only_1992}.pdf", replace
		graph drop _all
	}
}

