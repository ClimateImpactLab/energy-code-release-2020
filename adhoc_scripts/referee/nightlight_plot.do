
clear all
set more off
macro drop _all
cilpath
global root "${REPO}/energy-code-release-2020"
set scheme s1color

foreach temp in 35 0 {
	foreach fuel in "electricity" "other_energy" {

		* read data, replace temperature with 35 or 0, generate above/below 20 indicators
		use "$root/data/GMFD_TINV_clim_regsort_nightlight_1992.dta", clear

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


		* nightlight model predictions
		estimates use "$root/sters/FD_FGLS_inter_nightlight"

		local line ""
		local add ""

		* loop through polynomial order 1 and 2
		foreach k of num 1/2 {	

			* the following lines are the same as plotting code 
			* except that FD_dc1_lgdppc_MA15I`ig'temp`k' term is from the dataset, not determined based on the cell
			local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
			local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*FD_cdd20_TINVtemp`k'_GMFD * (temp`k' - 20^`k')"
			local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*FD_hdd20_TINVtemp`k'_GMFD * (20^`k' - temp`k')"
			
			* loop through the large/small income groups
			foreach ig of num 1/2 {
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*FD_dc1_lgdppc_MA15I`ig'temp`k'*(temp`k' - 20^`k')"
			}
			* nightlight terms
			local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD#c.nightlight]*FD_temp`k'_GMFD * nightlight * (20^`k' - temp`k')"
			local add " + "
		}

		predictnl yhat_nl = `line', se(se_nl) ci(lower_nl upper_nl)

		* main model predictions, everything the same except for removing the nightlight line

		estimates use "$root/sters/FD_FGLS_inter_TINV_clim"
		
		local line ""
		local add ""

		foreach k of num 1/2 {
			local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
			local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*FD_cdd20_TINVtemp`k'_GMFD * (temp`k' - 20^`k')"
			local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*FD_hdd20_TINVtemp`k'_GMFD * (20^`k' - temp`k')"
			foreach ig of num 1/2 {
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*FD_dc1_lgdppc_MA15I`ig'temp`k'*(temp`k' - 20^`k')"
			}
			local add " + "
		}

		predictnl yhat_main = `line', se(se_main) ci(lower_main upper_main)

		
		* plot
		graph tw scatter yhat_nl yhat_main || line yhat_nl yhat_nl, sort ytitle("nightlight") xtitle("main model") title("`fuel' `temp'C") legend(off)
		graph export "$root/figures/referee_comments/main_vs_nightlight_`fuel'_at_`temp'.pdf", replace
		graph drop _all
	}
}

