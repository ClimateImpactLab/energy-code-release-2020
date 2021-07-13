/*

Purpose: Plot the energy/other energy separated version of 1A

*/

foreach fuel in "electricity" "other_energy" {
	set scheme s1color

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
	*Step 1: Load Data and Clean for Plotting
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
	* Step 2: Plot Plot Plot
	********************************************************************************
	local graphic ""
	local graphic_noSE ""

	// loop over income deciles
	forval lg=1/10 {
				
		// set up plotting locals
		local SE ""
		local noSE ""
		local colorGuide ""	

		foreach var in `fuel' {

			// assign product index
			if "`var'" == "electricity" {
				local pg = 1
			}
			else if "`var'" == "other_energy" {
				local pg=2
			}

			* construct local variable that holds dose response
			
			local line = ""
			local add = ""
			
			forval k = 1/2 {

				local line = "`line'`add'_b[c.indp`pg'#c.indf1#c.FD_I`lg'temp`k'] * (temp`k' - 20^`k')"
				local add " + "

			} 

			* use ster to estimate dose response

			estimates use "$OUTPUT/sters/FD_FGLS_income_decile_`model'"
			predictnl yhat`lg'_`var' = `line', se(se`lg'_`var') ci(lower`lg'_`var' upper`lg'_`var')
			
			// add predicted dose reponse to plotting locals
			loc SE = "`SE' rarea upper`lg'_`var' lower`lg'_`var' temp1, col(``var'_col'%30) || line yhat`lg'_`var' temp1, lc (``var'_col') ||"
			loc noSE "`noSE' line yhat`lg'_`var' temp1, lc (``var'_col') ||"
			loc colorGuide = "`colorGuide' `var' (``var'_colTT')"

		}
		


		//plot with SE
		tw `SE' , ///
		yline(0, lwidth(vthin)) xlabel(-5(10)35, labsize(vsmall)) ///
		ylabel(, labsize(vsmall) nogrid) legend(off) ///
		subtitle("", size(vsmall) color(dkgreen)) ///
		ytitle("", size(small)) xtitle("", size(small)) ///
		plotregion(color(white)) graphregion(color(white)) nodraw ///
		name(addgraph`lg', replace)

		//add graphic for combined plotting later
		local graphic = "`graphic' addgraph`lg'"
		local graphic_noSE = "`graphic_noSE' addgraph`lg'_noSE"
	}				
										
	// plot and save combined plot with SE
	graph combine `graphic', imargin(zero) ycomm rows(1) xsize(20) ysize(3) ///
	title("Poly 2 Income Decile Electricity Temperature Response (`model')", size(small)) ///
	subtitle("`colorGuide'", size(small)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb, replace)
	graph export "$OUTPUT/figures/fig_1A_`fuel'_income_decile_`model'.pdf", replace
		
	graph drop _all	

}

