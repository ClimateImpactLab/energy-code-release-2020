

clear all
set more off
macro drop _all
cilpath
* path to energy-code-release repo:

global root "${REPO}/energy-code-release-2020"

global model "TINV_clim"

********************************************************************************
* Step 1: Estimate Energy Temperature Response
********************************************************************************
global product "electricity"

****** Set Model Specification Locals ******************************************

local model = "$model" 
local var = "$product" 

********************************************************************************
* Step 1: Load Data and Clean for Plotting
********************************************************************************
		
use "$root/data/GMFD_`model'_regsort.dta", clear

//Set up locals for plotting
local obs = 35 + abs(-5) + 1

//clean data for plotting
drop if _n > 0
set obs `obs'

replace temp1_GMFD = _n - 6

foreach k of num 1/2 {
	rename temp`k'_GMFD temp`k'
	replace temp`k' = temp1 ^ `k'
}

********************************************************************************
* Step 2: Set up for plotting by: 
	* a) finding knot location 
	* b) load ster
	* b) assigning product index
********************************************************************************

* Get Income Spline Knot Location 
	
preserve
use "$root/data/break_data_`model'.dta", clear
summ maxInc_largegpid_`var' if largegpid_`var' == 1
local ibar = `r(max)'
restore

* load temporal trend ster file

estimates use "$root/sters/FD_FGLS_inter_`model'_lininter.ster"

* set product specific index for coefficients

if "`var'"=="electricity" {
	local pg=1
}
else if "`var'"=="other_energy" {
	local pg=2
}

********************************************************************************
* Step 3: Plot, Plot, Plot
********************************************************************************

* loop over income terciles

forval lg = 1/3 {

	* get income spline for plotting
	
	preserve
	
		use "$root/data/break_data_`model'.dta", clear
		duplicates drop tpid tgpid, force
		sort tpid tgpid 
		local subInc = avgInc_tgpid[`lg']
		local deltacut_subInc = `subInc' - `ibar'

	restore

	* assign the large income group based on the cell's income covariate
	if `subInc' > `ibar' local ig = 2
	else if `subInc' <= `ibar' local ig = 1

	* construct energy temperature response marginal effect of time in tech trend model
	local line ""
	local add ""
	forval k=1/2 {
		local line " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_yeartemp`k'_GMFD] * (temp`k' - 20^`k') "
		local line "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15yearI`ig'temp`k'] * `deltacut_subInc' * (temp`k' - 20^`k')"
		local add " + "
	}

	** trace out dose response marginal effect
	predictnl yhat`lg' = `line', se(se`lg') ci(lower`lg' upper`lg')

	list temp1 yhat`lg'
}

graph drop _all


