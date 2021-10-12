
********************************************************************************/* 
  */repeat the process for quadinter model for referee comment
********************************************************************************

set scheme s1color

****** Set Model Specification Locals ******************************************

// What is the main model for this plot?
local model = "$model" 

// What product's response function are we plotting?
local var = "$product" 

// Whats the plots figure number in the paper?
local fig = "fig_Appendix-G3A" 

local MEgraphic 
********************************************************************************
* Step 1: Load Data and Clean for Plotting
********************************************************************************
		
use "$DATA/regression/GMFD_`model'_regsort.dta", clear

//Set up locals for plotting
local obs = 2100 - 1971 + 1

//clean data for plotting
drop if _n > 0
set obs `obs'

local tbar = 1991

replace year = _n + 1970 
replace pyear = year - `tbar' if year >= `tbar'
replace pyear = `tbar' - year if year < `tbar'


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

// plot lininter in the same manner as sanity check
estimates use "$OUTPUT/sters/FD_FGLS_inter_`model'_plininter.ster"


* set product specific index for coefficients

if "`var'"=="electricity" {
	local pg=1
}
else if "`var'"=="other_energy" {
	local pg=2
}


// loop over temperature
foreach temp in 0 35 {
	* loop over income terciles
 
	cap drop *yhat* *lower* *upper*  *se*
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

	
		// two cases for the time interaction term: >= and < 1991
		// turn indt on and off for to select which part of the curve to plot	
		foreach pt in 0 1 {
	
			// construct energy temperature response marginal effect of time in tech trend model
			local line0 ""
			local line1 ""
			local add ""

			if `pt' == 0 {
				local sign "(-1) *"
				replace indt = 1 if year < `tbar'
				replace indt = 0 if year >= `tbar'					
			}
			else {
				local sign ""
				replace indt = 1 if year >= `tbar'
				replace indt = 0 if year < `tbar'
			}

			forval k=1/2 {
				local line`pt' " `line`pt'' `add' `sign' indt * _b[`pt'.indt#c.indp`pg'#c.indf1#c.FD_pyeartemp`k'_GMFD] * (`temp'^`k' - 20^`k') * pyear "
				local line`pt' "`line`pt'' + `sign' indt * _b[`pt'.indt#c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15pyearI`ig'temp`k'] * `deltacut_subInc' * (`temp'^`k' - 20^`k') * pyear"
				local add " + "
			}
			** trace out dose response marginal effect
			predictnl yhat`lg'`pt' = `line`pt'', se(se`lg'`pt') ci(lower`lg'`pt' upper`lg'`pt')
		}

		* sum up the two segments
		foreach v in yhat se lower upper {
			gen `v'`lg' = `v'`lg'0 + `v'`lg'1
		}

		* plot dose response
		tw rarea upper`lg' lower`lg' year, col(ltbluishgray) || line yhat`lg' year, lc (dknavy) ///
		yline(0, lwidth(vthin))  ///
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
	graph export "$OUTPUT/figures/`fig'_ME_time_`model'_plininter_`var'_`temp'C_over_time.pdf", replace
	graph drop _all

}
