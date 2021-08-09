/*

Purpose: Plot change in energy temperature response per year in Temporal Trend Model
plininter model
*/

set scheme s1color

****** Set Model Specification Locals ******************************************

local model = "$model" // What is the main model for this plot?
local var = "$product" // What product's response function are we plotting?
local fig = "fig_Appendix-G3A" // Whats the plots figure number in the paper?

********************************************************************************
* Step 1: Load Data and Clean for Plotting
********************************************************************************
		
use "$DATA/regression/GMFD_`model'_regsort.dta", clear
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
use "$DATA/regression/break_data_`model'.dta", clear
summ maxInc_largegpid_`var' if largegpid_`var' == 1
local ibar = `r(max)'
restore

* load temporal trend ster file


estimates use "$OUTPUT/sters/FD_FGLS_inter_`model'_plininter.ster"

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

// local tbar = 1991 
// loop over two time periods: 1971-1991 and 1991-2010
foreach pt in 0 1  {
	* loop over income terciles
	local MEgraphic
	forval lg = 1/3 {

		// get income spline for plotting
		
		preserve
		
			use "$DATA/regression/break_data_`model'.dta", clear
			duplicates drop tpid tgpid, force
			sort tpid tgpid 
			local subInc = avgInc_tgpid[`lg']
			local deltacut_subInc = `subInc' - `ibar'

		restore

		// assign the large income group based on the cell's income covariate
		if `subInc' > `ibar' local ig = 2
		else if `subInc' <= `ibar' local ig = 1

		// construct energy temperature response marginal effect of time in tech trend model
		local line ""
		local add ""

		// determine the sign of the coefficients based on time period
		if `pt' == 0 {
			local sign "-"
			local period "1971-1990"
		}
		else {
			local sign ""
			local period "1991-2010"
		}

		forval k=1/2 {
			local line " `line' `add' `sign'_b[`pt'.indt#c.indp`pg'#c.indf1#c.FD_pyeartemp`k'_GMFD] * (temp`k' - 20^`k') "
			local line "`line' + `sign'_b[`pt'.indt#c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15pyearI`ig'temp`k'] * `deltacut_subInc' * (temp`k' - 20^`k')"
			local add " + "
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
	graph export "$OUTPUT/figures/`fig'_ME_time_`model'_plininter_`var'_`period'.pdf", replace
	graph drop _all
	drop yhat* se* lower* upper*

}

