
clear all
set more off
macro drop _all
set pause on
cilpath
global root "${REPO}/energy-code-release-2020"
set scheme s1color

foreach temp in 35 0 {
	foreach fuel in "electricity" "other_energy" {

		* to get the ibar_main value
		loc fuel "electricity"
		loc temp 35
		use "$DATA/regression/break_data_TINV_clim.dta", clear
		summ maxInc_largegpid_`fuel' if largegpid_`fuel' == 1
		local ibar_main = `r(max)'

		duplicates drop tpid tgpid, force
		sort tpid tgpid 
		local tr_index = 3 * 3 
		keep *gdp* avgCDD* avgHDD* avgInc* tpid tgpid large*
		gen temp1 = `temp'
		gen temp2 = temp1 ^ 2

		gen above20 = (temp1 >= 20) 
		gen below20 = (temp1 < 20) 


		if "`fuel'"=="electricity" {
			local pg=1
		}
		else if "`fuel'"=="other_energy" {
			local pg=2
		}

		gen largeind_`fuel'1 = 1 if avgInc_tgpid <= `ibar_main'
		gen largeind_`fuel'2 = 0 if avgInc_tgpid <= `ibar_main'
		
		replace largeind_`fuel'2 = 1 if avgInc_tgpid > `ibar_main'
		replace largeind_`fuel'1 = 0 if avgInc_tgpid > `ibar_main'

		* this value in our plotting code is constructed using 
		* the average income in each cell minus ibar_main
		* so I constructed it by substracting the income of each observation with ibar_main
		gen deltacut_subInc = avgInc_tgpid - `ibar_main'


		* main model predictions, everything the same except for removing the nightlight line

		estimates use "$OUTPUT/sters/FD_FGLS_inter_TINV_clim"
		
		local line ""
		local add ""

		foreach k of num 1/2 {
			local line = " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD] * (temp`k' - 20^`k')"
			local line = "`line' + above20*_b[c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD]*avgCDD_tpid * (temp`k' - 20^`k')"
			local line = "`line' + below20*_b[c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD]*avgHDD_tpid * (20^`k' - temp`k')"
			foreach ig of num 1/2 {
				local line = "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`ig'temp`k']*deltacut_subInc*largeind_`fuel'`ig'*(temp`k' - 20^`k')"
			}
		 	local add " + "
		}

		predictnl yhat_main = `line'

		* plot
		graph tw scatter yhat_main temp1, ytitle("main model") xtitle("temp") title("`fuel' `temp'C") 
		graph export "$OUTPUT/figures/referee_comments/main_vs_nightlight_`fuel'_at_`temp'_test.pdf", replace
		graph drop _all
	}
}

