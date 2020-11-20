
clear all
set more off
macro drop _all
set pause on
cilpath
global root "${REPO}/energy-code-release-2020"
set scheme s1color





clear all
set more off
qui ssc inst egenmore
macro drop _all
pause off
cilpath

/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

// path to energy-code-release repo 

global root "$REPO/energy-code-release-2020"

/////////////////////////////////////////////////////////////////////////////////////////////////

******Set Script Toggles********************************************************

// What model do you want? TINV_clim or TINV_clim_EX
global model "TINV_clim"
local model $model	

*************************************************************************
* Step 1) Construct FE regimes and drop data according to specification
*************************************************************************

do "$root/0_make_dataset/merged/1_issue_fix_v2.do"

//rename COMPILE -- OTHERIND and make sure only have desired flows and products for spec
// OTHERIND = TOTOTHER + TOTIND

replace flow = "OTHERIND" if flow == "COMPILE"
keep if inlist(flow, "OTHERIND")
keep if inlist(product, "other_energy", "electricity")

*************************************************************************
* Step 2) Match Product Specific Climate Data with respective product
*************************************************************************

* Reference climate data construction for information about the issues causing different climate data for different products

forval p=1/4 {
	replace temp`p'_GMFD = temp`p'_other_GMFD if inlist(product,"other_energy")
}

forval q=1/2 {
	replace precip`q'_GMFD = precip`q'_other_GMFD if product=="other_energy"
	replace polyAbove`q'_GMFD = polyAbove`q'_other_GMFD if inlist(product,"other_energy")
	replace polyBelow`q'_GMFD = polyBelow`q'_other_GMFD if inlist(product,"other_energy")
}

replace cdd20_TINV_GMFD = cdd20_other_TINV_GMFD if inlist(product,"other_energy")
replace hdd20_TINV_GMFD = hdd20_other_TINV_GMFD if inlist(product,"other_energy")


***********************************************************************************************************************
* Step 3) Identify income spline knot location by constructing two income groups for each product
***********************************************************************************************************************

//Part A) Prepare Dataset for Income group construction by ensuring only data included in regression remains in dataset

	//Keep only observations we actually have data for
	drop if load_pc == . | lgdppc_MA15 == . | temp1_GMFD == .


	// zero energy consumption for electricity or other energy for TOTOTHER and TOTIND deamed infeasible -> drop observations
	drop if load_pc == 0

	//generate reporting regimes
	egen region_i = group(country FEtag flow product)
	sort region_i year
	tset region_i year

	//Organize variables
	order country year flow product load_pc lgdppc_MA15 pop FEtag *GMFD*

//Part B) Construct Income Groups

	preserve

		duplicates drop country year, force

		// create income and climate quantiles 
		qui egen gpid=xtile(lgdppc_MA15), nq(10)
		pause
		qui egen tpid=xtile(cdd20_TINV_GMFD), nq(3)
		qui egen tgpid=xtile(lgdppc_MA15), nq(3)

		**reversing the order of tpid to put hot ones on top**
		qui replace tpid = 4 - tpid
			
		//Generate large income groups (knot location varies by product)

		qui generate largegpid_electricity =.
		qui replace largegpid_electricity = 1 if (gpid>=1) & (gpid<=6) 
		qui replace largegpid_electricity = 2 if gpid==7 | gpid==8 
		qui replace largegpid_electricity = 2 if gpid==9 | gpid==10 
						
		qui generate largegpid_other_energy =.
		qui replace largegpid_other_energy = 1 if (gpid >= 1) & (gpid <= 2) 
		qui replace largegpid_other_energy = 2 if (gpid >= 3) & (gpid <= 6) 
		qui replace largegpid_other_energy = 2 if (gpid >= 7) & (gpid <= 10)				

		//keep only necessary vars
		keep cdd20_TINV_GMFD hdd20_TINV_GMFD country year lgdppc_MA15 gpid tpid tgpid large*

		// generate average variables for climate and income quantiles for plotting
		//average CDD in each cell
		qui egen avgCDD_tpid=mean(cdd20_TINV_GMFD), by(tpid) 
		//average HDD in each cell
		qui egen avgHDD_tpid=mean(hdd20_TINV_GMFD), by(tpid) 
		//average lgdppc in each cell
		qui egen avgInc_tgpid=mean(lgdppc_MA15), by(tgpid) 

		qui egen maxInc_gpid=max(lgdppc_MA15), by(gpid) //max lgdppc in each cell - this is needed for configs
		
		//max lggdppc for each large income group for each cell
		foreach var in "other_energy" "electricity" {
			qui egen maxInc_largegpid_`var'=max(lgdppc_MA15), by(largegpid_`var') 
		}


		local break_data "$root/data/break_data_`model'.dta"
		save "`break_data'", replace

	restore














foreach temp in 35 0 {
	foreach fuel in "electricity" "other_energy" {

		* to get the ibar_main value
		loc fuel "electricity"
		loc temp 35
		use "$root/data/break_data_TINV_clim.dta", clear
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

		estimates use "$root/sters/FD_FGLS_inter_TINV_clim"
		
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
		graph export "$root/figures/referee_comments/main_vs_nightlight_`fuel'_at_`temp'_test.pdf", replace
		graph drop _all
	}
}

