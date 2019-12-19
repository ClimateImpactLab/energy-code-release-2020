/*
Creator: Maya Norman
Date last modified: 12/17/19 
Last modified by: 

Purpose: Make time marginal effect plots

*/

****** Set Model Specification Locals ******************************************

local model_main = "$model" // What is the main model for this plot?
local var = "$product" // What product's response function are we plotting?
			
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

* load tech trend ster file

estimates use "$root/sters/FD_FGLS_inter_`model'_lininter.ster"
ereturn display
pause

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

	// get income spline for plotting
	
	preserve
	
	use "$root/data/break_data_`model'.dta", clear
	duplicates drop tpid tgpid, force
	sort tpid tgpid 

	local subInc = avgInc_tgpid[`lg']

	local deltacut_subInc = `subInc' - `ibar'

	restore

	// assign the large income group based on the cell's income covariate
	
	if `subInc' > `ibar' local ig = 2
	else if `subInc' <= `ibar' local ig = 1

	// construct dose response marginal effect of time

	local line ""
	local add ""
	
	foreach k of num 1/2 {
		local line " `line' `add' _b[c.indp`pg'#c.indf1#c.FD_yeartemp`k'_GMFD] * (temp`k' - 20^`k') "
		local line "`line' + _b[c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15yearI`ig'temp`k'] * `deltacut_subInc' * (temp`k' - 20^`k')'"
		local add "+"
	}

	** trace out dose response marginal effect
	predictnl yhat`lg' = `line', se(se`lg') ci(lower`lg' upper`lg')

	* plot dose response
	tw rarea upper`lg' lower`lg' temp1, col(ltbluishgray) || line yhat`lg' temp1, lc (dknavy) ///
	yline(0, lwidth(vthin)) xlabel(-5(10)35, labsize(vsmall)) ///
	ylabel(, labsize(vsmall) nogrid) legend(off) ///
	subtitle("Income Tercile `lg'", size(vsmall) color(dkgreen)) ///
	ytitle("", size(small)) xtitle("", size(small)) ///
	plotregion(color(white)) graphregion(color(white)) nodraw ///
	name(MEaddgraph`lg', replace)			
			
	**add graphic**
	local MEgraphic= "`MEgraphic' MEaddgraph`lg'"
}
	
	
graph combine `MEgraphic', imargin(zero) ycomm rows(1) xsize(9) ysize(3) ///
subtitle("Marginal Effect of Time `var'", size(small)) ///
plotregion(color(white)) graphregion(color(white)) name(comb`i', replace)
graph export "$root/figures/`fig'_ME_time_`var'.pdf", replace
graph drop _all

