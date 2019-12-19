/*
Creator: Yuqi Song
Date last modified: 1/15/19 
Last modified by: Maya Norman

Purpose: Plot stacked global dose response function regression (Figure A.5 in the paper)

*/

****** Set Model Specification Locals ******************************************

local model = "$model"

****** Set Plotting Toggles ****************************************************

// plotting color and color name for title

* electricity 
local electricity_col "dknavy"
local electricity_colTT "Blue"

* other energy 
local other_energy_col "dkorange"
local other_energy_colTT "Orange"
			
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
* Step 2: Plot, Plot, Plot
********************************************************************************


// set up plotting locals
loc SE ""
loc nonSE ""
local colorGuide ""	

foreach var in "electricity" "other_energy" {

	// assign product index
	if "`var'"=="electricity" {
		local pg=1
	}
	else if "`var'"=="other_energy" {
		local pg=2
	}

	* construct local variable that holds dose response
	
	local line = ""
	local add = ""
	
	forval k = 1/4 {

		local line = "`line'`add'_b[c.indp`pg'#c.indf1#c.FD_temp1_GMFD] * (temp1 - 20^`k')"
		local add " + "

	} 

	* use ster to estimate dose response

	estimates use "$root/sters/FD_FGLS_global_`model'"
	predictnl yhat_`var' = `line', se(se_`var') ci(lower_`var' upper_`var')
	
	// add predicted dose reponse to plotting locals
	loc SE = "`SE' rarea upper_`var' lower_`var' temp1, col(``var'_col'%30) || line yhat_`var' temp1, lc (``var'_col') ||"
	loc noSE "`noSE' line yhat_`var' temp1, lc (``var'_col') ||"
	loc colorGuide = "`colorGuide' `var' (``var'_colTT')"

}

//plot with SE
tw `SE' , ///
yline(0, lwidth(vthin)) xlabel(-5(10)35, labsize(vsmall)) ///
ylabel(, labsize(vsmall) nogrid) legend(off) ///
title("Global Dose Response" , size(vsmall)) ///
subtitle("`colorGuide' " , size(vsmall)) ///
ytitle("", size(small)) xtitle("", size(vsmall)) ///
plotregion(color(white)) graphregion(color(white))
graph export "$root/figures/figA5_product_overlay_global.pdf", replace


//plot with no SE
tw `noSE' , ///
yline(0, lwidth(vthin)) xlabel(-5(10)35, labsize(vsmall)) ///
ylabel(, labsize(vsmall) nogrid) legend(off) ///
title("Global Dose Response" , size(vsmall)) ///
subtitle("`colorGuide'" , size(vsmall)) ///
ytitle("", size(small)) xtitle("", size(small)) ///
plotregion(color(white)) graphregion(color(white))
graph export "$root/figures/figA5_product_overlay_global_noSE.pdf", replace

